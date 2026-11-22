# 实验报告

## 实验基本信息

| 项目 | 内容 |
|------|------|
| **实验名称** | Lab 4：虚拟内存页操作、进程创建与初始化、进程调度 |
| **小组成员** | 2512607－董语晗、2513328－何妍希、2510720－董隽仪 |
| **完成日期** | 2026-11-20 |

### 小组分工

| 成员 | 负责的练习/模块 |
|------|----------------|
| 2512607－董语晗 | 功能模块一：虚拟内存页操作，`kern/mm/pmm.c` |
| 2513328－何妍希 | 功能模块二：进程创建及初始化，`kern/process/proc.c` |
| 2510720－董隽仪 | 功能模块三：进程调度及上下文切换，`proc.c`、`sched.c`、`switch.S` |

---

## 一、实验目的

1. 了解虚拟内存管理的基本结构，掌握虚拟内存的组织与管理方式
2. 了解内核线程创建/执行的管理过程
3. 了解内核线程的切换和基本调度过程

## 二、实验环境

| 项目 | 配置 |
|------|------|
| 开发系统       | WSL Ubuntu-22.04                                    |
| 目标架构       | RISC-V RV64，Sv39 分页                              |
| 编译工具链     | `riscv64-unknown-elf-gcc`、`riscv64-unknown-elf-ld` |
| 构建与运行     | GNU Make、`qemu-system-riscv64`，QEMU virt 平台     |
| 固件与内存     | OpenSBI v0.4，128 MB DRAM，起点 `0x80000000`        |
| 物理内存分配器 | `best_fit_pmm_manager`                              |

| 成员 | AI 编程工具 | 底层模型 |
|------|------------|---------|
| 2512607 | Codex | GPT6.1 |
| 2513328 | Codex | GPT6.1 |
| 2510720 | Codex | GPT6.1 |

## 三、实验整体逻辑分析

### 3.1 本章节的逻辑主线

本实验围绕“准备地址空间 → 创建内核线程 → 调度并执行线程”展开。物理内存分配器提供页面，页表操作把页面组织成可访问的地址空间，进程模块为线程准备 PCB 和首次运行现场，调度模块再把这些静态数据恢复成 CPU 上真正执行的线程。

主要启动链为：

```text
kern_init
  → pmm_init（含页表检查）
  → pic_init / idt_init
  → vmm_init
  → proc_init（建立 idleproc，创建 initproc）
  → clock_init / intr_enable
  → cpu_idle
  → schedule
  → proc_run
  → switch_to
```

新线程首次执行接续为：

```text
forkret → forkrets → __trapret → kernel_thread_entry
        → init_main("Hello world!!") → do_exit
```

### 3.2 功能的逐步实现

1. 先实现 `page_insert` 和 `page_remove`，保证映射维护、引用计数和 TLB 更新正确，为后续地址空间操作提供基础。
2. 再实现 PCB 分配、内核栈配置、首次运行现场构造与线程登记，使系统中存在可运行的 initproc。
3. 最后实现可运行线程选择、页表切换和寄存器恢复，把 initproc 从“链表中的结构体”变成实际执行的线程。

三个模块的连接点是：页表物理地址保存在 PCB 的 `pgdir` 中；模块二构造的 `context` 和 `trapframe`，由模块三及异常返回代码恢复。

## 四、实验内容与实现

### 功能模块一：虚拟内存页操作

**负责人：** 2512607董语晗

#### 模块功能描述

```c
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm);
void page_remove(pde_t *pgdir, uintptr_t la);
```

实现位置为 `kern/mm/pmm.c` ，模块负责建立和删除页映射，并维护物理页的引用计数。

`page_insert` 首先记录最高级目录项原来是否有效，再调用 `get_pte(pgdir, la, 1)` 定位或创建叶子页表项。如果分配失败，则返回 `-E_NO_MEM`；若本次调用只分配了第一个中间页表、随后分配失败，还会撤销新目录项、刷新对应 TLB 并释放该中间页表，避免遗留半完成的分配。

成功取得页表项后，先增加目标页面引用计数，再分情况处理：

| 原映射情况 | 处理方式 | 引用计数结果 |
|------------|----------|--------------|
| 原地址未映射 | 直接建立新映射 | 新页增加一次引用 |
| 原地址映射同一物理页 | 抵消预先增加的引用，再更新权限 | 引用数保持不变 |
| 原地址映射其他物理页 | 调用 `page_remove` 删除旧映射 | 旧页减少一次引用，新页增加一次引用 |

最后使用 `pte_create(page2ppn(page), perm | PTE_V)` 写入页表项，并调用 `tlb_invalidate`。先增加新引用可避免同页重映射时误把仍在使用的页释放。

`page_remove` 使用 `get_pte(pgdir, la, 0)` 查找页表项，不为删除操作分配页表。没有有效映射时直接返回；有映射时先清零页表项并使 TLB 失效，再减少物理页引用数，减至零时释放页面。它保留中间页表页，普通映射撤销不承担整棵页表的回收。

#### 最终提示词

````
[PROMPT]

**任务：**
修改 `kern/mm/pmm.c` 文件，实现虚拟内存页操作功能，包括物理页映射建立和映射删除。
本模块基于 RISC-V 64 位架构和 Sv39 多级页表机制，负责维护线性地址与物理页之间的映射关系。
需要实现两个核心函数：
1. `page_insert()`：建立或更新指定线性地址与物理页之间的映射关系。
2. `page_remove()`：删除指定线性地址对应的物理页映射。
这两个函数共同负责维护页表项、物理页引用计数和 TLB 状态的一致性，为后续虚拟内存管理和进程管理提供基础。

