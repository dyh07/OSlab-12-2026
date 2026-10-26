#include <assert.h>
#include <defs.h>
#include <list.h>
#include <mmu.h>
#include <pmm.h>
#include <slub.h>
#include <stdio.h>
#include <string.h>

//2513328

/*
 * 本实验实现的是单核环境下的简化 SLUB。
 *
 * 小对象按照固定大小类别进行管理：
 *
 *     8、16、32、64、128、256、512、1024、2048
 *
 * 每个 slab 占用一个 4KB 物理页。
 * slab 页开头保存管理信息，其余空间切分成等大的对象。
 *
 * 空闲对象本身的开头用来保存下一个空闲对象的地址，
 * 因此不需要为每个对象单独创建额外的描述符。
 */

#define SLUB_MAGIC          0x534C5542534C4142UL
#define SLUB_LARGE_MAGIC    0x4C41524745534C42UL

#define SLUB_MIN_SIZE       8
#define SLUB_MAX_SIZE       2048
#define SLUB_CACHE_COUNT    9
#define SLUB_ALIGNMENT      8

/*
 * 空闲对象节点。
 *
 * 当一个对象没有被使用时，对象最前面的若干字节保存 next。
 * 当对象分配给调用者后，这部分空间可以正常被调用者使用。
 */
struct slub_free_object {
    struct slub_free_object *next;
};

/*
 * 一个大小类别对应一个 cache。
 *
 * 例如：
 * caches[0] 管理 8 字节对象；
 * caches[1] 管理 16 字节对象；
 * caches[8] 管理 2048 字节对象。
 */
struct slub_cache {
    size_t object_size;
    list_entry_t slabs;
};

/*
 * 每个 slab 页面开头的管理信息。
 *
 * 这个结构直接保存在 slab 所占用的物理页中。
 */
struct slub_page {
    uint64_t magic;

    /*
     * slab 所属的大小类别。
     *
     * 小对象 slab 使用 0～8；
     * 大对象分配不使用 cache_index。
     */
    size_t cache_index;

    /*
     * 小对象的大小。
     */
    size_t object_size;

    /*
     * 当前正在使用的对象数量。
     */
    size_t inuse;

    /*
     * 本 slab 一共能够容纳多少个对象。
     */
    size_t total;

    /*
     * 空闲对象单链表表头。
     */
    struct slub_free_object *free_list;

    /*
     * 将该 slab 连接到所属 cache 的 slab 链表。
     */
    list_entry_t slab_link;

    /*
     * 该虚拟地址对应的物理页描述符。
     * 释放整个 slab 时需要用到它。
     */
    struct Page *page;

    /*
     * 大对象实际向 Buddy 请求的页数。
     *
     * Buddy 的 free_pages() 要求传入原始请求页数，
     * 因此必须把这个数保存下来。
     *
     * 小对象 slab 固定只使用一页，此字段为 1。
     */
    size_t requested_pages;
};

static struct slub_cache slub_caches[SLUB_CACHE_COUNT];
static bool slub_initialized = 0;

/*
 * 按 SLUB_ALIGNMENT 向上对齐。
 *
 * 例如：
 *     9  向上对齐到 16；
 *     17 向上对齐到 24。
 */
static uintptr_t
slub_align_up(uintptr_t value) {
    return ROUNDUP(value, SLUB_ALIGNMENT);
}

/*
 * 将 Page 描述符转换成内核虚拟地址。
 *
 * page2pa() 得到物理地址；
 * 加上 va_pa_offset 后得到内核直接映射虚拟地址。
 */
static void *
slub_page_to_kva(struct Page *page) {
    return (void *)(page2pa(page) + va_pa_offset);
}

/*
 * 根据申请大小选择最小的合适大小类别。
 *
 * 例如：
 *     1～8 字节   -> 8 字节类别；
 *     9～16 字节  -> 16 字节类别；
 *     17～32 字节 -> 32 字节类别。
 */
static size_t
slub_cache_index(size_t size) {
    size_t index = 0;
    size_t object_size = SLUB_MIN_SIZE;

    while (object_size < size && index + 1 < SLUB_CACHE_COUNT) {
        object_size <<= 1;
        index++;
    }

    return index;
}

