
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00008297          	auipc	t0,0x8
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0208000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00008297          	auipc	t0,0x8
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0208008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02072b7          	lui	t0,0xc0207
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0207137          	lui	sp,0xc0207

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00003517          	auipc	a0,0x3
ffffffffc0200050:	ac450513          	addi	a0,a0,-1340 # ffffffffc0202b10 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00003517          	auipc	a0,0x3
ffffffffc0200066:	ace50513          	addi	a0,a0,-1330 # ffffffffc0202b30 <etext+0x26>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00003597          	auipc	a1,0x3
ffffffffc0200072:	a9c58593          	addi	a1,a1,-1380 # ffffffffc0202b0a <etext>
ffffffffc0200076:	00003517          	auipc	a0,0x3
ffffffffc020007a:	ada50513          	addi	a0,a0,-1318 # ffffffffc0202b50 <etext+0x46>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00008597          	auipc	a1,0x8
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0208018 <before.2>
ffffffffc020008a:	00003517          	auipc	a0,0x3
ffffffffc020008e:	ae650513          	addi	a0,a0,-1306 # ffffffffc0202b70 <etext+0x66>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	0004a597          	auipc	a1,0x4a
ffffffffc020009a:	9e258593          	addi	a1,a1,-1566 # ffffffffc0249a78 <end>
ffffffffc020009e:	00003517          	auipc	a0,0x3
ffffffffc02000a2:	af250513          	addi	a0,a0,-1294 # ffffffffc0202b90 <etext+0x86>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	0004a597          	auipc	a1,0x4a
ffffffffc02000ae:	dcd58593          	addi	a1,a1,-563 # ffffffffc0249e77 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00003517          	auipc	a0,0x3
ffffffffc02000d0:	ae450513          	addi	a0,a0,-1308 # ffffffffc0202bb0 <etext+0xa6>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00008517          	auipc	a0,0x8
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0208018 <before.2>
ffffffffc02000e0:	0004a617          	auipc	a2,0x4a
ffffffffc02000e4:	99860613          	addi	a2,a2,-1640 # ffffffffc0249a78 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	1cd020ef          	jal	ra,ffffffffc0202abc <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00003517          	auipc	a0,0x3
ffffffffc0200100:	ae450513          	addi	a0,a0,-1308 # ffffffffc0202be0 <etext+0xd6>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	2d4020ef          	jal	ra,ffffffffc02023e0 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	566020ef          	jal	ra,ffffffffc02026a6 <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0207028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	530020ef          	jal	ra,ffffffffc02026a6 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	0004a317          	auipc	t1,0x4a
ffffffffc02001c6:	86630313          	addi	t1,t1,-1946 # ffffffffc0249a28 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00003517          	auipc	a0,0x3
ffffffffc02001f6:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0202c00 <etext+0xf6>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00003517          	auipc	a0,0x3
ffffffffc020020c:	9d050513          	addi	a0,a0,-1584 # ffffffffc0202bd8 <etext+0xce>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	00d0206f          	j	ffffffffc0202a28 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00003517          	auipc	a0,0x3
ffffffffc0200226:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0202c20 <etext+0x116>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00008597          	auipc	a1,0x8
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0208000 <boot_hartid>
ffffffffc0200250:	00003517          	auipc	a0,0x3
ffffffffc0200254:	9e050513          	addi	a0,a0,-1568 # ffffffffc0202c30 <etext+0x126>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00008417          	auipc	s0,0x8
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0208008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00003517          	auipc	a0,0x3
ffffffffc020026a:	9da50513          	addi	a0,a0,-1574 # ffffffffc0202c40 <etext+0x136>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00003517          	auipc	a0,0x3
ffffffffc020027a:	9e250513          	addi	a0,a0,-1566 # ffffffffc0202c58 <etext+0x14e>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe96475>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00003917          	auipc	s2,0x3
ffffffffc0200334:	97890913          	addi	s2,s2,-1672 # ffffffffc0202ca8 <etext+0x19e>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00003497          	auipc	s1,0x3
ffffffffc0200342:	96248493          	addi	s1,s1,-1694 # ffffffffc0202ca0 <etext+0x196>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00003517          	auipc	a0,0x3
ffffffffc0200396:	98e50513          	addi	a0,a0,-1650 # ffffffffc0202d20 <etext+0x216>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00003517          	auipc	a0,0x3
ffffffffc02003a2:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0202d58 <etext+0x24e>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00003517          	auipc	a0,0x3
ffffffffc02003e2:	89a50513          	addi	a0,a0,-1894 # ffffffffc0202c78 <etext+0x16e>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	656020ef          	jal	ra,ffffffffc0202a42 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	69c020ef          	jal	ra,ffffffffc0202a96 <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	5e8020ef          	jal	ra,ffffffffc0202a78 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00003517          	auipc	a0,0x3
ffffffffc02004a8:	80c50513          	addi	a0,a0,-2036 # ffffffffc0202cb0 <etext+0x1a6>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00002517          	auipc	a0,0x2
ffffffffc0200576:	75e50513          	addi	a0,a0,1886 # ffffffffc0202cd0 <etext+0x1c6>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00002517          	auipc	a0,0x2
ffffffffc0200588:	76450513          	addi	a0,a0,1892 # ffffffffc0202ce8 <etext+0x1de>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00002517          	auipc	a0,0x2
ffffffffc020059a:	77250513          	addi	a0,a0,1906 # ffffffffc0202d08 <etext+0x1fe>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00002517          	auipc	a0,0x2
ffffffffc02005a6:	7b650513          	addi	a0,a0,1974 # ffffffffc0202d58 <etext+0x24e>
        memory_base = mem_base;
ffffffffc02005aa:	00049797          	auipc	a5,0x49
ffffffffc02005ae:	4887b323          	sd	s0,1158(a5) # ffffffffc0249a30 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00049797          	auipc	a5,0x49
ffffffffc02005b6:	4967b323          	sd	s6,1158(a5) # ffffffffc0249a38 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00049517          	auipc	a0,0x49
ffffffffc02005c0:	47453503          	ld	a0,1140(a0) # ffffffffc0249a30 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00049517          	auipc	a0,0x49
ffffffffc02005ca:	47253503          	ld	a0,1138(a0) # ffffffffc0249a38 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_nr_free_pages>:
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005d0:	00049517          	auipc	a0,0x49
ffffffffc02005d4:	47053503          	ld	a0,1136(a0) # ffffffffc0249a40 <nr_free>
ffffffffc02005d8:	8082                	ret

ffffffffc02005da <page_index>:
page_index(struct Page *page) {
ffffffffc02005da:	1141                	addi	sp,sp,-16
ffffffffc02005dc:	e406                	sd	ra,8(sp)
    assert(npage >= nbase && npage - nbase <= BUDDY_CAPACITY);
ffffffffc02005de:	00049797          	auipc	a5,0x49
ffffffffc02005e2:	46a7b783          	ld	a5,1130(a5) # ffffffffc0249a48 <npage>
ffffffffc02005e6:	00004717          	auipc	a4,0x4
ffffffffc02005ea:	c3a73703          	ld	a4,-966(a4) # ffffffffc0204220 <nbase>
    uintptr_t addr = (uintptr_t)page, start = (uintptr_t)pages;
ffffffffc02005ee:	00049697          	auipc	a3,0x49
ffffffffc02005f2:	4626b683          	ld	a3,1122(a3) # ffffffffc0249a50 <pages>
    assert(npage >= nbase && npage - nbase <= BUDDY_CAPACITY);
ffffffffc02005f6:	02e7e563          	bltu	a5,a4,ffffffffc0200620 <page_index+0x46>
ffffffffc02005fa:	8f99                	sub	a5,a5,a4
ffffffffc02005fc:	6721                	lui	a4,0x8
ffffffffc02005fe:	02f76163          	bltu	a4,a5,ffffffffc0200620 <page_index+0x46>
    assert(addr >= start && (addr - start) % sizeof(struct Page) == 0);
ffffffffc0200602:	02d56f63          	bltu	a0,a3,ffffffffc0200640 <page_index+0x66>
ffffffffc0200606:	8d15                	sub	a0,a0,a3
ffffffffc0200608:	02800713          	li	a4,40
ffffffffc020060c:	02e576b3          	remu	a3,a0,a4
ffffffffc0200610:	ea85                	bnez	a3,ffffffffc0200640 <page_index+0x66>
    size_t index = (addr - start) / sizeof(struct Page);
ffffffffc0200612:	02e55533          	divu	a0,a0,a4
    assert(index < npage - nbase);
ffffffffc0200616:	04f57563          	bgeu	a0,a5,ffffffffc0200660 <page_index+0x86>
}
ffffffffc020061a:	60a2                	ld	ra,8(sp)
ffffffffc020061c:	0141                	addi	sp,sp,16
ffffffffc020061e:	8082                	ret
    assert(npage >= nbase && npage - nbase <= BUDDY_CAPACITY);
ffffffffc0200620:	00002697          	auipc	a3,0x2
ffffffffc0200624:	75068693          	addi	a3,a3,1872 # ffffffffc0202d70 <etext+0x266>
ffffffffc0200628:	00002617          	auipc	a2,0x2
ffffffffc020062c:	78060613          	addi	a2,a2,1920 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200630:	02100593          	li	a1,33
ffffffffc0200634:	00002517          	auipc	a0,0x2
ffffffffc0200638:	78c50513          	addi	a0,a0,1932 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc020063c:	b87ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(addr >= start && (addr - start) % sizeof(struct Page) == 0);
ffffffffc0200640:	00002697          	auipc	a3,0x2
ffffffffc0200644:	79868693          	addi	a3,a3,1944 # ffffffffc0202dd8 <etext+0x2ce>
ffffffffc0200648:	00002617          	auipc	a2,0x2
ffffffffc020064c:	76060613          	addi	a2,a2,1888 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200650:	02200593          	li	a1,34
ffffffffc0200654:	00002517          	auipc	a0,0x2
ffffffffc0200658:	76c50513          	addi	a0,a0,1900 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc020065c:	b67ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(index < npage - nbase);
ffffffffc0200660:	00002697          	auipc	a3,0x2
ffffffffc0200664:	7b868693          	addi	a3,a3,1976 # ffffffffc0202e18 <etext+0x30e>
ffffffffc0200668:	00002617          	auipc	a2,0x2
ffffffffc020066c:	74060613          	addi	a2,a2,1856 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200670:	02400593          	li	a1,36
ffffffffc0200674:	00002517          	auipc	a0,0x2
ffffffffc0200678:	74c50513          	addi	a0,a0,1868 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc020067c:	b47ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200680 <test_arena_reset>:
}

/* Discard only the borrowed arena's temporary state. Never call buddy_init:
 * that would erase metadata belonging to real kernel allocations. */
static void
test_arena_reset(void) {
ffffffffc0200680:	1141                	addi	sp,sp,-16
ffffffffc0200682:	e406                	sd	ra,8(sp)
ffffffffc0200684:	e022                	sd	s0,0(sp)
ffffffffc0200686:	00008797          	auipc	a5,0x8
ffffffffc020068a:	39278793          	addi	a5,a5,914 # ffffffffc0208a18 <free_lists>
ffffffffc020068e:	00008717          	auipc	a4,0x8
ffffffffc0200692:	48a70713          	addi	a4,a4,1162 # ffffffffc0208b18 <old_region.1>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200696:	e79c                	sd	a5,8(a5)
ffffffffc0200698:	e39c                	sd	a5,0(a5)
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc020069a:	07c1                	addi	a5,a5,16
ffffffffc020069c:	fee79de3          	bne	a5,a4,ffffffffc0200696 <test_arena_reset+0x16>
        list_init(&free_lists[order]);
    }
    nr_free = 0;
    size_t index = page_index(test_state.base);
ffffffffc02006a0:	00048417          	auipc	s0,0x48
ffffffffc02006a4:	67843403          	ld	s0,1656(s0) # ffffffffc0248d18 <test_state>
ffffffffc02006a8:	8522                	mv	a0,s0
    nr_free = 0;
ffffffffc02006aa:	00049797          	auipc	a5,0x49
ffffffffc02006ae:	3807bb23          	sd	zero,918(a5) # ffffffffc0249a40 <nr_free>
    size_t index = page_index(test_state.base);