**操作要求：**
在项目中实际编辑上述文件，只在对应区域补全代码。保留标记、已有注释及区域外的内容。沿用现有公开接口、构建配置和评分脚本。

**输出要求：**
1. 直接修改项目中的实际文件。
2. 保留原有代码结构、函数声明和注释。
3. 确保实现符合当前项目已有接口。
4. 完成后展示修改的两个函数，并解释关键代码。
5. 检查可能存在的编译错误、引用计数错误、页表状态错误和 TLB 一致性问题。
6. 给出本模块的编译和测试命令，并说明预期结果。

[RELY]

以下信息是实现本模块时可以依赖的上下文。具体定义必须以当前项目源代码为准。
**1. 相关文件**
主要修改文件：`kern/mm/pmm.c`
需要检查的相关文件：
- `kern/mm/pmm.h`
- `kern/mm/mmu.h`
- `kern/mm/vmm.c`
- `libs/riscv.h`

**2. 相关数据结构和类型**
需要检查并使用项目中已有的：
- `pde_t`
- `pte_t`
- `struct Page`
- `pages`
- `boot_pgdir_va`

重点检查 `struct Page` 中的引用计数字段，以及页表项的数据类型和地址转换关系。

**3. 可依赖的已有函数**
需要检查以下函数的真实实现和接口：
- `get_pte()`：查找或创建指定线性地址对应的页表项。
- `pte_create()`：根据物理地址和权限创建页表项。
- `pte2page()`：根据页表项获取对应物理页描述符。
- `page_ref_inc()`：增加物理页引用计数。
- `page_ref_dec()`：减少物理页引用计数。
- `set_page_ref()`：设置物理页引用计数。
- `alloc_page()`：分配物理页。
- `free_page()`：释放物理页。
- `tlb_invalidate()`：使指定线性地址对应的 TLB 项失效。
- `flush_tlb()`：刷新 TLB。

**4. 相关全局变量和常量**
需要检查：
- `pages`
- `boot_pgdir_va`
- `-E_NO_MEM`

[GUARANTEE]

必须实现以下两个函数，函数签名必须与项目原有声明保持一致：

```c
int page_insert(
    pde_t *pgdir,
    struct Page *page,
    uintptr_t la,
    uint32_t perm
);

void page_remove(
    pde_t *pgdir,
    uintptr_t la
);

**接口要求：**
1. `page_insert()` 成功时返回项目规定的成功值，失败时返回 `-E_NO_MEM`。
2. `page_remove()` 删除指定地址的映射，无映射时直接返回。
3. 正确维护物理页引用计数。
4. 正确维护页表项及权限位。
5. 在映射发生变化时正确处理 TLB 失效。
6. 不得因为重复映射、替换映射或删除无效映射导致引用计数错误。
7. 不得留下半完成的映射状态。

[SPECIFICATION]
1. page_insert()

```c
int page_insert(
    pde_t *pgdir,
    struct Page *page,
    uintptr_t la,
    uint32_t perm
);
```

**Pre-Condition：**

- `pgdir` 指向有效的页目录。
- `page` 指向有效的物理页描述符。
- `la` 是需要建立映射的线性地址。
- 调用者提供的权限参数 `perm` 符合当前实验的页表权限定义。
- 当前物理内存管理和页表管理基础设施已经初始化。

**Post-Condition：**

- 如果操作成功，`la` 对应的页表项指向 `page` 对应的物理页。
- 页表项有效位和权限位符合要求。
- 物理页引用计数与实际映射关系一致。
- 如果映射发生变化，对应 TLB 项已经失效。
- 如果操作失败，不留下不完整的映射。

**Case 1：目标地址尚未建立映射**

当 `la` 对应的页表项不存在有效映射时，建立新的映射，使其指向 `page` 对应的物理页，并正确设置页表权限和引用计数。
如果建立映射过程中需要分配中间级页表页，而分配失败，则返回 `-E_NO_MEM`，不得建立不完整的目标映射。

**Case 2：目标地址已经映射到同一个物理页**

当 `la` 已经映射到 `page` 对应的物理页时，不应重复增加物理页引用计数。
应更新已有页表项的权限，使其符合本次调用要求，并根据实际页表变化情况处理 TLB 失效。

**Case 3：目标地址已经映射到其他物理页**

当 `la` 已经映射到另一个物理页时，应先正确处理旧映射，维护旧物理页的引用计数，再建立指向新物理页的映射。
新旧物理页的引用计数必须正确，不能出现重复计数、引用计数丢失或错误释放。

**Case 4：页表创建过程中内存不足**

如果创建目标映射所需的中间级页表页分配失败，应返回 `-E_NO_MEM`。
必须保证原有有效映射不被意外破坏，同时检查是否存在已经分配但未使用的中间级页表页，确保资源处理符合项目现有页表管理机制。

**Requirements：**

- 必须正确处理同一物理页重复映射的特殊情况。
- 必须避免在覆盖已有映射时错误增加引用计数。
- 必须避免对仍然被映射的物理页进行错误释放。
- 必须根据 Sv39 的页表结构正确处理页表项。
- 必须考虑页表项更新后的 TLB 一致性。
- 需要核实 `get_pte()` 的失败返回方式以及是否会分配中间级页表页。

  2. page_remove()

```c
void page_remove(
    pde_t *pgdir,
    uintptr_t la
);
```

**Pre-Condition：**

- `pgdir` 指向有效的页目录。
- `la` 是需要删除映射的线性地址。
- 页表管理基础设施已经初始化。

**Post-Condition：**

- 如果 `la` 存在有效映射，对应页表项被清除。
- 被映射物理页的引用计数正确减少。
- 对应 TLB 项失效。
- 如果 `la` 没有有效映射，函数安全返回。
- 不释放仍然被其他映射引用的物理页。

**Case 1：目标地址存在有效映射**
找到目标地址对应的有效页表项，获取其对应的物理页描述符，正确减少物理页引用计数，并清除页表项。
完成页表修改后，使对应线性地址的 TLB 项失效。

**Case 2：目标地址不存在页表项**
当 `get_pte()` 无法找到目标页表项时，直接返回，不应发生非法访问。

**Case 3：目标地址存在页表项，但页表项无效**
当页表项不存在有效映射时，直接返回，不应修改无关页表项，也不应减少任何物理页的引用计数。

**Case 4：目标物理页还存在其他引用**
删除当前映射后，只减少当前映射对应的一次引用计数，不得直接释放仍然被其他映射引用的物理页。

**Requirements：**

- `page_remove()` 必须具有幂等性，重复删除同一地址不会产生错误。
- 必须先正确获取映射对应的物理页，再维护引用计数和页表项。
- 不能把删除映射与释放物理页混为一谈。
- 必须正确处理 TLB 一致性。
- 不应擅自删除仍被其他地址使用的物理页。

**最终验证要求：**

完成后请：

1. 检查两个函数是否与原有声明一致。
2. 检查所有使用的函数和宏是否真实存在。
3. 检查同一物理页重复映射时的引用计数。
4. 检查不同物理页替换映射时的引用计数。
5. 检查删除有效映射和删除无效映射的行为。
6. 检查 TLB 失效操作。
7. 执行项目提供的编译和测试命令。
8. 汇报修改文件、修改位置、编译结果和未解决的问题。
````


#### 实现迭代过程

第一次验证使用 `make obj/kern/mm/pmm.o V=`，编译输出没有报错，说明该源文件通过编译。随后执行完整 `make`，在链接阶段出现 `proc_init`、`cpu_idle` 未定义。这是当时模块二、三未完成导致的集成依赖问题，不应通过修改映射逻辑解决。

合入模块二、三后，运行日志出现 `check_pgdir() succeeded!` 与 `check_boot_pgdir() succeeded!`，证明现有页表检查通过。

### 功能模块二：进程创建及初始化

**负责人：** 2513328何妍希

#### 模块功能描述

```c
static struct proc_struct *alloc_proc(void);
void proc_init(void);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
static void copy_thread(struct proc_struct *proc, uintptr_t stack,
                        struct trapframe *tf);