/*
 * 计算 slab 页面中第一个对象的地址。
 *
 * 页面最前面先保存 struct slub_page，
 * 后面的地址再按照 8 字节边界向上对齐。
 */
static uintptr_t
slub_first_object(struct slub_page *slab) {
    return slub_align_up((uintptr_t)slab + sizeof(struct slub_page));
}

/*
 * 为某个大小类别创建一个新的 slab。
 *
 * 一个小对象 slab 固定向 Buddy 请求一个物理页。
 */
static struct slub_page *
slub_create_page(size_t cache_index) {
    assert(cache_index < SLUB_CACHE_COUNT);

    struct Page *page = alloc_page();
    if (page == NULL) {
        return NULL;
    }

    struct slub_cache *cache = &slub_caches[cache_index];
    struct slub_page *slab =
        (struct slub_page *)slub_page_to_kva(page);

    memset(slab, 0, PGSIZE);

    slab->magic = SLUB_MAGIC;
    slab->cache_index = cache_index;
    slab->object_size = cache->object_size;
    slab->inuse = 0;
    slab->page = page;
    slab->requested_pages = 1;
    list_init(&slab->slab_link);

    uintptr_t first = slub_first_object(slab);
    uintptr_t end = (uintptr_t)slab + PGSIZE;

    assert(first < end);

    slab->total = (end - first) / slab->object_size;
    assert(slab->total > 0);

    /*
     * 将页面剩余空间切分成多个对象，并组成单链表。
     */
    slab->free_list = NULL;

    for (size_t i = slab->total; i > 0; i--) {
        struct slub_free_object *object =
            (struct slub_free_object *)
                (first + (i - 1) * slab->object_size);

        object->next = slab->free_list;
        slab->free_list = object;
    }

    /*
     * 把新 slab 加入对应 cache 的 slab 链表。
     */
    list_add(&cache->slabs, &slab->slab_link);

    return slab;
}

/*
 * 在一个 cache 中寻找仍有空闲对象的 slab。
 */
static struct slub_page *
slub_find_available_page(struct slub_cache *cache) {
    list_entry_t *head = &cache->slabs;
    list_entry_t *entry = head;

    while ((entry = list_next(entry)) != head) {
        struct slub_page *slab =
            to_struct(entry, struct slub_page, slab_link);

        assert(slab->magic == SLUB_MAGIC);
        assert(slab->inuse <= slab->total);

        if (slab->free_list != NULL) {
            return slab;
        }
    }

    return NULL;
}

/*
 * 分配不超过 2048 字节的小对象。
 */
static void *
slub_alloc_small(size_t size) {
    size_t index = slub_cache_index(size);
    struct slub_cache *cache = &slub_caches[index];

    assert(cache->object_size >= size);

    struct slub_page *slab = slub_find_available_page(cache);

    if (slab == NULL) {
        slab = slub_create_page(index);
        if (slab == NULL) {
            return NULL;
        }
    }

    assert(slab->free_list != NULL);
    assert(slab->inuse < slab->total);

    /*
     * 从空闲对象链表表头取出一个对象。
     */
    struct slub_free_object *object = slab->free_list;
    slab->free_list = object->next;
    slab->inuse++;

    return object;
}

/*
 * 分配大于 2048 字节的大对象。
 *
 * 大对象不再切分成小块，而是直接向 Buddy 请求足够多的连续页。
 * 第一页开头仍然保存 struct slub_page 管理信息。
 */
static void *
slub_alloc_large(size_t size) {
    if (size > (size_t)-1 - sizeof(struct slub_page) -
                   SLUB_ALIGNMENT) {
        return NULL;
    }

    size_t needed =
        size + sizeof(struct slub_page) + SLUB_ALIGNMENT - 1;

    size_t pages_needed =
        (needed + PGSIZE - 1) / PGSIZE;

    struct Page *page = alloc_pages(pages_needed);
    if (page == NULL) {
        return NULL;
    }

    struct slub_page *slab =
        (struct slub_page *)slub_page_to_kva(page);

    /*
     * 这里只清空管理信息，不必把整个大对象全部清零。
     */
    memset(slab, 0, sizeof(struct slub_page));

    slab->magic = SLUB_LARGE_MAGIC;
    slab->object_size = size;
    slab->inuse = 1;
    slab->total = 1;
    slab->page = page;
    slab->requested_pages = pages_needed;
    list_init(&slab->slab_link);

    return (void *)slub_first_object(slab);
}

