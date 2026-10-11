## 提示词一：理解内核入口代码

### [PROMPT]

阅读 `kern/init/entry.S`，结合 Lab1 的内核启动过程，解释 `la sp, bootstacktop` 和 `tail kern_init` 分别完成了什么操作、目的是什么。请使用适合初学者理解的语言，同时保留必要的专业术语，不要修改源代码。

### [RELY]

```asm
kern_entry:
    la sp, bootstacktop
    tail kern_init

.section .data
.align PGSHIFT
bootstack:
    .space KSTACKSIZE
bootstacktop:
```

已知 RISC-V 的栈通常从高地址向低地址增长，`sp` 是栈指针；`kern_init` 是 `kern/init/init.c` 中的 C 语言内核初始化函数。

### [GUARANTEE]

必须解释：

1.`la sp, bootstacktop` 完成的操作和设置栈的目的；

2.`bootstack`、`.space KSTACKSIZE`、`bootstacktop` 三者的关系；

3.`tail kern_init` 完成的操作以及不需要返回 `kern_entry` 的原因。

### [SPECIFICATION]

解释时先分别回答“完成了什么操作”和“目的是什么”，再说明两条指令在启动流程中的先后关系。不要只堆积汇编术语，也不要用过度简化的比喻代替技术含义。

## 提示词二：使用 GDB 验证启动流程

### [PROMPT]

指导我们在 WSL Ubuntu 中使用 QEMU 和 GDB，从 RISC-V 加电后的复位地址开始调试，观察 CPU 进入 OpenSBI，最后在 `0x80200000` 的内核入口停下。请给出可以逐条执行的命令，并根据我们反馈的实际输出继续排查问题。

### [RELY]

1.实验目录：`/mnt/d/计算机系统软件基础/lab1/lab1`；

2.内核文件：`bin/kernel`；

3.QEMU：`qemu-system-riscv64`；

4.调试器：`gdb-multiarch`；

5.CPU 复位地址：`0x1000`；

6.OpenSBI 位于 `0x80000000` 附近；

7.内核入口：`0x80200000`。

当前环境使用下面的命令可以正确启动调试：

```bash
qemu-system-riscv64 \
  -machine virt \
  -nographic \
  -bios default \
  -kernel bin/kernel \
  -s -S
```

### [GUARANTEE]

必须完成并记录以下结果：

1.使用 `info registers pc` 确认初始 PC 为 `0x1000`；

2.使用 `x/8i 0x1000` 查看最初的指令；

3.使用 `si` 单步观察 CPU 进入 OpenSBI；

4.使用 `b *0x80200000` 设置断点，并用 `c` 继续运行；

5.确认断点命中 `kern_entry`，此时 PC 为 `0x80200000`；

6.继续运行，确认 QEMU 输出 `(THU.CST) os is loading ...`。

### [SPECIFICATION]

调试需要分别说明两个终端的用途：一个运行 QEMU，一个运行 GDB。每一步都说明命令的作用、正常情况下应看到的结果和适合截图的位置。如果实际结果与预期不同，应先根据 PC、断点信息和 OpenSBI 输出判断原因，不能直接假设实验已经成功。