static int copy_mm(uint32_t clone_flags, struct proc_struct *proc);
```

实现位于 `kern/process/proc.c` 。

`alloc_proc` 使用 `kmalloc` 分配 PCB，将状态设为 `PROC_UNINIT`、PID 设为 -1，清零运行次数、调度标记、上下文、名称和标志，初始化两个链表节点。地址空间指针 `mm` 为 NULL，`pgdir` 设置为 `boot_pgdir_pa`，表示当前内核线程共享内核页表。

`kernel_thread` 清零临时 trapframe，把函数入口和参数分别放入 `s0`、`s1`，将 `epc` 指向 `kernel_thread_entry`。状态寄存器设置 SPP、SPIE 并清除 SIE，为通过 `sret` 恢复到 S 态和恢复中断状态做好准备，随后调用 `do_fork(clone_flags | CLONE_VM, 0, &tf)`。

`copy_mm` 断言 `current->mm == NULL` 后返回 0，本阶段不复制用户地址空间。`copy_thread` 将 trapframe 放在新内核栈顶部，复制初始现场并将 `a0` 设为 0；当传入 stack 为 0 时，将恢复后的 `sp` 设为 trapframe 地址。它还设置 `context.ra = forkret` 和 `context.sp = proc->tf`，使第一次上下文切换能够进入异常返回链。

`do_fork` 按“检查进程上限 → 分配 PCB → 设置父进程 → 分配内核栈 → 处理地址空间 → 构造现场 → 登记并唤醒”的顺序工作。PID 分配、哈希表插入、进程链表插入和进程计数增加在关中断区域完成；资源准备完成后才调用 `wakeup_proc` 置为可运行。失败路径按已获得资源的逆序释放内核栈和 PCB，返回负错误码。

`proc_init` 初始化全局链表与 PID 哈希桶，将当前执行环境包装成 PID 为 0 的 idleproc，复用 `bootstack` 并设置 `need_resched = 1`、`current = idleproc`。随后调用 `kernel_thread` 创建 initproc，查找对应 PCB 并命名为 init，断言两个关键线程的 PID 分别为 0 和 1。idleproc 不通过普通 fork 创建，也不加入普通进程链表。

#### 最终提示词

````text
[PROMPT]
**任务**：修改文件 `kern/process/proc.c`，实现功能模块二“内核线程创建与初始化”。该模块负责初始化进程管理结构，将当前执行现场建立为 `idleproc`，创建 `initproc`，并完成新内核线程从 PCB 分配到进入可运行状态的完整流程。

**操作要求**：你必须在项目中修改实际文件，而不是仅展示代码。保留文件中的现有代码，只替换 `//LAB4 function2 YOUR CODE` 标记对应的模块二区域；不得修改功能模块一、功能模块三及已有公共接口。在模块二实现代码前只保留一处注释 `// LAB4 function2 2513328`。

**输出要求**：直接进行文件操作，使用下面 `[RELY]`、`[GUARANTEE]`、`[SPECIFICATION]` 中提供的信息，并以工程真实代码为准。实现应能与物理内存模块和调度模块配合，不引入无关功能。

[RELY]

// 相关宏和常量
```c
#define PROC_NAME_LEN 15
#define MAX_PROCESS 4096
#define MAX_PID (MAX_PROCESS * 2)
#define CLONE_VM 0x00000100
#define KSTACKSIZE (KSTACKPAGE * PGSIZE)

// 关键数据结构

```c
struct context {
    uintptr_t ra, sp;
    uintptr_t s0, s1, s2, s3, s4, s5, s6;
    uintptr_t s7, s8, s9, s10, s11;
};