/*
 * 初始化各个固定大小的 cache。
 */
void
slub_init(void) {
    size_t object_size = SLUB_MIN_SIZE;

    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
        slub_caches[i].object_size = object_size;
        list_init(&slub_caches[i].slabs);
        object_size <<= 1;
    }

    slub_initialized = 1;

    cprintf("SLUB allocator initialized: object size 8 - 2048 bytes.\n");
}

/*
 * 对外提供的任意大小内存分配接口。
 */
void *
kmalloc(size_t size) {
    assert(slub_initialized);

    /*
     * 将申请 0 字节规范化为 1 字节。
     * 这样返回值仍然是一个可以安全释放的有效对象。
     */
    if (size == 0) {
        size = 1;
    }

    if (size <= SLUB_MAX_SIZE) {
        return slub_alloc_small(size);
    }

    return slub_alloc_large(size);
}

/*
 * 检查 ptr 是否已经存在于空闲链表中。
 *
 * 这可以发现最常见的重复释放错误。
 */
static bool
slub_object_is_free(struct slub_page *slab, void *ptr) {
    struct slub_free_object *object = slab->free_list;
    size_t count = 0;

    while (object != NULL) {
        assert(count < slab->total);

        if ((void *)object == ptr) {
            return 1;
        }

        object = object->next;
        count++;
    }

    return 0;
}

/*
 * 释放一个小对象。
 */
static void
slub_free_small(struct slub_page *slab, void *ptr) {
    assert(slab->magic == SLUB_MAGIC);
    assert(slab->cache_index < SLUB_CACHE_COUNT);
    assert(slab->inuse > 0);
    assert(slab->inuse <= slab->total);

    uintptr_t first = slub_first_object(slab);
    uintptr_t address = (uintptr_t)ptr;
    uintptr_t end =
        first + slab->total * slab->object_size;

    /*
     * ptr 必须位于对象区域内，而且必须正好指向某个对象的开头。
     */
    assert(address >= first);
    assert(address < end);
    assert((address - first) % slab->object_size == 0);

    /*
     * 如果对象已经在空闲链表中，说明发生了重复释放。
     */
    assert(!slub_object_is_free(slab, ptr));

    struct slub_free_object *object =
        (struct slub_free_object *)ptr;

    object->next = slab->free_list;
    slab->free_list = object;
    slab->inuse--;

    /*
     * slab 中已经没有正在使用的对象时，将整个页面归还给 Buddy。
     *
     * 注意：free_page() 后 slab 所在内存就不能再访问了，
     * 因此先保存 page，并先从链表中删除 slab。
     */
    if (slab->inuse == 0) {
        struct Page *page = slab->page;

        list_del_init(&slab->slab_link);
        slab->magic = 0;

        free_page(page);
    }
}

/*
 * 释放一个大对象。
 */
static void
slub_free_large(struct slub_page *slab, void *ptr) {
    assert(slab->magic == SLUB_LARGE_MAGIC);
    assert(slab->inuse == 1);
    assert(slab->total == 1);
    assert(slab->page != NULL);
    assert(slab->requested_pages > 0);

    /*
     * 大对象必须从管理头之后的第一个对齐地址开始。
     */
    assert((uintptr_t)ptr == slub_first_object(slab));

    struct Page *page = slab->page;
    size_t requested_pages = slab->requested_pages;

    slab->magic = 0;

    /*
     * 必须传回原始请求页数，而不是 Buddy 向上取整后的页数。
     */
    free_pages(page, requested_pages);
}

/*
 * 对外提供的释放接口。
 */
void
kfree(void *ptr) {
    assert(slub_initialized);

    if (ptr == NULL) {
        return;
    }

    /*
     * 无论是小对象还是大对象，其管理信息都保存在对象所在内存块
     * 第一页的页首。因此将 ptr 向下按 4KB 对齐即可找到管理头。
     */
    struct slub_page *slab =
        (struct slub_page *)ROUNDDOWN((uintptr_t)ptr, PGSIZE);

    if (slab->magic == SLUB_MAGIC) {
        slub_free_small(slab, ptr);
        return;
    }

    if (slab->magic == SLUB_LARGE_MAGIC) {
        slub_free_large(slab, ptr);
        return;
    }

    panic("kfree called with invalid pointer");
}

