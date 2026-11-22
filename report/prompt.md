# 功能模块一提示词
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

# 功能模块二提示词
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

## proc_init

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

# 功能模块三提示词
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