struct proc_struct {
    enum proc_state state;
    int pid;
    int runs;
    uintptr_t kstack;
    volatile bool need_resched;
    struct proc_struct *parent;
    struct mm_struct *mm;
    struct context context;
    struct trapframe *tf;
    uintptr_t pgdir;
    uint32_t flags;
    char name[PROC_NAME_LEN + 1];
    list_entry_t list_link;
    list_entry_t hash_link;
};
```

// 可用全局变量

```c
extern uintptr_t boot_pgdir_pa;
extern char bootstack[], bootstacktop[];
extern struct proc_struct *idleproc, *initproc, *current;
extern list_entry_t proc_list;
```

// 可调用的已有函数

```c
void *kmalloc(size_t size);
void kfree(void *objp);
static int setup_kstack(struct proc_struct *proc);
static void put_kstack(struct proc_struct *proc);
static int get_pid(void);
static void hash_proc(struct proc_struct *proc);
void wakeup_proc(struct proc_struct *proc);
void list_init(list_entry_t *elm);
void list_add(list_entry_t *listelm, list_entry_t *elm);
struct proc_struct *find_proc(int pid);
char *set_proc_name(struct proc_struct *proc, const char *name);
void kernel_thread_entry(void);
```

[GUARANTEE]
必须实现或修改的主要接口：

```c
static struct proc_struct *alloc_proc(void);
void proc_init(void);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
static void copy_thread(struct proc_struct *proc, uintptr_t stack,
                        struct trapframe *tf);
