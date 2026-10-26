#include <buddy_pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>

//2512607
/* The boot mapping permits at most 128 MiB (32768 pages). Metadata lives
 * in kernel BSS, so page_init automatically reserves its physical storage. */
#define BUDDY_MAX_ORDER 15
#define BUDDY_CAPACITY ((PHYSICAL_MEMORY_END - DRAM_BASE) / PGSIZE)
static list_entry_t free_lists[BUDDY_MAX_ORDER + 1]; //free_lists按阶数管理空闲块
static size_t nr_free;
static unsigned int region[BUDDY_CAPACITY]; //记录物理页所属的初始化区域
static unsigned int requested[BUDDY_CAPACITY]; //记录实际申请的页数
//计算某阶块的页数
static size_t
block_size(unsigned int order) {
    return (size_t)1 << order;
}
//计算需要哪个阶数
static unsigned int
request_order(size_t n) {
    unsigned int order = 0;
    while (order < BUDDY_MAX_ORDER && block_size(order) < n) {
        order ++;
    }
    return order;
}
//获取页描述符索引
/* Validate addresses before pointer subtraction or descriptor access. */
static size_t
page_index(struct Page *page) {
    uintptr_t addr = (uintptr_t)page, start = (uintptr_t)pages;
    assert(npage >= nbase && npage - nbase <= BUDDY_CAPACITY);
    assert(addr >= start && (addr - start) % sizeof(struct Page) == 0);
    size_t index = (addr - start) / sizeof(struct Page);
    assert(index < npage - nbase);
    return index;
}
//把空闲块加入链表
static void
add_block(struct Page *page, unsigned int order) {
    page->property = block_size(order);
    SetPageProperty(page);
    list_add(&free_lists[order], &page->page_link);
}
//从链表中移除空闲块
static void
remove_block(struct Page *page) {
    list_del_init(&page->page_link);
    ClearPageProperty(page);
    page->property = 0;
}
/*初始化所有 order 的空闲链表。
将空闲页总数设置为 0。
清空区域信息和申请记录。*/
static void
buddy_init(void) {
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
        list_init(&free_lists[order]);
    }
    nr_free = 0;
    memset(region, 0, sizeof(region));
    memset(requested, 0, sizeof(requested));
}
//将物理页加入伙伴系统base：这段物理页对应的起始页描述符。n：这段连续物理页的数量。
static void
buddy_init_memmap(struct Page *base, size_t n) {
    size_t index = page_index(base);
    assert(n > 0 && n <= npage - nbase - index);
    /* Each invocation is a separate legal region, even if adjacent. */
    unsigned int id = index + 1;
    for (size_t i = 0; i < n; i ++) {
        assert(PageReserved(base + i) && region[index + i] == 0);
    }
    for (size_t i = 0; i < n; i ++) {
        ClearPageReserved(base + i);
        ClearPageProperty(base + i);
        base[i].property = 0;
        set_page_ref(base + i, 0);
        list_init(&base[i].page_link);
        region[index + i] = id;
    }
    nr_free += n;
    while (n != 0) {
        unsigned int order = BUDDY_MAX_ORDER;
        /* Alignment is in physical page numbers, not Page addresses. */
        while (block_size(order) > n ||
               (page2ppn(base) & (block_size(order) - 1)) != 0) {
            order --;
        }
        add_block(base, order);
        base += block_size(order);
        n -= block_size(order);
    }
}
//分配物理页
static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free || n > block_size(BUDDY_MAX_ORDER)) {
        return NULL;
    }
    unsigned int wanted = request_order(n), order = wanted;
    while (order <= BUDDY_MAX_ORDER && list_empty(&free_lists[order])) {
        order ++;
    }
    if (order > BUDDY_MAX_ORDER) {
        return NULL;
    }
    struct Page *page = le2page(list_next(&free_lists[order]), page_link);
    remove_block(page);
    while (order > wanted) {
        order --;
        add_block(page + block_size(order), order);
    }
    page->property = block_size(wanted);
    requested[page_index(page)] = n;
    nr_free -= block_size(wanted);
    return page;
}
//释放物理页，进行合并
static void
buddy_free_pages(struct Page *base, size_t n) {
    size_t index = page_index(base);
    assert(n > 0 && requested[index] == n);
    unsigned int order = request_order(n);
    size_t size = block_size(order);
    assert(size >= n && size <= npage - nbase - index);
    assert(!PageProperty(base) && base->property == size);
    assert((page2ppn(base) & (size - 1)) == 0);
    unsigned int id = region[index];
    assert(id != 0);
    for (size_t i = 0; i < size; i ++) {
        assert(!PageReserved(base + i) && !PageProperty(base + i));
        assert(region[index + i] == id);
        assert(i == 0 || requested[index + i] == 0);
    }
    requested[index] = 0;
    for (size_t i = 0; i < size; i ++) {
        base[i].property = 0;
        set_page_ref(base + i, 0);
    }
    nr_free += size;
    while (order < BUDDY_MAX_ORDER) {
        size_t buddy_ppn = page2ppn(base) ^ block_size(order);
        if (buddy_ppn < nbase || buddy_ppn >= npage) {
            break;
        }
        size_t other = buddy_ppn - nbase;
        struct Page *buddy = pages + other;
        if (block_size(order) > npage - buddy_ppn ||
            region[other] != id || PageReserved(buddy) ||
            !PageProperty(buddy) || buddy->property != block_size(order)) {
            break;
        }
        remove_block(buddy);
        if (buddy_ppn < page2ppn(base)) {
            base = buddy;
        }
        order ++;
    }
    add_block(base, order);
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

static void
check_lists(void) {
    size_t total = 0;
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
        list_entry_t *head = &free_lists[order], *le = head;
        while ((le = list_next(le)) != head) {
            struct Page *page = le2page(le, page_link);
            size_t index = page_index(page), size = block_size(order);
            assert(PageProperty(page) && page->property == size);
            assert((page2ppn(page) & (size - 1)) == 0);
            assert(size <= npage - nbase - index && region[index] != 0);
            for (size_t i = 0; i < size; i ++) {
                assert(!PageReserved(page + i) && requested[index + i] == 0);
                assert(region[index + i] == region[index]);
                assert(i == 0 || (!PageProperty(page + i) && page[i].property == 0));
            }
            total += size;
            assert(total <= nr_free);
        }
    }
    assert(total == nr_free);
}

