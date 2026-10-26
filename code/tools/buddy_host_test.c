/* Standalone host test of the actual implementation; no RISC-V execution.
 * gcc -std=gnu99 -O2 -Wall -Werror -Wno-unused -fno-builtin -nostdinc
 *     -Ilibs -Ikern/debug -Ikern/mm tools/buddy_host_test.c -o buddy_host_test
 */
#include "../kern/mm/buddy_pmm.c"

extern int printf(const char *, ...);
/* Plain declaration also works with editors that cannot parse GNU attributes. */
extern void exit(int);
struct Page *pages;
size_t npage;
const size_t nbase = DRAM_BASE / PGSIZE;
uint64_t va_pa_offset;
static struct Page descriptors[BUDDY_CAPACITY];
const struct pmm_manager *pmm_manager = &buddy_pmm_manager;

struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
}

void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
}

size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
}

/* Full metadata snapshots belong to the host test, not the kernel stack. */
static unsigned int saved_region[BUDDY_CAPACITY], saved_request[BUDDY_CAPACITY];

static void check_boot_tests_preserve_state(void) {
    size_t saved = nr_free_pages();
    struct Page *live = alloc_pages(3);
    assert(live != NULL);
    size_t live_index = page_index(live);
    memcpy(saved_region, region, sizeof(region));
    memcpy(saved_request, requested, sizeof(requested));
    size_t remaining = nr_free_pages();
    pmm_manager->check();
    assert(nr_free_pages() == remaining);
    assert(memcmp(saved_region, region, sizeof(region)) == 0);
    assert(memcmp(saved_request, requested, sizeof(requested)) == 0);
    assert(requested[live_index] == 3 && live->property == 4);
    assert(!PageProperty(live) && !PageReserved(live));
    free_pages(live, 3);
    assert(nr_free_pages() == saved);
    check_lists();
}

void __panic(const char *file, int line, const char *fmt, ...) {
    printf("assertion at %s:%d (%s)\n", file, line, fmt);
    exit(1);
    /* __panic is declared noreturn by assert.h. Keep that guarantee explicit
     * without requiring a compiler-specific attribute on the host exit(). */
    for (;;) {
    }
}

int cprintf(const char *fmt, ...) {
    return printf("%s", fmt);
}

static void reset(void) {
    pages = descriptors;
    npage = nbase + BUDDY_CAPACITY;
    memset(descriptors, 0, sizeof(descriptors));
    for (size_t i = 0; i < BUDDY_CAPACITY; i ++) {
        SetPageReserved(pages + i);
    }
    buddy_init();
}

int main(int argc, char **argv) {
    reset();
    buddy_init_memmap(pages + 3, 1001);
    buddy_init_memmap(pages + 1024, 4);
    buddy_init_memmap(pages + 1028, 4);
    /* Adjacent separately registered regions must not form an 8-page block. */
    assert(!PageProperty(pages + 1024) || pages[1024].property == 4);
    check_boot_tests_preserve_state();
    if (argc > 1) {
        struct Page *p = buddy_alloc_pages(3);
        assert(p != NULL);
        if (argv[1][0] == 'd') {
            buddy_free_pages(p, 3);
            buddy_free_pages(p, 3);
        } else if (argv[1][0] == 'i') {
            buddy_free_pages(p + 1, 1);
        } else if (argv[1][0] == 'z') {
            alloc_pages(0);
        } else if (argv[1][0] == 'f') {
            free_pages(p, 0);
        } else {
            buddy_free_pages(p, 4);
        }
        return 2; /* Invalid frees must have panicked. */
    }
    size_t saved = nr_free;
    list_entry_t allocated;
    list_init(&allocated);
    struct Page *p;
    size_t count = 0;
    while ((p = buddy_alloc_pages(1)) != NULL) {
        assert(region[page_index(p)] != 0);
        list_add(&allocated, &p->page_link);
        count ++;
    }
    assert(count == saved && nr_free == 0);
    while (!list_empty(&allocated)) {
        p = le2page(list_next(&allocated), page_link);
        list_del_init(&p->page_link);
        buddy_free_pages(p, 1);
    }
    assert(nr_free == saved);
    check_lists();
    reset();
    buddy_init_memmap(pages + 1024, 4);
    buddy_init_memmap(pages + 1028, 4);
    assert(buddy_alloc_pages(8) == NULL);
    reset();
    buddy_init_memmap(pages, BUDDY_CAPACITY);
    check_boot_tests_preserve_state();
    p = buddy_alloc_pages(BUDDY_CAPACITY - 1);
    assert(p == pages && nr_free == 0);
    buddy_free_pages(p, BUDDY_CAPACITY - 1);
    assert(nr_free == BUDDY_CAPACITY);
    check_lists();
    /* Repeated mixed-size allocation/free with changing release order. */
    struct Page *slots[64] = {NULL};
    size_t sizes[64];
    unsigned int seed = 1;
    for (size_t i = 0; i < 10000; i ++) {
        seed = seed * 1664525U + 1013904223U;
        size_t slot = (seed >> 16) % 64;
        if (slots[slot] != NULL) {
            buddy_free_pages(slots[slot], sizes[slot]);
            slots[slot] = NULL;
        } else {
            sizes[slot] = (seed >> 8) % 127 + 1;
            slots[slot] = buddy_alloc_pages(sizes[slot]);
        }
        if (i % 100 == 0) {
            check_lists();
        }
    }
    for (size_t i = 0; i < 64; i ++) {
        if (slots[i] != NULL) {
            buddy_free_pages(slots[i], sizes[i]);
        }
    }
    check_lists();
    assert(nr_free == BUDDY_CAPACITY && pages[0].property == BUDDY_CAPACITY);
    /* Make the borrowed arena end exactly at npage, exercising the real
     * descriptor-array upper-bound check, not merely a region boundary. */
    reset();
    npage = nbase + TEST_PAGES;
    buddy_init_memmap(pages, TEST_PAGES);
    pmm_manager->check();
    assert(nr_free_pages() == TEST_PAGES);
    assert(PageReserved(pages + TEST_PAGES));
    assert(region[TEST_PAGES] == 0 && requested[TEST_PAGES] == 0);
    check_lists();
    /* Insufficient boot scratch space must skip without reporting success. */
    reset();
    buddy_init_memmap(pages + 1, 13);
    size_t small_count = nr_free_pages();
    pmm_manager->check();
    assert(nr_free_pages() == small_count);
    check_lists();
    printf("buddy host tests passed\n");
    return 0;
}