static int copy_mm(uint32_t clone_flags, struct proc_struct *proc);
```

不新增或改变公开接口。若确需增加模块内部辅助逻辑，应保持为 `static`，且不得影响其他功能模块。

[SPECIFICATION]

## alloc_proc

**Pre-Condition**:

- 内核堆内存管理已经初始化，允许为一个 PCB 申请空间。

**Post-Condition**:

- 返回一个已完成基础字段初始化、尚未登记到系统中的 PCB；若内存不足则返回 `NULL`。

  **Case 1：分配成功**:

  - PCB 状态为 `PROC_UNINIT`，PID 为 `-1`；运行次数、内核栈、调度标志、父进程、`mm`、trapframe 和 flags 均为安全初值；上下文和名称清零；`pgdir` 使用 `boot_pgdir_pa`；两个链表节点处于独立初始化状态。

  **Case 2：分配失败**:

  - 返回 `NULL`，不得修改进程链表、哈希表或进程计数。

## kernel_thread

**Pre-Condition**:

- `fn` 是可在内核态执行的函数入口；`arg` 可以为空；进程管理全局结构已经初始化。

**Post-Condition**:

- 返回新线程 PID，或透传线程创建过程产生的负错误码。
- 新线程第一次恢复执行时从 `kernel_thread_entry` 进入，并能够取得 `fn` 和 `arg`。

**Requirements**:

- 临时 trapframe 必须从全零状态构造。
- 新线程运行于 S 模式，并在恢复后具备正确的中断状态。
- 内核线程必须带有 `CLONE_VM` 标志。

## copy_mm

**Pre-Condition**:

- 当前实验创建的是内核线程，`current->mm == NULL`。

**Post-Condition**:

- 不创建或复制用户地址空间，目标线程继续使用内核地址空间，并返回成功。

**Requirements**:

- 保留该接口，供后续实验扩展用户进程地址空间复制或共享逻辑。

## copy_thread

**Pre-Condition**:

- `proc` 已拥有大小为 `KSTACKSIZE` 的有效内核栈；`tf` 指向有效的初始 trapframe；`stack` 为 0 或合法的目标栈指针。

**Post-Condition**:

- 新线程自己的内核栈顶部保存了 trapframe 副本。

- 子线程返回值寄存器为 0，trapframe 栈指针和上下文栈指针正确。

- 新线程上下文的返回地址指向 `forkret`，第一次调度时能够进入统一恢复链路。

  **Case 1：`stack == 0`**:

  - 按内核线程场景处理，trapframe 中的栈指针指向新线程自己的 trapframe。

  **Case 2：`stack != 0`**:

  - trapframe 中的栈指针采用调用者提供的目标栈地址。

## do_fork

**Pre-Condition**:

- `current` 指向有效父线程；`tf` 指向待复制的运行现场；全局进程链表、PID 哈希表和内存分配器可用。

**Post-Condition**:

- 成功时返回新线程 PID；新 PCB 的父进程为 `current`，资源和首次运行现场完整，已加入哈希表及进程链表，状态为 `PROC_RUNNABLE`。

- 失败时返回负错误码，且不得留下未登记 PCB、内核栈泄漏或错误的进程计数。

  **Case 1：进程数量达到上限**:

  - 不再申请任何资源，返回 `-E_NO_FREE_PROC`。

  **Case 2：PCB 分配失败**:

  - 返回 `-E_NO_MEM`，全局进程状态保持不变。

  **Case 3：内核栈或后续资源处理失败**:

  - 按已获得资源的相反顺序回收内核栈和 PCB，返回对应负错误码。

  **Case 4：创建成功**:

  - 完成父子关系、内核栈、地址空间接口和运行现场设置；为新线程分配唯一 PID并登记；唤醒线程并返回其 PID。

**Requirements**:

- PID 分配、哈希表插入、进程链表插入和进程计数更新必须处于同一关中断临界区。
- 必须先完成全部资源与上下文设置，再将线程置为可运行状态。

##### proc_init

**Pre-Condition**:

- 物理内存、内核堆和启动栈已经初始化；尚未建立进程管理全局结构。

**Post-Condition**:

- `proc_list` 和所有 PID 哈希桶完成初始化。

- `idleproc` 存在，PID 为 0，状态为 `PROC_RUNNABLE`，使用 `bootstack`，并成为 `current`。

- `initproc` 存在，PID 为 1，父进程为 `idleproc`，名称为 `init`，且能够被后续调度模块选中执行。

  **Case 1：`idleproc` 分配失败**:

  - 触发内核错误并停止继续初始化，避免在无有效当前进程的状态下运行。

  **Case 2：`initproc` 创建失败**:

  - 触发内核错误并停止继续初始化，避免系统进入缺少初始化线程的状态。

**Requirements**:

- `idleproc` 代表当前启动执行现场，不通过普通 fork 创建。
- 完成后必须检查 `idleproc` 和 `initproc` 的关键 PID 不变量。
````

#### 实现过程与关键代码分析

##### 1. 初始化进程控制块

`alloc_proc` 使用 `kmalloc` 分配 `struct proc_struct`，并将进程状态、PID、运行次数、内核栈、调度标志、父进程、内存管理结构、上下文、trapframe、页表和名称等字段初始化为安全值。其中 `pgdir` 被设置为 `boot_pgdir_pa`，表示内核线程使用启动时建立的内核页表。两个链表节点也通过 `list_init` 完成初始化，避免未初始化指针进入进程链表。

##### 2. 构造内核线程的临时运行现场

`kernel_thread` 首先清零一个临时 trapframe，然后将线程入口函数和参数分别放入被调用者保存寄存器 `s0`、`s1`。`kernel_thread_entry` 会从这两个寄存器取出参数并调用目标函数。`status` 中设置 `SSTATUS_SPP` 和 `SSTATUS_SPIE`，并清除当前的 `SSTATUS_SIE`；`epc` 指向 `kernel_thread_entry`。最后调用 `do_fork` 创建线程。

##### 3. 设置新线程自己的内核栈与上下文

`copy_thread` 将 trapframe 放在新线程内核栈顶部并复制临时现场。子线程的 `a0` 被设置为 0，用于保持 fork 后子进程返回值语义；若创建的是内核线程，则 trapframe 中的栈指针指向该 trapframe。上下文的 `ra` 被设置为 `forkret`，`sp` 指向新线程的 trapframe，因此该线程第一次被调度时会沿着 `forkret -> forkrets -> __trapret -> kernel_thread_entry` 的路径恢复执行。

##### 4. 完成新线程的资源分配和系统登记

`do_fork` 先检查进程数量上限，再依次分配 PCB、设置 `proc->parent = current`、分配内核栈、处理地址空间并复制运行现场。在关闭中断的临界区内，为新线程分配唯一 PID，将其加入 PID 哈希表和全局进程链表，并更新进程数量。完成登记后调用 `wakeup_proc`，使线程进入 `PROC_RUNNABLE` 状态。

如果 PCB、内核栈或地址空间处理失败，函数通过错误标签按相反顺序释放已经分配的资源，避免内存泄漏和无效进程残留。

##### 5. 建立 idleproc 与 initproc

`proc_init` 初始化全局进程链表和所有 PID 哈希桶。`idleproc` 不通过普通 fork 创建，而是复用内核当前的执行现场，因此其 PID 固定为 0，内核栈使用 `bootstack`，并将其设置为当前进程。随后通过 `kernel_thread` 创建执行 `init_main` 的 `initproc`，从哈希表中取得其 PCB，将名称设置为 `init`，并检查两个关键线程的 PID 是否正确。

#### 实现迭代过程

**完成内容：**

- 实现了 `alloc_proc`、`kernel_thread`、`copy_mm`、`copy_thread`、`do_fork` 和 `proc_init`。
- 补充了 `proc->parent = current`，保证 `initproc->parent == idleproc`。
- 在 PID 分配与链表登记时使用关中断临界区，保证全局进程数据的一致性。
- 为失败路径增加 PCB 和内核栈资源回收逻辑。

#### 测试与验证

工程提供的 Lab4 测试中，与本模块直接相关的是 `test_lab4_process_create`。该测试主要检查：

- `current == idleproc`；
- `idleproc` 的 PID、状态、内核栈、父进程、内存管理结构和上下文初始化正确；
- `initproc` 的 PID 为 1、状态为 `PROC_RUNNABLE`；
- `initproc->parent == idleproc`；
- `initproc` 的 `context.ra` 和 `context.sp` 已正确设置。

本模块还会被调度测试间接使用，因为调度测试通过 `kernel_thread` 创建额外线程。最终工程中应执行：

```bash
make qemu
make grade
```

### 功能模块三：进程调度

**负责人：** 2510720董隽仪

#### 模块功能描述

**需要实现或修改的函数**

```c
/* kern/process/proc.c */
void cpu_idle(void);
void proc_run(struct proc_struct *proc);

/* kern/schedule/sched.c */
void schedule(void);

