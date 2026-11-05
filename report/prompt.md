# 功能模块一：Trap 上下文恢复与 Trap 入口功能提示词
## [PROMPT]

**任务**:现在我正在完成操作系统实验，需要实现 Trap 上下文恢复与 Trap 入口功能。请根据我提供的实验框架代码，帮助我完成 `kern/trap/trapentry.S` 中两个待实现部分：

- `RESTORE_ALL`
- `__alltraps`

**操作要求**：你必须在项目中修改文件，保留现有代码，只在标记位置补全。

**输出要求**：直接进行文件操作，使用下面部分的信息。完成后，请提供给我你进行了修改的文件的清单。

## [RELY]

阅读 `trapentry.S`、`trap.h`，分析：

- `SAVE_ALL` 的具体实现。
- `struct trapframe` 的字段顺序及偏移量。
- `__trapret` 的已有实现。
- `RESTORE_ALL` 应当恢复哪些内容。
- `__alltraps` 如何将 Trap frame 传递给 C 函数。

在此基础上实现'RESTORE_ALL'和'_alltraps'两个部分的功能

## [GUARANTEE]

本任务的目标是实现 RISC-V Trap 处理过程中的底层上下文管理，使系统能够完成以下完整流程：

Trap 发生 → 保存处理器上下文 → 进入 C 语言 Trap 处理函数 → 恢复处理器上下文 → 通过 `sret` 返回原执行流。

其中，已有的 `SAVE_ALL` 负责保存 Trap 发生时的处理器状态，本次只允许实现 `RESTORE_ALL` 和 `__alltraps`，不得修改已有的 `SAVE_ALL`、`struct trapframe`、`trap()` 函数签名及其他无关代码。

1. 必须以我提供的实际代码为依据，不得直接套用其他操作系统或实验版本的代码。
2. 不得修改 `SAVE_ALL`。
3. 不得修改 `struct trapframe`。
4. 不得修改 `trap(struct trapframe *tf)` 的函数签名。
5. 不得修改实验框架中其他已经实现的函数或宏。
6. 不得自行假设寄存器偏移量、Trap frame 大小或 CSR 布局。
7. 不得遗漏任何由 `SAVE_ALL` 保存、且需要由 `RESTORE_ALL` 恢复的状态。
8. 代码必须符合 RISC-V 64 位汇编语法及实验框架的编译环境。

## [SPECIFICATION]

### 1. 实现 RESTORE_ALL

请首先仔细分析已有的 `SAVE_ALL` 宏，明确以下内容：

- 每个通用寄存器保存到 Trap frame 中的偏移量。
- `sstatus`、`sepc`、`scause`、`stval` 等 CSR 的保存方式。
- Trap frame 的总布局和栈指针的变化。
- `x2(sp)` 与其他通用寄存器的保存方式是否存在区别。

在此基础上实现 `RESTORE_ALL`，要求：

1. 从当前栈指针所指向的 Trap frame 中恢复所有已保存的通用寄存器。
2. 正确恢复必要的 CSR 状态，特别是 `sstatus` 和 `sepc`。
3. 严格按照 `SAVE_ALL` 的实际保存偏移进行恢复，不能自行假设 Trap frame 布局。
4. 特别处理原始 `sp` 的恢复，避免在恢复过程中因修改当前栈指针而导致后续寄存器读取错误。
5. 恢复完成后，使处理器能够通过后续的 `sret` 正确返回 Trap 发生前的执行位置和特权状态。

### 2. 实现 __alltraps

请分析当前汇编文件中 `SAVE_ALL`、`RESTORE_ALL`、`__alltraps` 和 `__trapret` 的关系，以及 C 语言函数的调用约定。

实现 `__alltraps`，要求：

1. 在 Trap 入口执行已有的 `SAVE_ALL`，建立完整的 Trap frame。
2. 正确获取当前 Trap frame 的起始地址。
3. 按照 RISC-V 函数调用约定，将 Trap frame 地址放入正确的参数寄存器 `a0`，作为 `trap(struct trapframe *tf)` 的第一个参数。
4. 正确调用 C 语言函数 `trap()`。
5. `trap()` 返回以后，进入已有的 `__trapret`，由其完成上下文恢复和 Trap 返回。
6. 不得破坏 Trap frame 中保存的上下文信息。
7. 不得擅自修改 `__trapret` 的已有实现。

### 3.正确性验证

请逐项检查：

- Trap frame 中的寄存器是否全部正确恢复。
- 原始 `sp` 是否正确恢复。
- `sstatus` 和 `sepc` 是否正确恢复。
- `__alltraps` 是否正确调用 `trap()`。
- C 函数返回后是否能够进入 `__trapret`。
- 是否存在破坏 Trap frame 或提前覆盖寄存器的问题。


# 功能模块二：中断与异常处理功能interrupt_handler()提示词

## [PROMPT]
**任务**：修改文件 `kern/trap/trap.c`，实现 `interrupt_handler(struct trapframe *tf)`，使内核能够分类处理中断，并持续处理 S 模式时钟中断。

**操作要求**：必须修改项目中的实际文件，保留现有代码和 `lab3` 注释。不得修改 `exception_handler()`、`trap_dispatch()`、`trap()`、`struct trapframe` 或其他公开接口。

**输出要求**：直接进行文件操作，使用下面 `[RELY]`、`[GUARANTEE]` 和 `[SPECIFICATION]` 中的信息，以真实工程代码为准，不引入与中断处理无关的功能。