ffffffffc02006b2:	f29ff0ef          	jal	ra,ffffffffc02005da <page_index>
    for (size_t i = 0; i < TEST_PAGES; i ++) {
ffffffffc02006b6:	00251593          	slli	a1,a0,0x2
ffffffffc02006ba:	01840793          	addi	a5,s0,24
    size_t index = page_index(test_state.base);
ffffffffc02006be:	4681                	li	a3,0
ffffffffc02006c0:	00028317          	auipc	t1,0x28
ffffffffc02006c4:	65830313          	addi	t1,t1,1624 # ffffffffc0228d18 <requested>
ffffffffc02006c8:	00008897          	auipc	a7,0x8
ffffffffc02006cc:	65088893          	addi	a7,a7,1616 # ffffffffc0208d18 <region>
        struct Page *p = test_state.base + i;
        p->flags = p->property = 0;
        SetPageReserved(p);
ffffffffc02006d0:	4805                	li	a6,1
    for (size_t i = 0; i < TEST_PAGES; i ++) {
ffffffffc02006d2:	10000513          	li	a0,256
        set_page_ref(p, 0);
        list_init(&p->page_link);
        region[index + i] = requested[index + i] = 0;
ffffffffc02006d6:	00b68733          	add	a4,a3,a1
        p->flags = p->property = 0;
ffffffffc02006da:	fe07ac23          	sw	zero,-8(a5)
        SetPageReserved(p);
ffffffffc02006de:	ff07b823          	sd	a6,-16(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02006e2:	fe07a423          	sw	zero,-24(a5)
ffffffffc02006e6:	e79c                	sd	a5,8(a5)
ffffffffc02006e8:	e39c                	sd	a5,0(a5)
        region[index + i] = requested[index + i] = 0;
ffffffffc02006ea:	00e30633          	add	a2,t1,a4
ffffffffc02006ee:	9746                	add	a4,a4,a7
ffffffffc02006f0:	00062023          	sw	zero,0(a2)
ffffffffc02006f4:	00072023          	sw	zero,0(a4)
    for (size_t i = 0; i < TEST_PAGES; i ++) {
ffffffffc02006f8:	0691                	addi	a3,a3,4
ffffffffc02006fa:	02878793          	addi	a5,a5,40
ffffffffc02006fe:	fca69ce3          	bne	a3,a0,ffffffffc02006d6 <test_arena_reset+0x56>
    }
}
ffffffffc0200702:	60a2                	ld	ra,8(sp)
ffffffffc0200704:	6402                	ld	s0,0(sp)
ffffffffc0200706:	0141                	addi	sp,sp,16
ffffffffc0200708:	8082                	ret

ffffffffc020070a <check_lists>:
check_lists(void) {
ffffffffc020070a:	7119                	addi	sp,sp,-128
ffffffffc020070c:	f4a6                	sd	s1,104(sp)
ffffffffc020070e:	f0ca                	sd	s2,96(sp)
            assert(size <= npage - nbase - index && region[index] != 0);
ffffffffc0200710:	00049497          	auipc	s1,0x49
ffffffffc0200714:	3384b483          	ld	s1,824(s1) # ffffffffc0249a48 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200718:	00004917          	auipc	s2,0x4
ffffffffc020071c:	b0893903          	ld	s2,-1272(s2) # ffffffffc0204220 <nbase>
            assert(total <= nr_free);
ffffffffc0200720:	00049797          	auipc	a5,0x49
ffffffffc0200724:	3207b783          	ld	a5,800(a5) # ffffffffc0249a40 <nr_free>
check_lists(void) {
ffffffffc0200728:	f8a2                	sd	s0,112(sp)
ffffffffc020072a:	e4d6                	sd	s5,72(sp)
ffffffffc020072c:	e0da                	sd	s6,64(sp)
ffffffffc020072e:	fc5e                	sd	s7,56(sp)
ffffffffc0200730:	f862                	sd	s8,48(sp)
ffffffffc0200732:	ec6e                	sd	s11,24(sp)
ffffffffc0200734:	fc86                	sd	ra,120(sp)
ffffffffc0200736:	ecce                	sd	s3,88(sp)
ffffffffc0200738:	e8d2                	sd	s4,80(sp)
ffffffffc020073a:	f466                	sd	s9,40(sp)
ffffffffc020073c:	f06a                	sd	s10,32(sp)
ffffffffc020073e:	00049c17          	auipc	s8,0x49
ffffffffc0200742:	312c3c03          	ld	s8,786(s8) # ffffffffc0249a50 <pages>
            assert(size <= npage - nbase - index && region[index] != 0);
ffffffffc0200746:	412484b3          	sub	s1,s1,s2
            assert(total <= nr_free);
ffffffffc020074a:	e03e                	sd	a5,0(sp)
ffffffffc020074c:	00008417          	auipc	s0,0x8
ffffffffc0200750:	2cc40413          	addi	s0,s0,716 # ffffffffc0208a18 <free_lists>
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc0200754:	e402                	sd	zero,8(sp)
    size_t total = 0;
ffffffffc0200756:	4d81                	li	s11,0
ffffffffc0200758:	00004b97          	auipc	s7,0x4
ffffffffc020075c:	ac0bbb83          	ld	s7,-1344(s7) # ffffffffc0204218 <error_string+0x38>
            assert(size <= npage - nbase - index && region[index] != 0);
ffffffffc0200760:	00008b17          	auipc	s6,0x8
ffffffffc0200764:	5b8b0b13          	addi	s6,s6,1464 # ffffffffc0208d18 <region>
ffffffffc0200768:	00028a97          	auipc	s5,0x28
ffffffffc020076c:	5b0a8a93          	addi	s5,s5,1456 # ffffffffc0228d18 <requested>
    return (size_t)1 << order;
ffffffffc0200770:	6722                	ld	a4,8(sp)
ffffffffc0200772:	4785                	li	a5,1
        list_entry_t *head = &free_lists[order], *le = head;
ffffffffc0200774:	8d22                	mv	s10,s0
    return (size_t)1 << order;
ffffffffc0200776:	00e79cb3          	sll	s9,a5,a4
            assert((page2ppn(page) & (size - 1)) == 0);
ffffffffc020077a:	fffc8993          	addi	s3,s9,-1
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020077e:	008d3d03          	ld	s10,8(s10)
        while ((le = list_next(le)) != head) {
ffffffffc0200782:	108d0263          	beq	s10,s0,ffffffffc0200886 <check_lists+0x17c>
            struct Page *page = le2page(le, page_link);
ffffffffc0200786:	fe8d0a13          	addi	s4,s10,-24
            size_t index = page_index(page), size = block_size(order);
ffffffffc020078a:	8552                	mv	a0,s4
ffffffffc020078c:	e4fff0ef          	jal	ra,ffffffffc02005da <page_index>
            assert(PageProperty(page) && page->property == size);
ffffffffc0200790:	ff0d3703          	ld	a4,-16(s10)
ffffffffc0200794:	8b09                	andi	a4,a4,2
ffffffffc0200796:	18070263          	beqz	a4,ffffffffc020091a <check_lists+0x210>
ffffffffc020079a:	ff8d6703          	lwu	a4,-8(s10)
ffffffffc020079e:	17971e63          	bne	a4,s9,ffffffffc020091a <check_lists+0x210>
ffffffffc02007a2:	418a07b3          	sub	a5,s4,s8
ffffffffc02007a6:	878d                	srai	a5,a5,0x3
ffffffffc02007a8:	037787b3          	mul	a5,a5,s7
ffffffffc02007ac:	97ca                	add	a5,a5,s2
            assert((page2ppn(page) & (size - 1)) == 0);
ffffffffc02007ae:	0137f7b3          	and	a5,a5,s3
ffffffffc02007b2:	14079463          	bnez	a5,ffffffffc02008fa <check_lists+0x1f0>
            assert(size <= npage - nbase - index && region[index] != 0);
ffffffffc02007b6:	40a48733          	sub	a4,s1,a0
ffffffffc02007ba:	13976063          	bltu	a4,s9,ffffffffc02008da <check_lists+0x1d0>
ffffffffc02007be:	00251613          	slli	a2,a0,0x2
ffffffffc02007c2:	00cb05b3          	add	a1,s6,a2
ffffffffc02007c6:	0005ae03          	lw	t3,0(a1)
ffffffffc02007ca:	100e0863          	beqz	t3,ffffffffc02008da <check_lists+0x1d0>
ffffffffc02007ce:	ff0d0693          	addi	a3,s10,-16
ffffffffc02007d2:	9656                	add	a2,a2,s5
                assert(!PageReserved(page + i) && requested[index + i] == 0);
ffffffffc02007d4:	6298                	ld	a4,0(a3)
ffffffffc02007d6:	00177513          	andi	a0,a4,1
ffffffffc02007da:	e531                	bnez	a0,ffffffffc0200826 <check_lists+0x11c>
ffffffffc02007dc:	4208                	lw	a0,0(a2)
ffffffffc02007de:	e521                	bnez	a0,ffffffffc0200826 <check_lists+0x11c>
                assert(region[index + i] == region[index]);
ffffffffc02007e0:	4188                	lw	a0,0(a1)
ffffffffc02007e2:	09c51263          	bne	a0,t3,ffffffffc0200866 <check_lists+0x15c>
                assert(i == 0 || (!PageProperty(page + i) && page[i].property == 0));
ffffffffc02007e6:	c789                	beqz	a5,ffffffffc02007f0 <check_lists+0xe6>
ffffffffc02007e8:	8b09                	andi	a4,a4,2
ffffffffc02007ea:	ef31                	bnez	a4,ffffffffc0200846 <check_lists+0x13c>
ffffffffc02007ec:	4698                	lw	a4,8(a3)
ffffffffc02007ee:	ef21                	bnez	a4,ffffffffc0200846 <check_lists+0x13c>
            for (size_t i = 0; i < size; i ++) {
ffffffffc02007f0:	0785                	addi	a5,a5,1
ffffffffc02007f2:	02868693          	addi	a3,a3,40
ffffffffc02007f6:	0591                	addi	a1,a1,4
ffffffffc02007f8:	0611                	addi	a2,a2,4
ffffffffc02007fa:	fd97ede3          	bltu	a5,s9,ffffffffc02007d4 <check_lists+0xca>
            assert(total <= nr_free);
ffffffffc02007fe:	6782                	ld	a5,0(sp)
            total += size;
ffffffffc0200800:	9de6                	add	s11,s11,s9
            assert(total <= nr_free);
ffffffffc0200802:	f7b7fee3          	bgeu	a5,s11,ffffffffc020077e <check_lists+0x74>
ffffffffc0200806:	00002697          	auipc	a3,0x2
ffffffffc020080a:	75a68693          	addi	a3,a3,1882 # ffffffffc0202f60 <etext+0x456>
ffffffffc020080e:	00002617          	auipc	a2,0x2
ffffffffc0200812:	59a60613          	addi	a2,a2,1434 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200816:	0b900593          	li	a1,185
ffffffffc020081a:	00002517          	auipc	a0,0x2
ffffffffc020081e:	5a650513          	addi	a0,a0,1446 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200822:	9a1ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(!PageReserved(page + i) && requested[index + i] == 0);
ffffffffc0200826:	00002697          	auipc	a3,0x2
ffffffffc020082a:	69a68693          	addi	a3,a3,1690 # ffffffffc0202ec0 <etext+0x3b6>
ffffffffc020082e:	00002617          	auipc	a2,0x2
ffffffffc0200832:	57a60613          	addi	a2,a2,1402 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200836:	0b400593          	li	a1,180
ffffffffc020083a:	00002517          	auipc	a0,0x2
ffffffffc020083e:	58650513          	addi	a0,a0,1414 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200842:	981ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(i == 0 || (!PageProperty(page + i) && page[i].property == 0));
ffffffffc0200846:	00002697          	auipc	a3,0x2
ffffffffc020084a:	6da68693          	addi	a3,a3,1754 # ffffffffc0202f20 <etext+0x416>
ffffffffc020084e:	00002617          	auipc	a2,0x2
ffffffffc0200852:	55a60613          	addi	a2,a2,1370 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200856:	0b600593          	li	a1,182
ffffffffc020085a:	00002517          	auipc	a0,0x2
ffffffffc020085e:	56650513          	addi	a0,a0,1382 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200862:	961ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(region[index + i] == region[index]);
ffffffffc0200866:	00002697          	auipc	a3,0x2
ffffffffc020086a:	69268693          	addi	a3,a3,1682 # ffffffffc0202ef8 <etext+0x3ee>
ffffffffc020086e:	00002617          	auipc	a2,0x2
ffffffffc0200872:	53a60613          	addi	a2,a2,1338 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200876:	0b500593          	li	a1,181
ffffffffc020087a:	00002517          	auipc	a0,0x2
ffffffffc020087e:	54650513          	addi	a0,a0,1350 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200882:	941ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc0200886:	67a2                	ld	a5,8(sp)
ffffffffc0200888:	4741                	li	a4,16
ffffffffc020088a:	010d0413          	addi	s0,s10,16
ffffffffc020088e:	2785                	addiw	a5,a5,1
ffffffffc0200890:	e43e                	sd	a5,8(sp)
ffffffffc0200892:	ece79fe3          	bne	a5,a4,ffffffffc0200770 <check_lists+0x66>
    assert(total == nr_free);
ffffffffc0200896:	6782                	ld	a5,0(sp)
ffffffffc0200898:	03b79163          	bne	a5,s11,ffffffffc02008ba <check_lists+0x1b0>
}
ffffffffc020089c:	70e6                	ld	ra,120(sp)
ffffffffc020089e:	7446                	ld	s0,112(sp)
ffffffffc02008a0:	74a6                	ld	s1,104(sp)
ffffffffc02008a2:	7906                	ld	s2,96(sp)
ffffffffc02008a4:	69e6                	ld	s3,88(sp)
ffffffffc02008a6:	6a46                	ld	s4,80(sp)
ffffffffc02008a8:	6aa6                	ld	s5,72(sp)
ffffffffc02008aa:	6b06                	ld	s6,64(sp)
ffffffffc02008ac:	7be2                	ld	s7,56(sp)
ffffffffc02008ae:	7c42                	ld	s8,48(sp)
ffffffffc02008b0:	7ca2                	ld	s9,40(sp)
ffffffffc02008b2:	7d02                	ld	s10,32(sp)
ffffffffc02008b4:	6de2                	ld	s11,24(sp)
ffffffffc02008b6:	6109                	addi	sp,sp,128
ffffffffc02008b8:	8082                	ret
    assert(total == nr_free);
ffffffffc02008ba:	00002697          	auipc	a3,0x2
ffffffffc02008be:	6be68693          	addi	a3,a3,1726 # ffffffffc0202f78 <etext+0x46e>
ffffffffc02008c2:	00002617          	auipc	a2,0x2
ffffffffc02008c6:	4e660613          	addi	a2,a2,1254 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02008ca:	0bc00593          	li	a1,188
ffffffffc02008ce:	00002517          	auipc	a0,0x2
ffffffffc02008d2:	4f250513          	addi	a0,a0,1266 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02008d6:	8edff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(size <= npage - nbase - index && region[index] != 0);
ffffffffc02008da:	00002697          	auipc	a3,0x2
ffffffffc02008de:	5ae68693          	addi	a3,a3,1454 # ffffffffc0202e88 <etext+0x37e>
ffffffffc02008e2:	00002617          	auipc	a2,0x2
ffffffffc02008e6:	4c660613          	addi	a2,a2,1222 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02008ea:	0b200593          	li	a1,178
ffffffffc02008ee:	00002517          	auipc	a0,0x2
ffffffffc02008f2:	4d250513          	addi	a0,a0,1234 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02008f6:	8cdff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert((page2ppn(page) & (size - 1)) == 0);
ffffffffc02008fa:	00002697          	auipc	a3,0x2
ffffffffc02008fe:	56668693          	addi	a3,a3,1382 # ffffffffc0202e60 <etext+0x356>
ffffffffc0200902:	00002617          	auipc	a2,0x2
ffffffffc0200906:	4a660613          	addi	a2,a2,1190 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020090a:	0b100593          	li	a1,177
ffffffffc020090e:	00002517          	auipc	a0,0x2
ffffffffc0200912:	4b250513          	addi	a0,a0,1202 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200916:	8adff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(PageProperty(page) && page->property == size);
ffffffffc020091a:	00002697          	auipc	a3,0x2
ffffffffc020091e:	51668693          	addi	a3,a3,1302 # ffffffffc0202e30 <etext+0x326>
ffffffffc0200922:	00002617          	auipc	a2,0x2
ffffffffc0200926:	48660613          	addi	a2,a2,1158 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020092a:	0b000593          	li	a1,176
ffffffffc020092e:	00002517          	auipc	a0,0x2
ffffffffc0200932:	49250513          	addi	a0,a0,1170 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200936:	88dff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020093a <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc020093a:	7179                	addi	sp,sp,-48
ffffffffc020093c:	ec26                	sd	s1,24(sp)
ffffffffc020093e:	84ae                	mv	s1,a1
ffffffffc0200940:	f022                	sd	s0,32(sp)
ffffffffc0200942:	f406                	sd	ra,40(sp)
ffffffffc0200944:	e84a                	sd	s2,16(sp)
ffffffffc0200946:	e44e                	sd	s3,8(sp)
ffffffffc0200948:	842a                	mv	s0,a0
    size_t index = page_index(base);
ffffffffc020094a:	c91ff0ef          	jal	ra,ffffffffc02005da <page_index>
    assert(n > 0 && requested[index] == n);
ffffffffc020094e:	2c048e63          	beqz	s1,ffffffffc0200c2a <buddy_free_pages+0x2f0>
ffffffffc0200952:	00028917          	auipc	s2,0x28
ffffffffc0200956:	3c690913          	addi	s2,s2,966 # ffffffffc0228d18 <requested>
ffffffffc020095a:	00251993          	slli	s3,a0,0x2
ffffffffc020095e:	013907b3          	add	a5,s2,s3
ffffffffc0200962:	0007e683          	lwu	a3,0(a5)
    unsigned int order = 0;
ffffffffc0200966:	4301                	li	t1,0
    return (size_t)1 << order;
ffffffffc0200968:	4785                	li	a5,1
    while (order < BUDDY_MAX_ORDER && block_size(order) < n) {
ffffffffc020096a:	473d                	li	a4,15
    assert(n > 0 && requested[index] == n);
ffffffffc020096c:	2a969f63          	bne	a3,s1,ffffffffc0200c2a <buddy_free_pages+0x2f0>
    return (size_t)1 << order;
ffffffffc0200970:	00679833          	sll	a6,a5,t1
    while (order < BUDDY_MAX_ORDER && block_size(order) < n) {
ffffffffc0200974:	00987963          	bgeu	a6,s1,ffffffffc0200986 <buddy_free_pages+0x4c>
        order ++;
ffffffffc0200978:	2305                	addiw	t1,t1,1
    while (order < BUDDY_MAX_ORDER && block_size(order) < n) {
ffffffffc020097a:	fee31be3          	bne	t1,a4,ffffffffc0200970 <buddy_free_pages+0x36>
    assert(size >= n && size <= npage - nbase - index);
ffffffffc020097e:	67a1                	lui	a5,0x8
ffffffffc0200980:	2897e563          	bltu	a5,s1,ffffffffc0200c0a <buddy_free_pages+0x2d0>
ffffffffc0200984:	6821                	lui	a6,0x8
ffffffffc0200986:	00049e97          	auipc	t4,0x49
ffffffffc020098a:	0c2ebe83          	ld	t4,194(t4) # ffffffffc0249a48 <npage>
ffffffffc020098e:	00004e17          	auipc	t3,0x4
ffffffffc0200992:	892e3e03          	ld	t3,-1902(t3) # ffffffffc0204220 <nbase>
ffffffffc0200996:	41ce87b3          	sub	a5,t4,t3
ffffffffc020099a:	40a78533          	sub	a0,a5,a0
ffffffffc020099e:	27056663          	bltu	a0,a6,ffffffffc0200c0a <buddy_free_pages+0x2d0>
    assert(!PageProperty(base) && base->property == size);
ffffffffc02009a2:	00843f03          	ld	t5,8(s0)
ffffffffc02009a6:	002f7793          	andi	a5,t5,2
ffffffffc02009aa:	2c079063          	bnez	a5,ffffffffc0200c6a <buddy_free_pages+0x330>
ffffffffc02009ae:	01046783          	lwu	a5,16(s0)
ffffffffc02009b2:	2b079c63          	bne	a5,a6,ffffffffc0200c6a <buddy_free_pages+0x330>
ffffffffc02009b6:	00049f97          	auipc	t6,0x49
ffffffffc02009ba:	09afbf83          	ld	t6,154(t6) # ffffffffc0249a50 <pages>
ffffffffc02009be:	41f408b3          	sub	a7,s0,t6
ffffffffc02009c2:	4038d893          	srai	a7,a7,0x3
ffffffffc02009c6:	00004297          	auipc	t0,0x4
ffffffffc02009ca:	8522b283          	ld	t0,-1966(t0) # ffffffffc0204218 <error_string+0x38>
ffffffffc02009ce:	025888b3          	mul	a7,a7,t0
    assert((page2ppn(base) & (size - 1)) == 0);
ffffffffc02009d2:	fff80793          	addi	a5,a6,-1 # 7fff <kern_entry-0xffffffffc01f8001>
ffffffffc02009d6:	98f2                	add	a7,a7,t3
ffffffffc02009d8:	0117f7b3          	and	a5,a5,a7
ffffffffc02009dc:	26079763          	bnez	a5,ffffffffc0200c4a <buddy_free_pages+0x310>
    unsigned int id = region[index];
ffffffffc02009e0:	00008397          	auipc	t2,0x8
ffffffffc02009e4:	33838393          	addi	t2,t2,824 # ffffffffc0208d18 <region>
ffffffffc02009e8:	013386b3          	add	a3,t2,s3
ffffffffc02009ec:	4288                	lw	a0,0(a3)
    assert(id != 0);
ffffffffc02009ee:	1e050e63          	beqz	a0,ffffffffc0200bea <buddy_free_pages+0x2b0>
ffffffffc02009f2:	02840613          	addi	a2,s0,40
ffffffffc02009f6:	013905b3          	add	a1,s2,s3
ffffffffc02009fa:	877a                	mv	a4,t5
ffffffffc02009fc:	a021                	j	ffffffffc0200a04 <buddy_free_pages+0xca>
        assert(!PageReserved(base + i) && !PageProperty(base + i));
ffffffffc02009fe:	6618                	ld	a4,8(a2)
ffffffffc0200a00:	02860613          	addi	a2,a2,40
ffffffffc0200a04:	8b0d                	andi	a4,a4,3
ffffffffc0200a06:	1a071263          	bnez	a4,ffffffffc0200baa <buddy_free_pages+0x270>
        assert(region[index + i] == id);
ffffffffc0200a0a:	4298                	lw	a4,0(a3)
ffffffffc0200a0c:	16a71f63          	bne	a4,a0,ffffffffc0200b8a <buddy_free_pages+0x250>
        assert(i == 0 || requested[index + i] == 0);
ffffffffc0200a10:	c781                	beqz	a5,ffffffffc0200a18 <buddy_free_pages+0xde>
ffffffffc0200a12:	4198                	lw	a4,0(a1)
ffffffffc0200a14:	1a071b63          	bnez	a4,ffffffffc0200bca <buddy_free_pages+0x290>
    for (size_t i = 0; i < size; i ++) {
ffffffffc0200a18:	0785                	addi	a5,a5,1
ffffffffc0200a1a:	0591                	addi	a1,a1,4
ffffffffc0200a1c:	0691                	addi	a3,a3,4
ffffffffc0200a1e:	ff0790e3          	bne	a5,a6,ffffffffc02009fe <buddy_free_pages+0xc4>
    requested[index] = 0;
ffffffffc0200a22:	00281713          	slli	a4,a6,0x2
ffffffffc0200a26:	9742                	add	a4,a4,a6
ffffffffc0200a28:	994e                	add	s2,s2,s3
ffffffffc0200a2a:	070e                	slli	a4,a4,0x3
ffffffffc0200a2c:	00092023          	sw	zero,0(s2)
    for (size_t i = 0; i < size; i ++) {
ffffffffc0200a30:	87a2                	mv	a5,s0
ffffffffc0200a32:	9722                	add	a4,a4,s0
        base[i].property = 0;
ffffffffc0200a34:	0007a823          	sw	zero,16(a5) # 8010 <kern_entry-0xffffffffc01f7ff0>
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200a38:	0007a023          	sw	zero,0(a5)
    for (size_t i = 0; i < size; i ++) {
ffffffffc0200a3c:	02878793          	addi	a5,a5,40
ffffffffc0200a40:	fef71ae3          	bne	a4,a5,ffffffffc0200a34 <buddy_free_pages+0xfa>
    nr_free += size;
ffffffffc0200a44:	00049717          	auipc	a4,0x49
ffffffffc0200a48:	ffc70713          	addi	a4,a4,-4 # ffffffffc0249a40 <nr_free>
ffffffffc0200a4c:	631c                	ld	a5,0(a4)
    while (order < BUDDY_MAX_ORDER) {
ffffffffc0200a4e:	46bd                	li	a3,15
    nr_free += size;
ffffffffc0200a50:	97c2                	add	a5,a5,a6
ffffffffc0200a52:	e31c                	sd	a5,0(a4)
    while (order < BUDDY_MAX_ORDER) {
ffffffffc0200a54:	12d30663          	beq	t1,a3,ffffffffc0200b80 <buddy_free_pages+0x246>
        size_t buddy_ppn = page2ppn(base) ^ block_size(order);
ffffffffc0200a58:	0108c6b3          	xor	a3,a7,a6
        if (buddy_ppn < nbase || buddy_ppn >= npage) {
ffffffffc0200a5c:	11c6ea63          	bltu	a3,t3,ffffffffc0200b70 <buddy_free_pages+0x236>
ffffffffc0200a60:	11d6f863          	bgeu	a3,t4,ffffffffc0200b70 <buddy_free_pages+0x236>
        size_t other = buddy_ppn - nbase;
ffffffffc0200a64:	41c68733          	sub	a4,a3,t3
        struct Page *buddy = pages + other;
ffffffffc0200a68:	00271613          	slli	a2,a4,0x2
ffffffffc0200a6c:	9732                	add	a4,a4,a2
ffffffffc0200a6e:	070e                	slli	a4,a4,0x3
        if (block_size(order) > npage - buddy_ppn ||
ffffffffc0200a70:	40de85b3          	sub	a1,t4,a3
        struct Page *buddy = pages + other;
ffffffffc0200a74:	00ef87b3          	add	a5,t6,a4
        if (block_size(order) > npage - buddy_ppn ||
ffffffffc0200a78:	0f05ec63          	bltu	a1,a6,ffffffffc0200b70 <buddy_free_pages+0x236>
            region[other] != id || PageReserved(buddy) ||
ffffffffc0200a7c:	4589                	li	a1,2
    while (order < BUDDY_MAX_ORDER) {
ffffffffc0200a7e:	4f3d                	li	t5,15
    return (size_t)1 << order;
ffffffffc0200a80:	4485                	li	s1,1
ffffffffc0200a82:	a89d                	j	ffffffffc0200af8 <buddy_free_pages+0x1be>
            region[other] != id || PageReserved(buddy) ||
ffffffffc0200a84:	6798                	ld	a4,8(a5)
ffffffffc0200a86:	00377613          	andi	a2,a4,3
ffffffffc0200a8a:	06b61b63          	bne	a2,a1,ffffffffc0200b00 <buddy_free_pages+0x1c6>
            !PageProperty(buddy) || buddy->property != block_size(order)) {
ffffffffc0200a8e:	0107e603          	lwu	a2,16(a5)
ffffffffc0200a92:	07061763          	bne	a2,a6,ffffffffc0200b00 <buddy_free_pages+0x1c6>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a96:	0187b903          	ld	s2,24(a5)
ffffffffc0200a9a:	0207b803          	ld	a6,32(a5)
    list_del_init(&page->page_link);
ffffffffc0200a9e:	01878613          	addi	a2,a5,24
    ClearPageProperty(page);
ffffffffc0200aa2:	9b75                	andi	a4,a4,-3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200aa4:	01093423          	sd	a6,8(s2)
    next->prev = prev;
ffffffffc0200aa8:	01283023          	sd	s2,0(a6)
    elm->prev = elm->next = elm;
ffffffffc0200aac:	f390                	sd	a2,32(a5)
ffffffffc0200aae:	ef90                	sd	a2,24(a5)
ffffffffc0200ab0:	e798                	sd	a4,8(a5)
    page->property = 0;
ffffffffc0200ab2:	0007a823          	sw	zero,16(a5)
        if (buddy_ppn < page2ppn(base)) {
ffffffffc0200ab6:	0116f363          	bgeu	a3,a7,ffffffffc0200abc <buddy_free_pages+0x182>
ffffffffc0200aba:	843e                	mv	s0,a5
        order ++;
ffffffffc0200abc:	2305                	addiw	t1,t1,1
    while (order < BUDDY_MAX_ORDER) {
ffffffffc0200abe:	0be30063          	beq	t1,t5,ffffffffc0200b5e <buddy_free_pages+0x224>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ac2:	41f408b3          	sub	a7,s0,t6
ffffffffc0200ac6:	4038d893          	srai	a7,a7,0x3
ffffffffc0200aca:	025888b3          	mul	a7,a7,t0
    return (size_t)1 << order;
ffffffffc0200ace:	00649833          	sll	a6,s1,t1
ffffffffc0200ad2:	98f2                	add	a7,a7,t3
        size_t buddy_ppn = page2ppn(base) ^ block_size(order);
ffffffffc0200ad4:	011846b3          	xor	a3,a6,a7
        if (buddy_ppn < nbase || buddy_ppn >= npage) {
ffffffffc0200ad8:	07c6e963          	bltu	a3,t3,ffffffffc0200b4a <buddy_free_pages+0x210>
ffffffffc0200adc:	07d6f763          	bgeu	a3,t4,ffffffffc0200b4a <buddy_free_pages+0x210>
        size_t other = buddy_ppn - nbase;
ffffffffc0200ae0:	41c68733          	sub	a4,a3,t3
        struct Page *buddy = pages + other;
ffffffffc0200ae4:	00271613          	slli	a2,a4,0x2
ffffffffc0200ae8:	00e607b3          	add	a5,a2,a4
ffffffffc0200aec:	078e                	slli	a5,a5,0x3
        if (block_size(order) > npage - buddy_ppn ||
ffffffffc0200aee:	40de8733          	sub	a4,t4,a3
        struct Page *buddy = pages + other;
ffffffffc0200af2:	97fe                	add	a5,a5,t6
        if (block_size(order) > npage - buddy_ppn ||
ffffffffc0200af4:	05076b63          	bltu	a4,a6,ffffffffc0200b4a <buddy_free_pages+0x210>
            region[other] != id || PageReserved(buddy) ||
ffffffffc0200af8:	961e                	add	a2,a2,t2
        if (block_size(order) > npage - buddy_ppn ||
ffffffffc0200afa:	4218                	lw	a4,0(a2)
ffffffffc0200afc:	f8a704e3          	beq	a4,a0,ffffffffc0200a84 <buddy_free_pages+0x14a>
ffffffffc0200b00:	02031713          	slli	a4,t1,0x20
    return (size_t)1 << order;
ffffffffc0200b04:	4785                	li	a5,1
    SetPageProperty(page);
ffffffffc0200b06:	00843f03          	ld	t5,8(s0)
ffffffffc0200b0a:	9301                	srli	a4,a4,0x20
    return (size_t)1 << order;
ffffffffc0200b0c:	006797b3          	sll	a5,a5,t1
ffffffffc0200b10:	00471593          	slli	a1,a4,0x4
    page->property = block_size(order);
ffffffffc0200b14:	2781                	sext.w	a5,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b16:	00008697          	auipc	a3,0x8
ffffffffc0200b1a:	f0268693          	addi	a3,a3,-254 # ffffffffc0208a18 <free_lists>
ffffffffc0200b1e:	0712                	slli	a4,a4,0x4
ffffffffc0200b20:	9736                	add	a4,a4,a3
ffffffffc0200b22:	6710                	ld	a2,8(a4)
    SetPageProperty(page);
ffffffffc0200b24:	002f6f13          	ori	t5,t5,2
    page->property = block_size(order);
ffffffffc0200b28:	c81c                	sw	a5,16(s0)
    SetPageProperty(page);
ffffffffc0200b2a:	01e43423          	sd	t5,8(s0)
    list_add(&free_lists[order], &page->page_link);
ffffffffc0200b2e:	01840793          	addi	a5,s0,24
    prev->next = next->prev = elm;
ffffffffc0200b32:	e21c                	sd	a5,0(a2)
ffffffffc0200b34:	e71c                	sd	a5,8(a4)
ffffffffc0200b36:	96ae                	add	a3,a3,a1
}
ffffffffc0200b38:	70a2                	ld	ra,40(sp)
    elm->next = next;
ffffffffc0200b3a:	f010                	sd	a2,32(s0)
    elm->prev = prev;
ffffffffc0200b3c:	ec14                	sd	a3,24(s0)
ffffffffc0200b3e:	7402                	ld	s0,32(sp)
ffffffffc0200b40:	64e2                	ld	s1,24(sp)
ffffffffc0200b42:	6942                	ld	s2,16(sp)
ffffffffc0200b44:	69a2                	ld	s3,8(sp)
ffffffffc0200b46:	6145                	addi	sp,sp,48
ffffffffc0200b48:	8082                	ret
ffffffffc0200b4a:	02031713          	slli	a4,t1,0x20
ffffffffc0200b4e:	9301                	srli	a4,a4,0x20
    SetPageProperty(page);
ffffffffc0200b50:	00843f03          	ld	t5,8(s0)
ffffffffc0200b54:	00471593          	slli	a1,a4,0x4
    page->property = block_size(order);
ffffffffc0200b58:	0008079b          	sext.w	a5,a6
ffffffffc0200b5c:	bf6d                	j	ffffffffc0200b16 <buddy_free_pages+0x1dc>
ffffffffc0200b5e:	02031713          	slli	a4,t1,0x20
    SetPageProperty(page);
ffffffffc0200b62:	00843f03          	ld	t5,8(s0)
ffffffffc0200b66:	67a1                	lui	a5,0x8
ffffffffc0200b68:	0f000593          	li	a1,240
ffffffffc0200b6c:	9301                	srli	a4,a4,0x20
ffffffffc0200b6e:	b765                	j	ffffffffc0200b16 <buddy_free_pages+0x1dc>
ffffffffc0200b70:	02031713          	slli	a4,t1,0x20
ffffffffc0200b74:	9301                	srli	a4,a4,0x20
ffffffffc0200b76:	00471593          	slli	a1,a4,0x4
    page->property = block_size(order);
ffffffffc0200b7a:	0008079b          	sext.w	a5,a6
ffffffffc0200b7e:	bf61                	j	ffffffffc0200b16 <buddy_free_pages+0x1dc>
    while (order < BUDDY_MAX_ORDER) {
ffffffffc0200b80:	67a1                	lui	a5,0x8
ffffffffc0200b82:	0f000593          	li	a1,240
ffffffffc0200b86:	473d                	li	a4,15
ffffffffc0200b88:	b779                	j	ffffffffc0200b16 <buddy_free_pages+0x1dc>
        assert(region[index + i] == id);
ffffffffc0200b8a:	00002697          	auipc	a3,0x2
ffffffffc0200b8e:	4ee68693          	addi	a3,a3,1262 # ffffffffc0203078 <etext+0x56e>
ffffffffc0200b92:	00002617          	auipc	a2,0x2
ffffffffc0200b96:	21660613          	addi	a2,a2,534 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200b9a:	08500593          	li	a1,133
ffffffffc0200b9e:	00002517          	auipc	a0,0x2
ffffffffc0200ba2:	22250513          	addi	a0,a0,546 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200ba6:	e1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(!PageReserved(base + i) && !PageProperty(base + i));
ffffffffc0200baa:	00002697          	auipc	a3,0x2
ffffffffc0200bae:	49668693          	addi	a3,a3,1174 # ffffffffc0203040 <etext+0x536>
ffffffffc0200bb2:	00002617          	auipc	a2,0x2
ffffffffc0200bb6:	1f660613          	addi	a2,a2,502 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200bba:	08400593          	li	a1,132
ffffffffc0200bbe:	00002517          	auipc	a0,0x2
ffffffffc0200bc2:	20250513          	addi	a0,a0,514 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200bc6:	dfcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(i == 0 || requested[index + i] == 0);
ffffffffc0200bca:	00002697          	auipc	a3,0x2
ffffffffc0200bce:	4c668693          	addi	a3,a3,1222 # ffffffffc0203090 <etext+0x586>
ffffffffc0200bd2:	00002617          	auipc	a2,0x2
ffffffffc0200bd6:	1d660613          	addi	a2,a2,470 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200bda:	08600593          	li	a1,134
ffffffffc0200bde:	00002517          	auipc	a0,0x2
ffffffffc0200be2:	1e250513          	addi	a0,a0,482 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200be6:	ddcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(id != 0);
ffffffffc0200bea:	00002697          	auipc	a3,0x2
ffffffffc0200bee:	44e68693          	addi	a3,a3,1102 # ffffffffc0203038 <etext+0x52e>
ffffffffc0200bf2:	00002617          	auipc	a2,0x2
ffffffffc0200bf6:	1b660613          	addi	a2,a2,438 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200bfa:	08200593          	li	a1,130
ffffffffc0200bfe:	00002517          	auipc	a0,0x2
ffffffffc0200c02:	1c250513          	addi	a0,a0,450 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200c06:	dbcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(size >= n && size <= npage - nbase - index);
ffffffffc0200c0a:	00002697          	auipc	a3,0x2
ffffffffc0200c0e:	3a668693          	addi	a3,a3,934 # ffffffffc0202fb0 <etext+0x4a6>
ffffffffc0200c12:	00002617          	auipc	a2,0x2
ffffffffc0200c16:	19660613          	addi	a2,a2,406 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200c1a:	07e00593          	li	a1,126
ffffffffc0200c1e:	00002517          	auipc	a0,0x2
ffffffffc0200c22:	1a250513          	addi	a0,a0,418 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200c26:	d9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0 && requested[index] == n);
ffffffffc0200c2a:	00002697          	auipc	a3,0x2
ffffffffc0200c2e:	36668693          	addi	a3,a3,870 # ffffffffc0202f90 <etext+0x486>
ffffffffc0200c32:	00002617          	auipc	a2,0x2
ffffffffc0200c36:	17660613          	addi	a2,a2,374 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200c3a:	07b00593          	li	a1,123
ffffffffc0200c3e:	00002517          	auipc	a0,0x2
ffffffffc0200c42:	18250513          	addi	a0,a0,386 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200c46:	d7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((page2ppn(base) & (size - 1)) == 0);
ffffffffc0200c4a:	00002697          	auipc	a3,0x2
ffffffffc0200c4e:	3c668693          	addi	a3,a3,966 # ffffffffc0203010 <etext+0x506>
ffffffffc0200c52:	00002617          	auipc	a2,0x2
ffffffffc0200c56:	15660613          	addi	a2,a2,342 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200c5a:	08000593          	li	a1,128
ffffffffc0200c5e:	00002517          	auipc	a0,0x2
ffffffffc0200c62:	16250513          	addi	a0,a0,354 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200c66:	d5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!PageProperty(base) && base->property == size);
ffffffffc0200c6a:	00002697          	auipc	a3,0x2
ffffffffc0200c6e:	37668693          	addi	a3,a3,886 # ffffffffc0202fe0 <etext+0x4d6>
ffffffffc0200c72:	00002617          	auipc	a2,0x2
ffffffffc0200c76:	13660613          	addi	a2,a2,310 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200c7a:	07f00593          	li	a1,127
ffffffffc0200c7e:	00002517          	auipc	a0,0x2
ffffffffc0200c82:	14250513          	addi	a0,a0,322 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200c86:	d3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200c8a <buddy_init>:
buddy_init(void) {
ffffffffc0200c8a:	1141                	addi	sp,sp,-16
ffffffffc0200c8c:	e406                	sd	ra,8(sp)
ffffffffc0200c8e:	00008797          	auipc	a5,0x8
ffffffffc0200c92:	d8a78793          	addi	a5,a5,-630 # ffffffffc0208a18 <free_lists>
ffffffffc0200c96:	00008717          	auipc	a4,0x8
ffffffffc0200c9a:	e8270713          	addi	a4,a4,-382 # ffffffffc0208b18 <old_region.1>
    elm->prev = elm->next = elm;
ffffffffc0200c9e:	e79c                	sd	a5,8(a5)
ffffffffc0200ca0:	e39c                	sd	a5,0(a5)
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc0200ca2:	07c1                	addi	a5,a5,16
ffffffffc0200ca4:	fee79de3          	bne	a5,a4,ffffffffc0200c9e <buddy_init+0x14>
    memset(region, 0, sizeof(region));
ffffffffc0200ca8:	00020637          	lui	a2,0x20
ffffffffc0200cac:	4581                	li	a1,0
ffffffffc0200cae:	00008517          	auipc	a0,0x8
ffffffffc0200cb2:	06a50513          	addi	a0,a0,106 # ffffffffc0208d18 <region>
    nr_free = 0;
ffffffffc0200cb6:	00049797          	auipc	a5,0x49
ffffffffc0200cba:	d807b523          	sd	zero,-630(a5) # ffffffffc0249a40 <nr_free>
    memset(region, 0, sizeof(region));
ffffffffc0200cbe:	5ff010ef          	jal	ra,ffffffffc0202abc <memset>
}
ffffffffc0200cc2:	60a2                	ld	ra,8(sp)
    memset(requested, 0, sizeof(requested));
ffffffffc0200cc4:	00020637          	lui	a2,0x20
ffffffffc0200cc8:	4581                	li	a1,0
ffffffffc0200cca:	00028517          	auipc	a0,0x28
ffffffffc0200cce:	04e50513          	addi	a0,a0,78 # ffffffffc0228d18 <requested>
}
ffffffffc0200cd2:	0141                	addi	sp,sp,16
    memset(requested, 0, sizeof(requested));
ffffffffc0200cd4:	5e90106f          	j	ffffffffc0202abc <memset>

ffffffffc0200cd8 <test_list_count>:
    list_entry_t *head = &free_lists[order], *le = head;
ffffffffc0200cd8:	02051793          	slli	a5,a0,0x20
ffffffffc0200cdc:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0200ce0:	00008617          	auipc	a2,0x8
ffffffffc0200ce4:	d3860613          	addi	a2,a2,-712 # ffffffffc0208a18 <free_lists>
ffffffffc0200ce8:	962a                	add	a2,a2,a0
    return listelm->next;
ffffffffc0200cea:	661c                	ld	a5,8(a2)
        assert(++ count <= BUDDY_CAPACITY);
ffffffffc0200cec:	65a1                	lui	a1,0x8
    size_t count = 0;
ffffffffc0200cee:	4501                	li	a0,0
        assert(++ count <= BUDDY_CAPACITY);
ffffffffc0200cf0:	0585                	addi	a1,a1,1
    while ((le = list_next(le)) != head) {
ffffffffc0200cf2:	04f60563          	beq	a2,a5,ffffffffc0200d3c <test_list_count+0x64>
test_list_count(unsigned int order) {
ffffffffc0200cf6:	1141                	addi	sp,sp,-16
ffffffffc0200cf8:	e406                	sd	ra,8(sp)
        assert(++ count <= BUDDY_CAPACITY);
ffffffffc0200cfa:	0505                	addi	a0,a0,1
ffffffffc0200cfc:	02b50063          	beq	a0,a1,ffffffffc0200d1c <test_list_count+0x44>
        assert(le->next->prev == le && le->prev->next == le);
ffffffffc0200d00:	6798                	ld	a4,8(a5)
ffffffffc0200d02:	6314                	ld	a3,0(a4)
ffffffffc0200d04:	02f69d63          	bne	a3,a5,ffffffffc0200d3e <test_list_count+0x66>
ffffffffc0200d08:	6394                	ld	a3,0(a5)
ffffffffc0200d0a:	6694                	ld	a3,8(a3)
ffffffffc0200d0c:	02f69963          	bne	a3,a5,ffffffffc0200d3e <test_list_count+0x66>
ffffffffc0200d10:	87ba                	mv	a5,a4
    while ((le = list_next(le)) != head) {
ffffffffc0200d12:	fee614e3          	bne	a2,a4,ffffffffc0200cfa <test_list_count+0x22>
}
ffffffffc0200d16:	60a2                	ld	ra,8(sp)
ffffffffc0200d18:	0141                	addi	sp,sp,16
ffffffffc0200d1a:	8082                	ret
        assert(++ count <= BUDDY_CAPACITY);
ffffffffc0200d1c:	00002697          	auipc	a3,0x2
ffffffffc0200d20:	39c68693          	addi	a3,a3,924 # ffffffffc02030b8 <etext+0x5ae>
ffffffffc0200d24:	00002617          	auipc	a2,0x2
ffffffffc0200d28:	08460613          	addi	a2,a2,132 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200d2c:	0d000593          	li	a1,208
ffffffffc0200d30:	00002517          	auipc	a0,0x2
ffffffffc0200d34:	09050513          	addi	a0,a0,144 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200d38:	c8aff0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc0200d3c:	8082                	ret
        assert(le->next->prev == le && le->prev->next == le);
ffffffffc0200d3e:	00002697          	auipc	a3,0x2
ffffffffc0200d42:	39a68693          	addi	a3,a3,922 # ffffffffc02030d8 <etext+0x5ce>
ffffffffc0200d46:	00002617          	auipc	a2,0x2
ffffffffc0200d4a:	06260613          	addi	a2,a2,98 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200d4e:	0d100593          	li	a1,209
ffffffffc0200d52:	00002517          	auipc	a0,0x2
ffffffffc0200d56:	06e50513          	addi	a0,a0,110 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200d5a:	c68ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d5e <test_arena_check>:
test_arena_check(void) {
ffffffffc0200d5e:	7135                	addi	sp,sp,-160
ffffffffc0200d60:	f0da                	sd	s6,96(sp)
    struct Page *base = test_state.base;
ffffffffc0200d62:	00048b17          	auipc	s6,0x48
ffffffffc0200d66:	fb6b3b03          	ld	s6,-74(s6) # ffffffffc0248d18 <test_state>
    size_t index = page_index(base);
ffffffffc0200d6a:	855a                	mv	a0,s6
test_arena_check(void) {
ffffffffc0200d6c:	ed06                	sd	ra,152(sp)
ffffffffc0200d6e:	e922                	sd	s0,144(sp)
ffffffffc0200d70:	e526                	sd	s1,136(sp)
ffffffffc0200d72:	f8d2                	sd	s4,112(sp)
ffffffffc0200d74:	f4d6                	sd	s5,104(sp)
ffffffffc0200d76:	ecde                	sd	s7,88(sp)
ffffffffc0200d78:	e8e2                	sd	s8,80(sp)
ffffffffc0200d7a:	e14a                	sd	s2,128(sp)
ffffffffc0200d7c:	fcce                	sd	s3,120(sp)
ffffffffc0200d7e:	e4e6                	sd	s9,72(sp)
    unsigned char covered[TEST_PAGES] = {0};
ffffffffc0200d80:	e002                	sd	zero,0(sp)
ffffffffc0200d82:	e402                	sd	zero,8(sp)
ffffffffc0200d84:	e802                	sd	zero,16(sp)
ffffffffc0200d86:	ec02                	sd	zero,24(sp)
ffffffffc0200d88:	f002                	sd	zero,32(sp)
ffffffffc0200d8a:	f402                	sd	zero,40(sp)
ffffffffc0200d8c:	f802                	sd	zero,48(sp)
ffffffffc0200d8e:	fc02                	sd	zero,56(sp)
    size_t index = page_index(base);
ffffffffc0200d90:	84bff0ef          	jal	ra,ffffffffc02005da <page_index>
ffffffffc0200d94:	842a                	mv	s0,a0
    check_lists();
ffffffffc0200d96:	00008497          	auipc	s1,0x8
ffffffffc0200d9a:	c8248493          	addi	s1,s1,-894 # ffffffffc0208a18 <free_lists>
ffffffffc0200d9e:	96dff0ef          	jal	ra,ffffffffc020070a <check_lists>
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc0200da2:	4b81                	li	s7,0
    return (size_t)1 << order;
ffffffffc0200da4:	4c05                	li	s8,1
            assert(pos < TEST_PAGES && size <= TEST_PAGES - pos);
ffffffffc0200da6:	03f00a93          	li	s5,63
ffffffffc0200daa:	04040a13          	addi	s4,s0,64
        test_list_count(order);
ffffffffc0200dae:	855e                	mv	a0,s7
ffffffffc0200db0:	f29ff0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0200db4:	0084bc83          	ld	s9,8(s1)
    return (size_t)1 << order;
ffffffffc0200db8:	017c1933          	sll	s2,s8,s7
ffffffffc0200dbc:	012109b3          	add	s3,sp,s2
        while ((le = list_next(le)) != head) {
ffffffffc0200dc0:	029c8e63          	beq	s9,s1,ffffffffc0200dfc <test_arena_check+0x9e>
            size_t pos = page_index(p) - index, size = block_size(order);
ffffffffc0200dc4:	fe8c8513          	addi	a0,s9,-24
ffffffffc0200dc8:	813ff0ef          	jal	ra,ffffffffc02005da <page_index>
ffffffffc0200dcc:	408506b3          	sub	a3,a0,s0
            assert(pos < TEST_PAGES && size <= TEST_PAGES - pos);
ffffffffc0200dd0:	1cdaec63          	bltu	s5,a3,ffffffffc0200fa8 <test_arena_check+0x24a>
ffffffffc0200dd4:	40aa0533          	sub	a0,s4,a0
ffffffffc0200dd8:	1d256863          	bltu	a0,s2,ffffffffc0200fa8 <test_arena_check+0x24a>
ffffffffc0200ddc:	00d107b3          	add	a5,sp,a3
ffffffffc0200de0:	96ce                	add	a3,a3,s3
                assert(covered[pos + i] == 0);
ffffffffc0200de2:	0007c703          	lbu	a4,0(a5)
ffffffffc0200de6:	16071d63          	bnez	a4,ffffffffc0200f60 <test_arena_check+0x202>
                covered[pos + i] = 1;
ffffffffc0200dea:	01878023          	sb	s8,0(a5)
            for (size_t i = 0; i < size; i ++) {
ffffffffc0200dee:	0785                	addi	a5,a5,1
ffffffffc0200df0:	fed799e3          	bne	a5,a3,ffffffffc0200de2 <test_arena_check+0x84>
ffffffffc0200df4:	008cbc83          	ld	s9,8(s9)
        while ((le = list_next(le)) != head) {
ffffffffc0200df8:	fc9c96e3          	bne	s9,s1,ffffffffc0200dc4 <test_arena_check+0x66>
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc0200dfc:	2b85                	addiw	s7,s7,1
ffffffffc0200dfe:	47c1                	li	a5,16
ffffffffc0200e00:	04c1                	addi	s1,s1,16
ffffffffc0200e02:	fafb96e3          	bne	s7,a5,ffffffffc0200dae <test_arena_check+0x50>
ffffffffc0200e06:	00241893          	slli	a7,s0,0x2
ffffffffc0200e0a:	00028f97          	auipc	t6,0x28
ffffffffc0200e0e:	f0ef8f93          	addi	t6,t6,-242 # ffffffffc0228d18 <requested>
ffffffffc0200e12:	00008797          	auipc	a5,0x8
ffffffffc0200e16:	f0678793          	addi	a5,a5,-250 # ffffffffc0208d18 <region>
ffffffffc0200e1a:	9fc6                	add	t6,t6,a7
ffffffffc0200e1c:	98be                	add	a7,a7,a5
ffffffffc0200e1e:	00049917          	auipc	s2,0x49
ffffffffc0200e22:	c3293903          	ld	s2,-974(s2) # ffffffffc0249a50 <pages>
ffffffffc0200e26:	00003497          	auipc	s1,0x3
ffffffffc0200e2a:	3fa4b483          	ld	s1,1018(s1) # ffffffffc0204220 <nbase>
ffffffffc0200e2e:	8f5a                	mv	t5,s6
ffffffffc0200e30:	8e46                	mv	t3,a7
ffffffffc0200e32:	83fe                	mv	t2,t6
ffffffffc0200e34:	04000293          	li	t0,64
        assert(size >= n && (size == 1 || size / 2 < n));
ffffffffc0200e38:	4e85                	li	t4,1
ffffffffc0200e3a:	00003417          	auipc	s0,0x3
ffffffffc0200e3e:	3de43403          	ld	s0,990(s0) # ffffffffc0204218 <error_string+0x38>
        if (requested[index + pos] == 0) {
ffffffffc0200e42:	0003a783          	lw	a5,0(t2)
ffffffffc0200e46:	c3cd                	beqz	a5,ffffffffc0200ee8 <test_arena_check+0x18a>
        size_t size = p->property, n = requested[index + pos];
ffffffffc0200e48:	010f6303          	lwu	t1,16(t5)
ffffffffc0200e4c:	1782                	slli	a5,a5,0x20
ffffffffc0200e4e:	9381                	srli	a5,a5,0x20
        assert(size > 0 && (size & (size - 1)) == 0);
ffffffffc0200e50:	1a030c63          	beqz	t1,ffffffffc0201008 <test_arena_check+0x2aa>
ffffffffc0200e54:	fff30713          	addi	a4,t1,-1
ffffffffc0200e58:	006776b3          	and	a3,a4,t1
ffffffffc0200e5c:	1a069663          	bnez	a3,ffffffffc0201008 <test_arena_check+0x2aa>
        assert(size >= n && (size == 1 || size / 2 < n));
ffffffffc0200e60:	1cf36463          	bltu	t1,a5,ffffffffc0201028 <test_arena_check+0x2ca>
ffffffffc0200e64:	11d30e63          	beq	t1,t4,ffffffffc0200f80 <test_arena_check+0x222>
ffffffffc0200e68:	00135613          	srli	a2,t1,0x1
ffffffffc0200e6c:	1af67e63          	bgeu	a2,a5,ffffffffc0201028 <test_arena_check+0x2ca>
        assert(size <= TEST_PAGES - pos && !PageProperty(p));
ffffffffc0200e70:	1062ec63          	bltu	t0,t1,ffffffffc0200f88 <test_arena_check+0x22a>
ffffffffc0200e74:	008f3783          	ld	a5,8(t5)
ffffffffc0200e78:	8b89                	andi	a5,a5,2
ffffffffc0200e7a:	10079763          	bnez	a5,ffffffffc0200f88 <test_arena_check+0x22a>
ffffffffc0200e7e:	412f07b3          	sub	a5,t5,s2
ffffffffc0200e82:	878d                	srai	a5,a5,0x3
ffffffffc0200e84:	028787b3          	mul	a5,a5,s0
ffffffffc0200e88:	97a6                	add	a5,a5,s1
        assert((page2ppn(p) & (size - 1)) == 0);
ffffffffc0200e8a:	8ff9                	and	a5,a5,a4
ffffffffc0200e8c:	1a079e63          	bnez	a5,ffffffffc0201048 <test_arena_check+0x2ea>
ffffffffc0200e90:	009c                	addi	a5,sp,64
ffffffffc0200e92:	40578633          	sub	a2,a5,t0
ffffffffc0200e96:	85f2                	mv	a1,t3
ffffffffc0200e98:	851e                	mv	a0,t2
ffffffffc0200e9a:	877a                	mv	a4,t5
            assert(covered[pos + i] == 0 && !PageReserved(p + i));
ffffffffc0200e9c:	00064783          	lbu	a5,0(a2)
ffffffffc0200ea0:	14079463          	bnez	a5,ffffffffc0200fe8 <test_arena_check+0x28a>
ffffffffc0200ea4:	671c                	ld	a5,8(a4)
ffffffffc0200ea6:	0017f813          	andi	a6,a5,1
ffffffffc0200eaa:	12081f63          	bnez	a6,ffffffffc0200fe8 <test_arena_check+0x28a>
            assert(!PageProperty(p + i) && page_ref(p + i) == 0);
ffffffffc0200eae:	8b89                	andi	a5,a5,2
ffffffffc0200eb0:	10079c63          	bnez	a5,ffffffffc0200fc8 <test_arena_check+0x26a>
ffffffffc0200eb4:	431c                	lw	a5,0(a4)
ffffffffc0200eb6:	10079963          	bnez	a5,ffffffffc0200fc8 <test_arena_check+0x26a>
            assert(region[index + pos + i] == region[index + pos]);
ffffffffc0200eba:	0005a803          	lw	a6,0(a1) # 8000 <kern_entry-0xffffffffc01f8000>
ffffffffc0200ebe:	000e2783          	lw	a5,0(t3)
ffffffffc0200ec2:	1af81363          	bne	a6,a5,ffffffffc0201068 <test_arena_check+0x30a>
            assert(i == 0 || (requested[index + pos + i] == 0 && p[i].property == 0));
ffffffffc0200ec6:	c699                	beqz	a3,ffffffffc0200ed4 <test_arena_check+0x176>
ffffffffc0200ec8:	411c                	lw	a5,0(a0)
ffffffffc0200eca:	1a079f63          	bnez	a5,ffffffffc0201088 <test_arena_check+0x32a>
ffffffffc0200ece:	4b1c                	lw	a5,16(a4)
ffffffffc0200ed0:	1a079c63          	bnez	a5,ffffffffc0201088 <test_arena_check+0x32a>
            covered[pos + i] = 1;
ffffffffc0200ed4:	01d60023          	sb	t4,0(a2)
        for (size_t i = 0; i < size; i ++) {
ffffffffc0200ed8:	0685                	addi	a3,a3,1
ffffffffc0200eda:	0605                	addi	a2,a2,1
ffffffffc0200edc:	02870713          	addi	a4,a4,40
ffffffffc0200ee0:	0511                	addi	a0,a0,4
ffffffffc0200ee2:	0591                	addi	a1,a1,4
ffffffffc0200ee4:	fad31ce3          	bne	t1,a3,ffffffffc0200e9c <test_arena_check+0x13e>
    for (size_t pos = 0; pos < TEST_PAGES; pos ++) {
ffffffffc0200ee8:	12fd                	addi	t0,t0,-1
ffffffffc0200eea:	0391                	addi	t2,t2,4
ffffffffc0200eec:	0e11                	addi	t3,t3,4
ffffffffc0200eee:	028f0f13          	addi	t5,t5,40
ffffffffc0200ef2:	f40298e3          	bnez	t0,ffffffffc0200e42 <test_arena_check+0xe4>
ffffffffc0200ef6:	0b21                	addi	s6,s6,8
ffffffffc0200ef8:	878a                	mv	a5,sp
            assert(!PageReserved(base + i) && covered[i] == 1);
ffffffffc0200efa:	4685                	li	a3,1
ffffffffc0200efc:	a03d                	j	ffffffffc0200f2a <test_arena_check+0x1cc>
            assert(PageReserved(base + i) && covered[i] == 0);
ffffffffc0200efe:	1e070263          	beqz	a4,ffffffffc02010e2 <test_arena_check+0x384>
ffffffffc0200f02:	0007c703          	lbu	a4,0(a5)
ffffffffc0200f06:	1c071e63          	bnez	a4,ffffffffc02010e2 <test_arena_check+0x384>
            assert(base[i].property == 0 && requested[index + i] == 0);
ffffffffc0200f0a:	008b2703          	lw	a4,8(s6)
ffffffffc0200f0e:	1a071a63          	bnez	a4,ffffffffc02010c2 <test_arena_check+0x364>
ffffffffc0200f12:	000fa703          	lw	a4,0(t6)
ffffffffc0200f16:	1a071663          	bnez	a4,ffffffffc02010c2 <test_arena_check+0x364>
    for (size_t i = 0; i < TEST_PAGES; i ++) {
ffffffffc0200f1a:	0785                	addi	a5,a5,1
ffffffffc0200f1c:	0098                	addi	a4,sp,64
ffffffffc0200f1e:	0891                	addi	a7,a7,4
ffffffffc0200f20:	028b0b13          	addi	s6,s6,40
ffffffffc0200f24:	0f91                	addi	t6,t6,4
ffffffffc0200f26:	18f70163          	beq	a4,a5,ffffffffc02010a8 <test_arena_check+0x34a>
            assert(PageReserved(base + i) && covered[i] == 0);
ffffffffc0200f2a:	000b3703          	ld	a4,0(s6)
        if (region[index + i] == 0) {
ffffffffc0200f2e:	0008a603          	lw	a2,0(a7)
            assert(PageReserved(base + i) && covered[i] == 0);
ffffffffc0200f32:	8b05                	andi	a4,a4,1
        if (region[index + i] == 0) {
ffffffffc0200f34:	d669                	beqz	a2,ffffffffc0200efe <test_arena_check+0x1a0>
            assert(!PageReserved(base + i) && covered[i] == 1);
ffffffffc0200f36:	e709                	bnez	a4,ffffffffc0200f40 <test_arena_check+0x1e2>
ffffffffc0200f38:	0007c703          	lbu	a4,0(a5)
ffffffffc0200f3c:	fcd70fe3          	beq	a4,a3,ffffffffc0200f1a <test_arena_check+0x1bc>
ffffffffc0200f40:	00002697          	auipc	a3,0x2
ffffffffc0200f44:	3f868693          	addi	a3,a3,1016 # ffffffffc0203338 <etext+0x82e>
ffffffffc0200f48:	00002617          	auipc	a2,0x2
ffffffffc0200f4c:	e6060613          	addi	a2,a2,-416 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200f50:	10200593          	li	a1,258
ffffffffc0200f54:	00002517          	auipc	a0,0x2
ffffffffc0200f58:	e6c50513          	addi	a0,a0,-404 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200f5c:	a66ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(covered[pos + i] == 0);
ffffffffc0200f60:	00002697          	auipc	a3,0x2
ffffffffc0200f64:	1d868693          	addi	a3,a3,472 # ffffffffc0203138 <etext+0x62e>
ffffffffc0200f68:	00002617          	auipc	a2,0x2
ffffffffc0200f6c:	e4060613          	addi	a2,a2,-448 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200f70:	0e600593          	li	a1,230
ffffffffc0200f74:	00002517          	auipc	a0,0x2
ffffffffc0200f78:	e4c50513          	addi	a0,a0,-436 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200f7c:	a46ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(size <= TEST_PAGES - pos && !PageProperty(p));
ffffffffc0200f80:	008f3783          	ld	a5,8(t5)
ffffffffc0200f84:	8b89                	andi	a5,a5,2
ffffffffc0200f86:	d789                	beqz	a5,ffffffffc0200e90 <test_arena_check+0x132>
ffffffffc0200f88:	00002697          	auipc	a3,0x2
ffffffffc0200f8c:	22068693          	addi	a3,a3,544 # ffffffffc02031a8 <etext+0x69e>
ffffffffc0200f90:	00002617          	auipc	a2,0x2
ffffffffc0200f94:	e1860613          	addi	a2,a2,-488 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200f98:	0f300593          	li	a1,243
ffffffffc0200f9c:	00002517          	auipc	a0,0x2
ffffffffc0200fa0:	e2450513          	addi	a0,a0,-476 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200fa4:	a1eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(pos < TEST_PAGES && size <= TEST_PAGES - pos);
ffffffffc0200fa8:	00002697          	auipc	a3,0x2
ffffffffc0200fac:	16068693          	addi	a3,a3,352 # ffffffffc0203108 <etext+0x5fe>
ffffffffc0200fb0:	00002617          	auipc	a2,0x2
ffffffffc0200fb4:	df860613          	addi	a2,a2,-520 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200fb8:	0e400593          	li	a1,228
ffffffffc0200fbc:	00002517          	auipc	a0,0x2
ffffffffc0200fc0:	e0450513          	addi	a0,a0,-508 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200fc4:	9feff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(!PageProperty(p + i) && page_ref(p + i) == 0);
ffffffffc0200fc8:	00002697          	auipc	a3,0x2
ffffffffc0200fcc:	26068693          	addi	a3,a3,608 # ffffffffc0203228 <etext+0x71e>
ffffffffc0200fd0:	00002617          	auipc	a2,0x2
ffffffffc0200fd4:	dd860613          	addi	a2,a2,-552 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200fd8:	0f700593          	li	a1,247
ffffffffc0200fdc:	00002517          	auipc	a0,0x2
ffffffffc0200fe0:	de450513          	addi	a0,a0,-540 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0200fe4:	9deff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(covered[pos + i] == 0 && !PageReserved(p + i));
ffffffffc0200fe8:	00002697          	auipc	a3,0x2
ffffffffc0200fec:	21068693          	addi	a3,a3,528 # ffffffffc02031f8 <etext+0x6ee>
ffffffffc0200ff0:	00002617          	auipc	a2,0x2
ffffffffc0200ff4:	db860613          	addi	a2,a2,-584 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0200ff8:	0f600593          	li	a1,246
ffffffffc0200ffc:	00002517          	auipc	a0,0x2
ffffffffc0201000:	dc450513          	addi	a0,a0,-572 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201004:	9beff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(size > 0 && (size & (size - 1)) == 0);
ffffffffc0201008:	00002697          	auipc	a3,0x2
ffffffffc020100c:	14868693          	addi	a3,a3,328 # ffffffffc0203150 <etext+0x646>
ffffffffc0201010:	00002617          	auipc	a2,0x2
ffffffffc0201014:	d9860613          	addi	a2,a2,-616 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201018:	0f100593          	li	a1,241
ffffffffc020101c:	00002517          	auipc	a0,0x2
ffffffffc0201020:	da450513          	addi	a0,a0,-604 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201024:	99eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(size >= n && (size == 1 || size / 2 < n));
ffffffffc0201028:	00002697          	auipc	a3,0x2
ffffffffc020102c:	15068693          	addi	a3,a3,336 # ffffffffc0203178 <etext+0x66e>
ffffffffc0201030:	00002617          	auipc	a2,0x2
ffffffffc0201034:	d7860613          	addi	a2,a2,-648 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201038:	0f200593          	li	a1,242
ffffffffc020103c:	00002517          	auipc	a0,0x2
ffffffffc0201040:	d8450513          	addi	a0,a0,-636 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201044:	97eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert((page2ppn(p) & (size - 1)) == 0);
ffffffffc0201048:	00002697          	auipc	a3,0x2
ffffffffc020104c:	19068693          	addi	a3,a3,400 # ffffffffc02031d8 <etext+0x6ce>
ffffffffc0201050:	00002617          	auipc	a2,0x2
ffffffffc0201054:	d5860613          	addi	a2,a2,-680 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201058:	0f400593          	li	a1,244
ffffffffc020105c:	00002517          	auipc	a0,0x2
ffffffffc0201060:	d6450513          	addi	a0,a0,-668 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201064:	95eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(region[index + pos + i] == region[index + pos]);
ffffffffc0201068:	00002697          	auipc	a3,0x2
ffffffffc020106c:	1f068693          	addi	a3,a3,496 # ffffffffc0203258 <etext+0x74e>
ffffffffc0201070:	00002617          	auipc	a2,0x2
ffffffffc0201074:	d3860613          	addi	a2,a2,-712 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201078:	0f800593          	li	a1,248
ffffffffc020107c:	00002517          	auipc	a0,0x2
ffffffffc0201080:	d4450513          	addi	a0,a0,-700 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201084:	93eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(i == 0 || (requested[index + pos + i] == 0 && p[i].property == 0));
ffffffffc0201088:	00002697          	auipc	a3,0x2
ffffffffc020108c:	20068693          	addi	a3,a3,512 # ffffffffc0203288 <etext+0x77e>
ffffffffc0201090:	00002617          	auipc	a2,0x2
ffffffffc0201094:	d1860613          	addi	a2,a2,-744 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201098:	0f900593          	li	a1,249
ffffffffc020109c:	00002517          	auipc	a0,0x2
ffffffffc02010a0:	d2450513          	addi	a0,a0,-732 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02010a4:	91eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
}
ffffffffc02010a8:	60ea                	ld	ra,152(sp)
ffffffffc02010aa:	644a                	ld	s0,144(sp)
ffffffffc02010ac:	64aa                	ld	s1,136(sp)
ffffffffc02010ae:	690a                	ld	s2,128(sp)
ffffffffc02010b0:	79e6                	ld	s3,120(sp)
ffffffffc02010b2:	7a46                	ld	s4,112(sp)
ffffffffc02010b4:	7aa6                	ld	s5,104(sp)
ffffffffc02010b6:	7b06                	ld	s6,96(sp)
ffffffffc02010b8:	6be6                	ld	s7,88(sp)
ffffffffc02010ba:	6c46                	ld	s8,80(sp)
ffffffffc02010bc:	6ca6                	ld	s9,72(sp)
ffffffffc02010be:	610d                	addi	sp,sp,160
ffffffffc02010c0:	8082                	ret
            assert(base[i].property == 0 && requested[index + i] == 0);
ffffffffc02010c2:	00002697          	auipc	a3,0x2
ffffffffc02010c6:	23e68693          	addi	a3,a3,574 # ffffffffc0203300 <etext+0x7f6>
ffffffffc02010ca:	00002617          	auipc	a2,0x2
ffffffffc02010ce:	cde60613          	addi	a2,a2,-802 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02010d2:	10000593          	li	a1,256
ffffffffc02010d6:	00002517          	auipc	a0,0x2
ffffffffc02010da:	cea50513          	addi	a0,a0,-790 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02010de:	8e4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(PageReserved(base + i) && covered[i] == 0);
ffffffffc02010e2:	00002697          	auipc	a3,0x2
ffffffffc02010e6:	1ee68693          	addi	a3,a3,494 # ffffffffc02032d0 <etext+0x7c6>
ffffffffc02010ea:	00002617          	auipc	a2,0x2
ffffffffc02010ee:	cbe60613          	addi	a2,a2,-834 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02010f2:	0ff00593          	li	a1,255
ffffffffc02010f6:	00002517          	auipc	a0,0x2
ffffffffc02010fa:	cca50513          	addi	a0,a0,-822 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02010fe:	8c4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201102 <test_failed_alloc>:
    assert(base->property == block_size(order) && PageProperty(base));
}

/* Allocation failure must leave descriptors, metadata, heads and count intact. */
static void
test_failed_alloc(size_t n) {
ffffffffc0201102:	7129                	addi	sp,sp,-320
ffffffffc0201104:	e656                	sd	s5,264(sp)
    static struct Page before[TEST_PAGES];
    static unsigned int old_region[TEST_PAGES], old_request[TEST_PAGES];
    list_entry_t heads[BUDDY_MAX_ORDER + 1];
    size_t count = nr_free_pages(), index = page_index(test_state.base);
ffffffffc0201106:	00048a97          	auipc	s5,0x48
ffffffffc020110a:	c12a8a93          	addi	s5,s5,-1006 # ffffffffc0248d18 <test_state>
test_failed_alloc(size_t n) {
ffffffffc020110e:	fe06                	sd	ra,312(sp)
ffffffffc0201110:	fa22                	sd	s0,304(sp)
ffffffffc0201112:	f626                	sd	s1,296(sp)
ffffffffc0201114:	f24a                	sd	s2,288(sp)
ffffffffc0201116:	ee4e                	sd	s3,280(sp)
ffffffffc0201118:	ea52                	sd	s4,272(sp)
ffffffffc020111a:	892a                	mv	s2,a0
    size_t count = nr_free_pages(), index = page_index(test_state.base);
ffffffffc020111c:	2b8010ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc0201120:	000ab483          	ld	s1,0(s5)
ffffffffc0201124:	89aa                	mv	s3,a0
    memcpy(before, test_state.base, sizeof(before));
ffffffffc0201126:	6a05                	lui	s4,0x1
    size_t count = nr_free_pages(), index = page_index(test_state.base);
ffffffffc0201128:	8526                	mv	a0,s1
ffffffffc020112a:	cb0ff0ef          	jal	ra,ffffffffc02005da <page_index>
ffffffffc020112e:	842a                	mv	s0,a0
    memcpy(before, test_state.base, sizeof(before));
ffffffffc0201130:	85a6                	mv	a1,s1
ffffffffc0201132:	a00a0613          	addi	a2,s4,-1536 # a00 <kern_entry-0xffffffffc01ff600>
    memcpy(old_region, region + index, sizeof(old_region));
ffffffffc0201136:	040a                	slli	s0,s0,0x2
    memcpy(before, test_state.base, sizeof(before));
ffffffffc0201138:	00007517          	auipc	a0,0x7
ffffffffc020113c:	ee050513          	addi	a0,a0,-288 # ffffffffc0208018 <before.2>
    memcpy(old_region, region + index, sizeof(old_region));
ffffffffc0201140:	00008497          	auipc	s1,0x8
ffffffffc0201144:	bd848493          	addi	s1,s1,-1064 # ffffffffc0208d18 <region>
    memcpy(before, test_state.base, sizeof(before));
ffffffffc0201148:	187010ef          	jal	ra,ffffffffc0202ace <memcpy>
    memcpy(old_region, region + index, sizeof(old_region));
ffffffffc020114c:	94a2                	add	s1,s1,s0
ffffffffc020114e:	10000613          	li	a2,256
ffffffffc0201152:	85a6                	mv	a1,s1
ffffffffc0201154:	00008517          	auipc	a0,0x8
ffffffffc0201158:	9c450513          	addi	a0,a0,-1596 # ffffffffc0208b18 <old_region.1>
ffffffffc020115c:	173010ef          	jal	ra,ffffffffc0202ace <memcpy>
    memcpy(old_request, requested + index, sizeof(old_request));
ffffffffc0201160:	00028517          	auipc	a0,0x28
ffffffffc0201164:	bb850513          	addi	a0,a0,-1096 # ffffffffc0228d18 <requested>
ffffffffc0201168:	942a                	add	s0,s0,a0
ffffffffc020116a:	10000613          	li	a2,256
ffffffffc020116e:	85a2                	mv	a1,s0
ffffffffc0201170:	00008517          	auipc	a0,0x8
ffffffffc0201174:	aa850513          	addi	a0,a0,-1368 # ffffffffc0208c18 <old_request.0>
ffffffffc0201178:	157010ef          	jal	ra,ffffffffc0202ace <memcpy>
    memcpy(heads, free_lists, sizeof(heads));
ffffffffc020117c:	10000613          	li	a2,256
ffffffffc0201180:	00008597          	auipc	a1,0x8
ffffffffc0201184:	89858593          	addi	a1,a1,-1896 # ffffffffc0208a18 <free_lists>
ffffffffc0201188:	850a                	mv	a0,sp
ffffffffc020118a:	145010ef          	jal	ra,ffffffffc0202ace <memcpy>
    assert(alloc_pages(n) == NULL);
ffffffffc020118e:	854a                	mv	a0,s2
ffffffffc0201190:	22c010ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc0201194:	e92d                	bnez	a0,ffffffffc0201206 <test_failed_alloc+0x104>
    assert(nr_free_pages() == count);
ffffffffc0201196:	23e010ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc020119a:	11351663          	bne	a0,s3,ffffffffc02012a6 <test_failed_alloc+0x1a4>
    assert(memcmp(before, test_state.base, sizeof(before)) == 0);
ffffffffc020119e:	000ab583          	ld	a1,0(s5)
ffffffffc02011a2:	a00a0613          	addi	a2,s4,-1536
ffffffffc02011a6:	00007517          	auipc	a0,0x7
ffffffffc02011aa:	e7250513          	addi	a0,a0,-398 # ffffffffc0208018 <before.2>
ffffffffc02011ae:	139010ef          	jal	ra,ffffffffc0202ae6 <memcmp>
ffffffffc02011b2:	e971                	bnez	a0,ffffffffc0201286 <test_failed_alloc+0x184>
    assert(memcmp(old_region, region + index, sizeof(old_region)) == 0);
ffffffffc02011b4:	10000613          	li	a2,256
ffffffffc02011b8:	85a6                	mv	a1,s1
ffffffffc02011ba:	00008517          	auipc	a0,0x8
ffffffffc02011be:	95e50513          	addi	a0,a0,-1698 # ffffffffc0208b18 <old_region.1>
ffffffffc02011c2:	125010ef          	jal	ra,ffffffffc0202ae6 <memcmp>
ffffffffc02011c6:	e145                	bnez	a0,ffffffffc0201266 <test_failed_alloc+0x164>
    assert(memcmp(old_request, requested + index, sizeof(old_request)) == 0);
ffffffffc02011c8:	10000613          	li	a2,256
ffffffffc02011cc:	85a2                	mv	a1,s0
ffffffffc02011ce:	00008517          	auipc	a0,0x8
ffffffffc02011d2:	a4a50513          	addi	a0,a0,-1462 # ffffffffc0208c18 <old_request.0>
ffffffffc02011d6:	111010ef          	jal	ra,ffffffffc0202ae6 <memcmp>
ffffffffc02011da:	e535                	bnez	a0,ffffffffc0201246 <test_failed_alloc+0x144>
    assert(memcmp(heads, free_lists, sizeof(heads)) == 0);
ffffffffc02011dc:	10000613          	li	a2,256
ffffffffc02011e0:	00008597          	auipc	a1,0x8
ffffffffc02011e4:	83858593          	addi	a1,a1,-1992 # ffffffffc0208a18 <free_lists>
ffffffffc02011e8:	850a                	mv	a0,sp
ffffffffc02011ea:	0fd010ef          	jal	ra,ffffffffc0202ae6 <memcmp>
ffffffffc02011ee:	ed05                	bnez	a0,ffffffffc0201226 <test_failed_alloc+0x124>
    test_arena_check();
ffffffffc02011f0:	b6fff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
}
ffffffffc02011f4:	70f2                	ld	ra,312(sp)
ffffffffc02011f6:	7452                	ld	s0,304(sp)
ffffffffc02011f8:	74b2                	ld	s1,296(sp)
ffffffffc02011fa:	7912                	ld	s2,288(sp)
ffffffffc02011fc:	69f2                	ld	s3,280(sp)
ffffffffc02011fe:	6a52                	ld	s4,272(sp)
ffffffffc0201200:	6ab2                	ld	s5,264(sp)
ffffffffc0201202:	6131                	addi	sp,sp,320
ffffffffc0201204:	8082                	ret
    assert(alloc_pages(n) == NULL);
ffffffffc0201206:	00002697          	auipc	a3,0x2
ffffffffc020120a:	16268693          	addi	a3,a3,354 # ffffffffc0203368 <etext+0x85e>
ffffffffc020120e:	00002617          	auipc	a2,0x2
ffffffffc0201212:	b9a60613          	addi	a2,a2,-1126 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201216:	13000593          	li	a1,304
ffffffffc020121a:	00002517          	auipc	a0,0x2
ffffffffc020121e:	ba650513          	addi	a0,a0,-1114 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201222:	fa1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(memcmp(heads, free_lists, sizeof(heads)) == 0);
ffffffffc0201226:	00002697          	auipc	a3,0x2
ffffffffc020122a:	23a68693          	addi	a3,a3,570 # ffffffffc0203460 <etext+0x956>
ffffffffc020122e:	00002617          	auipc	a2,0x2
ffffffffc0201232:	b7a60613          	addi	a2,a2,-1158 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201236:	13500593          	li	a1,309
ffffffffc020123a:	00002517          	auipc	a0,0x2
ffffffffc020123e:	b8650513          	addi	a0,a0,-1146 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201242:	f81fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(memcmp(old_request, requested + index, sizeof(old_request)) == 0);
ffffffffc0201246:	00002697          	auipc	a3,0x2
ffffffffc020124a:	1d268693          	addi	a3,a3,466 # ffffffffc0203418 <etext+0x90e>
ffffffffc020124e:	00002617          	auipc	a2,0x2
ffffffffc0201252:	b5a60613          	addi	a2,a2,-1190 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201256:	13400593          	li	a1,308
ffffffffc020125a:	00002517          	auipc	a0,0x2
ffffffffc020125e:	b6650513          	addi	a0,a0,-1178 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201262:	f61fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(memcmp(old_region, region + index, sizeof(old_region)) == 0);
ffffffffc0201266:	00002697          	auipc	a3,0x2
ffffffffc020126a:	17268693          	addi	a3,a3,370 # ffffffffc02033d8 <etext+0x8ce>
ffffffffc020126e:	00002617          	auipc	a2,0x2
ffffffffc0201272:	b3a60613          	addi	a2,a2,-1222 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201276:	13300593          	li	a1,307
ffffffffc020127a:	00002517          	auipc	a0,0x2
ffffffffc020127e:	b4650513          	addi	a0,a0,-1210 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201282:	f41fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(memcmp(before, test_state.base, sizeof(before)) == 0);
ffffffffc0201286:	00002697          	auipc	a3,0x2
ffffffffc020128a:	11a68693          	addi	a3,a3,282 # ffffffffc02033a0 <etext+0x896>
ffffffffc020128e:	00002617          	auipc	a2,0x2
ffffffffc0201292:	b1a60613          	addi	a2,a2,-1254 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201296:	13200593          	li	a1,306
ffffffffc020129a:	00002517          	auipc	a0,0x2
ffffffffc020129e:	b2650513          	addi	a0,a0,-1242 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02012a2:	f21fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == count);
ffffffffc02012a6:	00002697          	auipc	a3,0x2
ffffffffc02012aa:	0da68693          	addi	a3,a3,218 # ffffffffc0203380 <etext+0x876>
ffffffffc02012ae:	00002617          	auipc	a2,0x2
ffffffffc02012b2:	afa60613          	addi	a2,a2,-1286 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02012b6:	13100593          	li	a1,305
ffffffffc02012ba:	00002517          	auipc	a0,0x2
ffffffffc02012be:	b0650513          	addi	a0,a0,-1274 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02012c2:	f01fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02012c6 <test_single_block>:
test_single_block(unsigned int order, struct Page *base) {
ffffffffc02012c6:	7179                	addi	sp,sp,-48
ffffffffc02012c8:	f406                	sd	ra,40(sp)
ffffffffc02012ca:	f022                	sd	s0,32(sp)
ffffffffc02012cc:	ec26                	sd	s1,24(sp)
ffffffffc02012ce:	e84a                	sd	s2,16(sp)
ffffffffc02012d0:	84aa                	mv	s1,a0
ffffffffc02012d2:	e44e                	sd	s3,8(sp)
ffffffffc02012d4:	e052                	sd	s4,0(sp)
ffffffffc02012d6:	89ae                	mv	s3,a1
    return (size_t)1 << order;
ffffffffc02012d8:	4a05                	li	s4,1
    test_arena_check();
ffffffffc02012da:	a85ff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    assert(nr_free_pages() == block_size(order));
ffffffffc02012de:	0f6010ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
    return (size_t)1 << order;
ffffffffc02012e2:	009a1a33          	sll	s4,s4,s1
ffffffffc02012e6:	4401                	li	s0,0
ffffffffc02012e8:	4941                	li	s2,16
    assert(nr_free_pages() == block_size(order));
ffffffffc02012ea:	07451b63          	bne	a0,s4,ffffffffc0201360 <test_single_block+0x9a>
        assert(test_list_count(i) == (i == order ? 1 : 0));
ffffffffc02012ee:	8522                	mv	a0,s0
ffffffffc02012f0:	9e9ff0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc02012f4:	408487b3          	sub	a5,s1,s0
ffffffffc02012f8:	0017b793          	seqz	a5,a5
ffffffffc02012fc:	04f51263          	bne	a0,a5,ffffffffc0201340 <test_single_block+0x7a>
    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i ++) {
ffffffffc0201300:	2405                	addiw	s0,s0,1
ffffffffc0201302:	ff2416e3          	bne	s0,s2,ffffffffc02012ee <test_single_block+0x28>
ffffffffc0201306:	02049793          	slli	a5,s1,0x20
ffffffffc020130a:	01c7d493          	srli	s1,a5,0x1c
ffffffffc020130e:	00007797          	auipc	a5,0x7
ffffffffc0201312:	70a78793          	addi	a5,a5,1802 # ffffffffc0208a18 <free_lists>
ffffffffc0201316:	94be                	add	s1,s1,a5
    assert(le2page(list_next(&free_lists[order]), page_link) == base);
ffffffffc0201318:	649c                	ld	a5,8(s1)
ffffffffc020131a:	17a1                	addi	a5,a5,-24
ffffffffc020131c:	08f99263          	bne	s3,a5,ffffffffc02013a0 <test_single_block+0xda>
    assert(base->property == block_size(order) && PageProperty(base));
ffffffffc0201320:	0109e783          	lwu	a5,16(s3)
ffffffffc0201324:	05479e63          	bne	a5,s4,ffffffffc0201380 <test_single_block+0xba>
ffffffffc0201328:	0089b783          	ld	a5,8(s3)
ffffffffc020132c:	8b89                	andi	a5,a5,2
ffffffffc020132e:	cba9                	beqz	a5,ffffffffc0201380 <test_single_block+0xba>
}
ffffffffc0201330:	70a2                	ld	ra,40(sp)
ffffffffc0201332:	7402                	ld	s0,32(sp)
ffffffffc0201334:	64e2                	ld	s1,24(sp)
ffffffffc0201336:	6942                	ld	s2,16(sp)
ffffffffc0201338:	69a2                	ld	s3,8(sp)
ffffffffc020133a:	6a02                	ld	s4,0(sp)
ffffffffc020133c:	6145                	addi	sp,sp,48
ffffffffc020133e:	8082                	ret
        assert(test_list_count(i) == (i == order ? 1 : 0));
ffffffffc0201340:	00002697          	auipc	a3,0x2
ffffffffc0201344:	17868693          	addi	a3,a3,376 # ffffffffc02034b8 <etext+0x9ae>
ffffffffc0201348:	00002617          	auipc	a2,0x2
ffffffffc020134c:	a6060613          	addi	a2,a2,-1440 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201350:	11f00593          	li	a1,287
ffffffffc0201354:	00002517          	auipc	a0,0x2
ffffffffc0201358:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc020135c:	e67fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == block_size(order));
ffffffffc0201360:	00002697          	auipc	a3,0x2
ffffffffc0201364:	13068693          	addi	a3,a3,304 # ffffffffc0203490 <etext+0x986>
ffffffffc0201368:	00002617          	auipc	a2,0x2
ffffffffc020136c:	a4060613          	addi	a2,a2,-1472 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201370:	11d00593          	li	a1,285
ffffffffc0201374:	00002517          	auipc	a0,0x2
ffffffffc0201378:	a4c50513          	addi	a0,a0,-1460 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc020137c:	e47fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(base->property == block_size(order) && PageProperty(base));
ffffffffc0201380:	00002697          	auipc	a3,0x2
ffffffffc0201384:	1a868693          	addi	a3,a3,424 # ffffffffc0203528 <etext+0xa1e>
ffffffffc0201388:	00002617          	auipc	a2,0x2
ffffffffc020138c:	a2060613          	addi	a2,a2,-1504 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201390:	12200593          	li	a1,290
ffffffffc0201394:	00002517          	auipc	a0,0x2
ffffffffc0201398:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc020139c:	e27fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(le2page(list_next(&free_lists[order]), page_link) == base);
ffffffffc02013a0:	00002697          	auipc	a3,0x2
ffffffffc02013a4:	14868693          	addi	a3,a3,328 # ffffffffc02034e8 <etext+0x9de>
ffffffffc02013a8:	00002617          	auipc	a2,0x2
ffffffffc02013ac:	a0060613          	addi	a2,a2,-1536 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02013b0:	12100593          	li	a1,289
ffffffffc02013b4:	00002517          	auipc	a0,0x2
ffffffffc02013b8:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02013bc:	e07fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02013c0 <buddy_alloc_pages>:
buddy_alloc_pages(size_t n) {
ffffffffc02013c0:	7179                	addi	sp,sp,-48
ffffffffc02013c2:	f406                	sd	ra,40(sp)
ffffffffc02013c4:	f022                	sd	s0,32(sp)
ffffffffc02013c6:	ec26                	sd	s1,24(sp)
ffffffffc02013c8:	e84a                	sd	s2,16(sp)
ffffffffc02013ca:	e44e                	sd	s3,8(sp)
ffffffffc02013cc:	e052                	sd	s4,0(sp)
    assert(n > 0);
ffffffffc02013ce:	10050163          	beqz	a0,ffffffffc02014d0 <buddy_alloc_pages+0x110>
    if (n > nr_free || n > block_size(BUDDY_MAX_ORDER)) {
ffffffffc02013d2:	00048997          	auipc	s3,0x48
ffffffffc02013d6:	66e98993          	addi	s3,s3,1646 # ffffffffc0249a40 <nr_free>
ffffffffc02013da:	0009ba03          	ld	s4,0(s3)
ffffffffc02013de:	842a                	mv	s0,a0
ffffffffc02013e0:	04aa6263          	bltu	s4,a0,ffffffffc0201424 <buddy_alloc_pages+0x64>
ffffffffc02013e4:	67a1                	lui	a5,0x8
ffffffffc02013e6:	02a7ef63          	bltu	a5,a0,ffffffffc0201424 <buddy_alloc_pages+0x64>
    unsigned int order = 0;
ffffffffc02013ea:	4681                	li	a3,0
    return (size_t)1 << order;
ffffffffc02013ec:	4705                	li	a4,1
    while (order < BUDDY_MAX_ORDER && block_size(order) < n) {
ffffffffc02013ee:	463d                	li	a2,15
    return (size_t)1 << order;
ffffffffc02013f0:	00d717b3          	sll	a5,a4,a3
    while (order < BUDDY_MAX_ORDER && block_size(order) < n) {
ffffffffc02013f4:	0087f563          	bgeu	a5,s0,ffffffffc02013fe <buddy_alloc_pages+0x3e>
        order ++;
ffffffffc02013f8:	2685                	addiw	a3,a3,1
    while (order < BUDDY_MAX_ORDER && block_size(order) < n) {
ffffffffc02013fa:	fec69be3          	bne	a3,a2,ffffffffc02013f0 <buddy_alloc_pages+0x30>
    while (order <= BUDDY_MAX_ORDER && list_empty(&free_lists[order])) {
ffffffffc02013fe:	02069793          	slli	a5,a3,0x20
ffffffffc0201402:	01c7d713          	srli	a4,a5,0x1c
ffffffffc0201406:	00007617          	auipc	a2,0x7
ffffffffc020140a:	61260613          	addi	a2,a2,1554 # ffffffffc0208a18 <free_lists>
ffffffffc020140e:	9732                	add	a4,a4,a2
    unsigned int order = 0;
ffffffffc0201410:	87b6                	mv	a5,a3
    while (order <= BUDDY_MAX_ORDER && list_empty(&free_lists[order])) {
ffffffffc0201412:	45c1                	li	a1,16
    return list->next == list;
ffffffffc0201414:	00873803          	ld	a6,8(a4)
ffffffffc0201418:	02e81063          	bne	a6,a4,ffffffffc0201438 <buddy_alloc_pages+0x78>
        order ++;
ffffffffc020141c:	2785                	addiw	a5,a5,1
    while (order <= BUDDY_MAX_ORDER && list_empty(&free_lists[order])) {
ffffffffc020141e:	0741                	addi	a4,a4,16
ffffffffc0201420:	feb79ae3          	bne	a5,a1,ffffffffc0201414 <buddy_alloc_pages+0x54>
        return NULL;
ffffffffc0201424:	4481                	li	s1,0
}
ffffffffc0201426:	70a2                	ld	ra,40(sp)
ffffffffc0201428:	7402                	ld	s0,32(sp)
ffffffffc020142a:	6942                	ld	s2,16(sp)
ffffffffc020142c:	69a2                	ld	s3,8(sp)
ffffffffc020142e:	6a02                	ld	s4,0(sp)
ffffffffc0201430:	8526                	mv	a0,s1
ffffffffc0201432:	64e2                	ld	s1,24(sp)
ffffffffc0201434:	6145                	addi	sp,sp,48
ffffffffc0201436:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0201438:	00083503          	ld	a0,0(a6)
ffffffffc020143c:	00883583          	ld	a1,8(a6)
    ClearPageProperty(page);
ffffffffc0201440:	ff083703          	ld	a4,-16(a6)
    struct Page *page = le2page(list_next(&free_lists[order]), page_link);
ffffffffc0201444:	fe880493          	addi	s1,a6,-24
    prev->next = next;
ffffffffc0201448:	e50c                	sd	a1,8(a0)
    next->prev = prev;
ffffffffc020144a:	e188                	sd	a0,0(a1)
    ClearPageProperty(page);
ffffffffc020144c:	9b75                	andi	a4,a4,-3
    elm->prev = elm->next = elm;
ffffffffc020144e:	01083423          	sd	a6,8(a6)
ffffffffc0201452:	01083023          	sd	a6,0(a6)
ffffffffc0201456:	fee83823          	sd	a4,-16(a6)
    page->property = 0;
ffffffffc020145a:	fe082c23          	sw	zero,-8(a6)
    while (order > wanted) {
ffffffffc020145e:	04f6f463          	bgeu	a3,a5,ffffffffc02014a6 <buddy_alloc_pages+0xe6>
ffffffffc0201462:	37fd                	addiw	a5,a5,-1
ffffffffc0201464:	02079593          	slli	a1,a5,0x20
ffffffffc0201468:	01c5d713          	srli	a4,a1,0x1c
ffffffffc020146c:	963a                	add	a2,a2,a4
        add_block(page + block_size(order), order);
ffffffffc020146e:	02800e13          	li	t3,40
    return (size_t)1 << order;
ffffffffc0201472:	4305                	li	t1,1
ffffffffc0201474:	a011                	j	ffffffffc0201478 <buddy_alloc_pages+0xb8>
ffffffffc0201476:	37fd                	addiw	a5,a5,-1
        add_block(page + block_size(order), order);
ffffffffc0201478:	00fe1733          	sll	a4,t3,a5
ffffffffc020147c:	9726                	add	a4,a4,s1
    SetPageProperty(page);
ffffffffc020147e:	670c                	ld	a1,8(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201480:	00863883          	ld	a7,8(a2)
    return (size_t)1 << order;
ffffffffc0201484:	00f31533          	sll	a0,t1,a5
    SetPageProperty(page);
ffffffffc0201488:	0025e593          	ori	a1,a1,2
ffffffffc020148c:	e70c                	sd	a1,8(a4)
    page->property = block_size(order);
ffffffffc020148e:	cb08                	sw	a0,16(a4)
    list_add(&free_lists[order], &page->page_link);
ffffffffc0201490:	01870593          	addi	a1,a4,24
    prev->next = next->prev = elm;
ffffffffc0201494:	00b8b023          	sd	a1,0(a7)
ffffffffc0201498:	e60c                	sd	a1,8(a2)
    elm->prev = prev;
ffffffffc020149a:	ef10                	sd	a2,24(a4)
    elm->next = next;
ffffffffc020149c:	03173023          	sd	a7,32(a4)
    while (order > wanted) {
ffffffffc02014a0:	1641                	addi	a2,a2,-16
ffffffffc02014a2:	fcd79ae3          	bne	a5,a3,ffffffffc0201476 <buddy_alloc_pages+0xb6>
    return (size_t)1 << order;
ffffffffc02014a6:	4905                	li	s2,1
ffffffffc02014a8:	00d91933          	sll	s2,s2,a3
    page->property = block_size(wanted);
ffffffffc02014ac:	ff282c23          	sw	s2,-8(a6)
    requested[page_index(page)] = n;
ffffffffc02014b0:	8526                	mv	a0,s1
ffffffffc02014b2:	928ff0ef          	jal	ra,ffffffffc02005da <page_index>
ffffffffc02014b6:	00251793          	slli	a5,a0,0x2
ffffffffc02014ba:	00028517          	auipc	a0,0x28
ffffffffc02014be:	85e50513          	addi	a0,a0,-1954 # ffffffffc0228d18 <requested>
ffffffffc02014c2:	953e                	add	a0,a0,a5
    nr_free -= block_size(wanted);
ffffffffc02014c4:	412a06b3          	sub	a3,s4,s2
    requested[page_index(page)] = n;
ffffffffc02014c8:	c100                	sw	s0,0(a0)
    nr_free -= block_size(wanted);
ffffffffc02014ca:	00d9b023          	sd	a3,0(s3)
    return page;
ffffffffc02014ce:	bfa1                	j	ffffffffc0201426 <buddy_alloc_pages+0x66>
    assert(n > 0);
ffffffffc02014d0:	00002697          	auipc	a3,0x2
ffffffffc02014d4:	09868693          	addi	a3,a3,152 # ffffffffc0203568 <etext+0xa5e>
ffffffffc02014d8:	00002617          	auipc	a2,0x2
ffffffffc02014dc:	8d060613          	addi	a2,a2,-1840 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02014e0:	06100593          	li	a1,97
ffffffffc02014e4:	00002517          	auipc	a0,0x2
ffffffffc02014e8:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02014ec:	cd7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02014f0 <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc02014f0:	1101                	addi	sp,sp,-32
ffffffffc02014f2:	e426                	sd	s1,8(sp)
ffffffffc02014f4:	84ae                	mv	s1,a1
ffffffffc02014f6:	e822                	sd	s0,16(sp)
ffffffffc02014f8:	ec06                	sd	ra,24(sp)
ffffffffc02014fa:	842a                	mv	s0,a0
    size_t index = page_index(base);
ffffffffc02014fc:	8deff0ef          	jal	ra,ffffffffc02005da <page_index>
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc0201500:	12048963          	beqz	s1,ffffffffc0201632 <buddy_init_memmap+0x142>
ffffffffc0201504:	00003317          	auipc	t1,0x3
ffffffffc0201508:	d1c33303          	ld	t1,-740(t1) # ffffffffc0204220 <nbase>
ffffffffc020150c:	00048797          	auipc	a5,0x48
ffffffffc0201510:	53c7b783          	ld	a5,1340(a5) # ffffffffc0249a48 <npage>
ffffffffc0201514:	406787b3          	sub	a5,a5,t1
ffffffffc0201518:	8f89                	sub	a5,a5,a0
ffffffffc020151a:	1097ec63          	bltu	a5,s1,ffffffffc0201632 <buddy_init_memmap+0x142>
    unsigned int id = index + 1;
ffffffffc020151e:	00251813          	slli	a6,a0,0x2
ffffffffc0201522:	00007597          	auipc	a1,0x7
ffffffffc0201526:	7f658593          	addi	a1,a1,2038 # ffffffffc0208d18 <region>
ffffffffc020152a:	982e                	add	a6,a6,a1
ffffffffc020152c:	0015089b          	addiw	a7,a0,1
    for (size_t i = 0; i < n; i ++) {
ffffffffc0201530:	00840693          	addi	a3,s0,8
    unsigned int id = index + 1;
ffffffffc0201534:	8742                	mv	a4,a6
    for (size_t i = 0; i < n; i ++) {
ffffffffc0201536:	4601                	li	a2,0
        assert(PageReserved(base + i) && region[index + i] == 0);
ffffffffc0201538:	629c                	ld	a5,0(a3)
ffffffffc020153a:	8b85                	andi	a5,a5,1
ffffffffc020153c:	cbf9                	beqz	a5,ffffffffc0201612 <buddy_init_memmap+0x122>
ffffffffc020153e:	431c                	lw	a5,0(a4)
ffffffffc0201540:	ebe9                	bnez	a5,ffffffffc0201612 <buddy_init_memmap+0x122>
    for (size_t i = 0; i < n; i ++) {
ffffffffc0201542:	0605                	addi	a2,a2,1
ffffffffc0201544:	02868693          	addi	a3,a3,40
ffffffffc0201548:	0711                	addi	a4,a4,4
ffffffffc020154a:	fec497e3          	bne	s1,a2,ffffffffc0201538 <buddy_init_memmap+0x48>
ffffffffc020154e:	00c506b3          	add	a3,a0,a2
ffffffffc0201552:	068a                	slli	a3,a3,0x2
ffffffffc0201554:	01840513          	addi	a0,s0,24
ffffffffc0201558:	87aa                	mv	a5,a0
ffffffffc020155a:	96ae                	add	a3,a3,a1
        ClearPageProperty(base + i);
ffffffffc020155c:	ff07b703          	ld	a4,-16(a5)
        base[i].property = 0;
ffffffffc0201560:	fe07ac23          	sw	zero,-8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201564:	fe07a423          	sw	zero,-24(a5)
        ClearPageProperty(base + i);
ffffffffc0201568:	9b71                	andi	a4,a4,-4
ffffffffc020156a:	fee7b823          	sd	a4,-16(a5)
    elm->prev = elm->next = elm;
ffffffffc020156e:	e79c                	sd	a5,8(a5)
ffffffffc0201570:	e39c                	sd	a5,0(a5)
        region[index + i] = id;
ffffffffc0201572:	01182023          	sw	a7,0(a6)
    for (size_t i = 0; i < n; i ++) {
ffffffffc0201576:	0811                	addi	a6,a6,4
ffffffffc0201578:	02878793          	addi	a5,a5,40
ffffffffc020157c:	ff0690e3          	bne	a3,a6,ffffffffc020155c <buddy_init_memmap+0x6c>
    nr_free += n;
ffffffffc0201580:	00048717          	auipc	a4,0x48
ffffffffc0201584:	4c070713          	addi	a4,a4,1216 # ffffffffc0249a40 <nr_free>
ffffffffc0201588:	631c                	ld	a5,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020158a:	00048f97          	auipc	t6,0x48
ffffffffc020158e:	4c6fbf83          	ld	t6,1222(t6) # ffffffffc0249a50 <pages>
ffffffffc0201592:	00007f17          	auipc	t5,0x7
ffffffffc0201596:	486f0f13          	addi	t5,t5,1158 # ffffffffc0208a18 <free_lists>
ffffffffc020159a:	97b2                	add	a5,a5,a2
ffffffffc020159c:	e31c                	sd	a5,0(a4)
    while (n != 0) {
ffffffffc020159e:	00003e97          	auipc	t4,0x3
ffffffffc02015a2:	c7aebe83          	ld	t4,-902(t4) # ffffffffc0204218 <error_string+0x38>
    return (size_t)1 << order;
ffffffffc02015a6:	4805                	li	a6,1
        base += block_size(order);
ffffffffc02015a8:	02800e13          	li	t3,40
ffffffffc02015ac:	41f408b3          	sub	a7,s0,t6
ffffffffc02015b0:	4038d893          	srai	a7,a7,0x3
ffffffffc02015b4:	03d888b3          	mul	a7,a7,t4
        unsigned int order = BUDDY_MAX_ORDER;
ffffffffc02015b8:	47bd                	li	a5,15
ffffffffc02015ba:	989a                	add	a7,a7,t1
    return (size_t)1 << order;
ffffffffc02015bc:	00f81733          	sll	a4,a6,a5
ffffffffc02015c0:	85be                	mv	a1,a5
        while (block_size(order) > n ||
ffffffffc02015c2:	00e66763          	bltu	a2,a4,ffffffffc02015d0 <buddy_init_memmap+0xe0>
               (page2ppn(base) & (block_size(order) - 1)) != 0) {
ffffffffc02015c6:	fff70693          	addi	a3,a4,-1
ffffffffc02015ca:	0116f6b3          	and	a3,a3,a7
        while (block_size(order) > n ||
ffffffffc02015ce:	c299                	beqz	a3,ffffffffc02015d4 <buddy_init_memmap+0xe4>
            order --;
ffffffffc02015d0:	37fd                	addiw	a5,a5,-1
ffffffffc02015d2:	b7ed                	j	ffffffffc02015bc <buddy_init_memmap+0xcc>
    __list_add(elm, listelm, listelm->next);
ffffffffc02015d4:	02079493          	slli	s1,a5,0x20
    SetPageProperty(page);
ffffffffc02015d8:	6414                	ld	a3,8(s0)
ffffffffc02015da:	01c4d793          	srli	a5,s1,0x1c
ffffffffc02015de:	97fa                	add	a5,a5,t5
ffffffffc02015e0:	0087b883          	ld	a7,8(a5)
ffffffffc02015e4:	0026e693          	ori	a3,a3,2
    page->property = block_size(order);
ffffffffc02015e8:	c818                	sw	a4,16(s0)
    SetPageProperty(page);
ffffffffc02015ea:	e414                	sd	a3,8(s0)
    prev->next = next->prev = elm;
ffffffffc02015ec:	00a8b023          	sd	a0,0(a7)
ffffffffc02015f0:	e788                	sd	a0,8(a5)
    elm->next = next;
ffffffffc02015f2:	03143023          	sd	a7,32(s0)
    elm->prev = prev;
ffffffffc02015f6:	ec1c                	sd	a5,24(s0)
        base += block_size(order);
ffffffffc02015f8:	00be15b3          	sll	a1,t3,a1
        n -= block_size(order);
ffffffffc02015fc:	8e19                	sub	a2,a2,a4
        base += block_size(order);
ffffffffc02015fe:	942e                	add	s0,s0,a1
    while (n != 0) {
ffffffffc0201600:	c601                	beqz	a2,ffffffffc0201608 <buddy_init_memmap+0x118>
ffffffffc0201602:	01840513          	addi	a0,s0,24
ffffffffc0201606:	b75d                	j	ffffffffc02015ac <buddy_init_memmap+0xbc>
}
ffffffffc0201608:	60e2                	ld	ra,24(sp)
ffffffffc020160a:	6442                	ld	s0,16(sp)
ffffffffc020160c:	64a2                	ld	s1,8(sp)
ffffffffc020160e:	6105                	addi	sp,sp,32
ffffffffc0201610:	8082                	ret
        assert(PageReserved(base + i) && region[index + i] == 0);
ffffffffc0201612:	00002697          	auipc	a3,0x2
ffffffffc0201616:	f8668693          	addi	a3,a3,-122 # ffffffffc0203598 <etext+0xa8e>
ffffffffc020161a:	00001617          	auipc	a2,0x1
ffffffffc020161e:	78e60613          	addi	a2,a2,1934 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201622:	04700593          	li	a1,71
ffffffffc0201626:	00001517          	auipc	a0,0x1
ffffffffc020162a:	79a50513          	addi	a0,a0,1946 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc020162e:	b95fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc0201632:	00002697          	auipc	a3,0x2
ffffffffc0201636:	f3e68693          	addi	a3,a3,-194 # ffffffffc0203570 <etext+0xa66>
ffffffffc020163a:	00001617          	auipc	a2,0x1
ffffffffc020163e:	76e60613          	addi	a2,a2,1902 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201642:	04300593          	li	a1,67
ffffffffc0201646:	00001517          	auipc	a0,0x1
ffffffffc020164a:	77a50513          	addi	a0,a0,1914 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc020164e:	b75fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201652 <buddy_check>:
    /* n == 0 violates the API's assert(n > 0); test it only in a host process. */
    cprintf("Buddy System boundary test passed!\n");
}

static void
buddy_check(void) {
ffffffffc0201652:	dd010113          	addi	sp,sp,-560
ffffffffc0201656:	22113423          	sd	ra,552(sp)
ffffffffc020165a:	22813023          	sd	s0,544(sp)
ffffffffc020165e:	20913c23          	sd	s1,536(sp)
ffffffffc0201662:	21213823          	sd	s2,528(sp)
ffffffffc0201666:	21313423          	sd	s3,520(sp)
ffffffffc020166a:	21413023          	sd	s4,512(sp)
ffffffffc020166e:	ffd6                	sd	s5,504(sp)
ffffffffc0201670:	fbda                	sd	s6,496(sp)
ffffffffc0201672:	f7de                	sd	s7,488(sp)
ffffffffc0201674:	f3e2                	sd	s8,480(sp)
ffffffffc0201676:	efe6                	sd	s9,472(sp)
ffffffffc0201678:	ebea                	sd	s10,464(sp)
ffffffffc020167a:	e7ee                	sd	s11,456(sp)
ffffffffc020167c:	0c010913          	addi	s2,sp,192
    size_t original = nr_free_pages();
ffffffffc0201680:	555000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc0201684:	e82a                	sd	a0,16(sp)
    size_t original_counts[BUDDY_MAX_ORDER + 1];
    check_lists();
ffffffffc0201686:	84ca                	mv	s1,s2
ffffffffc0201688:	882ff0ef          	jal	ra,ffffffffc020070a <check_lists>
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc020168c:	4401                	li	s0,0
ffffffffc020168e:	49c1                	li	s3,16
        original_counts[order] = test_list_count(order);
ffffffffc0201690:	8522                	mv	a0,s0
ffffffffc0201692:	e46ff0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201696:	e088                	sd	a0,0(s1)
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc0201698:	2405                	addiw	s0,s0,1
ffffffffc020169a:	04a1                	addi	s1,s1,8
ffffffffc020169c:	ff341ae3          	bne	s0,s3,ffffffffc0201690 <buddy_check+0x3e>
    }
    /* Only real free pages are borrowed; no kernel/reserved memory is tested.
     * If boot RAM is too fragmented/small, report that tests did not run. */
    struct Page *base = alloc_pages(TEST_PAGES);
ffffffffc02016a0:	04000513          	li	a0,64
ffffffffc02016a4:	519000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc02016a8:	ec2a                	sd	a0,24(sp)
    if (base == NULL) {
ffffffffc02016aa:	04050de3          	beqz	a0,ffffffffc0201f04 <buddy_check+0x8b2>
        assert(nr_free_pages() == original);
        check_lists();
        cprintf("Buddy System tests skipped: no 64-page test block available.\n");
        return;
    }
    test_state.base = base;
ffffffffc02016ae:	64e2                	ld	s1,24(sp)
ffffffffc02016b0:	00047a97          	auipc	s5,0x47
ffffffffc02016b4:	668a8a93          	addi	s5,s5,1640 # ffffffffc0248d18 <test_state>
ffffffffc02016b8:	05010b93          	addi	s7,sp,80
ffffffffc02016bc:	009ab023          	sd	s1,0(s5)
    size_t index = page_index(base);
ffffffffc02016c0:	f1bfe0ef          	jal	ra,ffffffffc02005da <page_index>
ffffffffc02016c4:	842a                	mv	s0,a0
    test_state.saved_free = nr_free_pages();
ffffffffc02016c6:	50f000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc02016ca:	00048717          	auipc	a4,0x48
ffffffffc02016ce:	64e70713          	addi	a4,a4,1614 # ffffffffc0249d18 <end+0x2a0>
ffffffffc02016d2:	87aa                	mv	a5,a0
    memcpy(test_state.heads, free_lists, sizeof(free_lists));
ffffffffc02016d4:	10000613          	li	a2,256
ffffffffc02016d8:	00007597          	auipc	a1,0x7
ffffffffc02016dc:	34058593          	addi	a1,a1,832 # ffffffffc0208a18 <free_lists>
ffffffffc02016e0:	00048517          	auipc	a0,0x48
ffffffffc02016e4:	24050513          	addi	a0,a0,576 # ffffffffc0249920 <test_state+0xc08>
    test_state.saved_free = nr_free_pages();
ffffffffc02016e8:	d0f73423          	sd	a5,-760(a4)
    memcpy(test_state.heads, free_lists, sizeof(free_lists));
ffffffffc02016ec:	3e2010ef          	jal	ra,ffffffffc0202ace <memcpy>
    memcpy(test_state.descriptors, base, sizeof(test_state.descriptors));
ffffffffc02016f0:	6605                	lui	a2,0x1
ffffffffc02016f2:	a0060613          	addi	a2,a2,-1536 # a00 <kern_entry-0xffffffffc01ff600>
ffffffffc02016f6:	85a6                	mv	a1,s1
ffffffffc02016f8:	00047517          	auipc	a0,0x47
ffffffffc02016fc:	62850513          	addi	a0,a0,1576 # ffffffffc0248d20 <test_state+0x8>
ffffffffc0201700:	3ce010ef          	jal	ra,ffffffffc0202ace <memcpy>
    memcpy(test_state.regions, region + index, sizeof(test_state.regions));
ffffffffc0201704:	040a                	slli	s0,s0,0x2
ffffffffc0201706:	00007797          	auipc	a5,0x7
ffffffffc020170a:	61278793          	addi	a5,a5,1554 # ffffffffc0208d18 <region>
ffffffffc020170e:	97a2                	add	a5,a5,s0
ffffffffc0201710:	85be                	mv	a1,a5
ffffffffc0201712:	10000613          	li	a2,256
ffffffffc0201716:	00048517          	auipc	a0,0x48
ffffffffc020171a:	00a50513          	addi	a0,a0,10 # ffffffffc0249720 <test_state+0xa08>
ffffffffc020171e:	f03e                	sd	a5,32(sp)
ffffffffc0201720:	3ae010ef          	jal	ra,ffffffffc0202ace <memcpy>
    memcpy(test_state.requests, requested + index, sizeof(test_state.requests));
ffffffffc0201724:	00027797          	auipc	a5,0x27
ffffffffc0201728:	5f478793          	addi	a5,a5,1524 # ffffffffc0228d18 <requested>
ffffffffc020172c:	97a2                	add	a5,a5,s0
ffffffffc020172e:	85be                	mv	a1,a5
ffffffffc0201730:	10000613          	li	a2,256
ffffffffc0201734:	00048517          	auipc	a0,0x48
ffffffffc0201738:	0ec50513          	addi	a0,a0,236 # ffffffffc0249820 <test_state+0xb08>
ffffffffc020173c:	f43e                	sd	a5,40(sp)
ffffffffc020173e:	390010ef          	jal	ra,ffffffffc0202ace <memcpy>
    const size_t counts[] = {1, 2, 4, 8, 3, 5, 7};
ffffffffc0201742:	00002797          	auipc	a5,0x2
ffffffffc0201746:	61678793          	addi	a5,a5,1558 # ffffffffc0203d58 <etext+0x124e>
ffffffffc020174a:	0007b283          	ld	t0,0(a5)
ffffffffc020174e:	0087bf83          	ld	t6,8(a5)
ffffffffc0201752:	0107bf03          	ld	t5,16(a5)
ffffffffc0201756:	0187be83          	ld	t4,24(a5)
ffffffffc020175a:	0207be03          	ld	t3,32(a5)
ffffffffc020175e:	0287b303          	ld	t1,40(a5)
ffffffffc0201762:	0307b883          	ld	a7,48(a5)
    const size_t actual[] = {1, 2, 4, 8, 4, 8, 8};
ffffffffc0201766:	0387b803          	ld	a6,56(a5)
ffffffffc020176a:	63a8                	ld	a0,64(a5)
ffffffffc020176c:	67ac                	ld	a1,72(a5)
ffffffffc020176e:	6bb0                	ld	a2,80(a5)
ffffffffc0201770:	6fb4                	ld	a3,88(a5)
ffffffffc0201772:	73b8                	ld	a4,96(a5)
ffffffffc0201774:	77bc                	ld	a5,104(a5)
    const size_t counts[] = {1, 2, 4, 8, 3, 5, 7};
ffffffffc0201776:	e896                	sd	t0,80(sp)
ffffffffc0201778:	ecfe                	sd	t6,88(sp)
ffffffffc020177a:	f0fa                	sd	t5,96(sp)
ffffffffc020177c:	f4f6                	sd	t4,104(sp)
ffffffffc020177e:	f8f2                	sd	t3,112(sp)
ffffffffc0201780:	fc9a                	sd	t1,120(sp)
ffffffffc0201782:	e146                	sd	a7,128(sp)
    const size_t actual[] = {1, 2, 4, 8, 4, 8, 8};
ffffffffc0201784:	e542                	sd	a6,136(sp)
ffffffffc0201786:	e92a                	sd	a0,144(sp)
ffffffffc0201788:	ed2e                	sd	a1,152(sp)
ffffffffc020178a:	f132                	sd	a2,160(sp)
ffffffffc020178c:	f536                	sd	a3,168(sp)
ffffffffc020178e:	f93a                	sd	a4,176(sp)
ffffffffc0201790:	fd3e                	sd	a5,184(sp)
    test_arena_reset();
ffffffffc0201792:	eeffe0ef          	jal	ra,ffffffffc0200680 <test_arena_reset>
    buddy_init_memmap(test_state.base, TEST_PAGES);
ffffffffc0201796:	000ab503          	ld	a0,0(s5)
ffffffffc020179a:	04000593          	li	a1,64
ffffffffc020179e:	0280                	addi	s0,sp,320
ffffffffc02017a0:	d51ff0ef          	jal	ra,ffffffffc02014f0 <buddy_init_memmap>
ffffffffc02017a4:	08810b13          	addi	s6,sp,136
ffffffffc02017a8:	8ca2                	mv	s9,s0
ffffffffc02017aa:	4985                	li	s3,1
ffffffffc02017ac:	00048d17          	auipc	s10,0x48
ffffffffc02017b0:	2a4d0d13          	addi	s10,s10,676 # ffffffffc0249a50 <pages>
        size_t before = nr_free_pages();
ffffffffc02017b4:	421000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
        struct Page *p = allocated[i] = alloc_pages(counts[i]);
ffffffffc02017b8:	000bba03          	ld	s4,0(s7)
        size_t before = nr_free_pages();
ffffffffc02017bc:	84aa                	mv	s1,a0
        struct Page *p = allocated[i] = alloc_pages(counts[i]);
ffffffffc02017be:	8552                	mv	a0,s4
ffffffffc02017c0:	3fd000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc02017c4:	00acb023          	sd	a0,0(s9)
ffffffffc02017c8:	8daa                	mv	s11,a0
        assert(p != NULL);
ffffffffc02017ca:	220509e3          	beqz	a0,ffffffffc02021fc <buddy_check+0xbaa>
        size_t index = page_index(p);
ffffffffc02017ce:	e0dfe0ef          	jal	ra,ffffffffc02005da <page_index>
ffffffffc02017d2:	87aa                	mv	a5,a0
        assert(index >= page_index(test_state.base));
ffffffffc02017d4:	000ab503          	ld	a0,0(s5)
        size_t index = page_index(p);
ffffffffc02017d8:	e43e                	sd	a5,8(sp)
        assert(index >= page_index(test_state.base));
ffffffffc02017da:	e01fe0ef          	jal	ra,ffffffffc02005da <page_index>
ffffffffc02017de:	67a2                	ld	a5,8(sp)
ffffffffc02017e0:	24a7eee3          	bltu	a5,a0,ffffffffc020223c <buddy_check+0xbea>
        assert(index + actual[i] <= page_index(test_state.base) + TEST_PAGES);
ffffffffc02017e4:	000b3c03          	ld	s8,0(s6)
ffffffffc02017e8:	04050513          	addi	a0,a0,64
ffffffffc02017ec:	018786b3          	add	a3,a5,s8
ffffffffc02017f0:	22d566e3          	bltu	a0,a3,ffffffffc020221c <buddy_check+0xbca>
        assert(p->property == actual[i] && requested[index] == counts[i]);
ffffffffc02017f4:	010de683          	lwu	a3,16(s11)
ffffffffc02017f8:	2cdc12e3          	bne	s8,a3,ffffffffc02022bc <buddy_check+0xc6a>
ffffffffc02017fc:	078a                	slli	a5,a5,0x2
ffffffffc02017fe:	00027717          	auipc	a4,0x27
ffffffffc0201802:	51a70713          	addi	a4,a4,1306 # ffffffffc0228d18 <requested>
ffffffffc0201806:	97ba                	add	a5,a5,a4
ffffffffc0201808:	0007e783          	lwu	a5,0(a5)
ffffffffc020180c:	2afa18e3          	bne	s4,a5,ffffffffc02022bc <buddy_check+0xc6a>
        assert(before - nr_free_pages() == actual[i]);
ffffffffc0201810:	3c5000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc0201814:	8c89                	sub	s1,s1,a0
ffffffffc0201816:	289c13e3          	bne	s8,s1,ffffffffc020229c <buddy_check+0xc4a>
ffffffffc020181a:	00003717          	auipc	a4,0x3
ffffffffc020181e:	a0670713          	addi	a4,a4,-1530 # ffffffffc0204220 <nbase>
ffffffffc0201822:	000d3783          	ld	a5,0(s10)
ffffffffc0201826:	6304                	ld	s1,0(a4)
ffffffffc0201828:	00003717          	auipc	a4,0x3
ffffffffc020182c:	9f070713          	addi	a4,a4,-1552 # ffffffffc0204218 <error_string+0x38>
ffffffffc0201830:	6318                	ld	a4,0(a4)
ffffffffc0201832:	40fd87b3          	sub	a5,s11,a5
ffffffffc0201836:	878d                	srai	a5,a5,0x3
ffffffffc0201838:	02e787b3          	mul	a5,a5,a4
        assert((page2pa(p) & (actual[i] * PGSIZE - 1)) == 0);
ffffffffc020183c:	00cc1693          	slli	a3,s8,0xc
ffffffffc0201840:	16fd                	addi	a3,a3,-1
ffffffffc0201842:	97a6                	add	a5,a5,s1
    return page2ppn(page) << PGSHIFT;
ffffffffc0201844:	07b2                	slli	a5,a5,0xc
ffffffffc0201846:	8ff5                	and	a5,a5,a3
ffffffffc0201848:	18079ae3          	bnez	a5,ffffffffc02021dc <buddy_check+0xb8a>
        for (size_t j = 0; j < i; j ++) {
ffffffffc020184c:	4785                	li	a5,1
ffffffffc020184e:	6af98763          	beq	s3,a5,ffffffffc0201efc <buddy_check+0x8aa>
            assert(p + actual[i] <= allocated[j] || allocated[j] + actual[j] <= p);
ffffffffc0201852:	002c1813          	slli	a6,s8,0x2
ffffffffc0201856:	9862                	add	a6,a6,s8
ffffffffc0201858:	080e                	slli	a6,a6,0x3
ffffffffc020185a:	986e                	add	a6,a6,s11
ffffffffc020185c:	0130                	addi	a2,sp,136
ffffffffc020185e:	87a2                	mv	a5,s0
ffffffffc0201860:	6398                	ld	a4,0(a5)
ffffffffc0201862:	01077a63          	bgeu	a4,a6,ffffffffc0201876 <buddy_check+0x224>
ffffffffc0201866:	620c                	ld	a1,0(a2)
ffffffffc0201868:	00259693          	slli	a3,a1,0x2
ffffffffc020186c:	96ae                	add	a3,a3,a1
ffffffffc020186e:	068e                	slli	a3,a3,0x3
ffffffffc0201870:	9736                	add	a4,a4,a3
ffffffffc0201872:	32ede5e3          	bltu	s11,a4,ffffffffc020239c <buddy_check+0xd4a>
        for (size_t j = 0; j < i; j ++) {
ffffffffc0201876:	07a1                	addi	a5,a5,8
ffffffffc0201878:	0621                	addi	a2,a2,8
ffffffffc020187a:	fefc93e3          	bne	s9,a5,ffffffffc0201860 <buddy_check+0x20e>
        test_arena_check();
ffffffffc020187e:	ce0ff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    for (size_t i = 0; i < 7; i ++) {
ffffffffc0201882:	479d                	li	a5,7
ffffffffc0201884:	00f98763          	beq	s3,a5,ffffffffc0201892 <buddy_check+0x240>
ffffffffc0201888:	0ba1                	addi	s7,s7,8
ffffffffc020188a:	0ca1                	addi	s9,s9,8
ffffffffc020188c:	0985                	addi	s3,s3,1
ffffffffc020188e:	0b21                	addi	s6,s6,8
ffffffffc0201890:	b715                	j	ffffffffc02017b4 <buddy_check+0x162>
    const unsigned int release[] = {3, 0, 5, 1, 6, 2, 4};
ffffffffc0201892:	4785                	li	a5,1
ffffffffc0201894:	02079713          	slli	a4,a5,0x20
ffffffffc0201898:	1786                	slli	a5,a5,0x21
ffffffffc020189a:	0799                	addi	a5,a5,6
ffffffffc020189c:	0715                	addi	a4,a4,5
ffffffffc020189e:	e0be                	sd	a5,64(sp)
ffffffffc02018a0:	4791                	li	a5,4
ffffffffc02018a2:	da02                	sw	zero,52(sp)
ffffffffc02018a4:	fc3a                	sd	a4,56(sp)
ffffffffc02018a6:	c4be                	sw	a5,72(sp)
    for (size_t i = 0; i < 7; i ++) {
ffffffffc02018a8:	03010b13          	addi	s6,sp,48
ffffffffc02018ac:	04c10993          	addi	s3,sp,76
    const unsigned int release[] = {3, 0, 5, 1, 6, 2, 4};
ffffffffc02018b0:	4a0d                	li	s4,3
ffffffffc02018b2:	a019                	j	ffffffffc02018b8 <buddy_check+0x266>
        unsigned int j = release[i];
ffffffffc02018b4:	000b2a03          	lw	s4,0(s6)
        size_t before = nr_free_pages();
ffffffffc02018b8:	31d000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
        free_pages(allocated[j], counts[j]);
ffffffffc02018bc:	020a1793          	slli	a5,s4,0x20
ffffffffc02018c0:	01d7da13          	srli	s4,a5,0x1d
ffffffffc02018c4:	039c                	addi	a5,sp,448
ffffffffc02018c6:	9a3e                	add	s4,s4,a5
ffffffffc02018c8:	e90a3583          	ld	a1,-368(s4)
        size_t before = nr_free_pages();
ffffffffc02018cc:	8baa                	mv	s7,a0
        free_pages(allocated[j], counts[j]);
ffffffffc02018ce:	f80a3503          	ld	a0,-128(s4)
ffffffffc02018d2:	2f7000ef          	jal	ra,ffffffffc02023c8 <free_pages>
        assert(nr_free_pages() - before == actual[j]);
ffffffffc02018d6:	2ff000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc02018da:	ec8a3703          	ld	a4,-312(s4)
ffffffffc02018de:	417507b3          	sub	a5,a0,s7
ffffffffc02018e2:	28e79de3          	bne	a5,a4,ffffffffc020237c <buddy_check+0xd2a>
    for (size_t i = 0; i < 7; i ++) {
ffffffffc02018e6:	0b11                	addi	s6,s6,4
        test_arena_check();
ffffffffc02018e8:	c76ff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    for (size_t i = 0; i < 7; i ++) {
ffffffffc02018ec:	fd6994e3          	bne	s3,s6,ffffffffc02018b4 <buddy_check+0x262>
    test_single_block(6, test_state.base);
ffffffffc02018f0:	000ab583          	ld	a1,0(s5)
ffffffffc02018f4:	4519                	li	a0,6
ffffffffc02018f6:	9d1ff0ef          	jal	ra,ffffffffc02012c6 <test_single_block>
    cprintf("Buddy System basic allocation test passed!\n");
ffffffffc02018fa:	00002517          	auipc	a0,0x2
ffffffffc02018fe:	eae50513          	addi	a0,a0,-338 # ffffffffc02037a8 <etext+0xc9e>
ffffffffc0201902:	84bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *base = test_state.base;
ffffffffc0201906:	000aba03          	ld	s4,0(s5)
    test_arena_reset();
ffffffffc020190a:	d77fe0ef          	jal	ra,ffffffffc0200680 <test_arena_reset>
    buddy_init_memmap(base, 16);
ffffffffc020190e:	45c1                	li	a1,16
ffffffffc0201910:	8552                	mv	a0,s4
ffffffffc0201912:	bdfff0ef          	jal	ra,ffffffffc02014f0 <buddy_init_memmap>
    test_single_block(4, base);
ffffffffc0201916:	85d2                	mv	a1,s4
ffffffffc0201918:	4511                	li	a0,4
ffffffffc020191a:	9adff0ef          	jal	ra,ffffffffc02012c6 <test_single_block>
    struct Page *one = alloc_pages(1);
ffffffffc020191e:	4505                	li	a0,1
ffffffffc0201920:	29d000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc0201924:	89aa                	mv	s3,a0
    assert(one == base && nr_free_pages() == 15);
ffffffffc0201926:	22aa1be3          	bne	s4,a0,ffffffffc020235c <buddy_check+0xd0a>
ffffffffc020192a:	2ab000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc020192e:	47bd                	li	a5,15
ffffffffc0201930:	22f516e3          	bne	a0,a5,ffffffffc020235c <buddy_check+0xd0a>
ffffffffc0201934:	00007d97          	auipc	s11,0x7
ffffffffc0201938:	0ecd8d93          	addi	s11,s11,236 # ffffffffc0208a20 <free_lists+0x8>
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc020193c:	4b81                	li	s7,0
        assert(test_list_count(order) == (order < 4 ? 1 : 0));
ffffffffc020193e:	4b0d                	li	s6,3
    return (size_t)1 << order;
ffffffffc0201940:	4c85                	li	s9,1
            assert(p == base + block_size(order));
ffffffffc0201942:	02800c13          	li	s8,40
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc0201946:	4a41                	li	s4,16
ffffffffc0201948:	a029                	j	ffffffffc0201952 <buddy_check+0x300>
ffffffffc020194a:	2b85                	addiw	s7,s7,1
ffffffffc020194c:	0dc1                	addi	s11,s11,16
ffffffffc020194e:	054b8e63          	beq	s7,s4,ffffffffc02019aa <buddy_check+0x358>
        assert(test_list_count(order) == (order < 4 ? 1 : 0));
ffffffffc0201952:	855e                	mv	a0,s7
ffffffffc0201954:	b84ff0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201958:	004bb693          	sltiu	a3,s7,4
ffffffffc020195c:	1ea690e3          	bne	a3,a0,ffffffffc020233c <buddy_check+0xcea>
        if (order < 4) {
ffffffffc0201960:	ff7b65e3          	bltu	s6,s7,ffffffffc020194a <buddy_check+0x2f8>
    return listelm->next;
ffffffffc0201964:	000db683          	ld	a3,0(s11)
            assert(p == base + block_size(order));
ffffffffc0201968:	017c1633          	sll	a2,s8,s7
ffffffffc020196c:	964e                	add	a2,a2,s3
            struct Page *p = le2page(list_next(&free_lists[order]), page_link);
ffffffffc020196e:	fe868513          	addi	a0,a3,-24
    return (size_t)1 << order;
ffffffffc0201972:	017c95b3          	sll	a1,s9,s7
            assert(p == base + block_size(order));
ffffffffc0201976:	1ac513e3          	bne	a0,a2,ffffffffc020231c <buddy_check+0xcca>
            assert(p->property == block_size(order) && PageProperty(p));
ffffffffc020197a:	ff86e603          	lwu	a2,-8(a3)
ffffffffc020197e:	00c59663          	bne	a1,a2,ffffffffc020198a <buddy_check+0x338>
ffffffffc0201982:	ff06b683          	ld	a3,-16(a3)
ffffffffc0201986:	8a89                	andi	a3,a3,2
ffffffffc0201988:	f2e9                	bnez	a3,ffffffffc020194a <buddy_check+0x2f8>
ffffffffc020198a:	00002697          	auipc	a3,0x2
ffffffffc020198e:	ec668693          	addi	a3,a3,-314 # ffffffffc0203850 <etext+0xd46>
ffffffffc0201992:	00001617          	auipc	a2,0x1
ffffffffc0201996:	41660613          	addi	a2,a2,1046 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020199a:	16900593          	li	a1,361
ffffffffc020199e:	00001517          	auipc	a0,0x1
ffffffffc02019a2:	42250513          	addi	a0,a0,1058 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02019a6:	81dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    test_arena_check();
ffffffffc02019aa:	bb4ff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    struct Page *eight = alloc_pages(8), *four = alloc_pages(4);
ffffffffc02019ae:	4521                	li	a0,8
ffffffffc02019b0:	20d000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc02019b4:	8a2a                	mv	s4,a0
ffffffffc02019b6:	4511                	li	a0,4
ffffffffc02019b8:	205000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc02019bc:	8daa                	mv	s11,a0
    struct Page *two = alloc_pages(2), *last = alloc_pages(1);
ffffffffc02019be:	4509                	li	a0,2
ffffffffc02019c0:	1fd000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc02019c4:	8b2a                	mv	s6,a0
ffffffffc02019c6:	4505                	li	a0,1
ffffffffc02019c8:	1f5000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
    assert(eight == base + 8 && four == base + 4);
ffffffffc02019cc:	14098793          	addi	a5,s3,320
    struct Page *two = alloc_pages(2), *last = alloc_pages(1);
ffffffffc02019d0:	8baa                	mv	s7,a0
    assert(eight == base + 8 && four == base + 4);
ffffffffc02019d2:	12fa15e3          	bne	s4,a5,ffffffffc02022fc <buddy_check+0xcaa>
ffffffffc02019d6:	0a098793          	addi	a5,s3,160
ffffffffc02019da:	12fd91e3          	bne	s11,a5,ffffffffc02022fc <buddy_check+0xcaa>
    assert(two == base + 2 && last == base + 1);
ffffffffc02019de:	05098793          	addi	a5,s3,80
ffffffffc02019e2:	0efb1de3          	bne	s6,a5,ffffffffc02022dc <buddy_check+0xc8a>
ffffffffc02019e6:	02898793          	addi	a5,s3,40
ffffffffc02019ea:	0ef519e3          	bne	a0,a5,ffffffffc02022dc <buddy_check+0xc8a>
    assert(nr_free_pages() == 0);
ffffffffc02019ee:	1e7000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc02019f2:	7c051563          	bnez	a0,ffffffffc02021bc <buddy_check+0xb6a>
    test_arena_check();
ffffffffc02019f6:	b68ff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    free_pages(two, 2);
ffffffffc02019fa:	855a                	mv	a0,s6
ffffffffc02019fc:	4589                	li	a1,2
ffffffffc02019fe:	1cb000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    free_pages(eight, 8);
ffffffffc0201a02:	8552                	mv	a0,s4
ffffffffc0201a04:	45a1                	li	a1,8
ffffffffc0201a06:	1c3000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    free_pages(last, 1);
ffffffffc0201a0a:	855e                	mv	a0,s7
ffffffffc0201a0c:	4585                	li	a1,1
ffffffffc0201a0e:	1bb000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    free_pages(four, 4);
ffffffffc0201a12:	4591                	li	a1,4
ffffffffc0201a14:	856e                	mv	a0,s11
ffffffffc0201a16:	1b3000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    free_pages(one, 1);
ffffffffc0201a1a:	854e                	mv	a0,s3
ffffffffc0201a1c:	4585                	li	a1,1
ffffffffc0201a1e:	1ab000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    test_single_block(4, base);
ffffffffc0201a22:	85ce                	mv	a1,s3
ffffffffc0201a24:	4511                	li	a0,4
ffffffffc0201a26:	8a1ff0ef          	jal	ra,ffffffffc02012c6 <test_single_block>
    cprintf("Buddy System split test passed!\n");
ffffffffc0201a2a:	00002517          	auipc	a0,0x2
ffffffffc0201a2e:	ec650513          	addi	a0,a0,-314 # ffffffffc02038f0 <etext+0xde6>
ffffffffc0201a32:	f1afe0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *base = test_state.base, *p[4];
ffffffffc0201a36:	000ab983          	ld	s3,0(s5)
    test_arena_reset();
ffffffffc0201a3a:	c47fe0ef          	jal	ra,ffffffffc0200680 <test_arena_reset>
    buddy_init_memmap(base, 16);
ffffffffc0201a3e:	45c1                	li	a1,16
ffffffffc0201a40:	854e                	mv	a0,s3
ffffffffc0201a42:	aafff0ef          	jal	ra,ffffffffc02014f0 <buddy_init_memmap>
    for (size_t i = 0; i < 4; i ++) {
ffffffffc0201a46:	8ba2                	mv	s7,s0
ffffffffc0201a48:	8b4e                	mv	s6,s3
ffffffffc0201a4a:	28098a13          	addi	s4,s3,640
        p[i] = alloc_pages(4);
ffffffffc0201a4e:	4511                	li	a0,4
ffffffffc0201a50:	16d000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc0201a54:	00abb023          	sd	a0,0(s7)
        assert(p[i] == base + 4 * i);
ffffffffc0201a58:	75651263          	bne	a0,s6,ffffffffc020219c <buddy_check+0xb4a>
    for (size_t i = 0; i < 4; i ++) {
ffffffffc0201a5c:	0a0b0b13          	addi	s6,s6,160
ffffffffc0201a60:	0ba1                	addi	s7,s7,8
ffffffffc0201a62:	ff4b16e3          	bne	s6,s4,ffffffffc0201a4e <buddy_check+0x3fc>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201a66:	000d3783          	ld	a5,0(s10)
    assert((page2ppn(p[0]) ^ 4) == page2ppn(p[1]));
ffffffffc0201a6a:	6d16                	ld	s10,320(sp)
ffffffffc0201a6c:	6bb6                	ld	s7,328(sp)
ffffffffc0201a6e:	00002617          	auipc	a2,0x2
ffffffffc0201a72:	7aa60613          	addi	a2,a2,1962 # ffffffffc0204218 <error_string+0x38>
ffffffffc0201a76:	620c                	ld	a1,0(a2)
ffffffffc0201a78:	40fd0733          	sub	a4,s10,a5
ffffffffc0201a7c:	870d                	srai	a4,a4,0x3
ffffffffc0201a7e:	40fb86b3          	sub	a3,s7,a5
ffffffffc0201a82:	02b70733          	mul	a4,a4,a1
ffffffffc0201a86:	868d                	srai	a3,a3,0x3
ffffffffc0201a88:	02b686b3          	mul	a3,a3,a1
ffffffffc0201a8c:	9726                	add	a4,a4,s1
ffffffffc0201a8e:	00474713          	xori	a4,a4,4
ffffffffc0201a92:	96a6                	add	a3,a3,s1
ffffffffc0201a94:	6ed71463          	bne	a4,a3,ffffffffc020217c <buddy_check+0xb2a>
    assert((page2ppn(p[2]) ^ 4) == page2ppn(p[3]));
ffffffffc0201a98:	6a56                	ld	s4,336(sp)
ffffffffc0201a9a:	6b76                	ld	s6,344(sp)
ffffffffc0201a9c:	00002697          	auipc	a3,0x2
ffffffffc0201aa0:	77c68693          	addi	a3,a3,1916 # ffffffffc0204218 <error_string+0x38>
ffffffffc0201aa4:	6290                	ld	a2,0(a3)
ffffffffc0201aa6:	40fa0733          	sub	a4,s4,a5
ffffffffc0201aaa:	870d                	srai	a4,a4,0x3
ffffffffc0201aac:	40fb07b3          	sub	a5,s6,a5
ffffffffc0201ab0:	878d                	srai	a5,a5,0x3
ffffffffc0201ab2:	02c70733          	mul	a4,a4,a2
ffffffffc0201ab6:	02c78c33          	mul	s8,a5,a2
ffffffffc0201aba:	009707b3          	add	a5,a4,s1
ffffffffc0201abe:	0047c793          	xori	a5,a5,4
ffffffffc0201ac2:	94e2                	add	s1,s1,s8
ffffffffc0201ac4:	68979c63          	bne	a5,s1,ffffffffc020215c <buddy_check+0xb0a>
    test_arena_check();
ffffffffc0201ac8:	a96ff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    free_pages(p[0], 4);
ffffffffc0201acc:	4591                	li	a1,4
ffffffffc0201ace:	856a                	mv	a0,s10
ffffffffc0201ad0:	0f9000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    assert(test_list_count(2) == 1 && test_list_count(3) == 0);
ffffffffc0201ad4:	4509                	li	a0,2
ffffffffc0201ad6:	a02ff0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201ada:	4785                	li	a5,1
ffffffffc0201adc:	84aa                	mv	s1,a0
ffffffffc0201ade:	64f51f63          	bne	a0,a5,ffffffffc020213c <buddy_check+0xaea>
ffffffffc0201ae2:	450d                	li	a0,3
ffffffffc0201ae4:	9f4ff0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201ae8:	64051a63          	bnez	a0,ffffffffc020213c <buddy_check+0xaea>
    test_arena_check();
ffffffffc0201aec:	a72ff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    free_pages(p[1], 4);
ffffffffc0201af0:	855e                	mv	a0,s7
ffffffffc0201af2:	4591                	li	a1,4
ffffffffc0201af4:	0d5000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    assert(test_list_count(2) == 0 && test_list_count(3) == 1);
ffffffffc0201af8:	4509                	li	a0,2
ffffffffc0201afa:	9deff0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201afe:	60051f63          	bnez	a0,ffffffffc020211c <buddy_check+0xaca>
ffffffffc0201b02:	450d                	li	a0,3
ffffffffc0201b04:	9d4ff0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201b08:	8baa                	mv	s7,a0
ffffffffc0201b0a:	60951963          	bne	a0,s1,ffffffffc020211c <buddy_check+0xaca>
    assert(PageProperty(base) && base->property == 8);
ffffffffc0201b0e:	0089b783          	ld	a5,8(s3)
ffffffffc0201b12:	8b89                	andi	a5,a5,2
ffffffffc0201b14:	5e078463          	beqz	a5,ffffffffc02020fc <buddy_check+0xaaa>
ffffffffc0201b18:	0109a703          	lw	a4,16(s3)
ffffffffc0201b1c:	47a1                	li	a5,8
ffffffffc0201b1e:	5cf71f63          	bne	a4,a5,ffffffffc02020fc <buddy_check+0xaaa>
    test_arena_check();
ffffffffc0201b22:	a3cff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    free_pages(p[3], 4);
ffffffffc0201b26:	4591                	li	a1,4
ffffffffc0201b28:	855a                	mv	a0,s6
ffffffffc0201b2a:	09f000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    test_arena_check();
ffffffffc0201b2e:	a30ff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    free_pages(p[2], 4); /* 4 + 4 -> 8, then 8 + 8 -> 16. */
ffffffffc0201b32:	8552                	mv	a0,s4
ffffffffc0201b34:	4591                	li	a1,4
ffffffffc0201b36:	093000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    test_single_block(4, base);
ffffffffc0201b3a:	4511                	li	a0,4
ffffffffc0201b3c:	85ce                	mv	a1,s3
ffffffffc0201b3e:	f88ff0ef          	jal	ra,ffffffffc02012c6 <test_single_block>
    struct Page *large = alloc_pages(16);
ffffffffc0201b42:	4541                	li	a0,16
ffffffffc0201b44:	079000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
    assert(large == base && nr_free_pages() == 0);
ffffffffc0201b48:	58a99a63          	bne	s3,a0,ffffffffc02020dc <buddy_check+0xa8a>
ffffffffc0201b4c:	089000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc0201b50:	58051663          	bnez	a0,ffffffffc02020dc <buddy_check+0xa8a>
    test_arena_check();
ffffffffc0201b54:	a0aff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    free_pages(large, 16);
ffffffffc0201b58:	854e                	mv	a0,s3
ffffffffc0201b5a:	45c1                	li	a1,16
ffffffffc0201b5c:	06d000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    test_single_block(4, base);
ffffffffc0201b60:	85ce                	mv	a1,s3
ffffffffc0201b62:	4511                	li	a0,4
ffffffffc0201b64:	f62ff0ef          	jal	ra,ffffffffc02012c6 <test_single_block>
    cprintf("Buddy System merge test passed!\n");
ffffffffc0201b68:	00002517          	auipc	a0,0x2
ffffffffc0201b6c:	ee050513          	addi	a0,a0,-288 # ffffffffc0203a48 <etext+0xf3e>
ffffffffc0201b70:	ddcfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    test_arena_reset();
ffffffffc0201b74:	b0dfe0ef          	jal	ra,ffffffffc0200680 <test_arena_reset>
    buddy_init_memmap(test_state.base, 16);
ffffffffc0201b78:	000ab503          	ld	a0,0(s5)
ffffffffc0201b7c:	45c1                	li	a1,16
    for (size_t round = 0; round < 8; round ++) {
ffffffffc0201b7e:	4a01                	li	s4,0
    buddy_init_memmap(test_state.base, 16);
ffffffffc0201b80:	971ff0ef          	jal	ra,ffffffffc02014f0 <buddy_init_memmap>
            assert(p[i] != NULL && nr_free_pages() == 15 - i);
ffffffffc0201b84:	49c1                	li	s3,16
    for (size_t round = 0; round < 8; round ++) {
ffffffffc0201b86:	4b21                	li	s6,8
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc0201b88:	84de                	mv	s1,s7
ffffffffc0201b8a:	8d22                	mv	s10,s0
            p[i] = alloc_pages(1);
ffffffffc0201b8c:	4505                	li	a0,1
ffffffffc0201b8e:	02f000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc0201b92:	00ad3023          	sd	a0,0(s10)
ffffffffc0201b96:	8c2a                	mv	s8,a0
            assert(p[i] != NULL && nr_free_pages() == 15 - i);
ffffffffc0201b98:	6e050263          	beqz	a0,ffffffffc020227c <buddy_check+0xc2a>
ffffffffc0201b9c:	039000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc0201ba0:	409987b3          	sub	a5,s3,s1
ffffffffc0201ba4:	6cf51c63          	bne	a0,a5,ffffffffc020227c <buddy_check+0xc2a>
            for (size_t j = 0; j < i; j ++) {
ffffffffc0201ba8:	4705                	li	a4,1
ffffffffc0201baa:	87a2                	mv	a5,s0
ffffffffc0201bac:	32e48363          	beq	s1,a4,ffffffffc0201ed2 <buddy_check+0x880>
                assert(p[i] != p[j]);
ffffffffc0201bb0:	6398                	ld	a4,0(a5)
ffffffffc0201bb2:	32ec0563          	beq	s8,a4,ffffffffc0201edc <buddy_check+0x88a>
            for (size_t j = 0; j < i; j ++) {
ffffffffc0201bb6:	07a1                	addi	a5,a5,8
ffffffffc0201bb8:	fefd1ce3          	bne	s10,a5,ffffffffc0201bb0 <buddy_check+0x55e>
            test_arena_check();
ffffffffc0201bbc:	9a2ff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
        for (size_t i = 0; i < 16; i ++) {
ffffffffc0201bc0:	01348563          	beq	s1,s3,ffffffffc0201bca <buddy_check+0x578>
ffffffffc0201bc4:	0d21                	addi	s10,s10,8
ffffffffc0201bc6:	0485                	addi	s1,s1,1
ffffffffc0201bc8:	b7d1                	j	ffffffffc0201b8c <buddy_check+0x53a>
        test_failed_alloc(1);
ffffffffc0201bca:	4505                	li	a0,1
ffffffffc0201bcc:	d36ff0ef          	jal	ra,ffffffffc0201102 <test_failed_alloc>
        test_failed_alloc(2);
ffffffffc0201bd0:	4509                	li	a0,2
ffffffffc0201bd2:	d30ff0ef          	jal	ra,ffffffffc0201102 <test_failed_alloc>
ffffffffc0201bd6:	84d2                	mv	s1,s4
        for (size_t i = 0; i < 16; i ++) {
ffffffffc0201bd8:	4c01                	li	s8,0
            size_t j = (5 * i + round) % 16; /* Permutation, different each round. */
ffffffffc0201bda:	00f4f793          	andi	a5,s1,15
            free_pages(p[j], 1);
ffffffffc0201bde:	0398                	addi	a4,sp,448
ffffffffc0201be0:	078e                	slli	a5,a5,0x3
ffffffffc0201be2:	97ba                	add	a5,a5,a4
ffffffffc0201be4:	f807b503          	ld	a0,-128(a5)
ffffffffc0201be8:	4585                	li	a1,1
            assert(nr_free_pages() == i + 1);
ffffffffc0201bea:	0c05                	addi	s8,s8,1
            free_pages(p[j], 1);
ffffffffc0201bec:	7dc000ef          	jal	ra,ffffffffc02023c8 <free_pages>
            assert(nr_free_pages() == i + 1);
ffffffffc0201bf0:	7e4000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc0201bf4:	67851463          	bne	a0,s8,ffffffffc020225c <buddy_check+0xc0a>
            test_arena_check();
ffffffffc0201bf8:	966ff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
        for (size_t i = 0; i < 16; i ++) {
ffffffffc0201bfc:	0495                	addi	s1,s1,5
ffffffffc0201bfe:	fd3c1ee3          	bne	s8,s3,ffffffffc0201bda <buddy_check+0x588>
        test_single_block(4, test_state.base);
ffffffffc0201c02:	000ab583          	ld	a1,0(s5)
    for (size_t round = 0; round < 8; round ++) {
ffffffffc0201c06:	0a05                	addi	s4,s4,1
        test_single_block(4, test_state.base);
ffffffffc0201c08:	4511                	li	a0,4
ffffffffc0201c0a:	ebcff0ef          	jal	ra,ffffffffc02012c6 <test_single_block>
    for (size_t round = 0; round < 8; round ++) {
ffffffffc0201c0e:	f76a1de3          	bne	s4,s6,ffffffffc0201b88 <buddy_check+0x536>
    struct Page *base = test_state.base;
ffffffffc0201c12:	000aba83          	ld	s5,0(s5)
    for (unsigned int order = 0; order <= 1; order ++) {
ffffffffc0201c16:	4981                	li	s3,0
    return (size_t)1 << order;
ffffffffc0201c18:	4b05                	li	s6,1
        test_arena_reset();
ffffffffc0201c1a:	a67fe0ef          	jal	ra,ffffffffc0200680 <test_arena_reset>
    return (size_t)1 << order;
ffffffffc0201c1e:	013b1a33          	sll	s4,s6,s3
        buddy_init_memmap(base, block_size(order));
ffffffffc0201c22:	85d2                	mv	a1,s4
ffffffffc0201c24:	8556                	mv	a0,s5
ffffffffc0201c26:	8cbff0ef          	jal	ra,ffffffffc02014f0 <buddy_init_memmap>
        test_single_block(order, base);
ffffffffc0201c2a:	85d6                	mv	a1,s5
ffffffffc0201c2c:	854e                	mv	a0,s3
ffffffffc0201c2e:	e98ff0ef          	jal	ra,ffffffffc02012c6 <test_single_block>
        test_failed_alloc(block_size(order) + 1);
ffffffffc0201c32:	001a0513          	addi	a0,s4,1
ffffffffc0201c36:	cccff0ef          	jal	ra,ffffffffc0201102 <test_failed_alloc>
        struct Page *p = alloc_pages(block_size(order));
ffffffffc0201c3a:	8552                	mv	a0,s4
ffffffffc0201c3c:	780000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc0201c40:	84aa                	mv	s1,a0
        assert(p == base && nr_free_pages() == 0);
ffffffffc0201c42:	2caa9d63          	bne	s5,a0,ffffffffc0201f1c <buddy_check+0x8ca>
ffffffffc0201c46:	78e000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc0201c4a:	2c051963          	bnez	a0,ffffffffc0201f1c <buddy_check+0x8ca>
        test_failed_alloc(1);
ffffffffc0201c4e:	4505                	li	a0,1
ffffffffc0201c50:	cb2ff0ef          	jal	ra,ffffffffc0201102 <test_failed_alloc>
        free_pages(p, block_size(order));
ffffffffc0201c54:	85d2                	mv	a1,s4
ffffffffc0201c56:	8526                	mv	a0,s1
ffffffffc0201c58:	770000ef          	jal	ra,ffffffffc02023c8 <free_pages>
        test_single_block(order, base);
ffffffffc0201c5c:	85a6                	mv	a1,s1
ffffffffc0201c5e:	854e                	mv	a0,s3
ffffffffc0201c60:	e66ff0ef          	jal	ra,ffffffffc02012c6 <test_single_block>
    for (unsigned int order = 0; order <= 1; order ++) {
ffffffffc0201c64:	27699a63          	bne	s3,s6,ffffffffc0201ed8 <buddy_check+0x886>
    test_arena_reset();
ffffffffc0201c68:	a19fe0ef          	jal	ra,ffffffffc0200680 <test_arena_reset>
    buddy_init_memmap(base + 1, 2);
ffffffffc0201c6c:	02848993          	addi	s3,s1,40
ffffffffc0201c70:	4589                	li	a1,2
ffffffffc0201c72:	854e                	mv	a0,s3
ffffffffc0201c74:	87dff0ef          	jal	ra,ffffffffc02014f0 <buddy_init_memmap>
    assert(test_list_count(0) == 2 && nr_free_pages() == 2);
ffffffffc0201c78:	4501                	li	a0,0
ffffffffc0201c7a:	85eff0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201c7e:	4789                	li	a5,2
ffffffffc0201c80:	8a2a                	mv	s4,a0
ffffffffc0201c82:	2af51d63          	bne	a0,a5,ffffffffc0201f3c <buddy_check+0x8ea>
ffffffffc0201c86:	74e000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc0201c8a:	8aaa                	mv	s5,a0
ffffffffc0201c8c:	2b451863          	bne	a0,s4,ffffffffc0201f3c <buddy_check+0x8ea>
    test_failed_alloc(2);
ffffffffc0201c90:	c72ff0ef          	jal	ra,ffffffffc0201102 <test_failed_alloc>
    struct Page *a = alloc_pages(1), *b = alloc_pages(1);
ffffffffc0201c94:	4505                	li	a0,1
ffffffffc0201c96:	726000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc0201c9a:	8b2a                	mv	s6,a0
ffffffffc0201c9c:	4505                	li	a0,1
ffffffffc0201c9e:	71e000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc0201ca2:	8a2a                	mv	s4,a0
    assert(a != NULL && b != NULL && a != b);
ffffffffc0201ca4:	2a0b0c63          	beqz	s6,ffffffffc0201f5c <buddy_check+0x90a>
ffffffffc0201ca8:	2a050a63          	beqz	a0,ffffffffc0201f5c <buddy_check+0x90a>
ffffffffc0201cac:	2aab0863          	beq	s6,a0,ffffffffc0201f5c <buddy_check+0x90a>
    free_pages(a, 1);
ffffffffc0201cb0:	4585                	li	a1,1
ffffffffc0201cb2:	855a                	mv	a0,s6
ffffffffc0201cb4:	714000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    free_pages(b, 1);
ffffffffc0201cb8:	8552                	mv	a0,s4
ffffffffc0201cba:	4585                	li	a1,1
ffffffffc0201cbc:	70c000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    assert(test_list_count(0) == 2 && test_list_count(1) == 0);
ffffffffc0201cc0:	4501                	li	a0,0
ffffffffc0201cc2:	816ff0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201cc6:	2b551b63          	bne	a0,s5,ffffffffc0201f7c <buddy_check+0x92a>
ffffffffc0201cca:	4505                	li	a0,1
ffffffffc0201ccc:	80cff0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201cd0:	2a051663          	bnez	a0,ffffffffc0201f7c <buddy_check+0x92a>
    test_arena_check();
ffffffffc0201cd4:	88aff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    test_arena_reset();
ffffffffc0201cd8:	9a9fe0ef          	jal	ra,ffffffffc0200680 <test_arena_reset>
    buddy_init_memmap(base + 1, 13);
ffffffffc0201cdc:	45b5                	li	a1,13
ffffffffc0201cde:	854e                	mv	a0,s3
ffffffffc0201ce0:	811ff0ef          	jal	ra,ffffffffc02014f0 <buddy_init_memmap>
    assert(test_list_count(0) == 1 && test_list_count(1) == 2);
ffffffffc0201ce4:	4501                	li	a0,0
ffffffffc0201ce6:	ff3fe0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201cea:	4785                	li	a5,1
ffffffffc0201cec:	2af51863          	bne	a0,a5,ffffffffc0201f9c <buddy_check+0x94a>
ffffffffc0201cf0:	fe9fe0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201cf4:	4789                	li	a5,2
ffffffffc0201cf6:	8a2a                	mv	s4,a0
ffffffffc0201cf8:	2af51263          	bne	a0,a5,ffffffffc0201f9c <buddy_check+0x94a>
    assert(test_list_count(2) == 2 && test_list_count(3) == 0);
ffffffffc0201cfc:	fddfe0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201d00:	2b451e63          	bne	a0,s4,ffffffffc0201fbc <buddy_check+0x96a>
ffffffffc0201d04:	450d                	li	a0,3
ffffffffc0201d06:	fd3fe0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201d0a:	2a051963          	bnez	a0,ffffffffc0201fbc <buddy_check+0x96a>
    test_failed_alloc(8); /* Enough total pages, but no aligned 8-page block. */
ffffffffc0201d0e:	4521                	li	a0,8
ffffffffc0201d10:	bf2ff0ef          	jal	ra,ffffffffc0201102 <test_failed_alloc>
    test_failed_alloc(14);
ffffffffc0201d14:	4539                	li	a0,14
ffffffffc0201d16:	becff0ef          	jal	ra,ffffffffc0201102 <test_failed_alloc>
    for (size_t i = 0; i < 13; i ++) {
ffffffffc0201d1a:	1a810a93          	addi	s5,sp,424
    test_failed_alloc(14);
ffffffffc0201d1e:	8b22                	mv	s6,s0
        assert(p[i] >= base + 1 && p[i] < base + 14);
ffffffffc0201d20:	23048a13          	addi	s4,s1,560
        p[i] = alloc_pages(1);
ffffffffc0201d24:	4505                	li	a0,1
ffffffffc0201d26:	696000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc0201d2a:	00ab3023          	sd	a0,0(s6)
        assert(p[i] >= base + 1 && p[i] < base + 14);
ffffffffc0201d2e:	2b356763          	bltu	a0,s3,ffffffffc0201fdc <buddy_check+0x98a>
ffffffffc0201d32:	2b457563          	bgeu	a0,s4,ffffffffc0201fdc <buddy_check+0x98a>
    for (size_t i = 0; i < 13; i ++) {
ffffffffc0201d36:	0b21                	addi	s6,s6,8
        test_arena_check();
ffffffffc0201d38:	826ff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    for (size_t i = 0; i < 13; i ++) {
ffffffffc0201d3c:	ff6a94e3          	bne	s5,s6,ffffffffc0201d24 <buddy_check+0x6d2>
    test_failed_alloc(1);
ffffffffc0201d40:	4505                	li	a0,1
ffffffffc0201d42:	bc0ff0ef          	jal	ra,ffffffffc0201102 <test_failed_alloc>
    for (size_t i = 13; i > 0; i --) {
ffffffffc0201d46:	1a010993          	addi	s3,sp,416
        free_pages(p[i - 1], 1);
ffffffffc0201d4a:	0009b503          	ld	a0,0(s3)
ffffffffc0201d4e:	4585                	li	a1,1
ffffffffc0201d50:	678000ef          	jal	ra,ffffffffc02023c8 <free_pages>
        test_arena_check();
ffffffffc0201d54:	80aff0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    for (size_t i = 13; i > 0; i --) {
ffffffffc0201d58:	87ce                	mv	a5,s3
ffffffffc0201d5a:	19e1                	addi	s3,s3,-8
ffffffffc0201d5c:	fef417e3          	bne	s0,a5,ffffffffc0201d4a <buddy_check+0x6f8>
    assert(nr_free_pages() == 13 && test_list_count(0) == 1);
ffffffffc0201d60:	674000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc0201d64:	47b5                	li	a5,13
ffffffffc0201d66:	28f51b63          	bne	a0,a5,ffffffffc0201ffc <buddy_check+0x9aa>
ffffffffc0201d6a:	4501                	li	a0,0
ffffffffc0201d6c:	f6dfe0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201d70:	4785                	li	a5,1
ffffffffc0201d72:	28f51563          	bne	a0,a5,ffffffffc0201ffc <buddy_check+0x9aa>
    assert(test_list_count(1) == 2 && test_list_count(2) == 2);
ffffffffc0201d76:	f63fe0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201d7a:	4789                	li	a5,2
ffffffffc0201d7c:	842a                	mv	s0,a0
ffffffffc0201d7e:	28f51f63          	bne	a0,a5,ffffffffc020201c <buddy_check+0x9ca>
ffffffffc0201d82:	f57fe0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201d86:	89aa                	mv	s3,a0
ffffffffc0201d88:	28851a63          	bne	a0,s0,ffffffffc020201c <buddy_check+0x9ca>
    test_arena_reset();
ffffffffc0201d8c:	8f5fe0ef          	jal	ra,ffffffffc0200680 <test_arena_reset>
    buddy_init_memmap(base, 4);
ffffffffc0201d90:	4591                	li	a1,4
ffffffffc0201d92:	8526                	mv	a0,s1
ffffffffc0201d94:	f5cff0ef          	jal	ra,ffffffffc02014f0 <buddy_init_memmap>
    buddy_init_memmap(base + 4, 4);
ffffffffc0201d98:	4591                	li	a1,4
ffffffffc0201d9a:	0a048513          	addi	a0,s1,160
ffffffffc0201d9e:	f52ff0ef          	jal	ra,ffffffffc02014f0 <buddy_init_memmap>
    a = alloc_pages(4);
ffffffffc0201da2:	4511                	li	a0,4
ffffffffc0201da4:	618000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
ffffffffc0201da8:	842a                	mv	s0,a0
    b = alloc_pages(4);
ffffffffc0201daa:	4511                	li	a0,4
ffffffffc0201dac:	610000ef          	jal	ra,ffffffffc02023bc <alloc_pages>
    assert(a != NULL && b != NULL && a != b);
ffffffffc0201db0:	28040663          	beqz	s0,ffffffffc020203c <buddy_check+0x9ea>
ffffffffc0201db4:	28050463          	beqz	a0,ffffffffc020203c <buddy_check+0x9ea>
ffffffffc0201db8:	28a40263          	beq	s0,a0,ffffffffc020203c <buddy_check+0x9ea>
    free_pages(b, 4);
ffffffffc0201dbc:	4591                	li	a1,4
ffffffffc0201dbe:	60a000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    free_pages(a, 4);
ffffffffc0201dc2:	4591                	li	a1,4
ffffffffc0201dc4:	8522                	mv	a0,s0
ffffffffc0201dc6:	602000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    assert(nr_free_pages() == 8 && test_list_count(2) == 2);
ffffffffc0201dca:	60a000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc0201dce:	47a1                	li	a5,8
ffffffffc0201dd0:	28f51663          	bne	a0,a5,ffffffffc020205c <buddy_check+0xa0a>
ffffffffc0201dd4:	4509                	li	a0,2
ffffffffc0201dd6:	f03fe0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201dda:	29351163          	bne	a0,s3,ffffffffc020205c <buddy_check+0xa0a>
    test_failed_alloc(8);
ffffffffc0201dde:	4521                	li	a0,8
ffffffffc0201de0:	b22ff0ef          	jal	ra,ffffffffc0201102 <test_failed_alloc>
    test_failed_alloc(block_size(BUDDY_MAX_ORDER) + 1);
ffffffffc0201de4:	6521                	lui	a0,0x8
ffffffffc0201de6:	0505                	addi	a0,a0,1
ffffffffc0201de8:	b1aff0ef          	jal	ra,ffffffffc0201102 <test_failed_alloc>
    cprintf("Buddy System boundary test passed!\n");
ffffffffc0201dec:	00002517          	auipc	a0,0x2
ffffffffc0201df0:	ed450513          	addi	a0,a0,-300 # ffffffffc0203cc0 <etext+0x11b6>
ffffffffc0201df4:	b58fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    test_exhaustion_and_reuse();
    test_boundary();

    /* Saved nodes still refer to the original free_lists addresses. Restoring
     * heads in place reconnects them; copying lists to new heads would not. */
    memcpy(base, test_state.descriptors, sizeof(test_state.descriptors));
ffffffffc0201df8:	6462                	ld	s0,24(sp)
ffffffffc0201dfa:	6605                	lui	a2,0x1
ffffffffc0201dfc:	a0060613          	addi	a2,a2,-1536 # a00 <kern_entry-0xffffffffc01ff600>
ffffffffc0201e00:	00047597          	auipc	a1,0x47
ffffffffc0201e04:	f2058593          	addi	a1,a1,-224 # ffffffffc0248d20 <test_state+0x8>
ffffffffc0201e08:	8522                	mv	a0,s0
ffffffffc0201e0a:	4c5000ef          	jal	ra,ffffffffc0202ace <memcpy>
    memcpy(region + index, test_state.regions, sizeof(test_state.regions));
ffffffffc0201e0e:	7502                	ld	a0,32(sp)
ffffffffc0201e10:	10000613          	li	a2,256
ffffffffc0201e14:	00048597          	auipc	a1,0x48
ffffffffc0201e18:	90c58593          	addi	a1,a1,-1780 # ffffffffc0249720 <test_state+0xa08>
ffffffffc0201e1c:	4b3000ef          	jal	ra,ffffffffc0202ace <memcpy>
    memcpy(requested + index, test_state.requests, sizeof(test_state.requests));
ffffffffc0201e20:	7522                	ld	a0,40(sp)
ffffffffc0201e22:	10000613          	li	a2,256
ffffffffc0201e26:	00048597          	auipc	a1,0x48
ffffffffc0201e2a:	9fa58593          	addi	a1,a1,-1542 # ffffffffc0249820 <test_state+0xb08>
ffffffffc0201e2e:	4a1000ef          	jal	ra,ffffffffc0202ace <memcpy>
    memcpy(free_lists, test_state.heads, sizeof(free_lists));
ffffffffc0201e32:	10000613          	li	a2,256
ffffffffc0201e36:	00048597          	auipc	a1,0x48
ffffffffc0201e3a:	aea58593          	addi	a1,a1,-1302 # ffffffffc0249920 <test_state+0xc08>
ffffffffc0201e3e:	00007517          	auipc	a0,0x7
ffffffffc0201e42:	bda50513          	addi	a0,a0,-1062 # ffffffffc0208a18 <free_lists>
ffffffffc0201e46:	489000ef          	jal	ra,ffffffffc0202ace <memcpy>
    nr_free = test_state.saved_free;
ffffffffc0201e4a:	00048797          	auipc	a5,0x48
ffffffffc0201e4e:	ece78793          	addi	a5,a5,-306 # ffffffffc0249d18 <end+0x2a0>
ffffffffc0201e52:	d087b783          	ld	a5,-760(a5)
ffffffffc0201e56:	00048717          	auipc	a4,0x48
ffffffffc0201e5a:	bef73523          	sd	a5,-1046(a4) # ffffffffc0249a40 <nr_free>
    check_lists();
ffffffffc0201e5e:	8adfe0ef          	jal	ra,ffffffffc020070a <check_lists>
    free_pages(base, TEST_PAGES);
ffffffffc0201e62:	04000593          	li	a1,64
ffffffffc0201e66:	8522                	mv	a0,s0
ffffffffc0201e68:	560000ef          	jal	ra,ffffffffc02023c8 <free_pages>
    assert(nr_free_pages() == original);
ffffffffc0201e6c:	568000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc0201e70:	67c2                	ld	a5,16(sp)
ffffffffc0201e72:	20f51563          	bne	a0,a5,ffffffffc020207c <buddy_check+0xa2a>
    check_lists();
ffffffffc0201e76:	895fe0ef          	jal	ra,ffffffffc020070a <check_lists>
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc0201e7a:	4401                	li	s0,0
ffffffffc0201e7c:	44c1                	li	s1,16
        assert(test_list_count(order) == original_counts[order]);
ffffffffc0201e7e:	8522                	mv	a0,s0
ffffffffc0201e80:	e59fe0ef          	jal	ra,ffffffffc0200cd8 <test_list_count>
ffffffffc0201e84:	00093783          	ld	a5,0(s2)
ffffffffc0201e88:	20f51a63          	bne	a0,a5,ffffffffc020209c <buddy_check+0xa4a>
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order ++) {
ffffffffc0201e8c:	2405                	addiw	s0,s0,1
ffffffffc0201e8e:	0921                	addi	s2,s2,8
ffffffffc0201e90:	fe9417e3          	bne	s0,s1,ffffffffc0201e7e <buddy_check+0x82c>
    }
    test_state.base = NULL;
    cprintf("Buddy System all tests passed!\n");
ffffffffc0201e94:	00002517          	auipc	a0,0x2
ffffffffc0201e98:	e8c50513          	addi	a0,a0,-372 # ffffffffc0203d20 <etext+0x1216>
    test_state.base = NULL;
ffffffffc0201e9c:	00047797          	auipc	a5,0x47
ffffffffc0201ea0:	e607be23          	sd	zero,-388(a5) # ffffffffc0248d18 <test_state>
}
ffffffffc0201ea4:	22013403          	ld	s0,544(sp)
ffffffffc0201ea8:	22813083          	ld	ra,552(sp)
ffffffffc0201eac:	21813483          	ld	s1,536(sp)
ffffffffc0201eb0:	21013903          	ld	s2,528(sp)
ffffffffc0201eb4:	20813983          	ld	s3,520(sp)
ffffffffc0201eb8:	20013a03          	ld	s4,512(sp)
ffffffffc0201ebc:	7afe                	ld	s5,504(sp)
ffffffffc0201ebe:	7b5e                	ld	s6,496(sp)
ffffffffc0201ec0:	7bbe                	ld	s7,488(sp)
ffffffffc0201ec2:	7c1e                	ld	s8,480(sp)
ffffffffc0201ec4:	6cfe                	ld	s9,472(sp)
ffffffffc0201ec6:	6d5e                	ld	s10,464(sp)
ffffffffc0201ec8:	6dbe                	ld	s11,456(sp)
ffffffffc0201eca:	23010113          	addi	sp,sp,560
    cprintf("Buddy System all tests passed!\n");
ffffffffc0201ece:	a7efe06f          	j	ffffffffc020014c <cprintf>
            test_arena_check();
ffffffffc0201ed2:	e8dfe0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
        for (size_t i = 0; i < 16; i ++) {
ffffffffc0201ed6:	b1fd                	j	ffffffffc0201bc4 <buddy_check+0x572>
ffffffffc0201ed8:	4985                	li	s3,1
ffffffffc0201eda:	b381                	j	ffffffffc0201c1a <buddy_check+0x5c8>
                assert(p[i] != p[j]);
ffffffffc0201edc:	00002697          	auipc	a3,0x2
ffffffffc0201ee0:	bc468693          	addi	a3,a3,-1084 # ffffffffc0203aa0 <etext+0xf96>
ffffffffc0201ee4:	00001617          	auipc	a2,0x1
ffffffffc0201ee8:	ec460613          	addi	a2,a2,-316 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201eec:	1a500593          	li	a1,421
ffffffffc0201ef0:	00001517          	auipc	a0,0x1
ffffffffc0201ef4:	ed050513          	addi	a0,a0,-304 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201ef8:	acafe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        test_arena_check();
ffffffffc0201efc:	e63fe0ef          	jal	ra,ffffffffc0200d5e <test_arena_check>
    for (size_t i = 0; i < 7; i ++) {
ffffffffc0201f00:	989ff06f          	j	ffffffffc0201888 <buddy_check+0x236>
        assert(nr_free_pages() == original);
ffffffffc0201f04:	4d0000ef          	jal	ra,ffffffffc02023d4 <nr_free_pages>
ffffffffc0201f08:	67c2                	ld	a5,16(sp)
ffffffffc0201f0a:	1af51963          	bne	a0,a5,ffffffffc02020bc <buddy_check+0xa6a>
        check_lists();
ffffffffc0201f0e:	ffcfe0ef          	jal	ra,ffffffffc020070a <check_lists>
        cprintf("Buddy System tests skipped: no 64-page test block available.\n");
ffffffffc0201f12:	00001517          	auipc	a0,0x1
ffffffffc0201f16:	6de50513          	addi	a0,a0,1758 # ffffffffc02035f0 <etext+0xae6>
ffffffffc0201f1a:	b769                	j	ffffffffc0201ea4 <buddy_check+0x852>
        assert(p == base && nr_free_pages() == 0);
ffffffffc0201f1c:	00002697          	auipc	a3,0x2
ffffffffc0201f20:	bb468693          	addi	a3,a3,-1100 # ffffffffc0203ad0 <etext+0xfc6>
ffffffffc0201f24:	00001617          	auipc	a2,0x1
ffffffffc0201f28:	e8460613          	addi	a2,a2,-380 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201f2c:	1be00593          	li	a1,446
ffffffffc0201f30:	00001517          	auipc	a0,0x1
ffffffffc0201f34:	e9050513          	addi	a0,a0,-368 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201f38:	a8afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(test_list_count(0) == 2 && nr_free_pages() == 2);
ffffffffc0201f3c:	00002697          	auipc	a3,0x2
ffffffffc0201f40:	bbc68693          	addi	a3,a3,-1092 # ffffffffc0203af8 <etext+0xfee>
ffffffffc0201f44:	00001617          	auipc	a2,0x1
ffffffffc0201f48:	e6460613          	addi	a2,a2,-412 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201f4c:	1c600593          	li	a1,454
ffffffffc0201f50:	00001517          	auipc	a0,0x1
ffffffffc0201f54:	e7050513          	addi	a0,a0,-400 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201f58:	a6afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(a != NULL && b != NULL && a != b);
ffffffffc0201f5c:	00002697          	auipc	a3,0x2
ffffffffc0201f60:	bcc68693          	addi	a3,a3,-1076 # ffffffffc0203b28 <etext+0x101e>
ffffffffc0201f64:	00001617          	auipc	a2,0x1
ffffffffc0201f68:	e4460613          	addi	a2,a2,-444 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201f6c:	1c900593          	li	a1,457
ffffffffc0201f70:	00001517          	auipc	a0,0x1
ffffffffc0201f74:	e5050513          	addi	a0,a0,-432 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201f78:	a4afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(test_list_count(0) == 2 && test_list_count(1) == 0);
ffffffffc0201f7c:	00002697          	auipc	a3,0x2
ffffffffc0201f80:	bd468693          	addi	a3,a3,-1068 # ffffffffc0203b50 <etext+0x1046>
ffffffffc0201f84:	00001617          	auipc	a2,0x1
ffffffffc0201f88:	e2460613          	addi	a2,a2,-476 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201f8c:	1cc00593          	li	a1,460
ffffffffc0201f90:	00001517          	auipc	a0,0x1
ffffffffc0201f94:	e3050513          	addi	a0,a0,-464 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201f98:	a2afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(test_list_count(0) == 1 && test_list_count(1) == 2);
ffffffffc0201f9c:	00002697          	auipc	a3,0x2
ffffffffc0201fa0:	bec68693          	addi	a3,a3,-1044 # ffffffffc0203b88 <etext+0x107e>
ffffffffc0201fa4:	00001617          	auipc	a2,0x1
ffffffffc0201fa8:	e0460613          	addi	a2,a2,-508 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201fac:	1d100593          	li	a1,465
ffffffffc0201fb0:	00001517          	auipc	a0,0x1
ffffffffc0201fb4:	e1050513          	addi	a0,a0,-496 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201fb8:	a0afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(test_list_count(2) == 2 && test_list_count(3) == 0);
ffffffffc0201fbc:	00002697          	auipc	a3,0x2
ffffffffc0201fc0:	c0468693          	addi	a3,a3,-1020 # ffffffffc0203bc0 <etext+0x10b6>
ffffffffc0201fc4:	00001617          	auipc	a2,0x1
ffffffffc0201fc8:	de460613          	addi	a2,a2,-540 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201fcc:	1d200593          	li	a1,466
ffffffffc0201fd0:	00001517          	auipc	a0,0x1
ffffffffc0201fd4:	df050513          	addi	a0,a0,-528 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201fd8:	9eafe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(p[i] >= base + 1 && p[i] < base + 14);
ffffffffc0201fdc:	00002697          	auipc	a3,0x2
ffffffffc0201fe0:	c1c68693          	addi	a3,a3,-996 # ffffffffc0203bf8 <etext+0x10ee>
ffffffffc0201fe4:	00001617          	auipc	a2,0x1
ffffffffc0201fe8:	dc460613          	addi	a2,a2,-572 # ffffffffc0202da8 <etext+0x29e>
ffffffffc0201fec:	1d800593          	li	a1,472
ffffffffc0201ff0:	00001517          	auipc	a0,0x1
ffffffffc0201ff4:	dd050513          	addi	a0,a0,-560 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0201ff8:	9cafe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == 13 && test_list_count(0) == 1);
ffffffffc0201ffc:	00002697          	auipc	a3,0x2
ffffffffc0202000:	c2468693          	addi	a3,a3,-988 # ffffffffc0203c20 <etext+0x1116>
ffffffffc0202004:	00001617          	auipc	a2,0x1
ffffffffc0202008:	da460613          	addi	a2,a2,-604 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020200c:	1e000593          	li	a1,480
ffffffffc0202010:	00001517          	auipc	a0,0x1
ffffffffc0202014:	db050513          	addi	a0,a0,-592 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202018:	9aafe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(test_list_count(1) == 2 && test_list_count(2) == 2);
ffffffffc020201c:	00002697          	auipc	a3,0x2
ffffffffc0202020:	c3c68693          	addi	a3,a3,-964 # ffffffffc0203c58 <etext+0x114e>
ffffffffc0202024:	00001617          	auipc	a2,0x1
ffffffffc0202028:	d8460613          	addi	a2,a2,-636 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020202c:	1e100593          	li	a1,481
ffffffffc0202030:	00001517          	auipc	a0,0x1
ffffffffc0202034:	d9050513          	addi	a0,a0,-624 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202038:	98afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(a != NULL && b != NULL && a != b);
ffffffffc020203c:	00002697          	auipc	a3,0x2
ffffffffc0202040:	aec68693          	addi	a3,a3,-1300 # ffffffffc0203b28 <etext+0x101e>
ffffffffc0202044:	00001617          	auipc	a2,0x1
ffffffffc0202048:	d6460613          	addi	a2,a2,-668 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020204c:	1e800593          	li	a1,488
ffffffffc0202050:	00001517          	auipc	a0,0x1
ffffffffc0202054:	d7050513          	addi	a0,a0,-656 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202058:	96afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == 8 && test_list_count(2) == 2);
ffffffffc020205c:	00002697          	auipc	a3,0x2
ffffffffc0202060:	c3468693          	addi	a3,a3,-972 # ffffffffc0203c90 <etext+0x1186>
ffffffffc0202064:	00001617          	auipc	a2,0x1
ffffffffc0202068:	d4460613          	addi	a2,a2,-700 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020206c:	1eb00593          	li	a1,491
ffffffffc0202070:	00001517          	auipc	a0,0x1
ffffffffc0202074:	d5050513          	addi	a0,a0,-688 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202078:	94afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == original);
ffffffffc020207c:	00001697          	auipc	a3,0x1
ffffffffc0202080:	55468693          	addi	a3,a3,1364 # ffffffffc02035d0 <etext+0xac6>
ffffffffc0202084:	00001617          	auipc	a2,0x1
ffffffffc0202088:	d2460613          	addi	a2,a2,-732 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020208c:	21a00593          	li	a1,538
ffffffffc0202090:	00001517          	auipc	a0,0x1
ffffffffc0202094:	d3050513          	addi	a0,a0,-720 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202098:	92afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(test_list_count(order) == original_counts[order]);
ffffffffc020209c:	00002697          	auipc	a3,0x2
ffffffffc02020a0:	c4c68693          	addi	a3,a3,-948 # ffffffffc0203ce8 <etext+0x11de>
ffffffffc02020a4:	00001617          	auipc	a2,0x1
ffffffffc02020a8:	d0460613          	addi	a2,a2,-764 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02020ac:	21d00593          	li	a1,541
ffffffffc02020b0:	00001517          	auipc	a0,0x1
ffffffffc02020b4:	d1050513          	addi	a0,a0,-752 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02020b8:	90afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(nr_free_pages() == original);
ffffffffc02020bc:	00001697          	auipc	a3,0x1
ffffffffc02020c0:	51468693          	addi	a3,a3,1300 # ffffffffc02035d0 <etext+0xac6>
ffffffffc02020c4:	00001617          	auipc	a2,0x1
ffffffffc02020c8:	ce460613          	addi	a2,a2,-796 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02020cc:	1fe00593          	li	a1,510
ffffffffc02020d0:	00001517          	auipc	a0,0x1
ffffffffc02020d4:	cf050513          	addi	a0,a0,-784 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02020d8:	8eafe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(large == base && nr_free_pages() == 0);
ffffffffc02020dc:	00002697          	auipc	a3,0x2
ffffffffc02020e0:	94468693          	addi	a3,a3,-1724 # ffffffffc0203a20 <etext+0xf16>
ffffffffc02020e4:	00001617          	auipc	a2,0x1
ffffffffc02020e8:	cc460613          	addi	a2,a2,-828 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02020ec:	19400593          	li	a1,404
ffffffffc02020f0:	00001517          	auipc	a0,0x1
ffffffffc02020f4:	cd050513          	addi	a0,a0,-816 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02020f8:	8cafe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(base) && base->property == 8);
ffffffffc02020fc:	00002697          	auipc	a3,0x2
ffffffffc0202100:	8f468693          	addi	a3,a3,-1804 # ffffffffc02039f0 <etext+0xee6>
ffffffffc0202104:	00001617          	auipc	a2,0x1
ffffffffc0202108:	ca460613          	addi	a2,a2,-860 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020210c:	18d00593          	li	a1,397
ffffffffc0202110:	00001517          	auipc	a0,0x1
ffffffffc0202114:	cb050513          	addi	a0,a0,-848 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202118:	8aafe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(test_list_count(2) == 0 && test_list_count(3) == 1);
ffffffffc020211c:	00002697          	auipc	a3,0x2
ffffffffc0202120:	89c68693          	addi	a3,a3,-1892 # ffffffffc02039b8 <etext+0xeae>
ffffffffc0202124:	00001617          	auipc	a2,0x1
ffffffffc0202128:	c8460613          	addi	a2,a2,-892 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020212c:	18c00593          	li	a1,396
ffffffffc0202130:	00001517          	auipc	a0,0x1
ffffffffc0202134:	c9050513          	addi	a0,a0,-880 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202138:	88afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(test_list_count(2) == 1 && test_list_count(3) == 0);
ffffffffc020213c:	00002697          	auipc	a3,0x2
ffffffffc0202140:	84468693          	addi	a3,a3,-1980 # ffffffffc0203980 <etext+0xe76>
ffffffffc0202144:	00001617          	auipc	a2,0x1
ffffffffc0202148:	c6460613          	addi	a2,a2,-924 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020214c:	18900593          	li	a1,393
ffffffffc0202150:	00001517          	auipc	a0,0x1
ffffffffc0202154:	c7050513          	addi	a0,a0,-912 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202158:	86afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((page2ppn(p[2]) ^ 4) == page2ppn(p[3]));
ffffffffc020215c:	00001697          	auipc	a3,0x1
ffffffffc0202160:	7fc68693          	addi	a3,a3,2044 # ffffffffc0203958 <etext+0xe4e>
ffffffffc0202164:	00001617          	auipc	a2,0x1
ffffffffc0202168:	c4460613          	addi	a2,a2,-956 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020216c:	18600593          	li	a1,390
ffffffffc0202170:	00001517          	auipc	a0,0x1
ffffffffc0202174:	c5050513          	addi	a0,a0,-944 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202178:	84afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((page2ppn(p[0]) ^ 4) == page2ppn(p[1]));
ffffffffc020217c:	00001697          	auipc	a3,0x1
ffffffffc0202180:	7b468693          	addi	a3,a3,1972 # ffffffffc0203930 <etext+0xe26>
ffffffffc0202184:	00001617          	auipc	a2,0x1
ffffffffc0202188:	c2460613          	addi	a2,a2,-988 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020218c:	18500593          	li	a1,389
ffffffffc0202190:	00001517          	auipc	a0,0x1
ffffffffc0202194:	c3050513          	addi	a0,a0,-976 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202198:	82afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(p[i] == base + 4 * i);
ffffffffc020219c:	00001697          	auipc	a3,0x1
ffffffffc02021a0:	77c68693          	addi	a3,a3,1916 # ffffffffc0203918 <etext+0xe0e>
ffffffffc02021a4:	00001617          	auipc	a2,0x1
ffffffffc02021a8:	c0460613          	addi	a2,a2,-1020 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02021ac:	18300593          	li	a1,387
ffffffffc02021b0:	00001517          	auipc	a0,0x1
ffffffffc02021b4:	c1050513          	addi	a0,a0,-1008 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02021b8:	80afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == 0);
ffffffffc02021bc:	00001697          	auipc	a3,0x1
ffffffffc02021c0:	71c68693          	addi	a3,a3,1820 # ffffffffc02038d8 <etext+0xdce>
ffffffffc02021c4:	00001617          	auipc	a2,0x1
ffffffffc02021c8:	be460613          	addi	a2,a2,-1052 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02021cc:	17100593          	li	a1,369
ffffffffc02021d0:	00001517          	auipc	a0,0x1
ffffffffc02021d4:	bf050513          	addi	a0,a0,-1040 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02021d8:	febfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert((page2pa(p) & (actual[i] * PGSIZE - 1)) == 0);
ffffffffc02021dc:	00001697          	auipc	a3,0x1
ffffffffc02021e0:	53468693          	addi	a3,a3,1332 # ffffffffc0203710 <etext+0xc06>
ffffffffc02021e4:	00001617          	auipc	a2,0x1
ffffffffc02021e8:	bc460613          	addi	a2,a2,-1084 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02021ec:	14900593          	li	a1,329
ffffffffc02021f0:	00001517          	auipc	a0,0x1
ffffffffc02021f4:	bd050513          	addi	a0,a0,-1072 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02021f8:	fcbfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(p != NULL);
ffffffffc02021fc:	00001697          	auipc	a3,0x1
ffffffffc0202200:	43468693          	addi	a3,a3,1076 # ffffffffc0203630 <etext+0xb26>
ffffffffc0202204:	00001617          	auipc	a2,0x1
ffffffffc0202208:	ba460613          	addi	a2,a2,-1116 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020220c:	14300593          	li	a1,323
ffffffffc0202210:	00001517          	auipc	a0,0x1
ffffffffc0202214:	bb050513          	addi	a0,a0,-1104 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202218:	fabfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(index + actual[i] <= page_index(test_state.base) + TEST_PAGES);
ffffffffc020221c:	00001697          	auipc	a3,0x1
ffffffffc0202220:	44c68693          	addi	a3,a3,1100 # ffffffffc0203668 <etext+0xb5e>
ffffffffc0202224:	00001617          	auipc	a2,0x1
ffffffffc0202228:	b8460613          	addi	a2,a2,-1148 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020222c:	14600593          	li	a1,326
ffffffffc0202230:	00001517          	auipc	a0,0x1
ffffffffc0202234:	b9050513          	addi	a0,a0,-1136 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202238:	f8bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(index >= page_index(test_state.base));
ffffffffc020223c:	00001697          	auipc	a3,0x1
ffffffffc0202240:	40468693          	addi	a3,a3,1028 # ffffffffc0203640 <etext+0xb36>
ffffffffc0202244:	00001617          	auipc	a2,0x1
ffffffffc0202248:	b6460613          	addi	a2,a2,-1180 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020224c:	14500593          	li	a1,325
ffffffffc0202250:	00001517          	auipc	a0,0x1
ffffffffc0202254:	b7050513          	addi	a0,a0,-1168 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202258:	f6bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(nr_free_pages() == i + 1);
ffffffffc020225c:	00002697          	auipc	a3,0x2
ffffffffc0202260:	85468693          	addi	a3,a3,-1964 # ffffffffc0203ab0 <etext+0xfa6>
ffffffffc0202264:	00001617          	auipc	a2,0x1
ffffffffc0202268:	b4460613          	addi	a2,a2,-1212 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020226c:	1ae00593          	li	a1,430
ffffffffc0202270:	00001517          	auipc	a0,0x1
ffffffffc0202274:	b5050513          	addi	a0,a0,-1200 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202278:	f4bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(p[i] != NULL && nr_free_pages() == 15 - i);
ffffffffc020227c:	00001697          	auipc	a3,0x1
ffffffffc0202280:	7f468693          	addi	a3,a3,2036 # ffffffffc0203a70 <etext+0xf66>
ffffffffc0202284:	00001617          	auipc	a2,0x1
ffffffffc0202288:	b2460613          	addi	a2,a2,-1244 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020228c:	1a300593          	li	a1,419
ffffffffc0202290:	00001517          	auipc	a0,0x1
ffffffffc0202294:	b3050513          	addi	a0,a0,-1232 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202298:	f2bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(before - nr_free_pages() == actual[i]);
ffffffffc020229c:	00001697          	auipc	a3,0x1
ffffffffc02022a0:	44c68693          	addi	a3,a3,1100 # ffffffffc02036e8 <etext+0xbde>
ffffffffc02022a4:	00001617          	auipc	a2,0x1
ffffffffc02022a8:	b0460613          	addi	a2,a2,-1276 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02022ac:	14800593          	li	a1,328
ffffffffc02022b0:	00001517          	auipc	a0,0x1
ffffffffc02022b4:	b1050513          	addi	a0,a0,-1264 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02022b8:	f0bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(p->property == actual[i] && requested[index] == counts[i]);
ffffffffc02022bc:	00001697          	auipc	a3,0x1
ffffffffc02022c0:	3ec68693          	addi	a3,a3,1004 # ffffffffc02036a8 <etext+0xb9e>
ffffffffc02022c4:	00001617          	auipc	a2,0x1
ffffffffc02022c8:	ae460613          	addi	a2,a2,-1308 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02022cc:	14700593          	li	a1,327
ffffffffc02022d0:	00001517          	auipc	a0,0x1
ffffffffc02022d4:	af050513          	addi	a0,a0,-1296 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02022d8:	eebfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(two == base + 2 && last == base + 1);
ffffffffc02022dc:	00001697          	auipc	a3,0x1
ffffffffc02022e0:	5d468693          	addi	a3,a3,1492 # ffffffffc02038b0 <etext+0xda6>
ffffffffc02022e4:	00001617          	auipc	a2,0x1
ffffffffc02022e8:	ac460613          	addi	a2,a2,-1340 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02022ec:	17000593          	li	a1,368
ffffffffc02022f0:	00001517          	auipc	a0,0x1
ffffffffc02022f4:	ad050513          	addi	a0,a0,-1328 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02022f8:	ecbfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(eight == base + 8 && four == base + 4);
ffffffffc02022fc:	00001697          	auipc	a3,0x1
ffffffffc0202300:	58c68693          	addi	a3,a3,1420 # ffffffffc0203888 <etext+0xd7e>
ffffffffc0202304:	00001617          	auipc	a2,0x1
ffffffffc0202308:	aa460613          	addi	a2,a2,-1372 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020230c:	16f00593          	li	a1,367
ffffffffc0202310:	00001517          	auipc	a0,0x1
ffffffffc0202314:	ab050513          	addi	a0,a0,-1360 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202318:	eabfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(p == base + block_size(order));
ffffffffc020231c:	00001697          	auipc	a3,0x1
ffffffffc0202320:	51468693          	addi	a3,a3,1300 # ffffffffc0203830 <etext+0xd26>
ffffffffc0202324:	00001617          	auipc	a2,0x1
ffffffffc0202328:	a8460613          	addi	a2,a2,-1404 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020232c:	16800593          	li	a1,360
ffffffffc0202330:	00001517          	auipc	a0,0x1
ffffffffc0202334:	a9050513          	addi	a0,a0,-1392 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202338:	e8bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(test_list_count(order) == (order < 4 ? 1 : 0));
ffffffffc020233c:	00001697          	auipc	a3,0x1
ffffffffc0202340:	4c468693          	addi	a3,a3,1220 # ffffffffc0203800 <etext+0xcf6>
ffffffffc0202344:	00001617          	auipc	a2,0x1
ffffffffc0202348:	a6460613          	addi	a2,a2,-1436 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020234c:	16500593          	li	a1,357
ffffffffc0202350:	00001517          	auipc	a0,0x1
ffffffffc0202354:	a7050513          	addi	a0,a0,-1424 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202358:	e6bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(one == base && nr_free_pages() == 15);
ffffffffc020235c:	00001697          	auipc	a3,0x1
ffffffffc0202360:	47c68693          	addi	a3,a3,1148 # ffffffffc02037d8 <etext+0xcce>
ffffffffc0202364:	00001617          	auipc	a2,0x1
ffffffffc0202368:	a4460613          	addi	a2,a2,-1468 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020236c:	16300593          	li	a1,355
ffffffffc0202370:	00001517          	auipc	a0,0x1
ffffffffc0202374:	a5050513          	addi	a0,a0,-1456 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202378:	e4bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(nr_free_pages() - before == actual[j]);
ffffffffc020237c:	00001697          	auipc	a3,0x1
ffffffffc0202380:	40468693          	addi	a3,a3,1028 # ffffffffc0203780 <etext+0xc76>
ffffffffc0202384:	00001617          	auipc	a2,0x1
ffffffffc0202388:	a2460613          	addi	a2,a2,-1500 # ffffffffc0202da8 <etext+0x29e>
ffffffffc020238c:	15500593          	li	a1,341
ffffffffc0202390:	00001517          	auipc	a0,0x1
ffffffffc0202394:	a3050513          	addi	a0,a0,-1488 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc0202398:	e2bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(p + actual[i] <= allocated[j] || allocated[j] + actual[j] <= p);
ffffffffc020239c:	00001697          	auipc	a3,0x1
ffffffffc02023a0:	3a468693          	addi	a3,a3,932 # ffffffffc0203740 <etext+0xc36>
ffffffffc02023a4:	00001617          	auipc	a2,0x1
ffffffffc02023a8:	a0460613          	addi	a2,a2,-1532 # ffffffffc0202da8 <etext+0x29e>
ffffffffc02023ac:	14b00593          	li	a1,331
ffffffffc02023b0:	00001517          	auipc	a0,0x1
ffffffffc02023b4:	a1050513          	addi	a0,a0,-1520 # ffffffffc0202dc0 <etext+0x2b6>
ffffffffc02023b8:	e0bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02023bc <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc02023bc:	00047797          	auipc	a5,0x47
ffffffffc02023c0:	69c7b783          	ld	a5,1692(a5) # ffffffffc0249a58 <pmm_manager>
ffffffffc02023c4:	6f9c                	ld	a5,24(a5)
ffffffffc02023c6:	8782                	jr	a5

ffffffffc02023c8 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc02023c8:	00047797          	auipc	a5,0x47
ffffffffc02023cc:	6907b783          	ld	a5,1680(a5) # ffffffffc0249a58 <pmm_manager>
ffffffffc02023d0:	739c                	ld	a5,32(a5)
ffffffffc02023d2:	8782                	jr	a5

ffffffffc02023d4 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc02023d4:	00047797          	auipc	a5,0x47
ffffffffc02023d8:	6847b783          	ld	a5,1668(a5) # ffffffffc0249a58 <pmm_manager>
ffffffffc02023dc:	779c                	ld	a5,40(a5)
ffffffffc02023de:	8782                	jr	a5

ffffffffc02023e0 <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc02023e0:	00002797          	auipc	a5,0x2
ffffffffc02023e4:	9e878793          	addi	a5,a5,-1560 # ffffffffc0203dc8 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02023e8:	638c                	ld	a1,0(a5)




/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02023ea:	715d                	addi	sp,sp,-80
ffffffffc02023ec:	e0a2                	sd	s0,64(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02023ee:	00002517          	auipc	a0,0x2
ffffffffc02023f2:	a1250513          	addi	a0,a0,-1518 # ffffffffc0203e00 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager;
ffffffffc02023f6:	00047417          	auipc	s0,0x47
ffffffffc02023fa:	66240413          	addi	s0,s0,1634 # ffffffffc0249a58 <pmm_manager>
void pmm_init(void) {
ffffffffc02023fe:	e486                	sd	ra,72(sp)
ffffffffc0202400:	fc26                	sd	s1,56(sp)
ffffffffc0202402:	f84a                	sd	s2,48(sp)
ffffffffc0202404:	f44e                	sd	s3,40(sp)
ffffffffc0202406:	f052                	sd	s4,32(sp)
ffffffffc0202408:	ec56                	sd	s5,24(sp)
ffffffffc020240a:	e85a                	sd	s6,16(sp)
ffffffffc020240c:	e45e                	sd	s7,8(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc020240e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202410:	d3dfd0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0202414:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202416:	00047497          	auipc	s1,0x47
ffffffffc020241a:	65a48493          	addi	s1,s1,1626 # ffffffffc0249a70 <va_pa_offset>
    pmm_manager->init();
ffffffffc020241e:	679c                	ld	a5,8(a5)
ffffffffc0202420:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202422:	57f5                	li	a5,-3
ffffffffc0202424:	07fa                	slli	a5,a5,0x1e
ffffffffc0202426:	e09c                	sd	a5,0(s1)
    uint64_t mem_base = get_memory_base();
ffffffffc0202428:	994fe0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc020242c:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020242e:	998fe0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_base == 0 || mem_size == 0) {
ffffffffc0202432:	16090b63          	beqz	s2,ffffffffc02025a8 <pmm_init+0x1c8>
ffffffffc0202436:	8a2a                	mv	s4,a0
ffffffffc0202438:	16050863          	beqz	a0,ffffffffc02025a8 <pmm_init+0x1c8>
    uint64_t detected_mem_end = mem_base + mem_size;
ffffffffc020243c:	00a90ab3          	add	s5,s2,a0
    if (detected_mem_end < mem_base) {
ffffffffc0202440:	192aec63          	bltu	s5,s2,ffffffffc02025d8 <pmm_init+0x1f8>
    maxpa = ROUNDDOWN(maxpa, PGSIZE);
ffffffffc0202444:	47c5                	li	a5,17
ffffffffc0202446:	07ee                	slli	a5,a5,0x1b
ffffffffc0202448:	89d6                	mv	s3,s5
ffffffffc020244a:	1157ec63          	bltu	a5,s5,ffffffffc0202562 <pmm_init+0x182>
    if (mem_base > KERNEL_BEGIN_PADDR || maxpa <= KERNEL_BEGIN_PADDR) {
ffffffffc020244e:	40100713          	li	a4,1025
    maxpa = ROUNDDOWN(maxpa, PGSIZE);
ffffffffc0202452:	7b7d                	lui	s6,0xfffff
    if (mem_base > KERNEL_BEGIN_PADDR || maxpa <= KERNEL_BEGIN_PADDR) {
ffffffffc0202454:	0756                	slli	a4,a4,0x15
    maxpa = ROUNDDOWN(maxpa, PGSIZE);
ffffffffc0202456:	0169f9b3          	and	s3,s3,s6
    if (mem_base > KERNEL_BEGIN_PADDR || maxpa <= KERNEL_BEGIN_PADDR) {
ffffffffc020245a:	13276b63          	bltu	a4,s2,ffffffffc0202590 <pmm_init+0x1b0>
ffffffffc020245e:	13377963          	bgeu	a4,s3,ffffffffc0202590 <pmm_init+0x1b0>
    npage = PPN(maxpa);
ffffffffc0202462:	00c9d793          	srli	a5,s3,0xc
ffffffffc0202466:	00047b97          	auipc	s7,0x47
ffffffffc020246a:	5e2b8b93          	addi	s7,s7,1506 # ffffffffc0249a48 <npage>
    cprintf("physical memory map:\n");
ffffffffc020246e:	00002517          	auipc	a0,0x2
ffffffffc0202472:	a3a50513          	addi	a0,a0,-1478 # ffffffffc0203ea8 <buddy_pmm_manager+0xe0>
    npage = PPN(maxpa);
ffffffffc0202476:	00fbb023          	sd	a5,0(s7)
    cprintf("physical memory map:\n");
ffffffffc020247a:	cd3fd0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n",
ffffffffc020247e:	864a                	mv	a2,s2
ffffffffc0202480:	fffa8693          	addi	a3,s5,-1
ffffffffc0202484:	85d2                	mv	a1,s4
ffffffffc0202486:	00002517          	auipc	a0,0x2
ffffffffc020248a:	a3a50513          	addi	a0,a0,-1478 # ffffffffc0203ec0 <buddy_pmm_manager+0xf8>
ffffffffc020248e:	cbffd0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t page_count = npage - nbase;
ffffffffc0202492:	000bb803          	ld	a6,0(s7)
ffffffffc0202496:	fff80737          	lui	a4,0xfff80
ffffffffc020249a:	00048797          	auipc	a5,0x48
ffffffffc020249e:	5dd78793          	addi	a5,a5,1501 # ffffffffc024aa77 <end+0xfff>
ffffffffc02024a2:	9742                	add	a4,a4,a6
    uintptr_t pages_end_va = (uintptr_t)(pages + page_count);
ffffffffc02024a4:	00271693          	slli	a3,a4,0x2
ffffffffc02024a8:	0167f7b3          	and	a5,a5,s6
ffffffffc02024ac:	96ba                	add	a3,a3,a4
ffffffffc02024ae:	068e                	slli	a3,a3,0x3
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc02024b0:	00047617          	auipc	a2,0x47
ffffffffc02024b4:	5af63023          	sd	a5,1440(a2) # ffffffffc0249a50 <pages>
    uintptr_t pages_end_va = (uintptr_t)(pages + page_count);
ffffffffc02024b8:	96be                	add	a3,a3,a5
    uintptr_t pages_end_pa = PADDR(pages_end_va);
ffffffffc02024ba:	c0200637          	lui	a2,0xc0200
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc02024be:	853e                	mv	a0,a5
    uintptr_t pages_end_pa = PADDR(pages_end_va);
ffffffffc02024c0:	10c6e063          	bltu	a3,a2,ffffffffc02025c0 <pmm_init+0x1e0>
ffffffffc02024c4:	6090                	ld	a2,0(s1)
ffffffffc02024c6:	8e91                	sub	a3,a3,a2
    if (pages_end_pa > maxpa) {
ffffffffc02024c8:	12d9e463          	bltu	s3,a3,ffffffffc02025f0 <pmm_init+0x210>
    for (size_t i = 0; i < page_count; i++) {
ffffffffc02024cc:	c31d                	beqz	a4,ffffffffc02024f2 <pmm_init+0x112>
ffffffffc02024ce:	00281713          	slli	a4,a6,0x2
ffffffffc02024d2:	9742                	add	a4,a4,a6
ffffffffc02024d4:	fec00637          	lui	a2,0xfec00
ffffffffc02024d8:	070e                	slli	a4,a4,0x3
ffffffffc02024da:	9732                	add	a4,a4,a2
ffffffffc02024dc:	973e                	add	a4,a4,a5
        SetPageReserved(&pages[i]);
ffffffffc02024de:	4605                	li	a2,1
        pages[i].property = 0;
ffffffffc02024e0:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02024e4:	0007a023          	sw	zero,0(a5)
        SetPageReserved(&pages[i]);
ffffffffc02024e8:	e790                	sd	a2,8(a5)
    for (size_t i = 0; i < page_count; i++) {
ffffffffc02024ea:	02878793          	addi	a5,a5,40
ffffffffc02024ee:	fef719e3          	bne	a4,a5,ffffffffc02024e0 <pmm_init+0x100>
    uintptr_t free_begin = ROUNDUP(pages_end_pa, PGSIZE);
ffffffffc02024f2:	6605                	lui	a2,0x1
ffffffffc02024f4:	167d                	addi	a2,a2,-1
ffffffffc02024f6:	77fd                	lui	a5,0xfffff
ffffffffc02024f8:	96b2                	add	a3,a3,a2
    uintptr_t aligned_mem_base = ROUNDUP(mem_base, PGSIZE);
ffffffffc02024fa:	9932                	add	s2,s2,a2
ffffffffc02024fc:	00f97933          	and	s2,s2,a5
ffffffffc0202500:	8ff5                	and	a5,a5,a3
ffffffffc0202502:	0727e263          	bltu	a5,s2,ffffffffc0202566 <pmm_init+0x186>
    if (free_begin < free_end) {
ffffffffc0202506:	0737e363          	bltu	a5,s3,ffffffffc020256c <pmm_init+0x18c>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020250a:	601c                	ld	a5,0(s0)
ffffffffc020250c:	7b9c                	ld	a5,48(a5)
ffffffffc020250e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202510:	00002517          	auipc	a0,0x2
ffffffffc0202514:	a6050513          	addi	a0,a0,-1440 # ffffffffc0203f70 <buddy_pmm_manager+0x1a8>
ffffffffc0202518:	c35fd0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020251c:	00005597          	auipc	a1,0x5
ffffffffc0202520:	ae458593          	addi	a1,a1,-1308 # ffffffffc0207000 <boot_page_table_sv39>
ffffffffc0202524:	00047797          	auipc	a5,0x47
ffffffffc0202528:	54b7b223          	sd	a1,1348(a5) # ffffffffc0249a68 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020252c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202530:	0cf5ec63          	bltu	a1,a5,ffffffffc0202608 <pmm_init+0x228>
ffffffffc0202534:	6090                	ld	a2,0(s1)
}
ffffffffc0202536:	6406                	ld	s0,64(sp)
ffffffffc0202538:	60a6                	ld	ra,72(sp)
ffffffffc020253a:	74e2                	ld	s1,56(sp)
ffffffffc020253c:	7942                	ld	s2,48(sp)
ffffffffc020253e:	79a2                	ld	s3,40(sp)
ffffffffc0202540:	7a02                	ld	s4,32(sp)
ffffffffc0202542:	6ae2                	ld	s5,24(sp)
ffffffffc0202544:	6b42                	ld	s6,16(sp)
ffffffffc0202546:	6ba2                	ld	s7,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0202548:	40c58633          	sub	a2,a1,a2
ffffffffc020254c:	00047797          	auipc	a5,0x47
ffffffffc0202550:	50c7ba23          	sd	a2,1300(a5) # ffffffffc0249a60 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0202554:	00002517          	auipc	a0,0x2
ffffffffc0202558:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0203f90 <buddy_pmm_manager+0x1c8>
}
ffffffffc020255c:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020255e:	beffd06f          	j	ffffffffc020014c <cprintf>
    maxpa = ROUNDDOWN(maxpa, PGSIZE);
ffffffffc0202562:	89be                	mv	s3,a5
ffffffffc0202564:	b5ed                	j	ffffffffc020244e <pmm_init+0x6e>
ffffffffc0202566:	87ca                	mv	a5,s2
    if (free_begin < free_end) {
ffffffffc0202568:	fb37f1e3          	bgeu	a5,s3,ffffffffc020250a <pmm_init+0x12a>
        size_t free_page_count = (free_end - free_begin) / PGSIZE;
ffffffffc020256c:	40f985b3          	sub	a1,s3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0202570:	83b1                	srli	a5,a5,0xc
ffffffffc0202572:	81b1                	srli	a1,a1,0xc
ffffffffc0202574:	0b07f763          	bgeu	a5,a6,ffffffffc0202622 <pmm_init+0x242>
    pmm_manager->init_memmap(base, n);
ffffffffc0202578:	6014                	ld	a3,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020257a:	fff80737          	lui	a4,0xfff80
ffffffffc020257e:	97ba                	add	a5,a5,a4
ffffffffc0202580:	00279713          	slli	a4,a5,0x2
ffffffffc0202584:	97ba                	add	a5,a5,a4
ffffffffc0202586:	6a98                	ld	a4,16(a3)
ffffffffc0202588:	078e                	slli	a5,a5,0x3
ffffffffc020258a:	953e                	add	a0,a0,a5
ffffffffc020258c:	9702                	jalr	a4
}
ffffffffc020258e:	bfb5                	j	ffffffffc020250a <pmm_init+0x12a>
        panic("physical memory does not contain the kernel");
ffffffffc0202590:	00002617          	auipc	a2,0x2
ffffffffc0202594:	8e860613          	addi	a2,a2,-1816 # ffffffffc0203e78 <buddy_pmm_manager+0xb0>
ffffffffc0202598:	07b00593          	li	a1,123
ffffffffc020259c:	00002517          	auipc	a0,0x2
ffffffffc02025a0:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0203e48 <buddy_pmm_manager+0x80>
ffffffffc02025a4:	c1ffd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("invalid physical memory information from DTB");
ffffffffc02025a8:	00002617          	auipc	a2,0x2
ffffffffc02025ac:	87060613          	addi	a2,a2,-1936 # ffffffffc0203e18 <buddy_pmm_manager+0x50>
ffffffffc02025b0:	05b00593          	li	a1,91
ffffffffc02025b4:	00002517          	auipc	a0,0x2
ffffffffc02025b8:	89450513          	addi	a0,a0,-1900 # ffffffffc0203e48 <buddy_pmm_manager+0x80>
ffffffffc02025bc:	c07fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t pages_end_pa = PADDR(pages_end_va);
ffffffffc02025c0:	00002617          	auipc	a2,0x2
ffffffffc02025c4:	93060613          	addi	a2,a2,-1744 # ffffffffc0203ef0 <buddy_pmm_manager+0x128>
ffffffffc02025c8:	0aa00593          	li	a1,170
ffffffffc02025cc:	00002517          	auipc	a0,0x2
ffffffffc02025d0:	87c50513          	addi	a0,a0,-1924 # ffffffffc0203e48 <buddy_pmm_manager+0x80>
ffffffffc02025d4:	beffd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("physical memory range overflow");
ffffffffc02025d8:	00002617          	auipc	a2,0x2
ffffffffc02025dc:	88060613          	addi	a2,a2,-1920 # ffffffffc0203e58 <buddy_pmm_manager+0x90>
ffffffffc02025e0:	06400593          	li	a1,100
ffffffffc02025e4:	00002517          	auipc	a0,0x2
ffffffffc02025e8:	86450513          	addi	a0,a0,-1948 # ffffffffc0203e48 <buddy_pmm_manager+0x80>
ffffffffc02025ec:	bd7fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("not enough memory for Page descriptors");
ffffffffc02025f0:	00002617          	auipc	a2,0x2
ffffffffc02025f4:	92860613          	addi	a2,a2,-1752 # ffffffffc0203f18 <buddy_pmm_manager+0x150>
ffffffffc02025f8:	0b000593          	li	a1,176
ffffffffc02025fc:	00002517          	auipc	a0,0x2
ffffffffc0202600:	84c50513          	addi	a0,a0,-1972 # ffffffffc0203e48 <buddy_pmm_manager+0x80>
ffffffffc0202604:	bbffd0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0202608:	86ae                	mv	a3,a1
ffffffffc020260a:	00002617          	auipc	a2,0x2
ffffffffc020260e:	8e660613          	addi	a2,a2,-1818 # ffffffffc0203ef0 <buddy_pmm_manager+0x128>
ffffffffc0202612:	0f500593          	li	a1,245
ffffffffc0202616:	00002517          	auipc	a0,0x2
ffffffffc020261a:	83250513          	addi	a0,a0,-1998 # ffffffffc0203e48 <buddy_pmm_manager+0x80>
ffffffffc020261e:	ba5fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202622:	00002617          	auipc	a2,0x2
ffffffffc0202626:	91e60613          	addi	a2,a2,-1762 # ffffffffc0203f40 <buddy_pmm_manager+0x178>
ffffffffc020262a:	06a00593          	li	a1,106
ffffffffc020262e:	00002517          	auipc	a0,0x2
ffffffffc0202632:	93250513          	addi	a0,a0,-1742 # ffffffffc0203f60 <buddy_pmm_manager+0x198>
ffffffffc0202636:	b8dfd0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020263a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020263a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020263e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0202640:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202644:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0202646:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020264a:	f022                	sd	s0,32(sp)
ffffffffc020264c:	ec26                	sd	s1,24(sp)
ffffffffc020264e:	e84a                	sd	s2,16(sp)
ffffffffc0202650:	f406                	sd	ra,40(sp)
ffffffffc0202652:	e44e                	sd	s3,8(sp)
ffffffffc0202654:	84aa                	mv	s1,a0
ffffffffc0202656:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0202658:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020265c:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020265e:	03067e63          	bgeu	a2,a6,ffffffffc020269a <printnum+0x60>
ffffffffc0202662:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0202664:	00805763          	blez	s0,ffffffffc0202672 <printnum+0x38>
ffffffffc0202668:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020266a:	85ca                	mv	a1,s2
ffffffffc020266c:	854e                	mv	a0,s3
ffffffffc020266e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0202670:	fc65                	bnez	s0,ffffffffc0202668 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202672:	1a02                	slli	s4,s4,0x20
ffffffffc0202674:	00002797          	auipc	a5,0x2
ffffffffc0202678:	95c78793          	addi	a5,a5,-1700 # ffffffffc0203fd0 <buddy_pmm_manager+0x208>
ffffffffc020267c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0202680:	9a3e                	add	s4,s4,a5
}
ffffffffc0202682:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202684:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0202688:	70a2                	ld	ra,40(sp)
ffffffffc020268a:	69a2                	ld	s3,8(sp)
ffffffffc020268c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020268e:	85ca                	mv	a1,s2
ffffffffc0202690:	87a6                	mv	a5,s1
}
ffffffffc0202692:	6942                	ld	s2,16(sp)
ffffffffc0202694:	64e2                	ld	s1,24(sp)
ffffffffc0202696:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202698:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020269a:	03065633          	divu	a2,a2,a6
ffffffffc020269e:	8722                	mv	a4,s0
ffffffffc02026a0:	f9bff0ef          	jal	ra,ffffffffc020263a <printnum>
ffffffffc02026a4:	b7f9                	j	ffffffffc0202672 <printnum+0x38>

ffffffffc02026a6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02026a6:	7119                	addi	sp,sp,-128
ffffffffc02026a8:	f4a6                	sd	s1,104(sp)
ffffffffc02026aa:	f0ca                	sd	s2,96(sp)
ffffffffc02026ac:	ecce                	sd	s3,88(sp)
ffffffffc02026ae:	e8d2                	sd	s4,80(sp)
ffffffffc02026b0:	e4d6                	sd	s5,72(sp)
ffffffffc02026b2:	e0da                	sd	s6,64(sp)
ffffffffc02026b4:	fc5e                	sd	s7,56(sp)
ffffffffc02026b6:	f06a                	sd	s10,32(sp)
ffffffffc02026b8:	fc86                	sd	ra,120(sp)
ffffffffc02026ba:	f8a2                	sd	s0,112(sp)
ffffffffc02026bc:	f862                	sd	s8,48(sp)
ffffffffc02026be:	f466                	sd	s9,40(sp)
ffffffffc02026c0:	ec6e                	sd	s11,24(sp)
ffffffffc02026c2:	892a                	mv	s2,a0
ffffffffc02026c4:	84ae                	mv	s1,a1
ffffffffc02026c6:	8d32                	mv	s10,a2
ffffffffc02026c8:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02026ca:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02026ce:	5b7d                	li	s6,-1
ffffffffc02026d0:	00002a97          	auipc	s5,0x2
ffffffffc02026d4:	934a8a93          	addi	s5,s5,-1740 # ffffffffc0204004 <buddy_pmm_manager+0x23c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02026d8:	00002b97          	auipc	s7,0x2
ffffffffc02026dc:	b08b8b93          	addi	s7,s7,-1272 # ffffffffc02041e0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02026e0:	000d4503          	lbu	a0,0(s10)
ffffffffc02026e4:	001d0413          	addi	s0,s10,1
ffffffffc02026e8:	01350a63          	beq	a0,s3,ffffffffc02026fc <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02026ec:	c121                	beqz	a0,ffffffffc020272c <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02026ee:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02026f0:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02026f2:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02026f4:	fff44503          	lbu	a0,-1(s0)
ffffffffc02026f8:	ff351ae3          	bne	a0,s3,ffffffffc02026ec <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02026fc:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0202700:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0202704:	4c81                	li	s9,0
ffffffffc0202706:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0202708:	5c7d                	li	s8,-1
ffffffffc020270a:	5dfd                	li	s11,-1
ffffffffc020270c:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0202710:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202712:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0202716:	0ff5f593          	zext.b	a1,a1
ffffffffc020271a:	00140d13          	addi	s10,s0,1
ffffffffc020271e:	04b56263          	bltu	a0,a1,ffffffffc0202762 <vprintfmt+0xbc>
ffffffffc0202722:	058a                	slli	a1,a1,0x2
ffffffffc0202724:	95d6                	add	a1,a1,s5
ffffffffc0202726:	4194                	lw	a3,0(a1)
ffffffffc0202728:	96d6                	add	a3,a3,s5
ffffffffc020272a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020272c:	70e6                	ld	ra,120(sp)
ffffffffc020272e:	7446                	ld	s0,112(sp)
ffffffffc0202730:	74a6                	ld	s1,104(sp)
ffffffffc0202732:	7906                	ld	s2,96(sp)
ffffffffc0202734:	69e6                	ld	s3,88(sp)
ffffffffc0202736:	6a46                	ld	s4,80(sp)
ffffffffc0202738:	6aa6                	ld	s5,72(sp)
ffffffffc020273a:	6b06                	ld	s6,64(sp)
ffffffffc020273c:	7be2                	ld	s7,56(sp)
ffffffffc020273e:	7c42                	ld	s8,48(sp)
ffffffffc0202740:	7ca2                	ld	s9,40(sp)
ffffffffc0202742:	7d02                	ld	s10,32(sp)
ffffffffc0202744:	6de2                	ld	s11,24(sp)
ffffffffc0202746:	6109                	addi	sp,sp,128
ffffffffc0202748:	8082                	ret
            padc = '0';
ffffffffc020274a:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020274c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202750:	846a                	mv	s0,s10
ffffffffc0202752:	00140d13          	addi	s10,s0,1
ffffffffc0202756:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020275a:	0ff5f593          	zext.b	a1,a1
ffffffffc020275e:	fcb572e3          	bgeu	a0,a1,ffffffffc0202722 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0202762:	85a6                	mv	a1,s1
ffffffffc0202764:	02500513          	li	a0,37
ffffffffc0202768:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020276a:	fff44783          	lbu	a5,-1(s0)
ffffffffc020276e:	8d22                	mv	s10,s0
ffffffffc0202770:	f73788e3          	beq	a5,s3,ffffffffc02026e0 <vprintfmt+0x3a>
ffffffffc0202774:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0202778:	1d7d                	addi	s10,s10,-1
ffffffffc020277a:	ff379de3          	bne	a5,s3,ffffffffc0202774 <vprintfmt+0xce>
ffffffffc020277e:	b78d                	j	ffffffffc02026e0 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0202780:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0202784:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202788:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020278a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020278e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0202792:	02d86463          	bltu	a6,a3,ffffffffc02027ba <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0202796:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020279a:	002c169b          	slliw	a3,s8,0x2
ffffffffc020279e:	0186873b          	addw	a4,a3,s8
ffffffffc02027a2:	0017171b          	slliw	a4,a4,0x1
ffffffffc02027a6:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02027a8:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02027ac:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02027ae:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02027b2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02027b6:	fed870e3          	bgeu	a6,a3,ffffffffc0202796 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02027ba:	f40ddce3          	bgez	s11,ffffffffc0202712 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02027be:	8de2                	mv	s11,s8
ffffffffc02027c0:	5c7d                	li	s8,-1
ffffffffc02027c2:	bf81                	j	ffffffffc0202712 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02027c4:	fffdc693          	not	a3,s11
ffffffffc02027c8:	96fd                	srai	a3,a3,0x3f
ffffffffc02027ca:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02027ce:	00144603          	lbu	a2,1(s0)
ffffffffc02027d2:	2d81                	sext.w	s11,s11
ffffffffc02027d4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02027d6:	bf35                	j	ffffffffc0202712 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02027d8:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02027dc:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02027e0:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02027e2:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02027e4:	bfd9                	j	ffffffffc02027ba <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02027e6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02027e8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02027ec:	01174463          	blt	a4,a7,ffffffffc02027f4 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02027f0:	1a088e63          	beqz	a7,ffffffffc02029ac <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02027f4:	000a3603          	ld	a2,0(s4)
ffffffffc02027f8:	46c1                	li	a3,16
ffffffffc02027fa:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02027fc:	2781                	sext.w	a5,a5
ffffffffc02027fe:	876e                	mv	a4,s11
ffffffffc0202800:	85a6                	mv	a1,s1
ffffffffc0202802:	854a                	mv	a0,s2
ffffffffc0202804:	e37ff0ef          	jal	ra,ffffffffc020263a <printnum>
            break;
ffffffffc0202808:	bde1                	j	ffffffffc02026e0 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020280a:	000a2503          	lw	a0,0(s4)
ffffffffc020280e:	85a6                	mv	a1,s1
ffffffffc0202810:	0a21                	addi	s4,s4,8
ffffffffc0202812:	9902                	jalr	s2
            break;
ffffffffc0202814:	b5f1                	j	ffffffffc02026e0 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0202816:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202818:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020281c:	01174463          	blt	a4,a7,ffffffffc0202824 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0202820:	18088163          	beqz	a7,ffffffffc02029a2 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0202824:	000a3603          	ld	a2,0(s4)
ffffffffc0202828:	46a9                	li	a3,10
ffffffffc020282a:	8a2e                	mv	s4,a1
ffffffffc020282c:	bfc1                	j	ffffffffc02027fc <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020282e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0202832:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202834:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0202836:	bdf1                	j	ffffffffc0202712 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0202838:	85a6                	mv	a1,s1
ffffffffc020283a:	02500513          	li	a0,37
ffffffffc020283e:	9902                	jalr	s2
            break;
ffffffffc0202840:	b545                	j	ffffffffc02026e0 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202842:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0202846:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202848:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020284a:	b5e1                	j	ffffffffc0202712 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020284c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020284e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202852:	01174463          	blt	a4,a7,ffffffffc020285a <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0202856:	14088163          	beqz	a7,ffffffffc0202998 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020285a:	000a3603          	ld	a2,0(s4)
ffffffffc020285e:	46a1                	li	a3,8
ffffffffc0202860:	8a2e                	mv	s4,a1
ffffffffc0202862:	bf69                	j	ffffffffc02027fc <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0202864:	03000513          	li	a0,48
ffffffffc0202868:	85a6                	mv	a1,s1
ffffffffc020286a:	e03e                	sd	a5,0(sp)
ffffffffc020286c:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020286e:	85a6                	mv	a1,s1
ffffffffc0202870:	07800513          	li	a0,120
ffffffffc0202874:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202876:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0202878:	6782                	ld	a5,0(sp)
ffffffffc020287a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020287c:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0202880:	bfb5                	j	ffffffffc02027fc <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0202882:	000a3403          	ld	s0,0(s4)
ffffffffc0202886:	008a0713          	addi	a4,s4,8
ffffffffc020288a:	e03a                	sd	a4,0(sp)
ffffffffc020288c:	14040263          	beqz	s0,ffffffffc02029d0 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0202890:	0fb05763          	blez	s11,ffffffffc020297e <vprintfmt+0x2d8>
ffffffffc0202894:	02d00693          	li	a3,45
ffffffffc0202898:	0cd79163          	bne	a5,a3,ffffffffc020295a <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020289c:	00044783          	lbu	a5,0(s0)
ffffffffc02028a0:	0007851b          	sext.w	a0,a5
ffffffffc02028a4:	cf85                	beqz	a5,ffffffffc02028dc <vprintfmt+0x236>
ffffffffc02028a6:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02028aa:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02028ae:	000c4563          	bltz	s8,ffffffffc02028b8 <vprintfmt+0x212>
ffffffffc02028b2:	3c7d                	addiw	s8,s8,-1
ffffffffc02028b4:	036c0263          	beq	s8,s6,ffffffffc02028d8 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02028b8:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02028ba:	0e0c8e63          	beqz	s9,ffffffffc02029b6 <vprintfmt+0x310>
ffffffffc02028be:	3781                	addiw	a5,a5,-32
ffffffffc02028c0:	0ef47b63          	bgeu	s0,a5,ffffffffc02029b6 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02028c4:	03f00513          	li	a0,63
ffffffffc02028c8:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02028ca:	000a4783          	lbu	a5,0(s4)
ffffffffc02028ce:	3dfd                	addiw	s11,s11,-1
ffffffffc02028d0:	0a05                	addi	s4,s4,1
ffffffffc02028d2:	0007851b          	sext.w	a0,a5
ffffffffc02028d6:	ffe1                	bnez	a5,ffffffffc02028ae <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02028d8:	01b05963          	blez	s11,ffffffffc02028ea <vprintfmt+0x244>
ffffffffc02028dc:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02028de:	85a6                	mv	a1,s1
ffffffffc02028e0:	02000513          	li	a0,32
ffffffffc02028e4:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02028e6:	fe0d9be3          	bnez	s11,ffffffffc02028dc <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02028ea:	6a02                	ld	s4,0(sp)
ffffffffc02028ec:	bbd5                	j	ffffffffc02026e0 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02028ee:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02028f0:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02028f4:	01174463          	blt	a4,a7,ffffffffc02028fc <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02028f8:	08088d63          	beqz	a7,ffffffffc0202992 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02028fc:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0202900:	0a044d63          	bltz	s0,ffffffffc02029ba <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0202904:	8622                	mv	a2,s0
ffffffffc0202906:	8a66                	mv	s4,s9
ffffffffc0202908:	46a9                	li	a3,10
ffffffffc020290a:	bdcd                	j	ffffffffc02027fc <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020290c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202910:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0202912:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0202914:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0202918:	8fb5                	xor	a5,a5,a3
ffffffffc020291a:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020291e:	02d74163          	blt	a4,a3,ffffffffc0202940 <vprintfmt+0x29a>
ffffffffc0202922:	00369793          	slli	a5,a3,0x3
ffffffffc0202926:	97de                	add	a5,a5,s7
ffffffffc0202928:	639c                	ld	a5,0(a5)
ffffffffc020292a:	cb99                	beqz	a5,ffffffffc0202940 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020292c:	86be                	mv	a3,a5
ffffffffc020292e:	00001617          	auipc	a2,0x1
ffffffffc0202932:	6d260613          	addi	a2,a2,1746 # ffffffffc0204000 <buddy_pmm_manager+0x238>
ffffffffc0202936:	85a6                	mv	a1,s1
ffffffffc0202938:	854a                	mv	a0,s2
ffffffffc020293a:	0ce000ef          	jal	ra,ffffffffc0202a08 <printfmt>
ffffffffc020293e:	b34d                	j	ffffffffc02026e0 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0202940:	00001617          	auipc	a2,0x1
ffffffffc0202944:	6b060613          	addi	a2,a2,1712 # ffffffffc0203ff0 <buddy_pmm_manager+0x228>
ffffffffc0202948:	85a6                	mv	a1,s1
ffffffffc020294a:	854a                	mv	a0,s2
ffffffffc020294c:	0bc000ef          	jal	ra,ffffffffc0202a08 <printfmt>
ffffffffc0202950:	bb41                	j	ffffffffc02026e0 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0202952:	00001417          	auipc	s0,0x1
ffffffffc0202956:	69640413          	addi	s0,s0,1686 # ffffffffc0203fe8 <buddy_pmm_manager+0x220>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020295a:	85e2                	mv	a1,s8
ffffffffc020295c:	8522                	mv	a0,s0
ffffffffc020295e:	e43e                	sd	a5,8(sp)
ffffffffc0202960:	0fc000ef          	jal	ra,ffffffffc0202a5c <strnlen>
ffffffffc0202964:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0202968:	01b05b63          	blez	s11,ffffffffc020297e <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020296c:	67a2                	ld	a5,8(sp)
ffffffffc020296e:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202972:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0202974:	85a6                	mv	a1,s1
ffffffffc0202976:	8552                	mv	a0,s4
ffffffffc0202978:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020297a:	fe0d9ce3          	bnez	s11,ffffffffc0202972 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020297e:	00044783          	lbu	a5,0(s0)
ffffffffc0202982:	00140a13          	addi	s4,s0,1
ffffffffc0202986:	0007851b          	sext.w	a0,a5
ffffffffc020298a:	d3a5                	beqz	a5,ffffffffc02028ea <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020298c:	05e00413          	li	s0,94
ffffffffc0202990:	bf39                	j	ffffffffc02028ae <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0202992:	000a2403          	lw	s0,0(s4)
ffffffffc0202996:	b7ad                	j	ffffffffc0202900 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0202998:	000a6603          	lwu	a2,0(s4)
ffffffffc020299c:	46a1                	li	a3,8
ffffffffc020299e:	8a2e                	mv	s4,a1
ffffffffc02029a0:	bdb1                	j	ffffffffc02027fc <vprintfmt+0x156>
ffffffffc02029a2:	000a6603          	lwu	a2,0(s4)
ffffffffc02029a6:	46a9                	li	a3,10
ffffffffc02029a8:	8a2e                	mv	s4,a1
ffffffffc02029aa:	bd89                	j	ffffffffc02027fc <vprintfmt+0x156>
ffffffffc02029ac:	000a6603          	lwu	a2,0(s4)
ffffffffc02029b0:	46c1                	li	a3,16
ffffffffc02029b2:	8a2e                	mv	s4,a1
ffffffffc02029b4:	b5a1                	j	ffffffffc02027fc <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02029b6:	9902                	jalr	s2
ffffffffc02029b8:	bf09                	j	ffffffffc02028ca <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02029ba:	85a6                	mv	a1,s1
ffffffffc02029bc:	02d00513          	li	a0,45
ffffffffc02029c0:	e03e                	sd	a5,0(sp)
ffffffffc02029c2:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02029c4:	6782                	ld	a5,0(sp)
ffffffffc02029c6:	8a66                	mv	s4,s9
ffffffffc02029c8:	40800633          	neg	a2,s0
ffffffffc02029cc:	46a9                	li	a3,10
ffffffffc02029ce:	b53d                	j	ffffffffc02027fc <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02029d0:	03b05163          	blez	s11,ffffffffc02029f2 <vprintfmt+0x34c>
ffffffffc02029d4:	02d00693          	li	a3,45
ffffffffc02029d8:	f6d79de3          	bne	a5,a3,ffffffffc0202952 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02029dc:	00001417          	auipc	s0,0x1
ffffffffc02029e0:	60c40413          	addi	s0,s0,1548 # ffffffffc0203fe8 <buddy_pmm_manager+0x220>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02029e4:	02800793          	li	a5,40
ffffffffc02029e8:	02800513          	li	a0,40
ffffffffc02029ec:	00140a13          	addi	s4,s0,1
ffffffffc02029f0:	bd6d                	j	ffffffffc02028aa <vprintfmt+0x204>
ffffffffc02029f2:	00001a17          	auipc	s4,0x1
ffffffffc02029f6:	5f7a0a13          	addi	s4,s4,1527 # ffffffffc0203fe9 <buddy_pmm_manager+0x221>
ffffffffc02029fa:	02800513          	li	a0,40
ffffffffc02029fe:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202a02:	05e00413          	li	s0,94
ffffffffc0202a06:	b565                	j	ffffffffc02028ae <vprintfmt+0x208>

ffffffffc0202a08 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202a08:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0202a0a:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202a0e:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0202a10:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202a12:	ec06                	sd	ra,24(sp)
ffffffffc0202a14:	f83a                	sd	a4,48(sp)
ffffffffc0202a16:	fc3e                	sd	a5,56(sp)
ffffffffc0202a18:	e0c2                	sd	a6,64(sp)
ffffffffc0202a1a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0202a1c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0202a1e:	c89ff0ef          	jal	ra,ffffffffc02026a6 <vprintfmt>
}
ffffffffc0202a22:	60e2                	ld	ra,24(sp)
ffffffffc0202a24:	6161                	addi	sp,sp,80
ffffffffc0202a26:	8082                	ret

ffffffffc0202a28 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0202a28:	4781                	li	a5,0
ffffffffc0202a2a:	00005717          	auipc	a4,0x5
ffffffffc0202a2e:	5e673703          	ld	a4,1510(a4) # ffffffffc0208010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0202a32:	88ba                	mv	a7,a4
ffffffffc0202a34:	852a                	mv	a0,a0
ffffffffc0202a36:	85be                	mv	a1,a5
ffffffffc0202a38:	863e                	mv	a2,a5
ffffffffc0202a3a:	00000073          	ecall
ffffffffc0202a3e:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0202a40:	8082                	ret

ffffffffc0202a42 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0202a42:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0202a46:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0202a48:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0202a4a:	cb81                	beqz	a5,ffffffffc0202a5a <strlen+0x18>
        cnt ++;
ffffffffc0202a4c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0202a4e:	00a707b3          	add	a5,a4,a0
ffffffffc0202a52:	0007c783          	lbu	a5,0(a5)
ffffffffc0202a56:	fbfd                	bnez	a5,ffffffffc0202a4c <strlen+0xa>
ffffffffc0202a58:	8082                	ret
    }
    return cnt;
}
ffffffffc0202a5a:	8082                	ret

ffffffffc0202a5c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0202a5c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202a5e:	e589                	bnez	a1,ffffffffc0202a68 <strnlen+0xc>
ffffffffc0202a60:	a811                	j	ffffffffc0202a74 <strnlen+0x18>
        cnt ++;
ffffffffc0202a62:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202a64:	00f58863          	beq	a1,a5,ffffffffc0202a74 <strnlen+0x18>
ffffffffc0202a68:	00f50733          	add	a4,a0,a5
ffffffffc0202a6c:	00074703          	lbu	a4,0(a4)
ffffffffc0202a70:	fb6d                	bnez	a4,ffffffffc0202a62 <strnlen+0x6>
ffffffffc0202a72:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0202a74:	852e                	mv	a0,a1
ffffffffc0202a76:	8082                	ret

ffffffffc0202a78 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202a78:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202a7c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202a80:	cb89                	beqz	a5,ffffffffc0202a92 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0202a82:	0505                	addi	a0,a0,1
ffffffffc0202a84:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202a86:	fee789e3          	beq	a5,a4,ffffffffc0202a78 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202a8a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0202a8e:	9d19                	subw	a0,a0,a4
ffffffffc0202a90:	8082                	ret
ffffffffc0202a92:	4501                	li	a0,0
ffffffffc0202a94:	bfed                	j	ffffffffc0202a8e <strcmp+0x16>

ffffffffc0202a96 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202a96:	c20d                	beqz	a2,ffffffffc0202ab8 <strncmp+0x22>
ffffffffc0202a98:	962e                	add	a2,a2,a1
ffffffffc0202a9a:	a031                	j	ffffffffc0202aa6 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0202a9c:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202a9e:	00e79a63          	bne	a5,a4,ffffffffc0202ab2 <strncmp+0x1c>
ffffffffc0202aa2:	00b60b63          	beq	a2,a1,ffffffffc0202ab8 <strncmp+0x22>
ffffffffc0202aa6:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0202aaa:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202aac:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0202ab0:	f7f5                	bnez	a5,ffffffffc0202a9c <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202ab2:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0202ab6:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202ab8:	4501                	li	a0,0
ffffffffc0202aba:	8082                	ret

ffffffffc0202abc <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0202abc:	ca01                	beqz	a2,ffffffffc0202acc <memset+0x10>
ffffffffc0202abe:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0202ac0:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0202ac2:	0785                	addi	a5,a5,1
ffffffffc0202ac4:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0202ac8:	fec79de3          	bne	a5,a2,ffffffffc0202ac2 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0202acc:	8082                	ret

ffffffffc0202ace <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0202ace:	ca19                	beqz	a2,ffffffffc0202ae4 <memcpy+0x16>
ffffffffc0202ad0:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0202ad2:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0202ad4:	0005c703          	lbu	a4,0(a1)
ffffffffc0202ad8:	0585                	addi	a1,a1,1
ffffffffc0202ada:	0785                	addi	a5,a5,1
ffffffffc0202adc:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0202ae0:	fec59ae3          	bne	a1,a2,ffffffffc0202ad4 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0202ae4:	8082                	ret

ffffffffc0202ae6 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0202ae6:	c205                	beqz	a2,ffffffffc0202b06 <memcmp+0x20>
ffffffffc0202ae8:	962e                	add	a2,a2,a1
ffffffffc0202aea:	a019                	j	ffffffffc0202af0 <memcmp+0xa>
ffffffffc0202aec:	00c58d63          	beq	a1,a2,ffffffffc0202b06 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0202af0:	00054783          	lbu	a5,0(a0)
ffffffffc0202af4:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0202af8:	0505                	addi	a0,a0,1
ffffffffc0202afa:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0202afc:	fee788e3          	beq	a5,a4,ffffffffc0202aec <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202b00:	40e7853b          	subw	a0,a5,a4
ffffffffc0202b04:	8082                	ret
    }
    return 0;
ffffffffc0202b06:	4501                	li	a0,0
}
ffffffffc0202b08:	8082                	ret