/* BEGIN BUDDY TESTS: no allocation/merge algorithm is changed below.
 * Tests run synchronously during boot, before other allocator users run.
 * BSS snapshots avoid placing several kilobytes on the kernel stack. */
#define TEST_PAGES 64
static struct {
    struct Page *base;
    struct Page descriptors[TEST_PAGES];
    unsigned int regions[TEST_PAGES], requests[TEST_PAGES];
    list_entry_t heads[BUDDY_MAX_ORDER + 1];
    size_t saved_free;
} test_state;

static size_t
test_list_count(unsigned int order) {
    size_t count = 0;
    list_entry_t *head = &free_lists[order], *le = head;
    while ((le = list_next(le)) != head) {
        assert(++ count <= BUDDY_CAPACITY);
        assert(le->next->prev == le && le->prev->next == le);
    }
    return count;
}

/* Stronger sandbox invariant: no overlapping free blocks; every arena page
 * is either reserved, free exactly once, or covered by one live allocation. */
static void
test_arena_check(void) {
    unsigned char covered[TEST_PAGES] = {0};
    struct Page *base = test_state.base;
    size_t index = page_index(base);
    check_lists();
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
        test_list_count(order);
        list_entry_t *head = &free_lists[order], *le = head;
        while ((le = list_next(le)) != head) {
            struct Page *p = le2page(le, page_link);
            size_t pos = page_index(p) - index, size = block_size(order);
            assert(pos < TEST_PAGES && size <= TEST_PAGES - pos);
            for (size_t i = 0; i < size; i ++) {
                assert(covered[pos + i] == 0);
                covered[pos + i] = 1;
            }
        }
    }
    for (size_t pos = 0; pos < TEST_PAGES; pos ++) {
        if (requested[index + pos] == 0) {
            continue;
        }
        struct Page *p = base + pos;
        size_t size = p->property, n = requested[index + pos];
        assert(size > 0 && (size & (size - 1)) == 0);
        assert(size >= n && (size == 1 || size / 2 < n));
        assert(size <= TEST_PAGES - pos && !PageProperty(p));
        assert((page2ppn(p) & (size - 1)) == 0);
        for (size_t i = 0; i < size; i ++) {
            assert(covered[pos + i] == 0 && !PageReserved(p + i));
            assert(!PageProperty(p + i) && page_ref(p + i) == 0);
            assert(region[index + pos + i] == region[index + pos]);
            assert(i == 0 || (requested[index + pos + i] == 0 && p[i].property == 0));
            covered[pos + i] = 1;
        }
    }
    for (size_t i = 0; i < TEST_PAGES; i ++) {
        if (region[index + i] == 0) {
            assert(PageReserved(base + i) && covered[i] == 0);
            assert(base[i].property == 0 && requested[index + i] == 0);
        } else {
            assert(!PageReserved(base + i) && covered[i] == 1);
        }
    }
}