## [RELY]
#define TICK_NUM 100
#define SHUTDOWN_AFTER 10

// libs/riscv.h 提供 IRQ_U_SOFT 到 IRQ_M_EXT 的中断编号
#define IRQ_U_SOFT   0
#define IRQ_S_SOFT   1
#define IRQ_H_SOFT   2
#define IRQ_M_SOFT   3
#define IRQ_U_TIMER  4
#define IRQ_S_TIMER  5
#define IRQ_H_TIMER  6
#define IRQ_M_TIMER  7
#define IRQ_U_EXT    8
#define IRQ_S_EXT    9
#define IRQ_H_EXT    10
#define IRQ_M_EXT    11

struct trapframe {
    struct pushregs gpr;
    uintptr_t status;
    uintptr_t epc;
    uintptr_t badvaddr;
    uintptr_t cause;
};

extern volatile size_t ticks;
void clock_set_next_event(void);
void print_trapframe(struct trapframe *tf);
void sbi_shutdown(void);
static void print_ticks(void);

// RV64 的 scause 最高位为 1 表示中断，其余位为中断编号

## [GUARANTEE]
必须实现：
```c
void interrupt_handler(struct trapframe *tf);
```

可以增加仅用于统计输出次数的函数内部静态变量，不得修改公开接口和统一 Trap 分发流程。

## [SPECIFICATION]
### interrupt_handler
**Pre-Condition**:
- `tf` 指向有效 Trap frame，`tf->cause` 保存当前中断原因。
- 时钟和 SBI 接口已经初始化并可调用。

**Post-Condition**:
- 当前中断已按去除最高标志位后的实际编号分类处理。
- 可识别中断已输出对应提示；未知中断已输出 cause 和完整 Trap frame。
- 除达到关机条件外，函数能够返回统一 Trap 恢复流程。

**Case 1：S 模式时钟中断**:
- 安排下一次时钟事件，使 `ticks` 恰好增加一次；新值为 `TICK_NUM` 的整数倍时输出一次统计，累计输出达到 `SHUTDOWN_AFTER` 次时调用关机接口。

**Case 2：其他已知中断**:
- 输出与中断类型对应的提示，不修改 `ticks` 和 `epc`。

**Case 3：未知中断**:
- 输出 `Unknown interrupt: cause N`，其中 `N` 是实际中断编号，并调用 `print_trapframe(tf)`。

**Requirements**:
- 分类前必须排除 `scause` 最高中断标志位的影响。
- 每次 S 模式时钟中断都必须重新安排下一次事件。
- 每次时钟中断只能使 `ticks` 增加一次。


# 功能模块二：中断与异常处理功能exception_handler()提示词
## [PROMPT]
**任务**：修改文件 `kern/trap/trap.c`，实现 `exception_handler(struct trapframe *tf)` 及必要的指令长度判断辅助函数，使内核能够处理非法指令和断点异常，并从正确的下一条指令继续执行。

**操作要求**：必须修改项目中的实际文件，保留现有代码和 `lab3` 注释。不得修改 `interrupt_handler()`、`trap_dispatch()`、`trap()`、`struct trapframe` 或其他公开接口。

**输出要求**：直接进行文件操作，使用下面 `[RELY]`、`[GUARANTEE]` 和 `[SPECIFICATION]` 中的信息，以真实工程代码为准，不引入与异常处理无关的功能。

## [RELY]
#define CAUSE_ILLEGAL_INSTRUCTION 0x2
#define CAUSE_BREAKPOINT          0x3

struct trapframe {
    struct pushregs gpr;
    uintptr_t status;
    uintptr_t epc;
    uintptr_t badvaddr;
    uintptr_t cause;
};

void print_trapframe(struct trapframe *tf);

// tf->cause 保存同步异常编号，tf->epc 指向触发异常的指令
// RISC-V 指令低两位为 11 时是 32 位指令，否则是 16 位压缩指令

## [GUARANTEE]
必须实现：
```c
void exception_handler(struct trapframe *tf);
```

可以根据需要添加：
- 指令长度判断辅助函数，必须声明为 `static`；
- 仅在 `trap.c` 内使用的内部常量。

不得修改公开接口和统一 Trap 分发流程。

## [SPECIFICATION]
### exception_handler
**Pre-Condition**:
- `tf` 指向有效 Trap frame。
- `tf->cause` 保存同步异常编号，`tf->epc` 指向触发异常的指令。

**Post-Condition**:
- 非法指令和断点异常已输出对应诊断信息，并把返回地址更新到下一条指令。
- 未规定专门处理方式的异常已输出完整 Trap frame。

**Case 1：非法指令异常**:
- 当 cause 为 `CAUSE_ILLEGAL_INSTRUCTION` 时，输出包含 `Illegal instruction at` 和异常地址的信息；根据实际指令长度把 `tf->epc` 增加 2 或 4。

**Case 2：断点异常**:
- 当 cause 为 `CAUSE_BREAKPOINT` 时，输出包含 `Breakpoint at` 和异常地址的信息；根据实际断点指令长度更新 `tf->epc`。

**Case 3：其他异常**:
- 不假设该异常能够恢复，只调用 `print_trapframe(tf)` 输出诊断信息。

**Requirements**:
- 不能固定假设所有异常指令长度相同。
- 判断指令长度时遵循 RISC-V 指令低两位编码规则。
- 不修改无关 Trap frame 字段和全局状态。