/* kern/process/switch.S 中导出的汇编符号 */
void switch_to(struct context *from, struct context *to);
```

**功能说明**

`cpu_idle()` 在循环中检查 `current->need_resched`，标志置位时调用 `schedule()`。`schedule()` 保存并关闭本地中断，清除发起调度的线程的重调度标志。如果当前线程是 `idleproc`，就从链表头的下一项开始查找，否则从当前线程的下一项开始查找。遍历时跳过链表头，最多扫描一圈，选中首个状态为 `PROC_RUNNABLE` 的线程。绕回时仍可选中可运行的当前线程，找不到普通可运行线程时选择 `idleproc`。选中线程的 `runs` 加 1，只有目标与当前线程不同时才调用 `proc_run()`。

`proc_run()` 收到当前线程时直接返回。需要切换时，它保存本地中断状态、关闭中断，先保留旧的 `current`，再令 `current` 指向目标线程。它用 `SATP_MODE_SV39` 和从 `proc->pgdir` 换算得到的根页表物理页号构成 `satp`，写入寄存器后调用 `flush_tlb()`，最后将新旧线程的上下文地址传给 `switch_to()`。旧线程再次被调度时，会回到原来的切换调用位置，然后按进入各层临界区时保存的状态恢复本地中断。

`switch_to()` 按 RV64 调用约定接收 `a0` 指向的旧上下文和 `a1` 指向的新上下文，用 `sd` 和 `ld` 保存及恢复 `ra`、`sp`、`s0` 至 `s11`。每个字段占 8 字节，偏移从 0 到 104。最后执行 `ret`，用恢复后的 `ra` 继续执行。首次运行的线程通过 `forkret` → `forkrets` → `__trapret` 恢复 trapframe，经 `kernel_thread_entry` 进入线程函数。曾经切出的线程从原先的切换调用处继续。

#### 最终提示词

````markdown
[PROMPT]

**任务**：完成 RISC-V RV64 Lab 4 的进程调度与上下文切换模块，让内核能够发现调度请求、选择可运行线程，并切换到目标线程的地址空间和执行现场。进程初始化后，系统应能从空闲线程 `idleproc` 切换到 `initproc`，使后者执行入口函数。

**操作要求**：在项目中实际编辑上述文件，只在 `//LAB4 function3 YOUR CODE` 对应区域补全代码。保留标记、已有注释及区域外的内容，包括模块一、模块二和 `wakeup_proc()`。沿用现有公开接口、构建配置和评分脚本。

**输出要求**：以工程定义和下列行为规格为准。完成后列出实际改动的文件和函数，检查差异是否仅位于允许修改的位置。

[RELY]

-`kern/process/proc.h` 中的 `struct context` 依次包含 `ra`、`sp` 和 `s0` 至 `s11`，字段类型都是 `uintptr_t`。在 RV64 下每个字段占 8 字节，`ra` 和 `sp` 的偏移为 0 和 8，`s0` 至 `s11` 的偏移为 16 至 104，步长为 8 字节。按 RV64 调用约定，`switch_to()` 的 `from` 和 `to` 分别通过 `a0`、`a1` 传入。
-`struct proc_struct` 中与本模块相关的字段为 `state`、`runs`、`need_resched`、`context`、`pgdir` 和 `list_link`。`PROC_RUNNABLE` 表示线程可运行。`current` 指向正在运行的线程，`idleproc` 是没有普通线程可运行时的后备线程。
-`proc_list` 是带头节点的循环链表。普通线程通过 `list_link` 加入链表，`idleproc` 在链表外。`list_next()` 可用于遍历，`le2proc(entry, list_link)` 可从普通线程的链表节点取得 PCB。
-模块二的 `proc_init()` 已负责设置 `current`、建立 `idleproc` 并创建 `initproc`。`copy_thread()` 为新线程准备其内核栈与 trapframe，将初始 `context.ra` 设置为 `forkret`。框架通过 `forkret`、`forkrets` 和 `__trapret` 恢复新线程的现场，随后进入线程入口。
-`proc->pgdir` 保存根页表的物理地址，本实验中的内核线程使用 `boot_pgdir_pa`。`libs/riscv.h` 提供 `SATP_MODE_SV39`、`RISCV_PGSHIFT` 和 `write_csr()`，`kern/mm/pmm.h` 提供 `flush_tlb()`。Sv39 模式位于 RV64 `satp` 的高 4 位，根页表物理页号由物理地址右移 `RISCV_PGSHIFT` 得到。
-`kern/sync/sync.h` 提供 `local_intr_save(flag)` 和 `local_intr_restore(flag)`，用于保存并关闭本地中断，再按原状态恢复。进入临界区时若中断已经关闭，退出该层临界区时仍应保持关闭。

[GUARANTEE]

必须实现以下四个接口，并与项目已有声明一致。

```c
/* kern/process/proc.c */
void cpu_idle(void);
void proc_run(struct proc_struct *proc);

/* kern/schedule/sched.c */
void schedule(void);

/* kern/process/switch.S，供 C 代码调用的汇编符号 */
void switch_to(struct context *from, struct context *to);
```

`cpu_idle()` 应满足工程现有的 `noreturn` 声明。`switch_to` 应导出为可链接的全局汇编符号。确需新增 C 辅助函数时，将其设为相应源文件内的 `static` 函数。

[SPECIFICATION]

## cpu_idle

**Pre-Condition**：进程初始化已完成，首次进入时 `current` 指向 `idleproc`。

**Post-Condition**：空闲线程持续检查重调度请求。空闲线程再次获得 CPU 时，继续检查后续请求。

**Case 1**：当前线程的 `need_resched` 已置位，发起一次调度。

**Case 2**：没有重调度请求，继续空闲循环。

## schedule

**Pre-Condition**：`current` 和 `idleproc` 已初始化，`proc_list` 可遍历。当前线程若是普通线程，其节点已在链表中。

**Post-Condition**：清除发起调度的线程的 `need_resched`，给选中线程的 `runs` 增加一次。选中其他线程时发起切换。原调用者恢复执行并从本函数返回时，本地中断状态与进入本函数时一致。

**Case 1**：存在可运行的普通线程。当前线程为空闲线程时，从第一个普通线程开始寻找。当前线程为普通线程时，从它的下一个节点开始，按循环顺序选择第一个状态为 `PROC_RUNNABLE` 的线程。最多遍历一圈，跳过链表头，绕回时可以选中仍然可运行的当前线程。