/* Discard only the borrowed arena's temporary state. Never call buddy_init:
 * that would erase metadata belonging to real kernel allocations. */
static void
test_arena_reset(void) {
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
        list_init(&free_lists[order]);
    }
    nr_free = 0;
    size_t index = page_index(test_state.base);
    for (size_t i = 0; i < TEST_PAGES; i ++) {
        struct Page *p = test_state.base + i;
        p->flags = p->property = 0;
        SetPageReserved(p);
        set_page_ref(p, 0);
        list_init(&p->page_link);
        region[index + i] = requested[index + i] = 0;
    }
}

static void
test_single_block(unsigned int order, struct Page *base) {
    test_arena_check();
    assert(nr_free_pages() == block_size(order));
    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i ++) {
        assert(test_list_count(i) == (i == order ? 1 : 0));
    }
    assert(le2page(list_next(&free_lists[order]), page_link) == base);
    assert(base->property == block_size(order) && PageProperty(base));
}

/* Allocation failure must leave descriptors, metadata, heads and count intact. */
static void
test_failed_alloc(size_t n) {
    static struct Page before[TEST_PAGES];
    static unsigned int old_region[TEST_PAGES], old_request[TEST_PAGES];
    list_entry_t heads[BUDDY_MAX_ORDER + 1];
    size_t count = nr_free_pages(), index = page_index(test_state.base);
    memcpy(before, test_state.base, sizeof(before));
    memcpy(old_region, region + index, sizeof(old_region));
    memcpy(old_request, requested + index, sizeof(old_request));
    memcpy(heads, free_lists, sizeof(heads));
    assert(alloc_pages(n) == NULL);
    assert(nr_free_pages() == count);
    assert(memcmp(before, test_state.base, sizeof(before)) == 0);
    assert(memcmp(old_region, region + index, sizeof(old_region)) == 0);
    assert(memcmp(old_request, requested + index, sizeof(old_request)) == 0);
    assert(memcmp(heads, free_lists, sizeof(heads)) == 0);
    test_arena_check();
}

static void
test_basic_allocation(void) {
    const size_t counts[] = {1, 2, 4, 8, 3, 5, 7};
    const size_t actual[] = {1, 2, 4, 8, 4, 8, 8};
    struct Page *allocated[7];
    test_arena_reset();
    buddy_init_memmap(test_state.base, TEST_PAGES);
    for (size_t i = 0; i < 7; i ++) {
        size_t before = nr_free_pages();
        struct Page *p = allocated[i] = alloc_pages(counts[i]);
        assert(p != NULL);
        size_t index = page_index(p);
        assert(index >= page_index(test_state.base));
        assert(index + actual[i] <= page_index(test_state.base) + TEST_PAGES);
        assert(p->property == actual[i] && requested[index] == counts[i]);
        assert(before - nr_free_pages() == actual[i]);
        assert((page2pa(p) & (actual[i] * PGSIZE - 1)) == 0);
        for (size_t j = 0; j < i; j ++) {
            assert(p + actual[i] <= allocated[j] || allocated[j] + actual[j] <= p);
        }
        test_arena_check();
    }
    /* A non-LIFO order also exercises holes between still allocated blocks. */
    const unsigned int release[] = {3, 0, 5, 1, 6, 2, 4};
    for (size_t i = 0; i < 7; i ++) {
        unsigned int j = release[i];
        size_t before = nr_free_pages();
        free_pages(allocated[j], counts[j]);
        assert(nr_free_pages() - before == actual[j]);
        test_arena_check();
    }
    test_single_block(6, test_state.base);
    cprintf("Buddy System basic allocation test passed!\n");
}

