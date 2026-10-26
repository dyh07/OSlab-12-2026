#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>

//2513328

/*
 * 初始化 SLUB 分配器。
 *
 * 必须在 pmm_init() 完成之后调用，因为 SLUB 需要通过
 * alloc_pages() 和 free_pages() 向底层 Buddy 分配器申请和归还页面。
 */
void slub_init(void);

/*
 * 从内核内存中分配 size 字节。
 *
 * 1～2048 字节使用小对象缓存；
 * 大于 2048 字节直接通过 Buddy 分配连续物理页。
 *
 * 分配失败时返回 NULL。
 */
void *kmalloc(size_t size);

/*
 * 释放 kmalloc() 返回的内存。
 *
 * ptr 必须是以前由 kmalloc() 返回且尚未释放的地址。
 * kfree(NULL) 不执行任何操作。
 */
void kfree(void *ptr);

/*
 * 检查 SLUB 分配器的基本正确性。
 *
 * 测试内容包括：
 * 1. 不同大小对象的分配；
 * 2. 同一大小类别内对象的复用；
 * 3. 多个 slab 页面的使用；
 * 4. 大对象的分配与释放；
 * 5. 页面是否最终全部归还给 Buddy。
 */
void slub_check(void);

#endif /* !__KERN_MM_SLUB_H__ */