**Case 2**：链表为空，或一圈内没有可运行的普通线程，选择 `idleproc`。

**Case 3**：如果最终选中的就是当前线程，完成标志与计数更新后继续执行，省去上下文切换。

**Requirements**：清除调度标志、遍历链表、更新运行计数和发起切换期间须关闭本地中断。

## proc_run

**Pre-Condition**：`proc` 和 `current` 均指向有效线程。目标线程的根页表、内核栈和上下文已准备好。

**Post-Condition**：实际发生切换后，`current`、生效的根页表和 CPU 执行现场均属于目标线程，旧线程的上下文可在将来恢复。

**Case 1**：目标线程就是当前线程，直接返回。

**Case 2**：目标线程与当前线程不同。在本地中断保护下完成当前线程更新、Sv39 地址空间切换和上下文切换。新线程首次运行时走框架已有的恢复路径，曾运行过的线程从保存的位置继续。

**Requirements**：目标线程执行前应使其根页表生效并刷新 TLB。旧线程被重新调度并从原切换调用返回后，应恢复进入本函数临界区前的本地中断状态。

## switch_to

**Pre-Condition**：`from` 指向可写的旧线程上下文，`to` 指向已准备好的目标线程上下文。调用方负责选择线程及提供中断保护。

**Post-Condition**：将旧线程的 `ra`、`sp` 和 `s0` 至 `s11` 保存到 `from`，从 `to` 恢复对应寄存器，按恢复后的栈指针和返回地址继续执行目标线程。

**Case 1**：目标线程首次运行，恢复后的返回地址指向预设的 `forkret`。

**Case 2**：目标线程曾运行过，从上一次切出时保存的返回位置继续执行。

**Requirements**：寄存器读写的宽度和偏移应与 RV64 下的 `struct context` 一致。本函数只负责寄存器上下文切换。
````

#### 实现迭代过程

##### 实现与验证

`make` 成功生成内核镜像，`make qemu` 启动后进入了 `init_main()`。

##### 评分环境排查与复测

首次执行 `make grade` 时，评分脚本尝试向临时副本 `/tmp/lab4_grade/kern/mm/pmm.c` 插入测试代码，返回 `PermissionError: [Errno 13] Permission denied`。检查时发现原文件和临时副本的权限均为 `-r-xr-xr-x`。补充评分脚本需要写入的源文件的所有者写权限后，重新评分后，`check Schedule` 显示 `OK`，整份实验得分为 `30/30`。

### 扩展练习 Challenge

#### 1. `local_intr_save()` 与 `local_intr_restore()` 如何实现开关中断

在 `kern/sync/sync.h` 中，两个宏的核心实现如下：

```
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}
```

`local_intr_save(intr_flag)` 首先读取 RISC-V 的 `sstatus` 控制状态寄存器，并检查其中的 `SSTATUS_SIE` 位。SIE 是 S 模式的全局中断使能位：

- 如果 SIE 为 1，说明执行前允许响应 S 模式中断。函数调用 `intr_disable()` 清除 SIE，并将 `intr_flag` 保存为 1。
- 如果 SIE 为 0，说明执行前中断已经关闭，此时不需要重复关闭，并将 `intr_flag` 保存为 0。

`intr_disable()` 和 `intr_enable()` 位于 `kern/driver/intr.c`，分别通过 `clear_csr` 和 `set_csr` 指令清除或设置 `sstatus.SIE`：

```
void intr_enable(void)  { set_csr(sstatus, SSTATUS_SIE); }
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
```

临界区执行结束后，`local_intr_restore(intr_flag)` 根据之前保存的状态决定是否重新开启中断。只有当 `intr_flag` 为 1，即进入临界区前中断原本开启时，才会调用 `intr_enable()`；如果进入前中断已经关闭，则保持关闭状态。

因此，这组操作并不是简单地“先关中断、再无条件开中断”，而是“保存原中断状态、关闭中断、最后恢复原状态”。这种设计能够正确支持嵌套临界区。例如，外层关闭中断后，内层再次调用 `local_intr_save()` 会保存状态为 0，因此退出内层时不会错误地提前打开中断。

需要注意，该机制只阻止当前处理器核响应可屏蔽的 S 模式中断，不能屏蔽同步异常，也不能代替多核环境中的自旋锁等同步机制。

#### 2. `get_pte()` 中两段代码为什么如此相像

`get_pte()` 中两段相似代码分别处理 Sv39 页表遍历中的两个中间层级：

```
pde_t *pdep1 = &pgdir[PDX1(la)];
```

第一段根据最高级虚拟页号找到根页表中的表项。如果该表项无效，则根据 `create` 参数决定是否分配一张新的下一级页表。

```
pde_t *pdep0 =
    &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
```

第二段进入刚找到的下一级页表，再根据第二级虚拟页号找到表项。如果该表项无效，同样根据 `create` 参数决定是否分配最低一级页表。

两段代码执行的操作基本一致：

1. 检查当前层页表项的 `PTE_V` 有效位。
2. 如果表项无效且 `create` 为假，则返回 `NULL`。
3. 如果允许创建，则调用 `alloc_page()` 分配新的页表页。
4. 设置页表页的引用计数并将其内容清零。
5. 将新页表的物理页号及权限位写入当前层页表项。
6. 进入下一级页表继续查找。

它们之所以相似，是因为多级页表的每一级本质上都在重复“使用本级索引查找表项，再由该表项进入下一级页表”的过程，区别主要在于使用的地址索引不同。

如果采用 Sv32，只需要经过一个中间页表层级，因此类似的代码只需要一段；如果采用 Sv48，则需要经过三个中间层级，因此还要增加一段相似逻辑。实际系统中可以使用循环和“页表级数”参数统一实现页表遍历，减少针对不同分页模式的重复代码。