static void
test_split(void) {
    struct Page *base = test_state.base;
    test_arena_reset();
    buddy_init_memmap(base, 16);
    test_single_block(4, base);
    struct Page *one = alloc_pages(1);
    assert(one == base && nr_free_pages() == 15);
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
        assert(test_list_count(order) == (order < 4 ? 1 : 0));
        if (order < 4) {
            struct Page *p = le2page(list_next(&free_lists[order]), page_link);
            assert(p == base + block_size(order));
            assert(p->property == block_size(order) && PageProperty(p));
        }
    }
    test_arena_check();
    struct Page *eight = alloc_pages(8), *four = alloc_pages(4);
    struct Page *two = alloc_pages(2), *last = alloc_pages(1);
    assert(eight == base + 8 && four == base + 4);
    assert(two == base + 2 && last == base + 1);
    assert(nr_free_pages() == 0);
    test_arena_check();
    free_pages(two, 2);
    free_pages(eight, 8);
    free_pages(last, 1);
    free_pages(four, 4);
    free_pages(one, 1);
    test_single_block(4, base);
    cprintf("Buddy System split test passed!\n");
}

static void
test_merge(void) {
    struct Page *base = test_state.base, *p[4];
    test_arena_reset();
    buddy_init_memmap(base, 16);
    for (size_t i = 0; i < 4; i ++) {
        p[i] = alloc_pages(4);
        assert(p[i] == base + 4 * i);
    }
    assert((page2ppn(p[0]) ^ 4) == page2ppn(p[1]));
    assert((page2ppn(p[2]) ^ 4) == page2ppn(p[3]));
    test_arena_check();
    free_pages(p[0], 4);
    assert(test_list_count(2) == 1 && test_list_count(3) == 0);
    test_arena_check();
    free_pages(p[1], 4);
    assert(test_list_count(2) == 0 && test_list_count(3) == 1);
    assert(PageProperty(base) && base->property == 8);
    test_arena_check();
    free_pages(p[3], 4);
    test_arena_check();
    free_pages(p[2], 4); /* 4 + 4 -> 8, then 8 + 8 -> 16. */
    test_single_block(4, base);
    struct Page *large = alloc_pages(16);
    assert(large == base && nr_free_pages() == 0);
    test_arena_check();
    free_pages(large, 16);
    test_single_block(4, base);
    cprintf("Buddy System merge test passed!\n");
}

static void
test_exhaustion_and_reuse(void) {
    struct Page *p[16];
    test_arena_reset();
    buddy_init_memmap(test_state.base, 16);
    for (size_t round = 0; round < 8; round ++) {
        for (size_t i = 0; i < 16; i ++) {
            p[i] = alloc_pages(1);
            assert(p[i] != NULL && nr_free_pages() == 15 - i);
            for (size_t j = 0; j < i; j ++) {
                assert(p[i] != p[j]);
            }
            test_arena_check();
        }
        test_failed_alloc(1);
        test_failed_alloc(2);
        for (size_t i = 0; i < 16; i ++) {
            size_t j = (5 * i + round) % 16; /* Permutation, different each round. */
            free_pages(p[j], 1);
            assert(nr_free_pages() == i + 1);
            test_arena_check();
        }
        test_single_block(4, test_state.base);
    }
}