/*
 * 检查小对象内容互不干扰。
 */
static void
slub_test_different_sizes(void) {
    static const size_t sizes[] = {
        1, 8, 9, 16, 17, 31, 32, 33,
        63, 64, 65, 127, 128, 129,
        255, 256, 257, 511, 512, 513,
        1023, 1024, 1025, 2048, 2049, 5000
    };

    void *objects[sizeof(sizes) / sizeof(sizes[0])];

    size_t count = sizeof(sizes) / sizeof(sizes[0]);

    for (size_t i = 0; i < count; i++) {
        objects[i] = kmalloc(sizes[i]);
        assert(objects[i] != NULL);
        assert(((uintptr_t)objects[i] % SLUB_ALIGNMENT) == 0);

        /*
         * 写入第一个和最后一个字节，检查申请范围确实可访问。
         */
        unsigned char *bytes = (unsigned char *)objects[i];
        bytes[0] = (unsigned char)(i + 1);
        bytes[sizes[i] - 1] = (unsigned char)(0xA0 + i);
    }

    /*
     * 再次读取，检查对象之间没有发生重叠或相互覆盖。
     */
    for (size_t i = 0; i < count; i++) {
        unsigned char *bytes = (unsigned char *)objects[i];


        /*
         * 当 size 为 1 时，第一个字节和最后一个字节是同一个位置，
         * 最后一次写入的是 0xA0 + i。
         */
        if (sizes[i] == 1) {
            assert(bytes[0] == (unsigned char)(0xA0 + i));
        } else {
            assert(bytes[sizes[i] - 1] ==
                   (unsigned char)(0xA0 + i));
        }
    }

    /*
     * 使用非顺序方式释放，模拟更真实的使用情况。
     */
    for (size_t i = 0; i < count; i += 2) {
        kfree(objects[i]);
    }

    for (size_t i = 1; i < count; i += 2) {
        kfree(objects[i]);
    }
}

/*
 * 检查释放的小对象能否重新使用。
 */
static void
slub_test_reuse(void) {
    enum {
        OBJECT_COUNT = 64
    };

    void *objects[OBJECT_COUNT];
    void *released[OBJECT_COUNT / 2];

    for (size_t i = 0; i < OBJECT_COUNT; i++) {
        objects[i] = kmalloc(24);
        assert(objects[i] != NULL);
        memset(objects[i], (int)i, 24);
    }

    /*
     * 先释放偶数编号对象，制造许多空洞。
     */
    for (size_t i = 0; i < OBJECT_COUNT; i += 2) {
        released[i / 2] = objects[i];
        kfree(objects[i]);
        objects[i] = NULL;
    }

    /*
     * 再分配相同大小对象。
     * 至少应当从刚才释放的空洞中复用地址。
     */
    for (size_t i = 0; i < OBJECT_COUNT; i += 2) {
        objects[i] = kmalloc(24);
        assert(objects[i] != NULL);

        bool found = 0;

        for (size_t j = 0; j < OBJECT_COUNT / 2; j++) {
            if (objects[i] == released[j]) {
                found = 1;
                break;
            }
        }

        assert(found);
    }

    for (size_t i = 0; i < OBJECT_COUNT; i++) {
        kfree(objects[i]);
    }
}

/*
 * SLUB 综合测试入口。
 */
void
slub_check(void) {
    assert(slub_initialized);

    size_t free_before = nr_free_pages();

    slub_test_different_sizes();
    slub_test_reuse();

    /*
     * 所有对象都释放后，所有空 slab 和大对象占用的页面都应当
     * 归还给 Buddy，所以空闲页数量必须恢复到测试前。
     */
    assert(nr_free_pages() == free_before);

    /*
     * NULL 可以安全释放。
     */
    kfree(NULL);

    cprintf("SLUB different-size allocation test passed!\n");
    cprintf("SLUB freed-object reuse test passed!\n");
    cprintf("SLUB page return test passed!\n");
    cprintf("SLUB all tests passed!\n");
}