#### 3. 是否应该拆分页表项查找和页表页分配功能

当前 `get_pte()` 使用 `create` 参数同时支持两种操作：

- `create == false`：只查找页表项，不修改页表。
- `create == true`：查找页表项，并在中间页表不存在时自动分配页表页。

这种写法是合理的。它使调用者可以通过一个函数完成页表遍历，并避免在 `page_insert()` 等函数中重复编写中间页表的创建代码，整体实现较为简洁。

但是，这种设计也存在不足。首先，函数名 `get_pte` 看起来像纯查找操作，但传入 `create == true` 时会分配内存并修改页表，存在隐藏的副作用。其次，如果第一层页表分配成功，而第二层页表分配失败，函数会直接返回 `NULL`，可能留下已经分配的中间页表。本工程的 `page_insert()` 需要额外判断这种情况并回收页表页，说明查找和分配耦合后会增加错误恢复的复杂度。

因此，可以将其拆分为：

```
lookup_pte()：只遍历和查找，不分配内存
ensure_pte()：保证页表路径存在，必要时分配页表页
```

还可以进一步提取一个负责“分配、清零并连接下一级页表”的内部辅助函数。这样能够使函数职责更加明确，也便于分别测试纯查找路径、创建路径以及内存不足时的回滚逻辑。

综合来看，在本实验规模下保留带 `create` 参数的 `get_pte()` 可以减少代码量，是可以接受的；如果面向更复杂的操作系统，则更适合将纯查找和带分配的查找分开，或者至少在内部进行模块化封装，并保证分配失败时能够完整回滚。

## 五、测试与验证

### 5.1 编译与运行步骤

在已配置交叉编译器与 QEMU 的 WSL 中执行：

```bash
make
make qemu
make grade
```

### 5.2 已有运行结果

以下节选来自用户提供的实际 QEMU 运行日志，本报告生成时未重新执行编译或 QEMU：

```text
memory management: best_fit_pmm_manager
check_alloc_page() succeeded!
check_pgdir() succeeded!
check_boot_pgdir() succeeded!
use SLOB allocator
kmalloc_init() succeeded!
check_vma_struct() succeeded!
check_vmm() succeeded.
++ setup timer interrupts
this initproc, pid = 1, name = "init"
To U: "Hello world!!".
To U: "en.., Bye, Bye. :)"
kernel panic at kern/process/proc.c:208:
    process exit!!.
Welcome to the kernel debug monitor!!
```

| 观察结果 | 能支持的结论 |
|----------|--------------|
| check_alloc_page 成功 | 现有物理页分配器检查通过 |
| check_pgdir 成功 | 已有检查涉及的页表定位、映射替换、权限、引用计数及撤销行为通过 |
| check_boot_pgdir 成功 | 静态映射检查及同一物理页的双地址访问检查通过 |
| kmalloc、VMA、VMM 检查成功 | 启动路径中的相应既有内存管理检查通过 |
| initproc 的 PID、名称和问候语正确 | 线程创建、登记、首次调度及参数传递链路已执行 |

现有日志末尾的 panic 来自模板中的 `do_exit()`：该函数目前直接执行 `panic("process exit!!.\n")`。`init_main` 返回后，`kernel_thread_entry` 调用 do_exit，因此会进入调试监视器。这属于当前退出占位实现的已知行为，并不表示页表检查失败，也不等于已实现正常的进程退出与资源回收。

### 5.3 测试截图
[make qemu测试结果](./images/测试截图1.png)
[make grade测试结果](./images/测试截图2.png)

## 六、实验总结与收获

### 对操作系统的理解

| 实验知识点 | 对应 OS 原理 | 关系及本实验的范围 |
|------------|-------------|-------------------|
| 页表项与 TLB 同步 | 虚拟地址转换与地址翻译缓存 | 修改内存页表后仍需失效缓存；本实验使用 sfence.vma |
| 物理页引用计数 | 共享资源的生命周期管理 | 多个映射可共享一页，最后一次引用撤销后才能释放；引用数不能简单等同于进程数 |
| PCB、内核栈、context、trapframe | 进程执行现场 | PCB 管理线程，context 服务函数调用边界的切换，trapframe 服务异常返回与首次启动 |
| idleproc 与 initproc | 空闲任务与普通内核线程 | 前者复用启动现场，后者需要构造新的首次执行现场 |
| 环形扫描可运行线程 | CPU 调度与机制/策略分离 | schedule 负责选择，switch_to 负责切换；当前策略较简单 |
| 关中断临界区 | 并发控制与原子性 | 保护本 CPU 的调度状态更新，不等同于多核互斥 |
| fork 失败清理 | 内核资源管理 | 逆序释放已取得资源，避免未初始化线程被调度 |

OS 原理中重要但本实验尚未完整覆盖的内容包括：用户态程序装载和隔离、用户地址空间复制及写时复制、缺页调页与页面置换、完整退出与等待回收、复杂调度策略、公平性与实时性、多核调度及跨核 TLB 同步。

### AI 协作开发的经验

1. 提示词应明确现有接口和架构约束。Sv39 satp 编码、context 字段顺序和线程入口恢复链若描述不清，即使代码语法正确，也可能在切换时出错。
2. 边界条件需要在生成前明确。同页重映射、删除不存在的映射、中间页表分配失败和 fork 逆序清理，都是核心逻辑的一部分。
3. 分阶段验证能定位问题。pmm.o 编译通过说明源文件编译正确；完整链接的未定义符号暴露模块依赖；QEMU 中的成功输出才提供实际执行证据。
4. 面对日志应判断来源。链接器清理未使用节的提示不是错误，do_exit 占位 panic 也不能直接归因于新实现的页表或调度函数。