static void
test_boundary(void) {
    struct Page *base = test_state.base;
    for (unsigned int order = 0; order <= 1; order ++) {
        test_arena_reset();
        buddy_init_memmap(base, block_size(order));
        test_single_block(order, base);
        test_failed_alloc(block_size(order) + 1);
        struct Page *p = alloc_pages(block_size(order));
        assert(p == base && nr_free_pages() == 0);
        test_failed_alloc(1);
        free_pages(p, block_size(order));
        test_single_block(order, base);
    }
    /* Two unaligned pages are separate order-0 blocks, not one order-1. */
    test_arena_reset();
    buddy_init_memmap(base + 1, 2);
    assert(test_list_count(0) == 2 && nr_free_pages() == 2);
    test_failed_alloc(2);
    struct Page *a = alloc_pages(1), *b = alloc_pages(1);
    assert(a != NULL && b != NULL && a != b);
    free_pages(a, 1);
    free_pages(b, 1);
    assert(test_list_count(0) == 2 && test_list_count(1) == 0);
    test_arena_check();
    /* [base+1, base+14): sizes 1,2,4,4,2. Guards stay reserved. */
    test_arena_reset();
    buddy_init_memmap(base + 1, 13);
    assert(test_list_count(0) == 1 && test_list_count(1) == 2);
    assert(test_list_count(2) == 2 && test_list_count(3) == 0);
    test_failed_alloc(8); /* Enough total pages, but no aligned 8-page block. */
    test_failed_alloc(14);
    struct Page *p[13];
    for (size_t i = 0; i < 13; i ++) {
        p[i] = alloc_pages(1);
        assert(p[i] >= base + 1 && p[i] < base + 14);
        test_arena_check();
    }
    test_failed_alloc(1);
    for (size_t i = 13; i > 0; i --) {
        free_pages(p[i - 1], 1);
        test_arena_check();
    }
    assert(nr_free_pages() == 13 && test_list_count(0) == 1);
    assert(test_list_count(1) == 2 && test_list_count(2) == 2);
    /* Physically adjacent buddies, but separately registered regions. */
    test_arena_reset();
    buddy_init_memmap(base, 4);
    buddy_init_memmap(base + 4, 4);
    a = alloc_pages(4);
    b = alloc_pages(4);
    assert(a != NULL && b != NULL && a != b);
    free_pages(b, 4);
    free_pages(a, 4);
    assert(nr_free_pages() == 8 && test_list_count(2) == 2);
    test_failed_alloc(8);
    test_failed_alloc(block_size(BUDDY_MAX_ORDER) + 1);
    /* n == 0 violates the API's assert(n > 0); test it only in a host process. */
    cprintf("Buddy System boundary test passed!\n");
}

static void
buddy_check(void) {
    size_t original = nr_free_pages();
    size_t original_counts[BUDDY_MAX_ORDER + 1];
    check_lists();
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
        original_counts[order] = test_list_count(order);
    }
    /* Only real free pages are borrowed; no kernel/reserved memory is tested.
     * If boot RAM is too fragmented/small, report that tests did not run. */
    struct Page *base = alloc_pages(TEST_PAGES);
    if (base == NULL) {
        assert(nr_free_pages() == original);
        check_lists();
        cprintf("Buddy System tests skipped: no 64-page test block available.\n");
        return;
    }
    test_state.base = base;
    size_t index = page_index(base);
    test_state.saved_free = nr_free_pages();
    memcpy(test_state.heads, free_lists, sizeof(free_lists));
    memcpy(test_state.descriptors, base, sizeof(test_state.descriptors));
    memcpy(test_state.regions, region + index, sizeof(test_state.regions));
    memcpy(test_state.requests, requested + index, sizeof(test_state.requests));

    test_basic_allocation();
    test_split();
    test_merge();
    test_exhaustion_and_reuse();
    test_boundary();

    /* Saved nodes still refer to the original free_lists addresses. Restoring
     * heads in place reconnects them; copying lists to new heads would not. */
    memcpy(base, test_state.descriptors, sizeof(test_state.descriptors));
    memcpy(region + index, test_state.regions, sizeof(test_state.regions));
    memcpy(requested + index, test_state.requests, sizeof(test_state.requests));
    memcpy(free_lists, test_state.heads, sizeof(free_lists));
    nr_free = test_state.saved_free;
    check_lists();
    free_pages(base, TEST_PAGES);
    assert(nr_free_pages() == original);
    check_lists();
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
        assert(test_list_count(order) == original_counts[order]);
    }
    test_state.base = NULL;
    cprintf("Buddy System all tests passed!\n");
}
/* END BUDDY TESTS */

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
