#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <buddy_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <riscv.h>
#include <dtb.h>

// virtual address of physical page array物理页描述符数组的虚拟地址
struct Page *pages;
// amount of physical memory (in pages)物理内存的数量，以页为单位，即内核可管理物理页的页号上界，这里是先初始化为0
size_t npage = 0;
// the kernel image is mapped at VA=KERNBASE and PA=info.base内核镜像被映射到虚拟地址 KERNBASE，它对应的物理地址是物理内存中内核的起始位置
uint64_t va_pa_offset;//这里的VA是虚拟地址，PA是物理地址，`va_pa_offset` 是虚拟地址与物理地址之间的固定差值。
// memory starts at 0x80000000 in RISC-V在本实验的 RISC-V 虚拟机中，内存从物理地址 0x80000000 开始
// DRAM_BASE defined in riscv.h as 0x80000000DRAM_BASE 在 riscv.h 中被定义为 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE;//`nbase` 是 DRAM 第一个物理页面的物理页号：nbase = 0x80000000 / 4096 = 0x80000

// virtual address of boot-time page directory
uintptr_t *satp_virtual = NULL;
// physical address of boot-time page directory
uintptr_t satp_physical;

// physical memory management
const struct pmm_manager *pmm_manager;


static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &best_fit_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
}


//lab2 function1 2513328

static void page_init(void) {
    extern char end[];

    /*
     * 内核采用固定偏移映射：
     *
     *     virtual address = physical address + va_pa_offset
     *
     * PADDR() 会使用 va_pa_offset，因此必须最先设置它。
     */
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;

    /*
     * 从 dtb_init() 保存的设备树信息中取得 DRAM 起点和大小。
     */
    uint64_t mem_base = get_memory_base();
    uint64_t mem_size = get_memory_size();

    /*
     * 设备树解析失败时，这两个值会保持为 0。
     * 此时不能继续初始化，否则后面的地址计算没有意义。
     */
    if (mem_base == 0 || mem_size == 0) {
        panic("invalid physical memory information from DTB");
    }

    /*
     * 检查 mem_base + mem_size 是否发生无符号整数溢出。
     * 如果相加后的值反而小于 mem_base，说明发生了回绕。
     */
    uint64_t detected_mem_end = mem_base + mem_size;
    if (detected_mem_end < mem_base) {
        panic("physical memory range overflow");
    }

    /*
     * 当前启动页表只映射到 PHYSICAL_MEMORY_END，因此即使设备树
     * 报告了更大的内存，也不能管理启动页表映射范围之外的部分。
     */
    uint64_t maxpa = detected_mem_end;
    if (maxpa > PHYSICAL_MEMORY_END) {
        maxpa = PHYSICAL_MEMORY_END;
    }

    /*
     * 内存末端向下按页对齐。
     * 不足一个完整页面的尾部字节不能交给页面分配器。
     */
    maxpa = ROUNDDOWN(maxpa, PGSIZE);

    /*
     * 当前内核加载在 KERNEL_BEGIN_PADDR。设备树给出的范围必须
     * 至少覆盖内核所在位置。
     */
    if (mem_base > KERNEL_BEGIN_PADDR || maxpa <= KERNEL_BEGIN_PADDR) {
        panic("physical memory does not contain the kernel");
    }

    /*
     * npage 是可管理物理页号的上界，而不是物理页数量。
     *
     * 例如 maxpa = 0x88000000：
     *     npage = 0x88000000 >> 12 = 0x88000
     */
    npage = PPN(maxpa);

    if (npage <= nbase) {
        panic("no manageable physical memory");
    }

    /*
     * 输出物理内存探测结果。
     * 注意 detected_mem_end 是开区间末端，因此输出最后一个有效地址
     * 时需要减 1。
     */
    cprintf("physical memory map:\n");
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n",
            mem_size, mem_base, detected_mem_end - 1);

    /*
     * Page 描述符数组放在内核镜像 end 之后。
     *
     * end 是虚拟地址；pages 也是内核虚拟地址。
     * 数组起点向上按页对齐，确保：
     *   1. pages 位于内核之后；
     *   2. pages 满足评分测试中的页对齐要求；
     *   3. 内核尾页不会与描述符数组混用。
     */
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);

    /*
     * Page 数组只需要描述 DRAM 范围 [nbase, npage)。
     */
    size_t page_count = npage - nbase;

    /*
     * 计算描述符数组末端。
     *
     * pages + page_count 是虚拟地址，必须用 PADDR() 转成物理地址，
     * 才能和 maxpa 这样的物理地址比较。
     */
    uintptr_t pages_end_va = (uintptr_t)(pages + page_count);
    uintptr_t pages_end_pa = PADDR(pages_end_va);

    /*
     * 如果描述符数组本身已经放不进物理内存，就不能继续写入数组。
     */
    if (pages_end_pa > maxpa) {
        panic("not enough memory for Page descriptors");
    }

    /*
     * 先把所有物理页标记为保留。
     *
     * 后面的 init_memmap() 只会释放真正可用的区域。
     * 这样 OpenSBI、内核镜像、描述符数组和对齐空隙都会继续保持
     * Reserved 状态。
     */
    for (size_t i = 0; i < page_count; i++) {
        pages[i].flags = 0;
        pages[i].property = 0;
        set_page_ref(&pages[i], 0);
        SetPageReserved(&pages[i]);
    }

    /*
     * Page 描述符数组结束后，继续向上按页对齐。
     * 从 free_begin 开始，页面才可能完整且可分配。
     */
    uintptr_t free_begin = ROUNDUP(pages_end_pa, PGSIZE);

    /*
     * 保险起见，可用区起点不能早于设备树报告的 DRAM 起点。
     */
    uintptr_t aligned_mem_base = ROUNDUP(mem_base, PGSIZE);
    if (free_begin < aligned_mem_base) {
        free_begin = aligned_mem_base;
    }

    /*
     * maxpa 已经向下按页对齐，可以直接作为空闲区的开区间末端。
     */
    uintptr_t free_end = maxpa;

    /*
     * 只有至少存在一个完整页面时才调用 init_memmap()。
     *
     * init_memmap() 要求 n > 0；若空闲区为空仍调用它，会触发断言。
     */
    if (free_begin < free_end) {
        size_t free_page_count = (free_end - free_begin) / PGSIZE;
        init_memmap(pa2page(free_begin), free_page_count);
    }
}





/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // First we should init a physical memory manager(pmm) based on the framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();

    extern char boot_page_table_sv39[];
    satp_virtual = (pte_t*)boot_page_table_sv39;
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}
