
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	00006517          	auipc	a0,0x6
ffffffffc020003a:	fda50513          	addi	a0,a0,-38 # ffffffffc0206010 <edata>
ffffffffc020003e:	00006617          	auipc	a2,0x6
ffffffffc0200042:	43260613          	addi	a2,a2,1074 # ffffffffc0206470 <end>
int kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	586010ef          	jal	ra,ffffffffc02015d4 <memset>
    cons_init();  // init the console
ffffffffc0200052:	412000ef          	jal	ra,ffffffffc0200464 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    cprintf("%s\n\n", message);
ffffffffc0200056:	00002597          	auipc	a1,0x2
ffffffffc020005a:	aa258593          	addi	a1,a1,-1374 # ffffffffc0201af8 <etext+0x6>
ffffffffc020005e:	00002517          	auipc	a0,0x2
ffffffffc0200062:	aba50513          	addi	a0,a0,-1350 # ffffffffc0201b18 <etext+0x26>
ffffffffc0200066:	064000ef          	jal	ra,ffffffffc02000ca <cprintf>
    cputs(message);
ffffffffc020006a:	00002517          	auipc	a0,0x2
ffffffffc020006e:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0201af8 <etext+0x6>
ffffffffc0200072:	090000ef          	jal	ra,ffffffffc0200102 <cputs>

    print_kerninfo();
ffffffffc0200076:	13c000ef          	jal	ra,ffffffffc02001b2 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc020007a:	404000ef          	jal	ra,ffffffffc020047e <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020007e:	097000ef          	jal	ra,ffffffffc0200914 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200082:	3fc000ef          	jal	ra,ffffffffc020047e <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200086:	39a000ef          	jal	ra,ffffffffc0200420 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc020008a:	3e8000ef          	jal	ra,ffffffffc0200472 <intr_enable>

   

    /* do nothing */
    while (1)
        ;
ffffffffc020008e:	a001                	j	ffffffffc020008e <kern_init+0x58>

ffffffffc0200090 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200090:	1141                	addi	sp,sp,-16
ffffffffc0200092:	e022                	sd	s0,0(sp)
ffffffffc0200094:	e406                	sd	ra,8(sp)
ffffffffc0200096:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200098:	3ce000ef          	jal	ra,ffffffffc0200466 <cons_putc>
    (*cnt) ++;
ffffffffc020009c:	401c                	lw	a5,0(s0)
}
ffffffffc020009e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000a0:	2785                	addiw	a5,a5,1
ffffffffc02000a2:	c01c                	sw	a5,0(s0)
}
ffffffffc02000a4:	6402                	ld	s0,0(sp)
ffffffffc02000a6:	0141                	addi	sp,sp,16
ffffffffc02000a8:	8082                	ret

ffffffffc02000aa <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000aa:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ac:	86ae                	mv	a3,a1
ffffffffc02000ae:	862a                	mv	a2,a0
ffffffffc02000b0:	006c                	addi	a1,sp,12
ffffffffc02000b2:	00000517          	auipc	a0,0x0
ffffffffc02000b6:	fde50513          	addi	a0,a0,-34 # ffffffffc0200090 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ba:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000bc:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	594010ef          	jal	ra,ffffffffc0201652 <vprintfmt>
    return cnt;
}
ffffffffc02000c2:	60e2                	ld	ra,24(sp)
ffffffffc02000c4:	4532                	lw	a0,12(sp)
ffffffffc02000c6:	6105                	addi	sp,sp,32
ffffffffc02000c8:	8082                	ret

ffffffffc02000ca <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000ca:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000cc:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000d0:	f42e                	sd	a1,40(sp)
ffffffffc02000d2:	f832                	sd	a2,48(sp)
ffffffffc02000d4:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000d6:	862a                	mv	a2,a0
ffffffffc02000d8:	004c                	addi	a1,sp,4
ffffffffc02000da:	00000517          	auipc	a0,0x0
ffffffffc02000de:	fb650513          	addi	a0,a0,-74 # ffffffffc0200090 <cputch>
ffffffffc02000e2:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000e4:	ec06                	sd	ra,24(sp)
ffffffffc02000e6:	e0ba                	sd	a4,64(sp)
ffffffffc02000e8:	e4be                	sd	a5,72(sp)
ffffffffc02000ea:	e8c2                	sd	a6,80(sp)
ffffffffc02000ec:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000ee:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000f0:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f2:	560010ef          	jal	ra,ffffffffc0201652 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000f6:	60e2                	ld	ra,24(sp)
ffffffffc02000f8:	4512                	lw	a0,4(sp)
ffffffffc02000fa:	6125                	addi	sp,sp,96
ffffffffc02000fc:	8082                	ret

ffffffffc02000fe <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000fe:	3680006f          	j	ffffffffc0200466 <cons_putc>

ffffffffc0200102 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200102:	1101                	addi	sp,sp,-32
ffffffffc0200104:	e822                	sd	s0,16(sp)
ffffffffc0200106:	ec06                	sd	ra,24(sp)
ffffffffc0200108:	e426                	sd	s1,8(sp)
ffffffffc020010a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020010c:	00054503          	lbu	a0,0(a0)
ffffffffc0200110:	c51d                	beqz	a0,ffffffffc020013e <cputs+0x3c>
ffffffffc0200112:	0405                	addi	s0,s0,1
ffffffffc0200114:	4485                	li	s1,1
ffffffffc0200116:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200118:	34e000ef          	jal	ra,ffffffffc0200466 <cons_putc>
    (*cnt) ++;
ffffffffc020011c:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc0200120:	0405                	addi	s0,s0,1
ffffffffc0200122:	fff44503          	lbu	a0,-1(s0)
ffffffffc0200126:	f96d                	bnez	a0,ffffffffc0200118 <cputs+0x16>
ffffffffc0200128:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020012c:	4529                	li	a0,10
ffffffffc020012e:	338000ef          	jal	ra,ffffffffc0200466 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200132:	8522                	mv	a0,s0
ffffffffc0200134:	60e2                	ld	ra,24(sp)
ffffffffc0200136:	6442                	ld	s0,16(sp)
ffffffffc0200138:	64a2                	ld	s1,8(sp)
ffffffffc020013a:	6105                	addi	sp,sp,32
ffffffffc020013c:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020013e:	4405                	li	s0,1
ffffffffc0200140:	b7f5                	j	ffffffffc020012c <cputs+0x2a>

ffffffffc0200142 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200142:	1141                	addi	sp,sp,-16
ffffffffc0200144:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200146:	328000ef          	jal	ra,ffffffffc020046e <cons_getc>
ffffffffc020014a:	dd75                	beqz	a0,ffffffffc0200146 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020014c:	60a2                	ld	ra,8(sp)
ffffffffc020014e:	0141                	addi	sp,sp,16
ffffffffc0200150:	8082                	ret

ffffffffc0200152 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200152:	00006317          	auipc	t1,0x6
ffffffffc0200156:	2be30313          	addi	t1,t1,702 # ffffffffc0206410 <is_panic>
ffffffffc020015a:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020015e:	715d                	addi	sp,sp,-80
ffffffffc0200160:	ec06                	sd	ra,24(sp)
ffffffffc0200162:	e822                	sd	s0,16(sp)
ffffffffc0200164:	f436                	sd	a3,40(sp)
ffffffffc0200166:	f83a                	sd	a4,48(sp)
ffffffffc0200168:	fc3e                	sd	a5,56(sp)
ffffffffc020016a:	e0c2                	sd	a6,64(sp)
ffffffffc020016c:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020016e:	02031c63          	bnez	t1,ffffffffc02001a6 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200172:	4785                	li	a5,1
ffffffffc0200174:	8432                	mv	s0,a2
ffffffffc0200176:	00006717          	auipc	a4,0x6
ffffffffc020017a:	28f72d23          	sw	a5,666(a4) # ffffffffc0206410 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020017e:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc0200180:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200182:	85aa                	mv	a1,a0
ffffffffc0200184:	00002517          	auipc	a0,0x2
ffffffffc0200188:	99c50513          	addi	a0,a0,-1636 # ffffffffc0201b20 <etext+0x2e>
    va_start(ap, fmt);
ffffffffc020018c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020018e:	f3dff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200192:	65a2                	ld	a1,8(sp)
ffffffffc0200194:	8522                	mv	a0,s0
ffffffffc0200196:	f15ff0ef          	jal	ra,ffffffffc02000aa <vcprintf>
    cprintf("\n");
ffffffffc020019a:	00002517          	auipc	a0,0x2
ffffffffc020019e:	a9e50513          	addi	a0,a0,-1378 # ffffffffc0201c38 <etext+0x146>
ffffffffc02001a2:	f29ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02001a6:	2d2000ef          	jal	ra,ffffffffc0200478 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02001aa:	4501                	li	a0,0
ffffffffc02001ac:	132000ef          	jal	ra,ffffffffc02002de <kmonitor>
ffffffffc02001b0:	bfed                	j	ffffffffc02001aa <__panic+0x58>

ffffffffc02001b2 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02001b2:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001b4:	00002517          	auipc	a0,0x2
ffffffffc02001b8:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0201b70 <etext+0x7e>
void print_kerninfo(void) {
ffffffffc02001bc:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001be:	f0dff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001c2:	00000597          	auipc	a1,0x0
ffffffffc02001c6:	e7458593          	addi	a1,a1,-396 # ffffffffc0200036 <kern_init>
ffffffffc02001ca:	00002517          	auipc	a0,0x2
ffffffffc02001ce:	9c650513          	addi	a0,a0,-1594 # ffffffffc0201b90 <etext+0x9e>
ffffffffc02001d2:	ef9ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001d6:	00002597          	auipc	a1,0x2
ffffffffc02001da:	91c58593          	addi	a1,a1,-1764 # ffffffffc0201af2 <etext>
ffffffffc02001de:	00002517          	auipc	a0,0x2
ffffffffc02001e2:	9d250513          	addi	a0,a0,-1582 # ffffffffc0201bb0 <etext+0xbe>
ffffffffc02001e6:	ee5ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001ea:	00006597          	auipc	a1,0x6
ffffffffc02001ee:	e2658593          	addi	a1,a1,-474 # ffffffffc0206010 <edata>
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	9de50513          	addi	a0,a0,-1570 # ffffffffc0201bd0 <etext+0xde>
ffffffffc02001fa:	ed1ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001fe:	00006597          	auipc	a1,0x6
ffffffffc0200202:	27258593          	addi	a1,a1,626 # ffffffffc0206470 <end>
ffffffffc0200206:	00002517          	auipc	a0,0x2
ffffffffc020020a:	9ea50513          	addi	a0,a0,-1558 # ffffffffc0201bf0 <etext+0xfe>
ffffffffc020020e:	ebdff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200212:	00006597          	auipc	a1,0x6
ffffffffc0200216:	65d58593          	addi	a1,a1,1629 # ffffffffc020686f <end+0x3ff>
ffffffffc020021a:	00000797          	auipc	a5,0x0
ffffffffc020021e:	e1c78793          	addi	a5,a5,-484 # ffffffffc0200036 <kern_init>
ffffffffc0200222:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200226:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020022a:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020022c:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200230:	95be                	add	a1,a1,a5
ffffffffc0200232:	85a9                	srai	a1,a1,0xa
ffffffffc0200234:	00002517          	auipc	a0,0x2
ffffffffc0200238:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0201c10 <etext+0x11e>
}
ffffffffc020023c:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020023e:	e8dff06f          	j	ffffffffc02000ca <cprintf>

ffffffffc0200242 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200242:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc0200244:	00002617          	auipc	a2,0x2
ffffffffc0200248:	8fc60613          	addi	a2,a2,-1796 # ffffffffc0201b40 <etext+0x4e>
ffffffffc020024c:	04e00593          	li	a1,78
ffffffffc0200250:	00002517          	auipc	a0,0x2
ffffffffc0200254:	90850513          	addi	a0,a0,-1784 # ffffffffc0201b58 <etext+0x66>
void print_stackframe(void) {
ffffffffc0200258:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020025a:	ef9ff0ef          	jal	ra,ffffffffc0200152 <__panic>

ffffffffc020025e <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025e:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200260:	00002617          	auipc	a2,0x2
ffffffffc0200264:	ac060613          	addi	a2,a2,-1344 # ffffffffc0201d20 <commands+0xe0>
ffffffffc0200268:	00002597          	auipc	a1,0x2
ffffffffc020026c:	ad858593          	addi	a1,a1,-1320 # ffffffffc0201d40 <commands+0x100>
ffffffffc0200270:	00002517          	auipc	a0,0x2
ffffffffc0200274:	ad850513          	addi	a0,a0,-1320 # ffffffffc0201d48 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200278:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020027a:	e51ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
ffffffffc020027e:	00002617          	auipc	a2,0x2
ffffffffc0200282:	ada60613          	addi	a2,a2,-1318 # ffffffffc0201d58 <commands+0x118>
ffffffffc0200286:	00002597          	auipc	a1,0x2
ffffffffc020028a:	afa58593          	addi	a1,a1,-1286 # ffffffffc0201d80 <commands+0x140>
ffffffffc020028e:	00002517          	auipc	a0,0x2
ffffffffc0200292:	aba50513          	addi	a0,a0,-1350 # ffffffffc0201d48 <commands+0x108>
ffffffffc0200296:	e35ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
ffffffffc020029a:	00002617          	auipc	a2,0x2
ffffffffc020029e:	af660613          	addi	a2,a2,-1290 # ffffffffc0201d90 <commands+0x150>
ffffffffc02002a2:	00002597          	auipc	a1,0x2
ffffffffc02002a6:	b0e58593          	addi	a1,a1,-1266 # ffffffffc0201db0 <commands+0x170>
ffffffffc02002aa:	00002517          	auipc	a0,0x2
ffffffffc02002ae:	a9e50513          	addi	a0,a0,-1378 # ffffffffc0201d48 <commands+0x108>
ffffffffc02002b2:	e19ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    }
    return 0;
}
ffffffffc02002b6:	60a2                	ld	ra,8(sp)
ffffffffc02002b8:	4501                	li	a0,0
ffffffffc02002ba:	0141                	addi	sp,sp,16
ffffffffc02002bc:	8082                	ret

ffffffffc02002be <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002be:	1141                	addi	sp,sp,-16
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002c2:	ef1ff0ef          	jal	ra,ffffffffc02001b2 <print_kerninfo>
    return 0;
}
ffffffffc02002c6:	60a2                	ld	ra,8(sp)
ffffffffc02002c8:	4501                	li	a0,0
ffffffffc02002ca:	0141                	addi	sp,sp,16
ffffffffc02002cc:	8082                	ret

ffffffffc02002ce <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ce:	1141                	addi	sp,sp,-16
ffffffffc02002d0:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002d2:	f71ff0ef          	jal	ra,ffffffffc0200242 <print_stackframe>
    return 0;
}
ffffffffc02002d6:	60a2                	ld	ra,8(sp)
ffffffffc02002d8:	4501                	li	a0,0
ffffffffc02002da:	0141                	addi	sp,sp,16
ffffffffc02002dc:	8082                	ret

ffffffffc02002de <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002de:	7115                	addi	sp,sp,-224
ffffffffc02002e0:	e962                	sd	s8,144(sp)
ffffffffc02002e2:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002e4:	00002517          	auipc	a0,0x2
ffffffffc02002e8:	9a450513          	addi	a0,a0,-1628 # ffffffffc0201c88 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc02002ec:	ed86                	sd	ra,216(sp)
ffffffffc02002ee:	e9a2                	sd	s0,208(sp)
ffffffffc02002f0:	e5a6                	sd	s1,200(sp)
ffffffffc02002f2:	e1ca                	sd	s2,192(sp)
ffffffffc02002f4:	fd4e                	sd	s3,184(sp)
ffffffffc02002f6:	f952                	sd	s4,176(sp)
ffffffffc02002f8:	f556                	sd	s5,168(sp)
ffffffffc02002fa:	f15a                	sd	s6,160(sp)
ffffffffc02002fc:	ed5e                	sd	s7,152(sp)
ffffffffc02002fe:	e566                	sd	s9,136(sp)
ffffffffc0200300:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200302:	dc9ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200306:	00002517          	auipc	a0,0x2
ffffffffc020030a:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0201cb0 <commands+0x70>
ffffffffc020030e:	dbdff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    if (tf != NULL) {
ffffffffc0200312:	000c0563          	beqz	s8,ffffffffc020031c <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200316:	8562                	mv	a0,s8
ffffffffc0200318:	346000ef          	jal	ra,ffffffffc020065e <print_trapframe>
ffffffffc020031c:	00002c97          	auipc	s9,0x2
ffffffffc0200320:	924c8c93          	addi	s9,s9,-1756 # ffffffffc0201c40 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200324:	00002997          	auipc	s3,0x2
ffffffffc0200328:	9b498993          	addi	s3,s3,-1612 # ffffffffc0201cd8 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020032c:	00002917          	auipc	s2,0x2
ffffffffc0200330:	9b490913          	addi	s2,s2,-1612 # ffffffffc0201ce0 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc0200334:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200336:	00002b17          	auipc	s6,0x2
ffffffffc020033a:	9b2b0b13          	addi	s6,s6,-1614 # ffffffffc0201ce8 <commands+0xa8>
    if (argc == 0) {
ffffffffc020033e:	00002a97          	auipc	s5,0x2
ffffffffc0200342:	a02a8a93          	addi	s5,s5,-1534 # ffffffffc0201d40 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200346:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200348:	854e                	mv	a0,s3
ffffffffc020034a:	694010ef          	jal	ra,ffffffffc02019de <readline>
ffffffffc020034e:	842a                	mv	s0,a0
ffffffffc0200350:	dd65                	beqz	a0,ffffffffc0200348 <kmonitor+0x6a>
ffffffffc0200352:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200356:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200358:	c999                	beqz	a1,ffffffffc020036e <kmonitor+0x90>
ffffffffc020035a:	854a                	mv	a0,s2
ffffffffc020035c:	25a010ef          	jal	ra,ffffffffc02015b6 <strchr>
ffffffffc0200360:	c925                	beqz	a0,ffffffffc02003d0 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc0200362:	00144583          	lbu	a1,1(s0)
ffffffffc0200366:	00040023          	sb	zero,0(s0)
ffffffffc020036a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020036c:	f5fd                	bnez	a1,ffffffffc020035a <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc020036e:	dce9                	beqz	s1,ffffffffc0200348 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200370:	6582                	ld	a1,0(sp)
ffffffffc0200372:	00002d17          	auipc	s10,0x2
ffffffffc0200376:	8ced0d13          	addi	s10,s10,-1842 # ffffffffc0201c40 <commands>
    if (argc == 0) {
ffffffffc020037a:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020037c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020037e:	0d61                	addi	s10,s10,24
ffffffffc0200380:	20c010ef          	jal	ra,ffffffffc020158c <strcmp>
ffffffffc0200384:	c919                	beqz	a0,ffffffffc020039a <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200386:	2405                	addiw	s0,s0,1
ffffffffc0200388:	09740463          	beq	s0,s7,ffffffffc0200410 <kmonitor+0x132>
ffffffffc020038c:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200390:	6582                	ld	a1,0(sp)
ffffffffc0200392:	0d61                	addi	s10,s10,24
ffffffffc0200394:	1f8010ef          	jal	ra,ffffffffc020158c <strcmp>
ffffffffc0200398:	f57d                	bnez	a0,ffffffffc0200386 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020039a:	00141793          	slli	a5,s0,0x1
ffffffffc020039e:	97a2                	add	a5,a5,s0
ffffffffc02003a0:	078e                	slli	a5,a5,0x3
ffffffffc02003a2:	97e6                	add	a5,a5,s9
ffffffffc02003a4:	6b9c                	ld	a5,16(a5)
ffffffffc02003a6:	8662                	mv	a2,s8
ffffffffc02003a8:	002c                	addi	a1,sp,8
ffffffffc02003aa:	fff4851b          	addiw	a0,s1,-1
ffffffffc02003ae:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003b0:	f8055ce3          	bgez	a0,ffffffffc0200348 <kmonitor+0x6a>
}
ffffffffc02003b4:	60ee                	ld	ra,216(sp)
ffffffffc02003b6:	644e                	ld	s0,208(sp)
ffffffffc02003b8:	64ae                	ld	s1,200(sp)
ffffffffc02003ba:	690e                	ld	s2,192(sp)
ffffffffc02003bc:	79ea                	ld	s3,184(sp)
ffffffffc02003be:	7a4a                	ld	s4,176(sp)
ffffffffc02003c0:	7aaa                	ld	s5,168(sp)
ffffffffc02003c2:	7b0a                	ld	s6,160(sp)
ffffffffc02003c4:	6bea                	ld	s7,152(sp)
ffffffffc02003c6:	6c4a                	ld	s8,144(sp)
ffffffffc02003c8:	6caa                	ld	s9,136(sp)
ffffffffc02003ca:	6d0a                	ld	s10,128(sp)
ffffffffc02003cc:	612d                	addi	sp,sp,224
ffffffffc02003ce:	8082                	ret
        if (*buf == '\0') {
ffffffffc02003d0:	00044783          	lbu	a5,0(s0)
ffffffffc02003d4:	dfc9                	beqz	a5,ffffffffc020036e <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc02003d6:	03448863          	beq	s1,s4,ffffffffc0200406 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc02003da:	00349793          	slli	a5,s1,0x3
ffffffffc02003de:	0118                	addi	a4,sp,128
ffffffffc02003e0:	97ba                	add	a5,a5,a4
ffffffffc02003e2:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003e6:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003ea:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003ec:	e591                	bnez	a1,ffffffffc02003f8 <kmonitor+0x11a>
ffffffffc02003ee:	b749                	j	ffffffffc0200370 <kmonitor+0x92>
            buf ++;
ffffffffc02003f0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003f2:	00044583          	lbu	a1,0(s0)
ffffffffc02003f6:	ddad                	beqz	a1,ffffffffc0200370 <kmonitor+0x92>
ffffffffc02003f8:	854a                	mv	a0,s2
ffffffffc02003fa:	1bc010ef          	jal	ra,ffffffffc02015b6 <strchr>
ffffffffc02003fe:	d96d                	beqz	a0,ffffffffc02003f0 <kmonitor+0x112>
ffffffffc0200400:	00044583          	lbu	a1,0(s0)
ffffffffc0200404:	bf91                	j	ffffffffc0200358 <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200406:	45c1                	li	a1,16
ffffffffc0200408:	855a                	mv	a0,s6
ffffffffc020040a:	cc1ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
ffffffffc020040e:	b7f1                	j	ffffffffc02003da <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200410:	6582                	ld	a1,0(sp)
ffffffffc0200412:	00002517          	auipc	a0,0x2
ffffffffc0200416:	8f650513          	addi	a0,a0,-1802 # ffffffffc0201d08 <commands+0xc8>
ffffffffc020041a:	cb1ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    return 0;
ffffffffc020041e:	b72d                	j	ffffffffc0200348 <kmonitor+0x6a>

ffffffffc0200420 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200420:	1141                	addi	sp,sp,-16
ffffffffc0200422:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200424:	02000793          	li	a5,32
ffffffffc0200428:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020042c:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200430:	67e1                	lui	a5,0x18
ffffffffc0200432:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc0200436:	953e                	add	a0,a0,a5
ffffffffc0200438:	680010ef          	jal	ra,ffffffffc0201ab8 <sbi_set_timer>
}
ffffffffc020043c:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020043e:	00006797          	auipc	a5,0x6
ffffffffc0200442:	fe07b923          	sd	zero,-14(a5) # ffffffffc0206430 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200446:	00002517          	auipc	a0,0x2
ffffffffc020044a:	97a50513          	addi	a0,a0,-1670 # ffffffffc0201dc0 <commands+0x180>
}
ffffffffc020044e:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200450:	c7bff06f          	j	ffffffffc02000ca <cprintf>

ffffffffc0200454 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200454:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200458:	67e1                	lui	a5,0x18
ffffffffc020045a:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020045e:	953e                	add	a0,a0,a5
ffffffffc0200460:	6580106f          	j	ffffffffc0201ab8 <sbi_set_timer>

ffffffffc0200464 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200464:	8082                	ret

ffffffffc0200466 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200466:	0ff57513          	andi	a0,a0,255
ffffffffc020046a:	6320106f          	j	ffffffffc0201a9c <sbi_console_putchar>

ffffffffc020046e <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020046e:	6660106f          	j	ffffffffc0201ad4 <sbi_console_getchar>

ffffffffc0200472 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200472:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200476:	8082                	ret

ffffffffc0200478 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200478:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020047c:	8082                	ret

ffffffffc020047e <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020047e:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200482:	00000797          	auipc	a5,0x0
ffffffffc0200486:	31278793          	addi	a5,a5,786 # ffffffffc0200794 <__alltraps>
ffffffffc020048a:	10579073          	csrw	stvec,a5
}
ffffffffc020048e:	8082                	ret

ffffffffc0200490 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200490:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200492:	1141                	addi	sp,sp,-16
ffffffffc0200494:	e022                	sd	s0,0(sp)
ffffffffc0200496:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200498:	00002517          	auipc	a0,0x2
ffffffffc020049c:	a4050513          	addi	a0,a0,-1472 # ffffffffc0201ed8 <commands+0x298>
void print_regs(struct pushregs *gpr) {
ffffffffc02004a0:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02004a2:	c29ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02004a6:	640c                	ld	a1,8(s0)
ffffffffc02004a8:	00002517          	auipc	a0,0x2
ffffffffc02004ac:	a4850513          	addi	a0,a0,-1464 # ffffffffc0201ef0 <commands+0x2b0>
ffffffffc02004b0:	c1bff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004b4:	680c                	ld	a1,16(s0)
ffffffffc02004b6:	00002517          	auipc	a0,0x2
ffffffffc02004ba:	a5250513          	addi	a0,a0,-1454 # ffffffffc0201f08 <commands+0x2c8>
ffffffffc02004be:	c0dff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004c2:	6c0c                	ld	a1,24(s0)
ffffffffc02004c4:	00002517          	auipc	a0,0x2
ffffffffc02004c8:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0201f20 <commands+0x2e0>
ffffffffc02004cc:	bffff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004d0:	700c                	ld	a1,32(s0)
ffffffffc02004d2:	00002517          	auipc	a0,0x2
ffffffffc02004d6:	a6650513          	addi	a0,a0,-1434 # ffffffffc0201f38 <commands+0x2f8>
ffffffffc02004da:	bf1ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004de:	740c                	ld	a1,40(s0)
ffffffffc02004e0:	00002517          	auipc	a0,0x2
ffffffffc02004e4:	a7050513          	addi	a0,a0,-1424 # ffffffffc0201f50 <commands+0x310>
ffffffffc02004e8:	be3ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004ec:	780c                	ld	a1,48(s0)
ffffffffc02004ee:	00002517          	auipc	a0,0x2
ffffffffc02004f2:	a7a50513          	addi	a0,a0,-1414 # ffffffffc0201f68 <commands+0x328>
ffffffffc02004f6:	bd5ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004fa:	7c0c                	ld	a1,56(s0)
ffffffffc02004fc:	00002517          	auipc	a0,0x2
ffffffffc0200500:	a8450513          	addi	a0,a0,-1404 # ffffffffc0201f80 <commands+0x340>
ffffffffc0200504:	bc7ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200508:	602c                	ld	a1,64(s0)
ffffffffc020050a:	00002517          	auipc	a0,0x2
ffffffffc020050e:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0201f98 <commands+0x358>
ffffffffc0200512:	bb9ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200516:	642c                	ld	a1,72(s0)
ffffffffc0200518:	00002517          	auipc	a0,0x2
ffffffffc020051c:	a9850513          	addi	a0,a0,-1384 # ffffffffc0201fb0 <commands+0x370>
ffffffffc0200520:	babff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200524:	682c                	ld	a1,80(s0)
ffffffffc0200526:	00002517          	auipc	a0,0x2
ffffffffc020052a:	aa250513          	addi	a0,a0,-1374 # ffffffffc0201fc8 <commands+0x388>
ffffffffc020052e:	b9dff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200532:	6c2c                	ld	a1,88(s0)
ffffffffc0200534:	00002517          	auipc	a0,0x2
ffffffffc0200538:	aac50513          	addi	a0,a0,-1364 # ffffffffc0201fe0 <commands+0x3a0>
ffffffffc020053c:	b8fff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200540:	702c                	ld	a1,96(s0)
ffffffffc0200542:	00002517          	auipc	a0,0x2
ffffffffc0200546:	ab650513          	addi	a0,a0,-1354 # ffffffffc0201ff8 <commands+0x3b8>
ffffffffc020054a:	b81ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020054e:	742c                	ld	a1,104(s0)
ffffffffc0200550:	00002517          	auipc	a0,0x2
ffffffffc0200554:	ac050513          	addi	a0,a0,-1344 # ffffffffc0202010 <commands+0x3d0>
ffffffffc0200558:	b73ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020055c:	782c                	ld	a1,112(s0)
ffffffffc020055e:	00002517          	auipc	a0,0x2
ffffffffc0200562:	aca50513          	addi	a0,a0,-1334 # ffffffffc0202028 <commands+0x3e8>
ffffffffc0200566:	b65ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020056a:	7c2c                	ld	a1,120(s0)
ffffffffc020056c:	00002517          	auipc	a0,0x2
ffffffffc0200570:	ad450513          	addi	a0,a0,-1324 # ffffffffc0202040 <commands+0x400>
ffffffffc0200574:	b57ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200578:	604c                	ld	a1,128(s0)
ffffffffc020057a:	00002517          	auipc	a0,0x2
ffffffffc020057e:	ade50513          	addi	a0,a0,-1314 # ffffffffc0202058 <commands+0x418>
ffffffffc0200582:	b49ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200586:	644c                	ld	a1,136(s0)
ffffffffc0200588:	00002517          	auipc	a0,0x2
ffffffffc020058c:	ae850513          	addi	a0,a0,-1304 # ffffffffc0202070 <commands+0x430>
ffffffffc0200590:	b3bff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200594:	684c                	ld	a1,144(s0)
ffffffffc0200596:	00002517          	auipc	a0,0x2
ffffffffc020059a:	af250513          	addi	a0,a0,-1294 # ffffffffc0202088 <commands+0x448>
ffffffffc020059e:	b2dff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02005a2:	6c4c                	ld	a1,152(s0)
ffffffffc02005a4:	00002517          	auipc	a0,0x2
ffffffffc02005a8:	afc50513          	addi	a0,a0,-1284 # ffffffffc02020a0 <commands+0x460>
ffffffffc02005ac:	b1fff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02005b0:	704c                	ld	a1,160(s0)
ffffffffc02005b2:	00002517          	auipc	a0,0x2
ffffffffc02005b6:	b0650513          	addi	a0,a0,-1274 # ffffffffc02020b8 <commands+0x478>
ffffffffc02005ba:	b11ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005be:	744c                	ld	a1,168(s0)
ffffffffc02005c0:	00002517          	auipc	a0,0x2
ffffffffc02005c4:	b1050513          	addi	a0,a0,-1264 # ffffffffc02020d0 <commands+0x490>
ffffffffc02005c8:	b03ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005cc:	784c                	ld	a1,176(s0)
ffffffffc02005ce:	00002517          	auipc	a0,0x2
ffffffffc02005d2:	b1a50513          	addi	a0,a0,-1254 # ffffffffc02020e8 <commands+0x4a8>
ffffffffc02005d6:	af5ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005da:	7c4c                	ld	a1,184(s0)
ffffffffc02005dc:	00002517          	auipc	a0,0x2
ffffffffc02005e0:	b2450513          	addi	a0,a0,-1244 # ffffffffc0202100 <commands+0x4c0>
ffffffffc02005e4:	ae7ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005e8:	606c                	ld	a1,192(s0)
ffffffffc02005ea:	00002517          	auipc	a0,0x2
ffffffffc02005ee:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0202118 <commands+0x4d8>
ffffffffc02005f2:	ad9ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005f6:	646c                	ld	a1,200(s0)
ffffffffc02005f8:	00002517          	auipc	a0,0x2
ffffffffc02005fc:	b3850513          	addi	a0,a0,-1224 # ffffffffc0202130 <commands+0x4f0>
ffffffffc0200600:	acbff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200604:	686c                	ld	a1,208(s0)
ffffffffc0200606:	00002517          	auipc	a0,0x2
ffffffffc020060a:	b4250513          	addi	a0,a0,-1214 # ffffffffc0202148 <commands+0x508>
ffffffffc020060e:	abdff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200612:	6c6c                	ld	a1,216(s0)
ffffffffc0200614:	00002517          	auipc	a0,0x2
ffffffffc0200618:	b4c50513          	addi	a0,a0,-1204 # ffffffffc0202160 <commands+0x520>
ffffffffc020061c:	aafff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200620:	706c                	ld	a1,224(s0)
ffffffffc0200622:	00002517          	auipc	a0,0x2
ffffffffc0200626:	b5650513          	addi	a0,a0,-1194 # ffffffffc0202178 <commands+0x538>
ffffffffc020062a:	aa1ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020062e:	746c                	ld	a1,232(s0)
ffffffffc0200630:	00002517          	auipc	a0,0x2
ffffffffc0200634:	b6050513          	addi	a0,a0,-1184 # ffffffffc0202190 <commands+0x550>
ffffffffc0200638:	a93ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020063c:	786c                	ld	a1,240(s0)
ffffffffc020063e:	00002517          	auipc	a0,0x2
ffffffffc0200642:	b6a50513          	addi	a0,a0,-1174 # ffffffffc02021a8 <commands+0x568>
ffffffffc0200646:	a85ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020064a:	7c6c                	ld	a1,248(s0)
}
ffffffffc020064c:	6402                	ld	s0,0(sp)
ffffffffc020064e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200650:	00002517          	auipc	a0,0x2
ffffffffc0200654:	b7050513          	addi	a0,a0,-1168 # ffffffffc02021c0 <commands+0x580>
}
ffffffffc0200658:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020065a:	a71ff06f          	j	ffffffffc02000ca <cprintf>

ffffffffc020065e <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020065e:	1141                	addi	sp,sp,-16
ffffffffc0200660:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200662:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200664:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200666:	00002517          	auipc	a0,0x2
ffffffffc020066a:	b7250513          	addi	a0,a0,-1166 # ffffffffc02021d8 <commands+0x598>
void print_trapframe(struct trapframe *tf) {
ffffffffc020066e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200670:	a5bff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200674:	8522                	mv	a0,s0
ffffffffc0200676:	e1bff0ef          	jal	ra,ffffffffc0200490 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020067a:	10043583          	ld	a1,256(s0)
ffffffffc020067e:	00002517          	auipc	a0,0x2
ffffffffc0200682:	b7250513          	addi	a0,a0,-1166 # ffffffffc02021f0 <commands+0x5b0>
ffffffffc0200686:	a45ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020068a:	10843583          	ld	a1,264(s0)
ffffffffc020068e:	00002517          	auipc	a0,0x2
ffffffffc0200692:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0202208 <commands+0x5c8>
ffffffffc0200696:	a35ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020069a:	11043583          	ld	a1,272(s0)
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	b8250513          	addi	a0,a0,-1150 # ffffffffc0202220 <commands+0x5e0>
ffffffffc02006a6:	a25ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006aa:	11843583          	ld	a1,280(s0)
}
ffffffffc02006ae:	6402                	ld	s0,0(sp)
ffffffffc02006b0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006b2:	00002517          	auipc	a0,0x2
ffffffffc02006b6:	b8650513          	addi	a0,a0,-1146 # ffffffffc0202238 <commands+0x5f8>
}
ffffffffc02006ba:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006bc:	a0fff06f          	j	ffffffffc02000ca <cprintf>

ffffffffc02006c0 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006c0:	11853783          	ld	a5,280(a0)
ffffffffc02006c4:	577d                	li	a4,-1
ffffffffc02006c6:	8305                	srli	a4,a4,0x1
ffffffffc02006c8:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02006ca:	472d                	li	a4,11
ffffffffc02006cc:	0af76563          	bltu	a4,a5,ffffffffc0200776 <interrupt_handler+0xb6>
ffffffffc02006d0:	00001717          	auipc	a4,0x1
ffffffffc02006d4:	70c70713          	addi	a4,a4,1804 # ffffffffc0201ddc <commands+0x19c>
ffffffffc02006d8:	078a                	slli	a5,a5,0x2
ffffffffc02006da:	97ba                	add	a5,a5,a4
ffffffffc02006dc:	439c                	lw	a5,0(a5)
ffffffffc02006de:	97ba                	add	a5,a5,a4
ffffffffc02006e0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006e2:	00001517          	auipc	a0,0x1
ffffffffc02006e6:	78e50513          	addi	a0,a0,1934 # ffffffffc0201e70 <commands+0x230>
ffffffffc02006ea:	9e1ff06f          	j	ffffffffc02000ca <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006ee:	00001517          	auipc	a0,0x1
ffffffffc02006f2:	76250513          	addi	a0,a0,1890 # ffffffffc0201e50 <commands+0x210>
ffffffffc02006f6:	9d5ff06f          	j	ffffffffc02000ca <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006fa:	00001517          	auipc	a0,0x1
ffffffffc02006fe:	71650513          	addi	a0,a0,1814 # ffffffffc0201e10 <commands+0x1d0>
ffffffffc0200702:	9c9ff06f          	j	ffffffffc02000ca <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200706:	00001517          	auipc	a0,0x1
ffffffffc020070a:	78a50513          	addi	a0,a0,1930 # ffffffffc0201e90 <commands+0x250>
ffffffffc020070e:	9bdff06f          	j	ffffffffc02000ca <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200712:	1141                	addi	sp,sp,-16
ffffffffc0200714:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
             clock_set_next_event();
ffffffffc0200716:	d3fff0ef          	jal	ra,ffffffffc0200454 <clock_set_next_event>
            ticks++;
ffffffffc020071a:	00006717          	auipc	a4,0x6
ffffffffc020071e:	d1670713          	addi	a4,a4,-746 # ffffffffc0206430 <ticks>
ffffffffc0200722:	631c                	ld	a5,0(a4)
ffffffffc0200724:	0785                	addi	a5,a5,1
ffffffffc0200726:	00006697          	auipc	a3,0x6
ffffffffc020072a:	d0f6b523          	sd	a5,-758(a3) # ffffffffc0206430 <ticks>
            if (ticks % TICK_NUM == 0 && ticks<=1000) {
ffffffffc020072e:	631c                	ld	a5,0(a4)
ffffffffc0200730:	06400693          	li	a3,100
ffffffffc0200734:	02d7f7b3          	remu	a5,a5,a3
ffffffffc0200738:	ef85                	bnez	a5,ffffffffc0200770 <interrupt_handler+0xb0>
ffffffffc020073a:	6318                	ld	a4,0(a4)
ffffffffc020073c:	3e800793          	li	a5,1000
ffffffffc0200740:	02e7e863          	bltu	a5,a4,ffffffffc0200770 <interrupt_handler+0xb0>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200744:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200746:	06400593          	li	a1,100
ffffffffc020074a:	00001517          	auipc	a0,0x1
ffffffffc020074e:	75e50513          	addi	a0,a0,1886 # ffffffffc0201ea8 <commands+0x268>
}
ffffffffc0200752:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200754:	977ff06f          	j	ffffffffc02000ca <cprintf>
            cprintf("Supervisor external interrupt\n");
ffffffffc0200758:	00001517          	auipc	a0,0x1
ffffffffc020075c:	76050513          	addi	a0,a0,1888 # ffffffffc0201eb8 <commands+0x278>
ffffffffc0200760:	96bff06f          	j	ffffffffc02000ca <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200764:	00001517          	auipc	a0,0x1
ffffffffc0200768:	6cc50513          	addi	a0,a0,1740 # ffffffffc0201e30 <commands+0x1f0>
ffffffffc020076c:	95fff06f          	j	ffffffffc02000ca <cprintf>
}
ffffffffc0200770:	60a2                	ld	ra,8(sp)
ffffffffc0200772:	0141                	addi	sp,sp,16
ffffffffc0200774:	8082                	ret
            print_trapframe(tf);
ffffffffc0200776:	ee9ff06f          	j	ffffffffc020065e <print_trapframe>

ffffffffc020077a <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc020077a:	11853783          	ld	a5,280(a0)
ffffffffc020077e:	0007c863          	bltz	a5,ffffffffc020078e <trap+0x14>
    switch (tf->cause) {
ffffffffc0200782:	472d                	li	a4,11
ffffffffc0200784:	00f76363          	bltu	a4,a5,ffffffffc020078a <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200788:	8082                	ret
            print_trapframe(tf);
ffffffffc020078a:	ed5ff06f          	j	ffffffffc020065e <print_trapframe>
        interrupt_handler(tf);
ffffffffc020078e:	f33ff06f          	j	ffffffffc02006c0 <interrupt_handler>
	...

ffffffffc0200794 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200794:	14011073          	csrw	sscratch,sp
ffffffffc0200798:	712d                	addi	sp,sp,-288
ffffffffc020079a:	e002                	sd	zero,0(sp)
ffffffffc020079c:	e406                	sd	ra,8(sp)
ffffffffc020079e:	ec0e                	sd	gp,24(sp)
ffffffffc02007a0:	f012                	sd	tp,32(sp)
ffffffffc02007a2:	f416                	sd	t0,40(sp)
ffffffffc02007a4:	f81a                	sd	t1,48(sp)
ffffffffc02007a6:	fc1e                	sd	t2,56(sp)
ffffffffc02007a8:	e0a2                	sd	s0,64(sp)
ffffffffc02007aa:	e4a6                	sd	s1,72(sp)
ffffffffc02007ac:	e8aa                	sd	a0,80(sp)
ffffffffc02007ae:	ecae                	sd	a1,88(sp)
ffffffffc02007b0:	f0b2                	sd	a2,96(sp)
ffffffffc02007b2:	f4b6                	sd	a3,104(sp)
ffffffffc02007b4:	f8ba                	sd	a4,112(sp)
ffffffffc02007b6:	fcbe                	sd	a5,120(sp)
ffffffffc02007b8:	e142                	sd	a6,128(sp)
ffffffffc02007ba:	e546                	sd	a7,136(sp)
ffffffffc02007bc:	e94a                	sd	s2,144(sp)
ffffffffc02007be:	ed4e                	sd	s3,152(sp)
ffffffffc02007c0:	f152                	sd	s4,160(sp)
ffffffffc02007c2:	f556                	sd	s5,168(sp)
ffffffffc02007c4:	f95a                	sd	s6,176(sp)
ffffffffc02007c6:	fd5e                	sd	s7,184(sp)
ffffffffc02007c8:	e1e2                	sd	s8,192(sp)
ffffffffc02007ca:	e5e6                	sd	s9,200(sp)
ffffffffc02007cc:	e9ea                	sd	s10,208(sp)
ffffffffc02007ce:	edee                	sd	s11,216(sp)
ffffffffc02007d0:	f1f2                	sd	t3,224(sp)
ffffffffc02007d2:	f5f6                	sd	t4,232(sp)
ffffffffc02007d4:	f9fa                	sd	t5,240(sp)
ffffffffc02007d6:	fdfe                	sd	t6,248(sp)
ffffffffc02007d8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc02007dc:	100024f3          	csrr	s1,sstatus
ffffffffc02007e0:	14102973          	csrr	s2,sepc
ffffffffc02007e4:	143029f3          	csrr	s3,stval
ffffffffc02007e8:	14202a73          	csrr	s4,scause
ffffffffc02007ec:	e822                	sd	s0,16(sp)
ffffffffc02007ee:	e226                	sd	s1,256(sp)
ffffffffc02007f0:	e64a                	sd	s2,264(sp)
ffffffffc02007f2:	ea4e                	sd	s3,272(sp)
ffffffffc02007f4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007f6:	850a                	mv	a0,sp
    jal trap
ffffffffc02007f8:	f83ff0ef          	jal	ra,ffffffffc020077a <trap>

ffffffffc02007fc <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007fc:	6492                	ld	s1,256(sp)
ffffffffc02007fe:	6932                	ld	s2,264(sp)
ffffffffc0200800:	10049073          	csrw	sstatus,s1
ffffffffc0200804:	14191073          	csrw	sepc,s2
ffffffffc0200808:	60a2                	ld	ra,8(sp)
ffffffffc020080a:	61e2                	ld	gp,24(sp)
ffffffffc020080c:	7202                	ld	tp,32(sp)
ffffffffc020080e:	72a2                	ld	t0,40(sp)
ffffffffc0200810:	7342                	ld	t1,48(sp)
ffffffffc0200812:	73e2                	ld	t2,56(sp)
ffffffffc0200814:	6406                	ld	s0,64(sp)
ffffffffc0200816:	64a6                	ld	s1,72(sp)
ffffffffc0200818:	6546                	ld	a0,80(sp)
ffffffffc020081a:	65e6                	ld	a1,88(sp)
ffffffffc020081c:	7606                	ld	a2,96(sp)
ffffffffc020081e:	76a6                	ld	a3,104(sp)
ffffffffc0200820:	7746                	ld	a4,112(sp)
ffffffffc0200822:	77e6                	ld	a5,120(sp)
ffffffffc0200824:	680a                	ld	a6,128(sp)
ffffffffc0200826:	68aa                	ld	a7,136(sp)
ffffffffc0200828:	694a                	ld	s2,144(sp)
ffffffffc020082a:	69ea                	ld	s3,152(sp)
ffffffffc020082c:	7a0a                	ld	s4,160(sp)
ffffffffc020082e:	7aaa                	ld	s5,168(sp)
ffffffffc0200830:	7b4a                	ld	s6,176(sp)
ffffffffc0200832:	7bea                	ld	s7,184(sp)
ffffffffc0200834:	6c0e                	ld	s8,192(sp)
ffffffffc0200836:	6cae                	ld	s9,200(sp)
ffffffffc0200838:	6d4e                	ld	s10,208(sp)
ffffffffc020083a:	6dee                	ld	s11,216(sp)
ffffffffc020083c:	7e0e                	ld	t3,224(sp)
ffffffffc020083e:	7eae                	ld	t4,232(sp)
ffffffffc0200840:	7f4e                	ld	t5,240(sp)
ffffffffc0200842:	7fee                	ld	t6,248(sp)
ffffffffc0200844:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200846:	10200073          	sret

ffffffffc020084a <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020084a:	100027f3          	csrr	a5,sstatus
ffffffffc020084e:	8b89                	andi	a5,a5,2
ffffffffc0200850:	eb89                	bnez	a5,ffffffffc0200862 <alloc_pages+0x18>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200852:	00006797          	auipc	a5,0x6
ffffffffc0200856:	bee78793          	addi	a5,a5,-1042 # ffffffffc0206440 <pmm_manager>
ffffffffc020085a:	639c                	ld	a5,0(a5)
ffffffffc020085c:	0187b303          	ld	t1,24(a5)
ffffffffc0200860:	8302                	jr	t1
struct Page *alloc_pages(size_t n) {
ffffffffc0200862:	1141                	addi	sp,sp,-16
ffffffffc0200864:	e406                	sd	ra,8(sp)
ffffffffc0200866:	e022                	sd	s0,0(sp)
ffffffffc0200868:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020086a:	c0fff0ef          	jal	ra,ffffffffc0200478 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020086e:	00006797          	auipc	a5,0x6
ffffffffc0200872:	bd278793          	addi	a5,a5,-1070 # ffffffffc0206440 <pmm_manager>
ffffffffc0200876:	639c                	ld	a5,0(a5)
ffffffffc0200878:	8522                	mv	a0,s0
ffffffffc020087a:	6f9c                	ld	a5,24(a5)
ffffffffc020087c:	9782                	jalr	a5
ffffffffc020087e:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0200880:	bf3ff0ef          	jal	ra,ffffffffc0200472 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200884:	8522                	mv	a0,s0
ffffffffc0200886:	60a2                	ld	ra,8(sp)
ffffffffc0200888:	6402                	ld	s0,0(sp)
ffffffffc020088a:	0141                	addi	sp,sp,16
ffffffffc020088c:	8082                	ret

ffffffffc020088e <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020088e:	100027f3          	csrr	a5,sstatus
ffffffffc0200892:	8b89                	andi	a5,a5,2
ffffffffc0200894:	eb89                	bnez	a5,ffffffffc02008a6 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200896:	00006797          	auipc	a5,0x6
ffffffffc020089a:	baa78793          	addi	a5,a5,-1110 # ffffffffc0206440 <pmm_manager>
ffffffffc020089e:	639c                	ld	a5,0(a5)
ffffffffc02008a0:	0207b303          	ld	t1,32(a5)
ffffffffc02008a4:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc02008a6:	1101                	addi	sp,sp,-32
ffffffffc02008a8:	ec06                	sd	ra,24(sp)
ffffffffc02008aa:	e822                	sd	s0,16(sp)
ffffffffc02008ac:	e426                	sd	s1,8(sp)
ffffffffc02008ae:	842a                	mv	s0,a0
ffffffffc02008b0:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02008b2:	bc7ff0ef          	jal	ra,ffffffffc0200478 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02008b6:	00006797          	auipc	a5,0x6
ffffffffc02008ba:	b8a78793          	addi	a5,a5,-1142 # ffffffffc0206440 <pmm_manager>
ffffffffc02008be:	639c                	ld	a5,0(a5)
ffffffffc02008c0:	85a6                	mv	a1,s1
ffffffffc02008c2:	8522                	mv	a0,s0
ffffffffc02008c4:	739c                	ld	a5,32(a5)
ffffffffc02008c6:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02008c8:	6442                	ld	s0,16(sp)
ffffffffc02008ca:	60e2                	ld	ra,24(sp)
ffffffffc02008cc:	64a2                	ld	s1,8(sp)
ffffffffc02008ce:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02008d0:	ba3ff06f          	j	ffffffffc0200472 <intr_enable>

ffffffffc02008d4 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02008d4:	100027f3          	csrr	a5,sstatus
ffffffffc02008d8:	8b89                	andi	a5,a5,2
ffffffffc02008da:	eb89                	bnez	a5,ffffffffc02008ec <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02008dc:	00006797          	auipc	a5,0x6
ffffffffc02008e0:	b6478793          	addi	a5,a5,-1180 # ffffffffc0206440 <pmm_manager>
ffffffffc02008e4:	639c                	ld	a5,0(a5)
ffffffffc02008e6:	0287b303          	ld	t1,40(a5)
ffffffffc02008ea:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc02008ec:	1141                	addi	sp,sp,-16
ffffffffc02008ee:	e406                	sd	ra,8(sp)
ffffffffc02008f0:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02008f2:	b87ff0ef          	jal	ra,ffffffffc0200478 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02008f6:	00006797          	auipc	a5,0x6
ffffffffc02008fa:	b4a78793          	addi	a5,a5,-1206 # ffffffffc0206440 <pmm_manager>
ffffffffc02008fe:	639c                	ld	a5,0(a5)
ffffffffc0200900:	779c                	ld	a5,40(a5)
ffffffffc0200902:	9782                	jalr	a5
ffffffffc0200904:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200906:	b6dff0ef          	jal	ra,ffffffffc0200472 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020090a:	8522                	mv	a0,s0
ffffffffc020090c:	60a2                	ld	ra,8(sp)
ffffffffc020090e:	6402                	ld	s0,0(sp)
ffffffffc0200910:	0141                	addi	sp,sp,16
ffffffffc0200912:	8082                	ret

ffffffffc0200914 <pmm_init>:
      pmm_manager = &best_fit_pmm_manager;
ffffffffc0200914:	00002797          	auipc	a5,0x2
ffffffffc0200918:	d9c78793          	addi	a5,a5,-612 # ffffffffc02026b0 <best_fit_pmm_manager>
      cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020091c:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020091e:	1101                	addi	sp,sp,-32
      cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200920:	00002517          	auipc	a0,0x2
ffffffffc0200924:	93050513          	addi	a0,a0,-1744 # ffffffffc0202250 <commands+0x610>
void pmm_init(void) {
ffffffffc0200928:	ec06                	sd	ra,24(sp)
      pmm_manager = &best_fit_pmm_manager;
ffffffffc020092a:	00006717          	auipc	a4,0x6
ffffffffc020092e:	b0f73b23          	sd	a5,-1258(a4) # ffffffffc0206440 <pmm_manager>
void pmm_init(void) {
ffffffffc0200932:	e822                	sd	s0,16(sp)
ffffffffc0200934:	e426                	sd	s1,8(sp)
      pmm_manager = &best_fit_pmm_manager;
ffffffffc0200936:	00006417          	auipc	s0,0x6
ffffffffc020093a:	b0a40413          	addi	s0,s0,-1270 # ffffffffc0206440 <pmm_manager>
      cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020093e:	f8cff0ef          	jal	ra,ffffffffc02000ca <cprintf>
      pmm_manager->init();
ffffffffc0200942:	601c                	ld	a5,0(s0)
ffffffffc0200944:	679c                	ld	a5,8(a5)
ffffffffc0200946:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200948:	57f5                	li	a5,-3
ffffffffc020094a:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc020094c:	00002517          	auipc	a0,0x2
ffffffffc0200950:	91c50513          	addi	a0,a0,-1764 # ffffffffc0202268 <commands+0x628>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200954:	00006717          	auipc	a4,0x6
ffffffffc0200958:	aef73a23          	sd	a5,-1292(a4) # ffffffffc0206448 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc020095c:	f6eff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200960:	46c5                	li	a3,17
ffffffffc0200962:	06ee                	slli	a3,a3,0x1b
ffffffffc0200964:	40100613          	li	a2,1025
ffffffffc0200968:	16fd                	addi	a3,a3,-1
ffffffffc020096a:	0656                	slli	a2,a2,0x15
ffffffffc020096c:	07e005b7          	lui	a1,0x7e00
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	91050513          	addi	a0,a0,-1776 # ffffffffc0202280 <commands+0x640>
ffffffffc0200978:	f52ff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020097c:	777d                	lui	a4,0xfffff
ffffffffc020097e:	00007797          	auipc	a5,0x7
ffffffffc0200982:	af178793          	addi	a5,a5,-1295 # ffffffffc020746f <end+0xfff>
ffffffffc0200986:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0200988:	00088737          	lui	a4,0x88
ffffffffc020098c:	00006697          	auipc	a3,0x6
ffffffffc0200990:	a8e6b623          	sd	a4,-1396(a3) # ffffffffc0206418 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200994:	4601                	li	a2,0
ffffffffc0200996:	00006717          	auipc	a4,0x6
ffffffffc020099a:	aaf73d23          	sd	a5,-1350(a4) # ffffffffc0206450 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020099e:	4681                	li	a3,0
ffffffffc02009a0:	00006897          	auipc	a7,0x6
ffffffffc02009a4:	a7888893          	addi	a7,a7,-1416 # ffffffffc0206418 <npage>
ffffffffc02009a8:	00006597          	auipc	a1,0x6
ffffffffc02009ac:	aa858593          	addi	a1,a1,-1368 # ffffffffc0206450 <pages>
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02009b0:	4805                	li	a6,1
ffffffffc02009b2:	fff80537          	lui	a0,0xfff80
ffffffffc02009b6:	a011                	j	ffffffffc02009ba <pmm_init+0xa6>
ffffffffc02009b8:	619c                	ld	a5,0(a1)
        SetPageReserved(pages + i);
ffffffffc02009ba:	97b2                	add	a5,a5,a2
ffffffffc02009bc:	07a1                	addi	a5,a5,8
ffffffffc02009be:	4107b02f          	amoor.d	zero,a6,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02009c2:	0008b703          	ld	a4,0(a7)
ffffffffc02009c6:	0685                	addi	a3,a3,1
ffffffffc02009c8:	02860613          	addi	a2,a2,40
ffffffffc02009cc:	00a707b3          	add	a5,a4,a0
ffffffffc02009d0:	fef6e4e3          	bltu	a3,a5,ffffffffc02009b8 <pmm_init+0xa4>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02009d4:	6190                	ld	a2,0(a1)
ffffffffc02009d6:	00271793          	slli	a5,a4,0x2
ffffffffc02009da:	97ba                	add	a5,a5,a4
ffffffffc02009dc:	fec006b7          	lui	a3,0xfec00
ffffffffc02009e0:	078e                	slli	a5,a5,0x3
ffffffffc02009e2:	96b2                	add	a3,a3,a2
ffffffffc02009e4:	96be                	add	a3,a3,a5
ffffffffc02009e6:	c02007b7          	lui	a5,0xc0200
ffffffffc02009ea:	08f6e863          	bltu	a3,a5,ffffffffc0200a7a <pmm_init+0x166>
ffffffffc02009ee:	00006497          	auipc	s1,0x6
ffffffffc02009f2:	a5a48493          	addi	s1,s1,-1446 # ffffffffc0206448 <va_pa_offset>
ffffffffc02009f6:	609c                	ld	a5,0(s1)
    if (freemem < mem_end) {
ffffffffc02009f8:	45c5                	li	a1,17
ffffffffc02009fa:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02009fc:	8e9d                	sub	a3,a3,a5
    if (freemem < mem_end) {
ffffffffc02009fe:	04b6e963          	bltu	a3,a1,ffffffffc0200a50 <pmm_init+0x13c>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200a02:	601c                	ld	a5,0(s0)
ffffffffc0200a04:	7b9c                	ld	a5,48(a5)
ffffffffc0200a06:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200a08:	00002517          	auipc	a0,0x2
ffffffffc0200a0c:	91050513          	addi	a0,a0,-1776 # ffffffffc0202318 <commands+0x6d8>
ffffffffc0200a10:	ebaff0ef          	jal	ra,ffffffffc02000ca <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200a14:	00004697          	auipc	a3,0x4
ffffffffc0200a18:	5ec68693          	addi	a3,a3,1516 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200a1c:	00006797          	auipc	a5,0x6
ffffffffc0200a20:	a0d7b223          	sd	a3,-1532(a5) # ffffffffc0206420 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200a24:	c02007b7          	lui	a5,0xc0200
ffffffffc0200a28:	06f6e563          	bltu	a3,a5,ffffffffc0200a92 <pmm_init+0x17e>
ffffffffc0200a2c:	609c                	ld	a5,0(s1)
}
ffffffffc0200a2e:	6442                	ld	s0,16(sp)
ffffffffc0200a30:	60e2                	ld	ra,24(sp)
ffffffffc0200a32:	64a2                	ld	s1,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200a34:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc0200a36:	8e9d                	sub	a3,a3,a5
ffffffffc0200a38:	00006797          	auipc	a5,0x6
ffffffffc0200a3c:	a0d7b023          	sd	a3,-1536(a5) # ffffffffc0206438 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200a40:	00002517          	auipc	a0,0x2
ffffffffc0200a44:	8f850513          	addi	a0,a0,-1800 # ffffffffc0202338 <commands+0x6f8>
ffffffffc0200a48:	8636                	mv	a2,a3
}
ffffffffc0200a4a:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200a4c:	e7eff06f          	j	ffffffffc02000ca <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200a50:	6785                	lui	a5,0x1
ffffffffc0200a52:	17fd                	addi	a5,a5,-1
ffffffffc0200a54:	96be                	add	a3,a3,a5
ffffffffc0200a56:	77fd                	lui	a5,0xfffff
ffffffffc0200a58:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200a5a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200a5e:	04e7f663          	bleu	a4,a5,ffffffffc0200aaa <pmm_init+0x196>
    pmm_manager->init_memmap(base, n);
ffffffffc0200a62:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200a64:	97aa                	add	a5,a5,a0
ffffffffc0200a66:	00279513          	slli	a0,a5,0x2
ffffffffc0200a6a:	953e                	add	a0,a0,a5
ffffffffc0200a6c:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200a6e:	8d95                	sub	a1,a1,a3
ffffffffc0200a70:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200a72:	81b1                	srli	a1,a1,0xc
ffffffffc0200a74:	9532                	add	a0,a0,a2
ffffffffc0200a76:	9782                	jalr	a5
ffffffffc0200a78:	b769                	j	ffffffffc0200a02 <pmm_init+0xee>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200a7a:	00002617          	auipc	a2,0x2
ffffffffc0200a7e:	83660613          	addi	a2,a2,-1994 # ffffffffc02022b0 <commands+0x670>
ffffffffc0200a82:	06f00593          	li	a1,111
ffffffffc0200a86:	00002517          	auipc	a0,0x2
ffffffffc0200a8a:	85250513          	addi	a0,a0,-1966 # ffffffffc02022d8 <commands+0x698>
ffffffffc0200a8e:	ec4ff0ef          	jal	ra,ffffffffc0200152 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200a92:	00002617          	auipc	a2,0x2
ffffffffc0200a96:	81e60613          	addi	a2,a2,-2018 # ffffffffc02022b0 <commands+0x670>
ffffffffc0200a9a:	08a00593          	li	a1,138
ffffffffc0200a9e:	00002517          	auipc	a0,0x2
ffffffffc0200aa2:	83a50513          	addi	a0,a0,-1990 # ffffffffc02022d8 <commands+0x698>
ffffffffc0200aa6:	eacff0ef          	jal	ra,ffffffffc0200152 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200aaa:	00002617          	auipc	a2,0x2
ffffffffc0200aae:	83e60613          	addi	a2,a2,-1986 # ffffffffc02022e8 <commands+0x6a8>
ffffffffc0200ab2:	06b00593          	li	a1,107
ffffffffc0200ab6:	00002517          	auipc	a0,0x2
ffffffffc0200aba:	85250513          	addi	a0,a0,-1966 # ffffffffc0202308 <commands+0x6c8>
ffffffffc0200abe:	e94ff0ef          	jal	ra,ffffffffc0200152 <__panic>

ffffffffc0200ac2 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ac2:	00006797          	auipc	a5,0x6
ffffffffc0200ac6:	99678793          	addi	a5,a5,-1642 # ffffffffc0206458 <free_area>
ffffffffc0200aca:	e79c                	sd	a5,8(a5)
ffffffffc0200acc:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200ace:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200ad2:	8082                	ret

ffffffffc0200ad4 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200ad4:	00006517          	auipc	a0,0x6
ffffffffc0200ad8:	99456503          	lwu	a0,-1644(a0) # ffffffffc0206468 <free_area+0x10>
ffffffffc0200adc:	8082                	ret

ffffffffc0200ade <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200ade:	c15d                	beqz	a0,ffffffffc0200b84 <best_fit_alloc_pages+0xa6>
    if (n > nr_free) {
ffffffffc0200ae0:	00006617          	auipc	a2,0x6
ffffffffc0200ae4:	97860613          	addi	a2,a2,-1672 # ffffffffc0206458 <free_area>
ffffffffc0200ae8:	01062803          	lw	a6,16(a2)
ffffffffc0200aec:	86aa                	mv	a3,a0
ffffffffc0200aee:	02081793          	slli	a5,a6,0x20
ffffffffc0200af2:	9381                	srli	a5,a5,0x20
ffffffffc0200af4:	08a7e663          	bltu	a5,a0,ffffffffc0200b80 <best_fit_alloc_pages+0xa2>
    size_t min_size = nr_free + 1;
ffffffffc0200af8:	0018059b          	addiw	a1,a6,1
ffffffffc0200afc:	1582                	slli	a1,a1,0x20
ffffffffc0200afe:	9181                	srli	a1,a1,0x20
    list_entry_t *le = &free_list;
ffffffffc0200b00:	87b2                	mv	a5,a2
    struct Page *page = NULL;
ffffffffc0200b02:	4501                	li	a0,0
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200b04:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b06:	00c78e63          	beq	a5,a2,ffffffffc0200b22 <best_fit_alloc_pages+0x44>
        if (p->property >= n && min_size > p->property) {
ffffffffc0200b0a:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200b0e:	fed76be3          	bltu	a4,a3,ffffffffc0200b04 <best_fit_alloc_pages+0x26>
ffffffffc0200b12:	feb779e3          	bleu	a1,a4,ffffffffc0200b04 <best_fit_alloc_pages+0x26>
        struct Page *p = le2page(le, page_link);
ffffffffc0200b16:	fe878513          	addi	a0,a5,-24
ffffffffc0200b1a:	679c                	ld	a5,8(a5)
ffffffffc0200b1c:	85ba                	mv	a1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b1e:	fec796e3          	bne	a5,a2,ffffffffc0200b0a <best_fit_alloc_pages+0x2c>
    if (page != NULL) {
ffffffffc0200b22:	c125                	beqz	a0,ffffffffc0200b82 <best_fit_alloc_pages+0xa4>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200b24:	7118                	ld	a4,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200b26:	6d10                	ld	a2,24(a0)
        if (page->property > n) {
ffffffffc0200b28:	490c                	lw	a1,16(a0)
ffffffffc0200b2a:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200b2e:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc0200b30:	e310                	sd	a2,0(a4)
ffffffffc0200b32:	02059713          	slli	a4,a1,0x20
ffffffffc0200b36:	9301                	srli	a4,a4,0x20
ffffffffc0200b38:	02e6f863          	bleu	a4,a3,ffffffffc0200b68 <best_fit_alloc_pages+0x8a>
            struct Page *p = page + n;
ffffffffc0200b3c:	00269713          	slli	a4,a3,0x2
ffffffffc0200b40:	9736                	add	a4,a4,a3
ffffffffc0200b42:	070e                	slli	a4,a4,0x3
ffffffffc0200b44:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0200b46:	411585bb          	subw	a1,a1,a7
ffffffffc0200b4a:	cb0c                	sw	a1,16(a4)
ffffffffc0200b4c:	4689                	li	a3,2
ffffffffc0200b4e:	00870593          	addi	a1,a4,8
ffffffffc0200b52:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b56:	6614                	ld	a3,8(a2)
            list_add(prev, &(p->page_link));
ffffffffc0200b58:	01870593          	addi	a1,a4,24
    prev->next = next->prev = elm;
ffffffffc0200b5c:	0107a803          	lw	a6,16(a5)
ffffffffc0200b60:	e28c                	sd	a1,0(a3)
ffffffffc0200b62:	e60c                	sd	a1,8(a2)
    elm->next = next;
ffffffffc0200b64:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0200b66:	ef10                	sd	a2,24(a4)
        nr_free -= n;
ffffffffc0200b68:	4118083b          	subw	a6,a6,a7
ffffffffc0200b6c:	00006797          	auipc	a5,0x6
ffffffffc0200b70:	8f07ae23          	sw	a6,-1796(a5) # ffffffffc0206468 <free_area+0x10>
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200b74:	57f5                	li	a5,-3
ffffffffc0200b76:	00850713          	addi	a4,a0,8
ffffffffc0200b7a:	60f7302f          	amoand.d	zero,a5,(a4)
ffffffffc0200b7e:	8082                	ret
        return NULL;
ffffffffc0200b80:	4501                	li	a0,0
}
ffffffffc0200b82:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200b84:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200b86:	00001697          	auipc	a3,0x1
ffffffffc0200b8a:	7f268693          	addi	a3,a3,2034 # ffffffffc0202378 <commands+0x738>
ffffffffc0200b8e:	00001617          	auipc	a2,0x1
ffffffffc0200b92:	7f260613          	addi	a2,a2,2034 # ffffffffc0202380 <commands+0x740>
ffffffffc0200b96:	07000593          	li	a1,112
ffffffffc0200b9a:	00001517          	auipc	a0,0x1
ffffffffc0200b9e:	7fe50513          	addi	a0,a0,2046 # ffffffffc0202398 <commands+0x758>
best_fit_alloc_pages(size_t n) {
ffffffffc0200ba2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200ba4:	daeff0ef          	jal	ra,ffffffffc0200152 <__panic>

ffffffffc0200ba8 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200ba8:	715d                	addi	sp,sp,-80
ffffffffc0200baa:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc0200bac:	00006917          	auipc	s2,0x6
ffffffffc0200bb0:	8ac90913          	addi	s2,s2,-1876 # ffffffffc0206458 <free_area>
ffffffffc0200bb4:	00893783          	ld	a5,8(s2)
ffffffffc0200bb8:	e486                	sd	ra,72(sp)
ffffffffc0200bba:	e0a2                	sd	s0,64(sp)
ffffffffc0200bbc:	fc26                	sd	s1,56(sp)
ffffffffc0200bbe:	f44e                	sd	s3,40(sp)
ffffffffc0200bc0:	f052                	sd	s4,32(sp)
ffffffffc0200bc2:	ec56                	sd	s5,24(sp)
ffffffffc0200bc4:	e85a                	sd	s6,16(sp)
ffffffffc0200bc6:	e45e                	sd	s7,8(sp)
ffffffffc0200bc8:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200bca:	2d278363          	beq	a5,s2,ffffffffc0200e90 <best_fit_check+0x2e8>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200bce:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200bd2:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200bd4:	8b05                	andi	a4,a4,1
ffffffffc0200bd6:	2c070163          	beqz	a4,ffffffffc0200e98 <best_fit_check+0x2f0>
    int count = 0, total = 0;
ffffffffc0200bda:	4401                	li	s0,0
ffffffffc0200bdc:	4481                	li	s1,0
ffffffffc0200bde:	a031                	j	ffffffffc0200bea <best_fit_check+0x42>
ffffffffc0200be0:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0200be4:	8b09                	andi	a4,a4,2
ffffffffc0200be6:	2a070963          	beqz	a4,ffffffffc0200e98 <best_fit_check+0x2f0>
        count ++, total += p->property;
ffffffffc0200bea:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200bee:	679c                	ld	a5,8(a5)
ffffffffc0200bf0:	2485                	addiw	s1,s1,1
ffffffffc0200bf2:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200bf4:	ff2796e3          	bne	a5,s2,ffffffffc0200be0 <best_fit_check+0x38>
ffffffffc0200bf8:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200bfa:	cdbff0ef          	jal	ra,ffffffffc02008d4 <nr_free_pages>
ffffffffc0200bfe:	37351d63          	bne	a0,s3,ffffffffc0200f78 <best_fit_check+0x3d0>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c02:	4505                	li	a0,1
ffffffffc0200c04:	c47ff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200c08:	8a2a                	mv	s4,a0
ffffffffc0200c0a:	3a050763          	beqz	a0,ffffffffc0200fb8 <best_fit_check+0x410>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c0e:	4505                	li	a0,1
ffffffffc0200c10:	c3bff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200c14:	89aa                	mv	s3,a0
ffffffffc0200c16:	38050163          	beqz	a0,ffffffffc0200f98 <best_fit_check+0x3f0>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c1a:	4505                	li	a0,1
ffffffffc0200c1c:	c2fff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200c20:	8aaa                	mv	s5,a0
ffffffffc0200c22:	30050b63          	beqz	a0,ffffffffc0200f38 <best_fit_check+0x390>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c26:	293a0963          	beq	s4,s3,ffffffffc0200eb8 <best_fit_check+0x310>
ffffffffc0200c2a:	28aa0763          	beq	s4,a0,ffffffffc0200eb8 <best_fit_check+0x310>
ffffffffc0200c2e:	28a98563          	beq	s3,a0,ffffffffc0200eb8 <best_fit_check+0x310>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c32:	000a2783          	lw	a5,0(s4)
ffffffffc0200c36:	2a079163          	bnez	a5,ffffffffc0200ed8 <best_fit_check+0x330>
ffffffffc0200c3a:	0009a783          	lw	a5,0(s3)
ffffffffc0200c3e:	28079d63          	bnez	a5,ffffffffc0200ed8 <best_fit_check+0x330>
ffffffffc0200c42:	411c                	lw	a5,0(a0)
ffffffffc0200c44:	28079a63          	bnez	a5,ffffffffc0200ed8 <best_fit_check+0x330>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c48:	00006797          	auipc	a5,0x6
ffffffffc0200c4c:	80878793          	addi	a5,a5,-2040 # ffffffffc0206450 <pages>
ffffffffc0200c50:	639c                	ld	a5,0(a5)
ffffffffc0200c52:	00001717          	auipc	a4,0x1
ffffffffc0200c56:	75e70713          	addi	a4,a4,1886 # ffffffffc02023b0 <commands+0x770>
ffffffffc0200c5a:	630c                	ld	a1,0(a4)
ffffffffc0200c5c:	40fa0733          	sub	a4,s4,a5
ffffffffc0200c60:	870d                	srai	a4,a4,0x3
ffffffffc0200c62:	02b70733          	mul	a4,a4,a1
ffffffffc0200c66:	00002697          	auipc	a3,0x2
ffffffffc0200c6a:	ce268693          	addi	a3,a3,-798 # ffffffffc0202948 <nbase>
ffffffffc0200c6e:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200c70:	00005697          	auipc	a3,0x5
ffffffffc0200c74:	7a868693          	addi	a3,a3,1960 # ffffffffc0206418 <npage>
ffffffffc0200c78:	6294                	ld	a3,0(a3)
ffffffffc0200c7a:	06b2                	slli	a3,a3,0xc
ffffffffc0200c7c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c7e:	0732                	slli	a4,a4,0xc
ffffffffc0200c80:	26d77c63          	bleu	a3,a4,ffffffffc0200ef8 <best_fit_check+0x350>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c84:	40f98733          	sub	a4,s3,a5
ffffffffc0200c88:	870d                	srai	a4,a4,0x3
ffffffffc0200c8a:	02b70733          	mul	a4,a4,a1
ffffffffc0200c8e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c90:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200c92:	42d77363          	bleu	a3,a4,ffffffffc02010b8 <best_fit_check+0x510>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c96:	40f507b3          	sub	a5,a0,a5
ffffffffc0200c9a:	878d                	srai	a5,a5,0x3
ffffffffc0200c9c:	02b787b3          	mul	a5,a5,a1
ffffffffc0200ca0:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ca2:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ca4:	3ed7fa63          	bleu	a3,a5,ffffffffc0201098 <best_fit_check+0x4f0>
    assert(alloc_page() == NULL);
ffffffffc0200ca8:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200caa:	00093c03          	ld	s8,0(s2)
ffffffffc0200cae:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200cb2:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200cb6:	00005797          	auipc	a5,0x5
ffffffffc0200cba:	7b27b523          	sd	s2,1962(a5) # ffffffffc0206460 <free_area+0x8>
ffffffffc0200cbe:	00005797          	auipc	a5,0x5
ffffffffc0200cc2:	7927bd23          	sd	s2,1946(a5) # ffffffffc0206458 <free_area>
    nr_free = 0;
ffffffffc0200cc6:	00005797          	auipc	a5,0x5
ffffffffc0200cca:	7a07a123          	sw	zero,1954(a5) # ffffffffc0206468 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200cce:	b7dff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200cd2:	3a051363          	bnez	a0,ffffffffc0201078 <best_fit_check+0x4d0>
    free_page(p0);
ffffffffc0200cd6:	4585                	li	a1,1
ffffffffc0200cd8:	8552                	mv	a0,s4
ffffffffc0200cda:	bb5ff0ef          	jal	ra,ffffffffc020088e <free_pages>
    free_page(p1);
ffffffffc0200cde:	4585                	li	a1,1
ffffffffc0200ce0:	854e                	mv	a0,s3
ffffffffc0200ce2:	badff0ef          	jal	ra,ffffffffc020088e <free_pages>
    free_page(p2);
ffffffffc0200ce6:	4585                	li	a1,1
ffffffffc0200ce8:	8556                	mv	a0,s5
ffffffffc0200cea:	ba5ff0ef          	jal	ra,ffffffffc020088e <free_pages>
    assert(nr_free == 3);
ffffffffc0200cee:	01092703          	lw	a4,16(s2)
ffffffffc0200cf2:	478d                	li	a5,3
ffffffffc0200cf4:	36f71263          	bne	a4,a5,ffffffffc0201058 <best_fit_check+0x4b0>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200cf8:	4505                	li	a0,1
ffffffffc0200cfa:	b51ff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200cfe:	89aa                	mv	s3,a0
ffffffffc0200d00:	32050c63          	beqz	a0,ffffffffc0201038 <best_fit_check+0x490>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d04:	4505                	li	a0,1
ffffffffc0200d06:	b45ff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200d0a:	8aaa                	mv	s5,a0
ffffffffc0200d0c:	30050663          	beqz	a0,ffffffffc0201018 <best_fit_check+0x470>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d10:	4505                	li	a0,1
ffffffffc0200d12:	b39ff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200d16:	8a2a                	mv	s4,a0
ffffffffc0200d18:	2e050063          	beqz	a0,ffffffffc0200ff8 <best_fit_check+0x450>
    assert(alloc_page() == NULL);
ffffffffc0200d1c:	4505                	li	a0,1
ffffffffc0200d1e:	b2dff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200d22:	2a051b63          	bnez	a0,ffffffffc0200fd8 <best_fit_check+0x430>
    free_page(p0);
ffffffffc0200d26:	4585                	li	a1,1
ffffffffc0200d28:	854e                	mv	a0,s3
ffffffffc0200d2a:	b65ff0ef          	jal	ra,ffffffffc020088e <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200d2e:	00893783          	ld	a5,8(s2)
ffffffffc0200d32:	1f278363          	beq	a5,s2,ffffffffc0200f18 <best_fit_check+0x370>
    assert((p = alloc_page()) == p0);
ffffffffc0200d36:	4505                	li	a0,1
ffffffffc0200d38:	b13ff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200d3c:	54a99e63          	bne	s3,a0,ffffffffc0201298 <best_fit_check+0x6f0>
    assert(alloc_page() == NULL);
ffffffffc0200d40:	4505                	li	a0,1
ffffffffc0200d42:	b09ff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200d46:	52051963          	bnez	a0,ffffffffc0201278 <best_fit_check+0x6d0>
    assert(nr_free == 0);
ffffffffc0200d4a:	01092783          	lw	a5,16(s2)
ffffffffc0200d4e:	50079563          	bnez	a5,ffffffffc0201258 <best_fit_check+0x6b0>
    free_page(p);
ffffffffc0200d52:	854e                	mv	a0,s3
ffffffffc0200d54:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200d56:	00005797          	auipc	a5,0x5
ffffffffc0200d5a:	7187b123          	sd	s8,1794(a5) # ffffffffc0206458 <free_area>
ffffffffc0200d5e:	00005797          	auipc	a5,0x5
ffffffffc0200d62:	7177b123          	sd	s7,1794(a5) # ffffffffc0206460 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0200d66:	00005797          	auipc	a5,0x5
ffffffffc0200d6a:	7167a123          	sw	s6,1794(a5) # ffffffffc0206468 <free_area+0x10>
    free_page(p);
ffffffffc0200d6e:	b21ff0ef          	jal	ra,ffffffffc020088e <free_pages>
    free_page(p1);
ffffffffc0200d72:	4585                	li	a1,1
ffffffffc0200d74:	8556                	mv	a0,s5
ffffffffc0200d76:	b19ff0ef          	jal	ra,ffffffffc020088e <free_pages>
    free_page(p2);
ffffffffc0200d7a:	4585                	li	a1,1
ffffffffc0200d7c:	8552                	mv	a0,s4
ffffffffc0200d7e:	b11ff0ef          	jal	ra,ffffffffc020088e <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200d82:	4515                	li	a0,5
ffffffffc0200d84:	ac7ff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200d88:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200d8a:	4a050763          	beqz	a0,ffffffffc0201238 <best_fit_check+0x690>
ffffffffc0200d8e:	651c                	ld	a5,8(a0)
ffffffffc0200d90:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200d92:	8b85                	andi	a5,a5,1
ffffffffc0200d94:	48079263          	bnez	a5,ffffffffc0201218 <best_fit_check+0x670>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200d98:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d9a:	00093b03          	ld	s6,0(s2)
ffffffffc0200d9e:	00893a83          	ld	s5,8(s2)
ffffffffc0200da2:	00005797          	auipc	a5,0x5
ffffffffc0200da6:	6b27bb23          	sd	s2,1718(a5) # ffffffffc0206458 <free_area>
ffffffffc0200daa:	00005797          	auipc	a5,0x5
ffffffffc0200dae:	6b27bb23          	sd	s2,1718(a5) # ffffffffc0206460 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200db2:	a99ff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200db6:	44051163          	bnez	a0,ffffffffc02011f8 <best_fit_check+0x650>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200dba:	4589                	li	a1,2
ffffffffc0200dbc:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200dc0:	01092b83          	lw	s7,16(s2)
    free_pages(p0 + 4, 1);
ffffffffc0200dc4:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200dc8:	00005797          	auipc	a5,0x5
ffffffffc0200dcc:	6a07a023          	sw	zero,1696(a5) # ffffffffc0206468 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200dd0:	abfff0ef          	jal	ra,ffffffffc020088e <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200dd4:	8562                	mv	a0,s8
ffffffffc0200dd6:	4585                	li	a1,1
ffffffffc0200dd8:	ab7ff0ef          	jal	ra,ffffffffc020088e <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ddc:	4511                	li	a0,4
ffffffffc0200dde:	a6dff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200de2:	3e051b63          	bnez	a0,ffffffffc02011d8 <best_fit_check+0x630>
ffffffffc0200de6:	0309b783          	ld	a5,48(s3)
ffffffffc0200dea:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200dec:	8b85                	andi	a5,a5,1
ffffffffc0200dee:	3c078563          	beqz	a5,ffffffffc02011b8 <best_fit_check+0x610>
ffffffffc0200df2:	0389a703          	lw	a4,56(s3)
ffffffffc0200df6:	4789                	li	a5,2
ffffffffc0200df8:	3cf71063          	bne	a4,a5,ffffffffc02011b8 <best_fit_check+0x610>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200dfc:	4505                	li	a0,1
ffffffffc0200dfe:	a4dff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200e02:	8a2a                	mv	s4,a0
ffffffffc0200e04:	38050a63          	beqz	a0,ffffffffc0201198 <best_fit_check+0x5f0>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200e08:	4509                	li	a0,2
ffffffffc0200e0a:	a41ff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200e0e:	36050563          	beqz	a0,ffffffffc0201178 <best_fit_check+0x5d0>
    assert(p0 + 4 == p1);
ffffffffc0200e12:	354c1363          	bne	s8,s4,ffffffffc0201158 <best_fit_check+0x5b0>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200e16:	854e                	mv	a0,s3
ffffffffc0200e18:	4595                	li	a1,5
ffffffffc0200e1a:	a75ff0ef          	jal	ra,ffffffffc020088e <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e1e:	4515                	li	a0,5
ffffffffc0200e20:	a2bff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200e24:	89aa                	mv	s3,a0
ffffffffc0200e26:	30050963          	beqz	a0,ffffffffc0201138 <best_fit_check+0x590>
    assert(alloc_page() == NULL);
ffffffffc0200e2a:	4505                	li	a0,1
ffffffffc0200e2c:	a1fff0ef          	jal	ra,ffffffffc020084a <alloc_pages>
ffffffffc0200e30:	2e051463          	bnez	a0,ffffffffc0201118 <best_fit_check+0x570>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200e34:	01092783          	lw	a5,16(s2)
ffffffffc0200e38:	2c079063          	bnez	a5,ffffffffc02010f8 <best_fit_check+0x550>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200e3c:	4595                	li	a1,5
ffffffffc0200e3e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200e40:	00005797          	auipc	a5,0x5
ffffffffc0200e44:	6377a423          	sw	s7,1576(a5) # ffffffffc0206468 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0200e48:	00005797          	auipc	a5,0x5
ffffffffc0200e4c:	6167b823          	sd	s6,1552(a5) # ffffffffc0206458 <free_area>
ffffffffc0200e50:	00005797          	auipc	a5,0x5
ffffffffc0200e54:	6157b823          	sd	s5,1552(a5) # ffffffffc0206460 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0200e58:	a37ff0ef          	jal	ra,ffffffffc020088e <free_pages>
    return listelm->next;
ffffffffc0200e5c:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e60:	01278963          	beq	a5,s2,ffffffffc0200e72 <best_fit_check+0x2ca>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200e64:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e68:	679c                	ld	a5,8(a5)
ffffffffc0200e6a:	34fd                	addiw	s1,s1,-1
ffffffffc0200e6c:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e6e:	ff279be3          	bne	a5,s2,ffffffffc0200e64 <best_fit_check+0x2bc>
    }
    assert(count == 0);
ffffffffc0200e72:	26049363          	bnez	s1,ffffffffc02010d8 <best_fit_check+0x530>
    assert(total == 0);
ffffffffc0200e76:	e06d                	bnez	s0,ffffffffc0200f58 <best_fit_check+0x3b0>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200e78:	60a6                	ld	ra,72(sp)
ffffffffc0200e7a:	6406                	ld	s0,64(sp)
ffffffffc0200e7c:	74e2                	ld	s1,56(sp)
ffffffffc0200e7e:	7942                	ld	s2,48(sp)
ffffffffc0200e80:	79a2                	ld	s3,40(sp)
ffffffffc0200e82:	7a02                	ld	s4,32(sp)
ffffffffc0200e84:	6ae2                	ld	s5,24(sp)
ffffffffc0200e86:	6b42                	ld	s6,16(sp)
ffffffffc0200e88:	6ba2                	ld	s7,8(sp)
ffffffffc0200e8a:	6c02                	ld	s8,0(sp)
ffffffffc0200e8c:	6161                	addi	sp,sp,80
ffffffffc0200e8e:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e90:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200e92:	4401                	li	s0,0
ffffffffc0200e94:	4481                	li	s1,0
ffffffffc0200e96:	b395                	j	ffffffffc0200bfa <best_fit_check+0x52>
        assert(PageProperty(p));
ffffffffc0200e98:	00001697          	auipc	a3,0x1
ffffffffc0200e9c:	52068693          	addi	a3,a3,1312 # ffffffffc02023b8 <commands+0x778>
ffffffffc0200ea0:	00001617          	auipc	a2,0x1
ffffffffc0200ea4:	4e060613          	addi	a2,a2,1248 # ffffffffc0202380 <commands+0x740>
ffffffffc0200ea8:	11000593          	li	a1,272
ffffffffc0200eac:	00001517          	auipc	a0,0x1
ffffffffc0200eb0:	4ec50513          	addi	a0,a0,1260 # ffffffffc0202398 <commands+0x758>
ffffffffc0200eb4:	a9eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200eb8:	00001697          	auipc	a3,0x1
ffffffffc0200ebc:	59068693          	addi	a3,a3,1424 # ffffffffc0202448 <commands+0x808>
ffffffffc0200ec0:	00001617          	auipc	a2,0x1
ffffffffc0200ec4:	4c060613          	addi	a2,a2,1216 # ffffffffc0202380 <commands+0x740>
ffffffffc0200ec8:	0dc00593          	li	a1,220
ffffffffc0200ecc:	00001517          	auipc	a0,0x1
ffffffffc0200ed0:	4cc50513          	addi	a0,a0,1228 # ffffffffc0202398 <commands+0x758>
ffffffffc0200ed4:	a7eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ed8:	00001697          	auipc	a3,0x1
ffffffffc0200edc:	59868693          	addi	a3,a3,1432 # ffffffffc0202470 <commands+0x830>
ffffffffc0200ee0:	00001617          	auipc	a2,0x1
ffffffffc0200ee4:	4a060613          	addi	a2,a2,1184 # ffffffffc0202380 <commands+0x740>
ffffffffc0200ee8:	0dd00593          	li	a1,221
ffffffffc0200eec:	00001517          	auipc	a0,0x1
ffffffffc0200ef0:	4ac50513          	addi	a0,a0,1196 # ffffffffc0202398 <commands+0x758>
ffffffffc0200ef4:	a5eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200ef8:	00001697          	auipc	a3,0x1
ffffffffc0200efc:	5b868693          	addi	a3,a3,1464 # ffffffffc02024b0 <commands+0x870>
ffffffffc0200f00:	00001617          	auipc	a2,0x1
ffffffffc0200f04:	48060613          	addi	a2,a2,1152 # ffffffffc0202380 <commands+0x740>
ffffffffc0200f08:	0df00593          	li	a1,223
ffffffffc0200f0c:	00001517          	auipc	a0,0x1
ffffffffc0200f10:	48c50513          	addi	a0,a0,1164 # ffffffffc0202398 <commands+0x758>
ffffffffc0200f14:	a3eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200f18:	00001697          	auipc	a3,0x1
ffffffffc0200f1c:	62068693          	addi	a3,a3,1568 # ffffffffc0202538 <commands+0x8f8>
ffffffffc0200f20:	00001617          	auipc	a2,0x1
ffffffffc0200f24:	46060613          	addi	a2,a2,1120 # ffffffffc0202380 <commands+0x740>
ffffffffc0200f28:	0f800593          	li	a1,248
ffffffffc0200f2c:	00001517          	auipc	a0,0x1
ffffffffc0200f30:	46c50513          	addi	a0,a0,1132 # ffffffffc0202398 <commands+0x758>
ffffffffc0200f34:	a1eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f38:	00001697          	auipc	a3,0x1
ffffffffc0200f3c:	4f068693          	addi	a3,a3,1264 # ffffffffc0202428 <commands+0x7e8>
ffffffffc0200f40:	00001617          	auipc	a2,0x1
ffffffffc0200f44:	44060613          	addi	a2,a2,1088 # ffffffffc0202380 <commands+0x740>
ffffffffc0200f48:	0da00593          	li	a1,218
ffffffffc0200f4c:	00001517          	auipc	a0,0x1
ffffffffc0200f50:	44c50513          	addi	a0,a0,1100 # ffffffffc0202398 <commands+0x758>
ffffffffc0200f54:	9feff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(total == 0);
ffffffffc0200f58:	00001697          	auipc	a3,0x1
ffffffffc0200f5c:	71068693          	addi	a3,a3,1808 # ffffffffc0202668 <commands+0xa28>
ffffffffc0200f60:	00001617          	auipc	a2,0x1
ffffffffc0200f64:	42060613          	addi	a2,a2,1056 # ffffffffc0202380 <commands+0x740>
ffffffffc0200f68:	15200593          	li	a1,338
ffffffffc0200f6c:	00001517          	auipc	a0,0x1
ffffffffc0200f70:	42c50513          	addi	a0,a0,1068 # ffffffffc0202398 <commands+0x758>
ffffffffc0200f74:	9deff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200f78:	00001697          	auipc	a3,0x1
ffffffffc0200f7c:	45068693          	addi	a3,a3,1104 # ffffffffc02023c8 <commands+0x788>
ffffffffc0200f80:	00001617          	auipc	a2,0x1
ffffffffc0200f84:	40060613          	addi	a2,a2,1024 # ffffffffc0202380 <commands+0x740>
ffffffffc0200f88:	11300593          	li	a1,275
ffffffffc0200f8c:	00001517          	auipc	a0,0x1
ffffffffc0200f90:	40c50513          	addi	a0,a0,1036 # ffffffffc0202398 <commands+0x758>
ffffffffc0200f94:	9beff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f98:	00001697          	auipc	a3,0x1
ffffffffc0200f9c:	47068693          	addi	a3,a3,1136 # ffffffffc0202408 <commands+0x7c8>
ffffffffc0200fa0:	00001617          	auipc	a2,0x1
ffffffffc0200fa4:	3e060613          	addi	a2,a2,992 # ffffffffc0202380 <commands+0x740>
ffffffffc0200fa8:	0d900593          	li	a1,217
ffffffffc0200fac:	00001517          	auipc	a0,0x1
ffffffffc0200fb0:	3ec50513          	addi	a0,a0,1004 # ffffffffc0202398 <commands+0x758>
ffffffffc0200fb4:	99eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fb8:	00001697          	auipc	a3,0x1
ffffffffc0200fbc:	43068693          	addi	a3,a3,1072 # ffffffffc02023e8 <commands+0x7a8>
ffffffffc0200fc0:	00001617          	auipc	a2,0x1
ffffffffc0200fc4:	3c060613          	addi	a2,a2,960 # ffffffffc0202380 <commands+0x740>
ffffffffc0200fc8:	0d800593          	li	a1,216
ffffffffc0200fcc:	00001517          	auipc	a0,0x1
ffffffffc0200fd0:	3cc50513          	addi	a0,a0,972 # ffffffffc0202398 <commands+0x758>
ffffffffc0200fd4:	97eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fd8:	00001697          	auipc	a3,0x1
ffffffffc0200fdc:	53868693          	addi	a3,a3,1336 # ffffffffc0202510 <commands+0x8d0>
ffffffffc0200fe0:	00001617          	auipc	a2,0x1
ffffffffc0200fe4:	3a060613          	addi	a2,a2,928 # ffffffffc0202380 <commands+0x740>
ffffffffc0200fe8:	0f500593          	li	a1,245
ffffffffc0200fec:	00001517          	auipc	a0,0x1
ffffffffc0200ff0:	3ac50513          	addi	a0,a0,940 # ffffffffc0202398 <commands+0x758>
ffffffffc0200ff4:	95eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ff8:	00001697          	auipc	a3,0x1
ffffffffc0200ffc:	43068693          	addi	a3,a3,1072 # ffffffffc0202428 <commands+0x7e8>
ffffffffc0201000:	00001617          	auipc	a2,0x1
ffffffffc0201004:	38060613          	addi	a2,a2,896 # ffffffffc0202380 <commands+0x740>
ffffffffc0201008:	0f300593          	li	a1,243
ffffffffc020100c:	00001517          	auipc	a0,0x1
ffffffffc0201010:	38c50513          	addi	a0,a0,908 # ffffffffc0202398 <commands+0x758>
ffffffffc0201014:	93eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201018:	00001697          	auipc	a3,0x1
ffffffffc020101c:	3f068693          	addi	a3,a3,1008 # ffffffffc0202408 <commands+0x7c8>
ffffffffc0201020:	00001617          	auipc	a2,0x1
ffffffffc0201024:	36060613          	addi	a2,a2,864 # ffffffffc0202380 <commands+0x740>
ffffffffc0201028:	0f200593          	li	a1,242
ffffffffc020102c:	00001517          	auipc	a0,0x1
ffffffffc0201030:	36c50513          	addi	a0,a0,876 # ffffffffc0202398 <commands+0x758>
ffffffffc0201034:	91eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201038:	00001697          	auipc	a3,0x1
ffffffffc020103c:	3b068693          	addi	a3,a3,944 # ffffffffc02023e8 <commands+0x7a8>
ffffffffc0201040:	00001617          	auipc	a2,0x1
ffffffffc0201044:	34060613          	addi	a2,a2,832 # ffffffffc0202380 <commands+0x740>
ffffffffc0201048:	0f100593          	li	a1,241
ffffffffc020104c:	00001517          	auipc	a0,0x1
ffffffffc0201050:	34c50513          	addi	a0,a0,844 # ffffffffc0202398 <commands+0x758>
ffffffffc0201054:	8feff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(nr_free == 3);
ffffffffc0201058:	00001697          	auipc	a3,0x1
ffffffffc020105c:	4d068693          	addi	a3,a3,1232 # ffffffffc0202528 <commands+0x8e8>
ffffffffc0201060:	00001617          	auipc	a2,0x1
ffffffffc0201064:	32060613          	addi	a2,a2,800 # ffffffffc0202380 <commands+0x740>
ffffffffc0201068:	0ef00593          	li	a1,239
ffffffffc020106c:	00001517          	auipc	a0,0x1
ffffffffc0201070:	32c50513          	addi	a0,a0,812 # ffffffffc0202398 <commands+0x758>
ffffffffc0201074:	8deff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201078:	00001697          	auipc	a3,0x1
ffffffffc020107c:	49868693          	addi	a3,a3,1176 # ffffffffc0202510 <commands+0x8d0>
ffffffffc0201080:	00001617          	auipc	a2,0x1
ffffffffc0201084:	30060613          	addi	a2,a2,768 # ffffffffc0202380 <commands+0x740>
ffffffffc0201088:	0ea00593          	li	a1,234
ffffffffc020108c:	00001517          	auipc	a0,0x1
ffffffffc0201090:	30c50513          	addi	a0,a0,780 # ffffffffc0202398 <commands+0x758>
ffffffffc0201094:	8beff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201098:	00001697          	auipc	a3,0x1
ffffffffc020109c:	45868693          	addi	a3,a3,1112 # ffffffffc02024f0 <commands+0x8b0>
ffffffffc02010a0:	00001617          	auipc	a2,0x1
ffffffffc02010a4:	2e060613          	addi	a2,a2,736 # ffffffffc0202380 <commands+0x740>
ffffffffc02010a8:	0e100593          	li	a1,225
ffffffffc02010ac:	00001517          	auipc	a0,0x1
ffffffffc02010b0:	2ec50513          	addi	a0,a0,748 # ffffffffc0202398 <commands+0x758>
ffffffffc02010b4:	89eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010b8:	00001697          	auipc	a3,0x1
ffffffffc02010bc:	41868693          	addi	a3,a3,1048 # ffffffffc02024d0 <commands+0x890>
ffffffffc02010c0:	00001617          	auipc	a2,0x1
ffffffffc02010c4:	2c060613          	addi	a2,a2,704 # ffffffffc0202380 <commands+0x740>
ffffffffc02010c8:	0e000593          	li	a1,224
ffffffffc02010cc:	00001517          	auipc	a0,0x1
ffffffffc02010d0:	2cc50513          	addi	a0,a0,716 # ffffffffc0202398 <commands+0x758>
ffffffffc02010d4:	87eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(count == 0);
ffffffffc02010d8:	00001697          	auipc	a3,0x1
ffffffffc02010dc:	58068693          	addi	a3,a3,1408 # ffffffffc0202658 <commands+0xa18>
ffffffffc02010e0:	00001617          	auipc	a2,0x1
ffffffffc02010e4:	2a060613          	addi	a2,a2,672 # ffffffffc0202380 <commands+0x740>
ffffffffc02010e8:	15100593          	li	a1,337
ffffffffc02010ec:	00001517          	auipc	a0,0x1
ffffffffc02010f0:	2ac50513          	addi	a0,a0,684 # ffffffffc0202398 <commands+0x758>
ffffffffc02010f4:	85eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(nr_free == 0);
ffffffffc02010f8:	00001697          	auipc	a3,0x1
ffffffffc02010fc:	47868693          	addi	a3,a3,1144 # ffffffffc0202570 <commands+0x930>
ffffffffc0201100:	00001617          	auipc	a2,0x1
ffffffffc0201104:	28060613          	addi	a2,a2,640 # ffffffffc0202380 <commands+0x740>
ffffffffc0201108:	14600593          	li	a1,326
ffffffffc020110c:	00001517          	auipc	a0,0x1
ffffffffc0201110:	28c50513          	addi	a0,a0,652 # ffffffffc0202398 <commands+0x758>
ffffffffc0201114:	83eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201118:	00001697          	auipc	a3,0x1
ffffffffc020111c:	3f868693          	addi	a3,a3,1016 # ffffffffc0202510 <commands+0x8d0>
ffffffffc0201120:	00001617          	auipc	a2,0x1
ffffffffc0201124:	26060613          	addi	a2,a2,608 # ffffffffc0202380 <commands+0x740>
ffffffffc0201128:	14000593          	li	a1,320
ffffffffc020112c:	00001517          	auipc	a0,0x1
ffffffffc0201130:	26c50513          	addi	a0,a0,620 # ffffffffc0202398 <commands+0x758>
ffffffffc0201134:	81eff0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201138:	00001697          	auipc	a3,0x1
ffffffffc020113c:	50068693          	addi	a3,a3,1280 # ffffffffc0202638 <commands+0x9f8>
ffffffffc0201140:	00001617          	auipc	a2,0x1
ffffffffc0201144:	24060613          	addi	a2,a2,576 # ffffffffc0202380 <commands+0x740>
ffffffffc0201148:	13f00593          	li	a1,319
ffffffffc020114c:	00001517          	auipc	a0,0x1
ffffffffc0201150:	24c50513          	addi	a0,a0,588 # ffffffffc0202398 <commands+0x758>
ffffffffc0201154:	ffffe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0201158:	00001697          	auipc	a3,0x1
ffffffffc020115c:	4d068693          	addi	a3,a3,1232 # ffffffffc0202628 <commands+0x9e8>
ffffffffc0201160:	00001617          	auipc	a2,0x1
ffffffffc0201164:	22060613          	addi	a2,a2,544 # ffffffffc0202380 <commands+0x740>
ffffffffc0201168:	13700593          	li	a1,311
ffffffffc020116c:	00001517          	auipc	a0,0x1
ffffffffc0201170:	22c50513          	addi	a0,a0,556 # ffffffffc0202398 <commands+0x758>
ffffffffc0201174:	fdffe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0201178:	00001697          	auipc	a3,0x1
ffffffffc020117c:	49868693          	addi	a3,a3,1176 # ffffffffc0202610 <commands+0x9d0>
ffffffffc0201180:	00001617          	auipc	a2,0x1
ffffffffc0201184:	20060613          	addi	a2,a2,512 # ffffffffc0202380 <commands+0x740>
ffffffffc0201188:	13600593          	li	a1,310
ffffffffc020118c:	00001517          	auipc	a0,0x1
ffffffffc0201190:	20c50513          	addi	a0,a0,524 # ffffffffc0202398 <commands+0x758>
ffffffffc0201194:	fbffe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0201198:	00001697          	auipc	a3,0x1
ffffffffc020119c:	45868693          	addi	a3,a3,1112 # ffffffffc02025f0 <commands+0x9b0>
ffffffffc02011a0:	00001617          	auipc	a2,0x1
ffffffffc02011a4:	1e060613          	addi	a2,a2,480 # ffffffffc0202380 <commands+0x740>
ffffffffc02011a8:	13500593          	li	a1,309
ffffffffc02011ac:	00001517          	auipc	a0,0x1
ffffffffc02011b0:	1ec50513          	addi	a0,a0,492 # ffffffffc0202398 <commands+0x758>
ffffffffc02011b4:	f9ffe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02011b8:	00001697          	auipc	a3,0x1
ffffffffc02011bc:	40868693          	addi	a3,a3,1032 # ffffffffc02025c0 <commands+0x980>
ffffffffc02011c0:	00001617          	auipc	a2,0x1
ffffffffc02011c4:	1c060613          	addi	a2,a2,448 # ffffffffc0202380 <commands+0x740>
ffffffffc02011c8:	13300593          	li	a1,307
ffffffffc02011cc:	00001517          	auipc	a0,0x1
ffffffffc02011d0:	1cc50513          	addi	a0,a0,460 # ffffffffc0202398 <commands+0x758>
ffffffffc02011d4:	f7ffe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02011d8:	00001697          	auipc	a3,0x1
ffffffffc02011dc:	3d068693          	addi	a3,a3,976 # ffffffffc02025a8 <commands+0x968>
ffffffffc02011e0:	00001617          	auipc	a2,0x1
ffffffffc02011e4:	1a060613          	addi	a2,a2,416 # ffffffffc0202380 <commands+0x740>
ffffffffc02011e8:	13200593          	li	a1,306
ffffffffc02011ec:	00001517          	auipc	a0,0x1
ffffffffc02011f0:	1ac50513          	addi	a0,a0,428 # ffffffffc0202398 <commands+0x758>
ffffffffc02011f4:	f5ffe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011f8:	00001697          	auipc	a3,0x1
ffffffffc02011fc:	31868693          	addi	a3,a3,792 # ffffffffc0202510 <commands+0x8d0>
ffffffffc0201200:	00001617          	auipc	a2,0x1
ffffffffc0201204:	18060613          	addi	a2,a2,384 # ffffffffc0202380 <commands+0x740>
ffffffffc0201208:	12600593          	li	a1,294
ffffffffc020120c:	00001517          	auipc	a0,0x1
ffffffffc0201210:	18c50513          	addi	a0,a0,396 # ffffffffc0202398 <commands+0x758>
ffffffffc0201214:	f3ffe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201218:	00001697          	auipc	a3,0x1
ffffffffc020121c:	37868693          	addi	a3,a3,888 # ffffffffc0202590 <commands+0x950>
ffffffffc0201220:	00001617          	auipc	a2,0x1
ffffffffc0201224:	16060613          	addi	a2,a2,352 # ffffffffc0202380 <commands+0x740>
ffffffffc0201228:	11d00593          	li	a1,285
ffffffffc020122c:	00001517          	auipc	a0,0x1
ffffffffc0201230:	16c50513          	addi	a0,a0,364 # ffffffffc0202398 <commands+0x758>
ffffffffc0201234:	f1ffe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(p0 != NULL);
ffffffffc0201238:	00001697          	auipc	a3,0x1
ffffffffc020123c:	34868693          	addi	a3,a3,840 # ffffffffc0202580 <commands+0x940>
ffffffffc0201240:	00001617          	auipc	a2,0x1
ffffffffc0201244:	14060613          	addi	a2,a2,320 # ffffffffc0202380 <commands+0x740>
ffffffffc0201248:	11c00593          	li	a1,284
ffffffffc020124c:	00001517          	auipc	a0,0x1
ffffffffc0201250:	14c50513          	addi	a0,a0,332 # ffffffffc0202398 <commands+0x758>
ffffffffc0201254:	efffe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(nr_free == 0);
ffffffffc0201258:	00001697          	auipc	a3,0x1
ffffffffc020125c:	31868693          	addi	a3,a3,792 # ffffffffc0202570 <commands+0x930>
ffffffffc0201260:	00001617          	auipc	a2,0x1
ffffffffc0201264:	12060613          	addi	a2,a2,288 # ffffffffc0202380 <commands+0x740>
ffffffffc0201268:	0fe00593          	li	a1,254
ffffffffc020126c:	00001517          	auipc	a0,0x1
ffffffffc0201270:	12c50513          	addi	a0,a0,300 # ffffffffc0202398 <commands+0x758>
ffffffffc0201274:	edffe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201278:	00001697          	auipc	a3,0x1
ffffffffc020127c:	29868693          	addi	a3,a3,664 # ffffffffc0202510 <commands+0x8d0>
ffffffffc0201280:	00001617          	auipc	a2,0x1
ffffffffc0201284:	10060613          	addi	a2,a2,256 # ffffffffc0202380 <commands+0x740>
ffffffffc0201288:	0fc00593          	li	a1,252
ffffffffc020128c:	00001517          	auipc	a0,0x1
ffffffffc0201290:	10c50513          	addi	a0,a0,268 # ffffffffc0202398 <commands+0x758>
ffffffffc0201294:	ebffe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201298:	00001697          	auipc	a3,0x1
ffffffffc020129c:	2b868693          	addi	a3,a3,696 # ffffffffc0202550 <commands+0x910>
ffffffffc02012a0:	00001617          	auipc	a2,0x1
ffffffffc02012a4:	0e060613          	addi	a2,a2,224 # ffffffffc0202380 <commands+0x740>
ffffffffc02012a8:	0fb00593          	li	a1,251
ffffffffc02012ac:	00001517          	auipc	a0,0x1
ffffffffc02012b0:	0ec50513          	addi	a0,a0,236 # ffffffffc0202398 <commands+0x758>
ffffffffc02012b4:	e9ffe0ef          	jal	ra,ffffffffc0200152 <__panic>

ffffffffc02012b8 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc02012b8:	1141                	addi	sp,sp,-16
ffffffffc02012ba:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02012bc:	18058063          	beqz	a1,ffffffffc020143c <best_fit_free_pages+0x184>
    for (; p != base + n; p ++) {
ffffffffc02012c0:	00259693          	slli	a3,a1,0x2
ffffffffc02012c4:	96ae                	add	a3,a3,a1
ffffffffc02012c6:	068e                	slli	a3,a3,0x3
ffffffffc02012c8:	96aa                	add	a3,a3,a0
ffffffffc02012ca:	02d50d63          	beq	a0,a3,ffffffffc0201304 <best_fit_free_pages+0x4c>
ffffffffc02012ce:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02012d0:	8b85                	andi	a5,a5,1
ffffffffc02012d2:	14079563          	bnez	a5,ffffffffc020141c <best_fit_free_pages+0x164>
ffffffffc02012d6:	651c                	ld	a5,8(a0)
ffffffffc02012d8:	8385                	srli	a5,a5,0x1
ffffffffc02012da:	8b85                	andi	a5,a5,1
ffffffffc02012dc:	14079063          	bnez	a5,ffffffffc020141c <best_fit_free_pages+0x164>
ffffffffc02012e0:	87aa                	mv	a5,a0
ffffffffc02012e2:	a809                	j	ffffffffc02012f4 <best_fit_free_pages+0x3c>
ffffffffc02012e4:	6798                	ld	a4,8(a5)
ffffffffc02012e6:	8b05                	andi	a4,a4,1
ffffffffc02012e8:	12071a63          	bnez	a4,ffffffffc020141c <best_fit_free_pages+0x164>
ffffffffc02012ec:	6798                	ld	a4,8(a5)
ffffffffc02012ee:	8b09                	andi	a4,a4,2
ffffffffc02012f0:	12071663          	bnez	a4,ffffffffc020141c <best_fit_free_pages+0x164>
        p->flags = 0;
ffffffffc02012f4:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02012f8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02012fc:	02878793          	addi	a5,a5,40
ffffffffc0201300:	fed792e3          	bne	a5,a3,ffffffffc02012e4 <best_fit_free_pages+0x2c>
    base->property = n;
ffffffffc0201304:	2581                	sext.w	a1,a1
ffffffffc0201306:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201308:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020130c:	4789                	li	a5,2
ffffffffc020130e:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201312:	00005697          	auipc	a3,0x5
ffffffffc0201316:	14668693          	addi	a3,a3,326 # ffffffffc0206458 <free_area>
ffffffffc020131a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020131c:	669c                	ld	a5,8(a3)
ffffffffc020131e:	9db9                	addw	a1,a1,a4
ffffffffc0201320:	00005717          	auipc	a4,0x5
ffffffffc0201324:	14b72423          	sw	a1,328(a4) # ffffffffc0206468 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0201328:	08d78f63          	beq	a5,a3,ffffffffc02013c6 <best_fit_free_pages+0x10e>
            struct Page* page = le2page(le, page_link);
ffffffffc020132c:	fe878713          	addi	a4,a5,-24
ffffffffc0201330:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201332:	4801                	li	a6,0
ffffffffc0201334:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201338:	00e56a63          	bltu	a0,a4,ffffffffc020134c <best_fit_free_pages+0x94>
    return listelm->next;
ffffffffc020133c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020133e:	02d70563          	beq	a4,a3,ffffffffc0201368 <best_fit_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201342:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201344:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201348:	fee57ae3          	bleu	a4,a0,ffffffffc020133c <best_fit_free_pages+0x84>
ffffffffc020134c:	00080663          	beqz	a6,ffffffffc0201358 <best_fit_free_pages+0xa0>
ffffffffc0201350:	00005817          	auipc	a6,0x5
ffffffffc0201354:	10b83423          	sd	a1,264(a6) # ffffffffc0206458 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201358:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc020135a:	e390                	sd	a2,0(a5)
ffffffffc020135c:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc020135e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201360:	ed0c                	sd	a1,24(a0)
    if (le != &free_list) {
ffffffffc0201362:	02d59163          	bne	a1,a3,ffffffffc0201384 <best_fit_free_pages+0xcc>
ffffffffc0201366:	a091                	j	ffffffffc02013aa <best_fit_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc0201368:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020136a:	f114                	sd	a3,32(a0)
ffffffffc020136c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020136e:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201370:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201372:	00d70563          	beq	a4,a3,ffffffffc020137c <best_fit_free_pages+0xc4>
ffffffffc0201376:	4805                	li	a6,1
ffffffffc0201378:	87ba                	mv	a5,a4
ffffffffc020137a:	b7e9                	j	ffffffffc0201344 <best_fit_free_pages+0x8c>
ffffffffc020137c:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020137e:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc0201380:	02d78163          	beq	a5,a3,ffffffffc02013a2 <best_fit_free_pages+0xea>
        if(p + p->property == base)
ffffffffc0201384:	ff85a803          	lw	a6,-8(a1)
        p = le2page(le, page_link);
ffffffffc0201388:	fe858613          	addi	a2,a1,-24
        if(p + p->property == base)
ffffffffc020138c:	02081713          	slli	a4,a6,0x20
ffffffffc0201390:	9301                	srli	a4,a4,0x20
ffffffffc0201392:	00271793          	slli	a5,a4,0x2
ffffffffc0201396:	97ba                	add	a5,a5,a4
ffffffffc0201398:	078e                	slli	a5,a5,0x3
ffffffffc020139a:	97b2                	add	a5,a5,a2
ffffffffc020139c:	02f50e63          	beq	a0,a5,ffffffffc02013d8 <best_fit_free_pages+0x120>
ffffffffc02013a0:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02013a2:	fe878713          	addi	a4,a5,-24
ffffffffc02013a6:	00d78d63          	beq	a5,a3,ffffffffc02013c0 <best_fit_free_pages+0x108>
        if (base + base->property == p) {
ffffffffc02013aa:	490c                	lw	a1,16(a0)
ffffffffc02013ac:	02059613          	slli	a2,a1,0x20
ffffffffc02013b0:	9201                	srli	a2,a2,0x20
ffffffffc02013b2:	00261693          	slli	a3,a2,0x2
ffffffffc02013b6:	96b2                	add	a3,a3,a2
ffffffffc02013b8:	068e                	slli	a3,a3,0x3
ffffffffc02013ba:	96aa                	add	a3,a3,a0
ffffffffc02013bc:	04d70063          	beq	a4,a3,ffffffffc02013fc <best_fit_free_pages+0x144>
}
ffffffffc02013c0:	60a2                	ld	ra,8(sp)
ffffffffc02013c2:	0141                	addi	sp,sp,16
ffffffffc02013c4:	8082                	ret
ffffffffc02013c6:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02013c8:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02013cc:	e398                	sd	a4,0(a5)
ffffffffc02013ce:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02013d0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02013d2:	ed1c                	sd	a5,24(a0)
}
ffffffffc02013d4:	0141                	addi	sp,sp,16
ffffffffc02013d6:	8082                	ret
            p->property += base->property;
ffffffffc02013d8:	491c                	lw	a5,16(a0)
ffffffffc02013da:	0107883b          	addw	a6,a5,a6
ffffffffc02013de:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02013e2:	57f5                	li	a5,-3
ffffffffc02013e4:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02013e8:	01853803          	ld	a6,24(a0)
ffffffffc02013ec:	7118                	ld	a4,32(a0)
            base = p;
ffffffffc02013ee:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc02013f0:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02013f4:	659c                	ld	a5,8(a1)
ffffffffc02013f6:	01073023          	sd	a6,0(a4)
ffffffffc02013fa:	b765                	j	ffffffffc02013a2 <best_fit_free_pages+0xea>
            base->property += p->property;
ffffffffc02013fc:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201400:	ff078693          	addi	a3,a5,-16
ffffffffc0201404:	9db9                	addw	a1,a1,a4
ffffffffc0201406:	c90c                	sw	a1,16(a0)
ffffffffc0201408:	5775                	li	a4,-3
ffffffffc020140a:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020140e:	6398                	ld	a4,0(a5)
ffffffffc0201410:	679c                	ld	a5,8(a5)
}
ffffffffc0201412:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201414:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201416:	e398                	sd	a4,0(a5)
ffffffffc0201418:	0141                	addi	sp,sp,16
ffffffffc020141a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020141c:	00001697          	auipc	a3,0x1
ffffffffc0201420:	25c68693          	addi	a3,a3,604 # ffffffffc0202678 <commands+0xa38>
ffffffffc0201424:	00001617          	auipc	a2,0x1
ffffffffc0201428:	f5c60613          	addi	a2,a2,-164 # ffffffffc0202380 <commands+0x740>
ffffffffc020142c:	09700593          	li	a1,151
ffffffffc0201430:	00001517          	auipc	a0,0x1
ffffffffc0201434:	f6850513          	addi	a0,a0,-152 # ffffffffc0202398 <commands+0x758>
ffffffffc0201438:	d1bfe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(n > 0);
ffffffffc020143c:	00001697          	auipc	a3,0x1
ffffffffc0201440:	f3c68693          	addi	a3,a3,-196 # ffffffffc0202378 <commands+0x738>
ffffffffc0201444:	00001617          	auipc	a2,0x1
ffffffffc0201448:	f3c60613          	addi	a2,a2,-196 # ffffffffc0202380 <commands+0x740>
ffffffffc020144c:	09400593          	li	a1,148
ffffffffc0201450:	00001517          	auipc	a0,0x1
ffffffffc0201454:	f4850513          	addi	a0,a0,-184 # ffffffffc0202398 <commands+0x758>
ffffffffc0201458:	cfbfe0ef          	jal	ra,ffffffffc0200152 <__panic>

ffffffffc020145c <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc020145c:	1141                	addi	sp,sp,-16
ffffffffc020145e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201460:	c1fd                	beqz	a1,ffffffffc0201546 <best_fit_init_memmap+0xea>
    for (; p != base + n; p ++) {
ffffffffc0201462:	00259693          	slli	a3,a1,0x2
ffffffffc0201466:	96ae                	add	a3,a3,a1
ffffffffc0201468:	068e                	slli	a3,a3,0x3
ffffffffc020146a:	96aa                	add	a3,a3,a0
ffffffffc020146c:	02d50463          	beq	a0,a3,ffffffffc0201494 <best_fit_init_memmap+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201470:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc0201472:	87aa                	mv	a5,a0
ffffffffc0201474:	8b05                	andi	a4,a4,1
ffffffffc0201476:	e709                	bnez	a4,ffffffffc0201480 <best_fit_init_memmap+0x24>
ffffffffc0201478:	a07d                	j	ffffffffc0201526 <best_fit_init_memmap+0xca>
ffffffffc020147a:	6798                	ld	a4,8(a5)
ffffffffc020147c:	8b05                	andi	a4,a4,1
ffffffffc020147e:	c745                	beqz	a4,ffffffffc0201526 <best_fit_init_memmap+0xca>
        p->flags = 0;
ffffffffc0201480:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc0201484:	0007a823          	sw	zero,16(a5)
ffffffffc0201488:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020148c:	02878793          	addi	a5,a5,40
ffffffffc0201490:	fed795e3          	bne	a5,a3,ffffffffc020147a <best_fit_init_memmap+0x1e>
    base->property = n;
ffffffffc0201494:	2581                	sext.w	a1,a1
ffffffffc0201496:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201498:	4789                	li	a5,2
ffffffffc020149a:	00850713          	addi	a4,a0,8
ffffffffc020149e:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02014a2:	00005697          	auipc	a3,0x5
ffffffffc02014a6:	fb668693          	addi	a3,a3,-74 # ffffffffc0206458 <free_area>
ffffffffc02014aa:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02014ac:	669c                	ld	a5,8(a3)
ffffffffc02014ae:	9db9                	addw	a1,a1,a4
ffffffffc02014b0:	00005717          	auipc	a4,0x5
ffffffffc02014b4:	fab72c23          	sw	a1,-72(a4) # ffffffffc0206468 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc02014b8:	04d78a63          	beq	a5,a3,ffffffffc020150c <best_fit_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc02014bc:	fe878713          	addi	a4,a5,-24
ffffffffc02014c0:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02014c2:	4801                	li	a6,0
ffffffffc02014c4:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02014c8:	00e56a63          	bltu	a0,a4,ffffffffc02014dc <best_fit_init_memmap+0x80>
    return listelm->next;
ffffffffc02014cc:	6798                	ld	a4,8(a5)
            if (list_next(le) == &free_list)
ffffffffc02014ce:	02d70563          	beq	a4,a3,ffffffffc02014f8 <best_fit_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014d2:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014d4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02014d8:	fee57ae3          	bleu	a4,a0,ffffffffc02014cc <best_fit_init_memmap+0x70>
ffffffffc02014dc:	00080663          	beqz	a6,ffffffffc02014e8 <best_fit_init_memmap+0x8c>
ffffffffc02014e0:	00005717          	auipc	a4,0x5
ffffffffc02014e4:	f6b73c23          	sd	a1,-136(a4) # ffffffffc0206458 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02014e8:	6398                	ld	a4,0(a5)
}
ffffffffc02014ea:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02014ec:	e390                	sd	a2,0(a5)
ffffffffc02014ee:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02014f0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02014f2:	ed18                	sd	a4,24(a0)
ffffffffc02014f4:	0141                	addi	sp,sp,16
ffffffffc02014f6:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02014f8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02014fa:	f114                	sd	a3,32(a0)
ffffffffc02014fc:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02014fe:	ed1c                	sd	a5,24(a0)
                list_add_after(&(page->page_link),&(base->page_link));
ffffffffc0201500:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201502:	00d70e63          	beq	a4,a3,ffffffffc020151e <best_fit_init_memmap+0xc2>
ffffffffc0201506:	4805                	li	a6,1
ffffffffc0201508:	87ba                	mv	a5,a4
ffffffffc020150a:	b7e9                	j	ffffffffc02014d4 <best_fit_init_memmap+0x78>
}
ffffffffc020150c:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020150e:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201512:	e398                	sd	a4,0(a5)
ffffffffc0201514:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201516:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201518:	ed1c                	sd	a5,24(a0)
}
ffffffffc020151a:	0141                	addi	sp,sp,16
ffffffffc020151c:	8082                	ret
ffffffffc020151e:	60a2                	ld	ra,8(sp)
ffffffffc0201520:	e290                	sd	a2,0(a3)
ffffffffc0201522:	0141                	addi	sp,sp,16
ffffffffc0201524:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201526:	00001697          	auipc	a3,0x1
ffffffffc020152a:	17a68693          	addi	a3,a3,378 # ffffffffc02026a0 <commands+0xa60>
ffffffffc020152e:	00001617          	auipc	a2,0x1
ffffffffc0201532:	e5260613          	addi	a2,a2,-430 # ffffffffc0202380 <commands+0x740>
ffffffffc0201536:	04b00593          	li	a1,75
ffffffffc020153a:	00001517          	auipc	a0,0x1
ffffffffc020153e:	e5e50513          	addi	a0,a0,-418 # ffffffffc0202398 <commands+0x758>
ffffffffc0201542:	c11fe0ef          	jal	ra,ffffffffc0200152 <__panic>
    assert(n > 0);
ffffffffc0201546:	00001697          	auipc	a3,0x1
ffffffffc020154a:	e3268693          	addi	a3,a3,-462 # ffffffffc0202378 <commands+0x738>
ffffffffc020154e:	00001617          	auipc	a2,0x1
ffffffffc0201552:	e3260613          	addi	a2,a2,-462 # ffffffffc0202380 <commands+0x740>
ffffffffc0201556:	04800593          	li	a1,72
ffffffffc020155a:	00001517          	auipc	a0,0x1
ffffffffc020155e:	e3e50513          	addi	a0,a0,-450 # ffffffffc0202398 <commands+0x758>
ffffffffc0201562:	bf1fe0ef          	jal	ra,ffffffffc0200152 <__panic>

ffffffffc0201566 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201566:	c185                	beqz	a1,ffffffffc0201586 <strnlen+0x20>
ffffffffc0201568:	00054783          	lbu	a5,0(a0)
ffffffffc020156c:	cf89                	beqz	a5,ffffffffc0201586 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc020156e:	4781                	li	a5,0
ffffffffc0201570:	a021                	j	ffffffffc0201578 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201572:	00074703          	lbu	a4,0(a4)
ffffffffc0201576:	c711                	beqz	a4,ffffffffc0201582 <strnlen+0x1c>
        cnt ++;
ffffffffc0201578:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020157a:	00f50733          	add	a4,a0,a5
ffffffffc020157e:	fef59ae3          	bne	a1,a5,ffffffffc0201572 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0201582:	853e                	mv	a0,a5
ffffffffc0201584:	8082                	ret
    size_t cnt = 0;
ffffffffc0201586:	4781                	li	a5,0
}
ffffffffc0201588:	853e                	mv	a0,a5
ffffffffc020158a:	8082                	ret

ffffffffc020158c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020158c:	00054783          	lbu	a5,0(a0)
ffffffffc0201590:	0005c703          	lbu	a4,0(a1)
ffffffffc0201594:	cb91                	beqz	a5,ffffffffc02015a8 <strcmp+0x1c>
ffffffffc0201596:	00e79c63          	bne	a5,a4,ffffffffc02015ae <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc020159a:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020159c:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc02015a0:	0585                	addi	a1,a1,1
ffffffffc02015a2:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015a6:	fbe5                	bnez	a5,ffffffffc0201596 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02015a8:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02015aa:	9d19                	subw	a0,a0,a4
ffffffffc02015ac:	8082                	ret
ffffffffc02015ae:	0007851b          	sext.w	a0,a5
ffffffffc02015b2:	9d19                	subw	a0,a0,a4
ffffffffc02015b4:	8082                	ret

ffffffffc02015b6 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02015b6:	00054783          	lbu	a5,0(a0)
ffffffffc02015ba:	cb91                	beqz	a5,ffffffffc02015ce <strchr+0x18>
        if (*s == c) {
ffffffffc02015bc:	00b79563          	bne	a5,a1,ffffffffc02015c6 <strchr+0x10>
ffffffffc02015c0:	a809                	j	ffffffffc02015d2 <strchr+0x1c>
ffffffffc02015c2:	00b78763          	beq	a5,a1,ffffffffc02015d0 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc02015c6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02015c8:	00054783          	lbu	a5,0(a0)
ffffffffc02015cc:	fbfd                	bnez	a5,ffffffffc02015c2 <strchr+0xc>
    }
    return NULL;
ffffffffc02015ce:	4501                	li	a0,0
}
ffffffffc02015d0:	8082                	ret
ffffffffc02015d2:	8082                	ret

ffffffffc02015d4 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02015d4:	ca01                	beqz	a2,ffffffffc02015e4 <memset+0x10>
ffffffffc02015d6:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02015d8:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02015da:	0785                	addi	a5,a5,1
ffffffffc02015dc:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02015e0:	fec79de3          	bne	a5,a2,ffffffffc02015da <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02015e4:	8082                	ret

ffffffffc02015e6 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02015e6:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02015ea:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02015ec:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02015f0:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02015f2:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02015f6:	f022                	sd	s0,32(sp)
ffffffffc02015f8:	ec26                	sd	s1,24(sp)
ffffffffc02015fa:	e84a                	sd	s2,16(sp)
ffffffffc02015fc:	f406                	sd	ra,40(sp)
ffffffffc02015fe:	e44e                	sd	s3,8(sp)
ffffffffc0201600:	84aa                	mv	s1,a0
ffffffffc0201602:	892e                	mv	s2,a1
ffffffffc0201604:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201608:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc020160a:	03067e63          	bleu	a6,a2,ffffffffc0201646 <printnum+0x60>
ffffffffc020160e:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201610:	00805763          	blez	s0,ffffffffc020161e <printnum+0x38>
ffffffffc0201614:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201616:	85ca                	mv	a1,s2
ffffffffc0201618:	854e                	mv	a0,s3
ffffffffc020161a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020161c:	fc65                	bnez	s0,ffffffffc0201614 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020161e:	1a02                	slli	s4,s4,0x20
ffffffffc0201620:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201624:	00001797          	auipc	a5,0x1
ffffffffc0201628:	26c78793          	addi	a5,a5,620 # ffffffffc0202890 <error_string+0x38>
ffffffffc020162c:	9a3e                	add	s4,s4,a5
}
ffffffffc020162e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201630:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201634:	70a2                	ld	ra,40(sp)
ffffffffc0201636:	69a2                	ld	s3,8(sp)
ffffffffc0201638:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020163a:	85ca                	mv	a1,s2
ffffffffc020163c:	8326                	mv	t1,s1
}
ffffffffc020163e:	6942                	ld	s2,16(sp)
ffffffffc0201640:	64e2                	ld	s1,24(sp)
ffffffffc0201642:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201644:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201646:	03065633          	divu	a2,a2,a6
ffffffffc020164a:	8722                	mv	a4,s0
ffffffffc020164c:	f9bff0ef          	jal	ra,ffffffffc02015e6 <printnum>
ffffffffc0201650:	b7f9                	j	ffffffffc020161e <printnum+0x38>

ffffffffc0201652 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201652:	7119                	addi	sp,sp,-128
ffffffffc0201654:	f4a6                	sd	s1,104(sp)
ffffffffc0201656:	f0ca                	sd	s2,96(sp)
ffffffffc0201658:	e8d2                	sd	s4,80(sp)
ffffffffc020165a:	e4d6                	sd	s5,72(sp)
ffffffffc020165c:	e0da                	sd	s6,64(sp)
ffffffffc020165e:	fc5e                	sd	s7,56(sp)
ffffffffc0201660:	f862                	sd	s8,48(sp)
ffffffffc0201662:	f06a                	sd	s10,32(sp)
ffffffffc0201664:	fc86                	sd	ra,120(sp)
ffffffffc0201666:	f8a2                	sd	s0,112(sp)
ffffffffc0201668:	ecce                	sd	s3,88(sp)
ffffffffc020166a:	f466                	sd	s9,40(sp)
ffffffffc020166c:	ec6e                	sd	s11,24(sp)
ffffffffc020166e:	892a                	mv	s2,a0
ffffffffc0201670:	84ae                	mv	s1,a1
ffffffffc0201672:	8d32                	mv	s10,a2
ffffffffc0201674:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201676:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201678:	00001a17          	auipc	s4,0x1
ffffffffc020167c:	088a0a13          	addi	s4,s4,136 # ffffffffc0202700 <best_fit_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201680:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201684:	00001c17          	auipc	s8,0x1
ffffffffc0201688:	1d4c0c13          	addi	s8,s8,468 # ffffffffc0202858 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020168c:	000d4503          	lbu	a0,0(s10)
ffffffffc0201690:	02500793          	li	a5,37
ffffffffc0201694:	001d0413          	addi	s0,s10,1
ffffffffc0201698:	00f50e63          	beq	a0,a5,ffffffffc02016b4 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc020169c:	c521                	beqz	a0,ffffffffc02016e4 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020169e:	02500993          	li	s3,37
ffffffffc02016a2:	a011                	j	ffffffffc02016a6 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc02016a4:	c121                	beqz	a0,ffffffffc02016e4 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc02016a6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016a8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02016aa:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016ac:	fff44503          	lbu	a0,-1(s0)
ffffffffc02016b0:	ff351ae3          	bne	a0,s3,ffffffffc02016a4 <vprintfmt+0x52>
ffffffffc02016b4:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02016b8:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02016bc:	4981                	li	s3,0
ffffffffc02016be:	4801                	li	a6,0
        width = precision = -1;
ffffffffc02016c0:	5cfd                	li	s9,-1
ffffffffc02016c2:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016c4:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc02016c8:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016ca:	fdd6069b          	addiw	a3,a2,-35
ffffffffc02016ce:	0ff6f693          	andi	a3,a3,255
ffffffffc02016d2:	00140d13          	addi	s10,s0,1
ffffffffc02016d6:	20d5e563          	bltu	a1,a3,ffffffffc02018e0 <vprintfmt+0x28e>
ffffffffc02016da:	068a                	slli	a3,a3,0x2
ffffffffc02016dc:	96d2                	add	a3,a3,s4
ffffffffc02016de:	4294                	lw	a3,0(a3)
ffffffffc02016e0:	96d2                	add	a3,a3,s4
ffffffffc02016e2:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02016e4:	70e6                	ld	ra,120(sp)
ffffffffc02016e6:	7446                	ld	s0,112(sp)
ffffffffc02016e8:	74a6                	ld	s1,104(sp)
ffffffffc02016ea:	7906                	ld	s2,96(sp)
ffffffffc02016ec:	69e6                	ld	s3,88(sp)
ffffffffc02016ee:	6a46                	ld	s4,80(sp)
ffffffffc02016f0:	6aa6                	ld	s5,72(sp)
ffffffffc02016f2:	6b06                	ld	s6,64(sp)
ffffffffc02016f4:	7be2                	ld	s7,56(sp)
ffffffffc02016f6:	7c42                	ld	s8,48(sp)
ffffffffc02016f8:	7ca2                	ld	s9,40(sp)
ffffffffc02016fa:	7d02                	ld	s10,32(sp)
ffffffffc02016fc:	6de2                	ld	s11,24(sp)
ffffffffc02016fe:	6109                	addi	sp,sp,128
ffffffffc0201700:	8082                	ret
    if (lflag >= 2) {
ffffffffc0201702:	4705                	li	a4,1
ffffffffc0201704:	008a8593          	addi	a1,s5,8
ffffffffc0201708:	01074463          	blt	a4,a6,ffffffffc0201710 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc020170c:	26080363          	beqz	a6,ffffffffc0201972 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc0201710:	000ab603          	ld	a2,0(s5)
ffffffffc0201714:	46c1                	li	a3,16
ffffffffc0201716:	8aae                	mv	s5,a1
ffffffffc0201718:	a06d                	j	ffffffffc02017c2 <vprintfmt+0x170>
            goto reswitch;
ffffffffc020171a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020171e:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201720:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201722:	b765                	j	ffffffffc02016ca <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0201724:	000aa503          	lw	a0,0(s5)
ffffffffc0201728:	85a6                	mv	a1,s1
ffffffffc020172a:	0aa1                	addi	s5,s5,8
ffffffffc020172c:	9902                	jalr	s2
            break;
ffffffffc020172e:	bfb9                	j	ffffffffc020168c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201730:	4705                	li	a4,1
ffffffffc0201732:	008a8993          	addi	s3,s5,8
ffffffffc0201736:	01074463          	blt	a4,a6,ffffffffc020173e <vprintfmt+0xec>
    else if (lflag) {
ffffffffc020173a:	22080463          	beqz	a6,ffffffffc0201962 <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc020173e:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0201742:	24044463          	bltz	s0,ffffffffc020198a <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0201746:	8622                	mv	a2,s0
ffffffffc0201748:	8ace                	mv	s5,s3
ffffffffc020174a:	46a9                	li	a3,10
ffffffffc020174c:	a89d                	j	ffffffffc02017c2 <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc020174e:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201752:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201754:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0201756:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020175a:	8fb5                	xor	a5,a5,a3
ffffffffc020175c:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201760:	1ad74363          	blt	a4,a3,ffffffffc0201906 <vprintfmt+0x2b4>
ffffffffc0201764:	00369793          	slli	a5,a3,0x3
ffffffffc0201768:	97e2                	add	a5,a5,s8
ffffffffc020176a:	639c                	ld	a5,0(a5)
ffffffffc020176c:	18078d63          	beqz	a5,ffffffffc0201906 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201770:	86be                	mv	a3,a5
ffffffffc0201772:	00001617          	auipc	a2,0x1
ffffffffc0201776:	1ce60613          	addi	a2,a2,462 # ffffffffc0202940 <error_string+0xe8>
ffffffffc020177a:	85a6                	mv	a1,s1
ffffffffc020177c:	854a                	mv	a0,s2
ffffffffc020177e:	240000ef          	jal	ra,ffffffffc02019be <printfmt>
ffffffffc0201782:	b729                	j	ffffffffc020168c <vprintfmt+0x3a>
            lflag ++;
ffffffffc0201784:	00144603          	lbu	a2,1(s0)
ffffffffc0201788:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020178a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020178c:	bf3d                	j	ffffffffc02016ca <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc020178e:	4705                	li	a4,1
ffffffffc0201790:	008a8593          	addi	a1,s5,8
ffffffffc0201794:	01074463          	blt	a4,a6,ffffffffc020179c <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0201798:	1e080263          	beqz	a6,ffffffffc020197c <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc020179c:	000ab603          	ld	a2,0(s5)
ffffffffc02017a0:	46a1                	li	a3,8
ffffffffc02017a2:	8aae                	mv	s5,a1
ffffffffc02017a4:	a839                	j	ffffffffc02017c2 <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc02017a6:	03000513          	li	a0,48
ffffffffc02017aa:	85a6                	mv	a1,s1
ffffffffc02017ac:	e03e                	sd	a5,0(sp)
ffffffffc02017ae:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02017b0:	85a6                	mv	a1,s1
ffffffffc02017b2:	07800513          	li	a0,120
ffffffffc02017b6:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02017b8:	0aa1                	addi	s5,s5,8
ffffffffc02017ba:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc02017be:	6782                	ld	a5,0(sp)
ffffffffc02017c0:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02017c2:	876e                	mv	a4,s11
ffffffffc02017c4:	85a6                	mv	a1,s1
ffffffffc02017c6:	854a                	mv	a0,s2
ffffffffc02017c8:	e1fff0ef          	jal	ra,ffffffffc02015e6 <printnum>
            break;
ffffffffc02017cc:	b5c1                	j	ffffffffc020168c <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02017ce:	000ab603          	ld	a2,0(s5)
ffffffffc02017d2:	0aa1                	addi	s5,s5,8
ffffffffc02017d4:	1c060663          	beqz	a2,ffffffffc02019a0 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc02017d8:	00160413          	addi	s0,a2,1
ffffffffc02017dc:	17b05c63          	blez	s11,ffffffffc0201954 <vprintfmt+0x302>
ffffffffc02017e0:	02d00593          	li	a1,45
ffffffffc02017e4:	14b79263          	bne	a5,a1,ffffffffc0201928 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017e8:	00064783          	lbu	a5,0(a2)
ffffffffc02017ec:	0007851b          	sext.w	a0,a5
ffffffffc02017f0:	c905                	beqz	a0,ffffffffc0201820 <vprintfmt+0x1ce>
ffffffffc02017f2:	000cc563          	bltz	s9,ffffffffc02017fc <vprintfmt+0x1aa>
ffffffffc02017f6:	3cfd                	addiw	s9,s9,-1
ffffffffc02017f8:	036c8263          	beq	s9,s6,ffffffffc020181c <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc02017fc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02017fe:	18098463          	beqz	s3,ffffffffc0201986 <vprintfmt+0x334>
ffffffffc0201802:	3781                	addiw	a5,a5,-32
ffffffffc0201804:	18fbf163          	bleu	a5,s7,ffffffffc0201986 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0201808:	03f00513          	li	a0,63
ffffffffc020180c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020180e:	0405                	addi	s0,s0,1
ffffffffc0201810:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201814:	3dfd                	addiw	s11,s11,-1
ffffffffc0201816:	0007851b          	sext.w	a0,a5
ffffffffc020181a:	fd61                	bnez	a0,ffffffffc02017f2 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc020181c:	e7b058e3          	blez	s11,ffffffffc020168c <vprintfmt+0x3a>
ffffffffc0201820:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201822:	85a6                	mv	a1,s1
ffffffffc0201824:	02000513          	li	a0,32
ffffffffc0201828:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020182a:	e60d81e3          	beqz	s11,ffffffffc020168c <vprintfmt+0x3a>
ffffffffc020182e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201830:	85a6                	mv	a1,s1
ffffffffc0201832:	02000513          	li	a0,32
ffffffffc0201836:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201838:	fe0d94e3          	bnez	s11,ffffffffc0201820 <vprintfmt+0x1ce>
ffffffffc020183c:	bd81                	j	ffffffffc020168c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020183e:	4705                	li	a4,1
ffffffffc0201840:	008a8593          	addi	a1,s5,8
ffffffffc0201844:	01074463          	blt	a4,a6,ffffffffc020184c <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0201848:	12080063          	beqz	a6,ffffffffc0201968 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc020184c:	000ab603          	ld	a2,0(s5)
ffffffffc0201850:	46a9                	li	a3,10
ffffffffc0201852:	8aae                	mv	s5,a1
ffffffffc0201854:	b7bd                	j	ffffffffc02017c2 <vprintfmt+0x170>
ffffffffc0201856:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc020185a:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020185e:	846a                	mv	s0,s10
ffffffffc0201860:	b5ad                	j	ffffffffc02016ca <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0201862:	85a6                	mv	a1,s1
ffffffffc0201864:	02500513          	li	a0,37
ffffffffc0201868:	9902                	jalr	s2
            break;
ffffffffc020186a:	b50d                	j	ffffffffc020168c <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc020186c:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0201870:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201874:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201876:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0201878:	e40dd9e3          	bgez	s11,ffffffffc02016ca <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc020187c:	8de6                	mv	s11,s9
ffffffffc020187e:	5cfd                	li	s9,-1
ffffffffc0201880:	b5a9                	j	ffffffffc02016ca <vprintfmt+0x78>
            goto reswitch;
ffffffffc0201882:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc0201886:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020188a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020188c:	bd3d                	j	ffffffffc02016ca <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc020188e:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0201892:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201896:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201898:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020189c:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02018a0:	fcd56ce3          	bltu	a0,a3,ffffffffc0201878 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc02018a4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02018a6:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02018aa:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02018ae:	0196873b          	addw	a4,a3,s9
ffffffffc02018b2:	0017171b          	slliw	a4,a4,0x1
ffffffffc02018b6:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc02018ba:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc02018be:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02018c2:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02018c6:	fcd57fe3          	bleu	a3,a0,ffffffffc02018a4 <vprintfmt+0x252>
ffffffffc02018ca:	b77d                	j	ffffffffc0201878 <vprintfmt+0x226>
            if (width < 0)
ffffffffc02018cc:	fffdc693          	not	a3,s11
ffffffffc02018d0:	96fd                	srai	a3,a3,0x3f
ffffffffc02018d2:	00ddfdb3          	and	s11,s11,a3
ffffffffc02018d6:	00144603          	lbu	a2,1(s0)
ffffffffc02018da:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018dc:	846a                	mv	s0,s10
ffffffffc02018de:	b3f5                	j	ffffffffc02016ca <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc02018e0:	85a6                	mv	a1,s1
ffffffffc02018e2:	02500513          	li	a0,37
ffffffffc02018e6:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02018e8:	fff44703          	lbu	a4,-1(s0)
ffffffffc02018ec:	02500793          	li	a5,37
ffffffffc02018f0:	8d22                	mv	s10,s0
ffffffffc02018f2:	d8f70de3          	beq	a4,a5,ffffffffc020168c <vprintfmt+0x3a>
ffffffffc02018f6:	02500713          	li	a4,37
ffffffffc02018fa:	1d7d                	addi	s10,s10,-1
ffffffffc02018fc:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0201900:	fee79de3          	bne	a5,a4,ffffffffc02018fa <vprintfmt+0x2a8>
ffffffffc0201904:	b361                	j	ffffffffc020168c <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201906:	00001617          	auipc	a2,0x1
ffffffffc020190a:	02a60613          	addi	a2,a2,42 # ffffffffc0202930 <error_string+0xd8>
ffffffffc020190e:	85a6                	mv	a1,s1
ffffffffc0201910:	854a                	mv	a0,s2
ffffffffc0201912:	0ac000ef          	jal	ra,ffffffffc02019be <printfmt>
ffffffffc0201916:	bb9d                	j	ffffffffc020168c <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201918:	00001617          	auipc	a2,0x1
ffffffffc020191c:	01060613          	addi	a2,a2,16 # ffffffffc0202928 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0201920:	00001417          	auipc	s0,0x1
ffffffffc0201924:	00940413          	addi	s0,s0,9 # ffffffffc0202929 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201928:	8532                	mv	a0,a2
ffffffffc020192a:	85e6                	mv	a1,s9
ffffffffc020192c:	e032                	sd	a2,0(sp)
ffffffffc020192e:	e43e                	sd	a5,8(sp)
ffffffffc0201930:	c37ff0ef          	jal	ra,ffffffffc0201566 <strnlen>
ffffffffc0201934:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201938:	6602                	ld	a2,0(sp)
ffffffffc020193a:	01b05d63          	blez	s11,ffffffffc0201954 <vprintfmt+0x302>
ffffffffc020193e:	67a2                	ld	a5,8(sp)
ffffffffc0201940:	2781                	sext.w	a5,a5
ffffffffc0201942:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0201944:	6522                	ld	a0,8(sp)
ffffffffc0201946:	85a6                	mv	a1,s1
ffffffffc0201948:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020194a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020194c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020194e:	6602                	ld	a2,0(sp)
ffffffffc0201950:	fe0d9ae3          	bnez	s11,ffffffffc0201944 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201954:	00064783          	lbu	a5,0(a2)
ffffffffc0201958:	0007851b          	sext.w	a0,a5
ffffffffc020195c:	e8051be3          	bnez	a0,ffffffffc02017f2 <vprintfmt+0x1a0>
ffffffffc0201960:	b335                	j	ffffffffc020168c <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc0201962:	000aa403          	lw	s0,0(s5)
ffffffffc0201966:	bbf1                	j	ffffffffc0201742 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc0201968:	000ae603          	lwu	a2,0(s5)
ffffffffc020196c:	46a9                	li	a3,10
ffffffffc020196e:	8aae                	mv	s5,a1
ffffffffc0201970:	bd89                	j	ffffffffc02017c2 <vprintfmt+0x170>
ffffffffc0201972:	000ae603          	lwu	a2,0(s5)
ffffffffc0201976:	46c1                	li	a3,16
ffffffffc0201978:	8aae                	mv	s5,a1
ffffffffc020197a:	b5a1                	j	ffffffffc02017c2 <vprintfmt+0x170>
ffffffffc020197c:	000ae603          	lwu	a2,0(s5)
ffffffffc0201980:	46a1                	li	a3,8
ffffffffc0201982:	8aae                	mv	s5,a1
ffffffffc0201984:	bd3d                	j	ffffffffc02017c2 <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0201986:	9902                	jalr	s2
ffffffffc0201988:	b559                	j	ffffffffc020180e <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc020198a:	85a6                	mv	a1,s1
ffffffffc020198c:	02d00513          	li	a0,45
ffffffffc0201990:	e03e                	sd	a5,0(sp)
ffffffffc0201992:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201994:	8ace                	mv	s5,s3
ffffffffc0201996:	40800633          	neg	a2,s0
ffffffffc020199a:	46a9                	li	a3,10
ffffffffc020199c:	6782                	ld	a5,0(sp)
ffffffffc020199e:	b515                	j	ffffffffc02017c2 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02019a0:	01b05663          	blez	s11,ffffffffc02019ac <vprintfmt+0x35a>
ffffffffc02019a4:	02d00693          	li	a3,45
ffffffffc02019a8:	f6d798e3          	bne	a5,a3,ffffffffc0201918 <vprintfmt+0x2c6>
ffffffffc02019ac:	00001417          	auipc	s0,0x1
ffffffffc02019b0:	f7d40413          	addi	s0,s0,-131 # ffffffffc0202929 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02019b4:	02800513          	li	a0,40
ffffffffc02019b8:	02800793          	li	a5,40
ffffffffc02019bc:	bd1d                	j	ffffffffc02017f2 <vprintfmt+0x1a0>

ffffffffc02019be <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02019be:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02019c0:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02019c4:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02019c6:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02019c8:	ec06                	sd	ra,24(sp)
ffffffffc02019ca:	f83a                	sd	a4,48(sp)
ffffffffc02019cc:	fc3e                	sd	a5,56(sp)
ffffffffc02019ce:	e0c2                	sd	a6,64(sp)
ffffffffc02019d0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02019d2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02019d4:	c7fff0ef          	jal	ra,ffffffffc0201652 <vprintfmt>
}
ffffffffc02019d8:	60e2                	ld	ra,24(sp)
ffffffffc02019da:	6161                	addi	sp,sp,80
ffffffffc02019dc:	8082                	ret

ffffffffc02019de <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02019de:	715d                	addi	sp,sp,-80
ffffffffc02019e0:	e486                	sd	ra,72(sp)
ffffffffc02019e2:	e0a2                	sd	s0,64(sp)
ffffffffc02019e4:	fc26                	sd	s1,56(sp)
ffffffffc02019e6:	f84a                	sd	s2,48(sp)
ffffffffc02019e8:	f44e                	sd	s3,40(sp)
ffffffffc02019ea:	f052                	sd	s4,32(sp)
ffffffffc02019ec:	ec56                	sd	s5,24(sp)
ffffffffc02019ee:	e85a                	sd	s6,16(sp)
ffffffffc02019f0:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02019f2:	c901                	beqz	a0,ffffffffc0201a02 <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02019f4:	85aa                	mv	a1,a0
ffffffffc02019f6:	00001517          	auipc	a0,0x1
ffffffffc02019fa:	f4a50513          	addi	a0,a0,-182 # ffffffffc0202940 <error_string+0xe8>
ffffffffc02019fe:	eccfe0ef          	jal	ra,ffffffffc02000ca <cprintf>
readline(const char *prompt) {
ffffffffc0201a02:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a04:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201a06:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201a08:	4aa9                	li	s5,10
ffffffffc0201a0a:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201a0c:	00004b97          	auipc	s7,0x4
ffffffffc0201a10:	604b8b93          	addi	s7,s7,1540 # ffffffffc0206010 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a14:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201a18:	f2afe0ef          	jal	ra,ffffffffc0200142 <getchar>
ffffffffc0201a1c:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a1e:	00054b63          	bltz	a0,ffffffffc0201a34 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a22:	00a95b63          	ble	a0,s2,ffffffffc0201a38 <readline+0x5a>
ffffffffc0201a26:	029a5463          	ble	s1,s4,ffffffffc0201a4e <readline+0x70>
        c = getchar();
ffffffffc0201a2a:	f18fe0ef          	jal	ra,ffffffffc0200142 <getchar>
ffffffffc0201a2e:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a30:	fe0559e3          	bgez	a0,ffffffffc0201a22 <readline+0x44>
            return NULL;
ffffffffc0201a34:	4501                	li	a0,0
ffffffffc0201a36:	a099                	j	ffffffffc0201a7c <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0201a38:	03341463          	bne	s0,s3,ffffffffc0201a60 <readline+0x82>
ffffffffc0201a3c:	e8b9                	bnez	s1,ffffffffc0201a92 <readline+0xb4>
        c = getchar();
ffffffffc0201a3e:	f04fe0ef          	jal	ra,ffffffffc0200142 <getchar>
ffffffffc0201a42:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a44:	fe0548e3          	bltz	a0,ffffffffc0201a34 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a48:	fea958e3          	ble	a0,s2,ffffffffc0201a38 <readline+0x5a>
ffffffffc0201a4c:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201a4e:	8522                	mv	a0,s0
ffffffffc0201a50:	eaefe0ef          	jal	ra,ffffffffc02000fe <cputchar>
            buf[i ++] = c;
ffffffffc0201a54:	009b87b3          	add	a5,s7,s1
ffffffffc0201a58:	00878023          	sb	s0,0(a5)
ffffffffc0201a5c:	2485                	addiw	s1,s1,1
ffffffffc0201a5e:	bf6d                	j	ffffffffc0201a18 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0201a60:	01540463          	beq	s0,s5,ffffffffc0201a68 <readline+0x8a>
ffffffffc0201a64:	fb641ae3          	bne	s0,s6,ffffffffc0201a18 <readline+0x3a>
            cputchar(c);
ffffffffc0201a68:	8522                	mv	a0,s0
ffffffffc0201a6a:	e94fe0ef          	jal	ra,ffffffffc02000fe <cputchar>
            buf[i] = '\0';
ffffffffc0201a6e:	00004517          	auipc	a0,0x4
ffffffffc0201a72:	5a250513          	addi	a0,a0,1442 # ffffffffc0206010 <edata>
ffffffffc0201a76:	94aa                	add	s1,s1,a0
ffffffffc0201a78:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201a7c:	60a6                	ld	ra,72(sp)
ffffffffc0201a7e:	6406                	ld	s0,64(sp)
ffffffffc0201a80:	74e2                	ld	s1,56(sp)
ffffffffc0201a82:	7942                	ld	s2,48(sp)
ffffffffc0201a84:	79a2                	ld	s3,40(sp)
ffffffffc0201a86:	7a02                	ld	s4,32(sp)
ffffffffc0201a88:	6ae2                	ld	s5,24(sp)
ffffffffc0201a8a:	6b42                	ld	s6,16(sp)
ffffffffc0201a8c:	6ba2                	ld	s7,8(sp)
ffffffffc0201a8e:	6161                	addi	sp,sp,80
ffffffffc0201a90:	8082                	ret
            cputchar(c);
ffffffffc0201a92:	4521                	li	a0,8
ffffffffc0201a94:	e6afe0ef          	jal	ra,ffffffffc02000fe <cputchar>
            i --;
ffffffffc0201a98:	34fd                	addiw	s1,s1,-1
ffffffffc0201a9a:	bfbd                	j	ffffffffc0201a18 <readline+0x3a>

ffffffffc0201a9c <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201a9c:	00004797          	auipc	a5,0x4
ffffffffc0201aa0:	56c78793          	addi	a5,a5,1388 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile (
ffffffffc0201aa4:	6398                	ld	a4,0(a5)
ffffffffc0201aa6:	4781                	li	a5,0
ffffffffc0201aa8:	88ba                	mv	a7,a4
ffffffffc0201aaa:	852a                	mv	a0,a0
ffffffffc0201aac:	85be                	mv	a1,a5
ffffffffc0201aae:	863e                	mv	a2,a5
ffffffffc0201ab0:	00000073          	ecall
ffffffffc0201ab4:	87aa                	mv	a5,a0
}
ffffffffc0201ab6:	8082                	ret

ffffffffc0201ab8 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201ab8:	00005797          	auipc	a5,0x5
ffffffffc0201abc:	97078793          	addi	a5,a5,-1680 # ffffffffc0206428 <SBI_SET_TIMER>
    __asm__ volatile (
ffffffffc0201ac0:	6398                	ld	a4,0(a5)
ffffffffc0201ac2:	4781                	li	a5,0
ffffffffc0201ac4:	88ba                	mv	a7,a4
ffffffffc0201ac6:	852a                	mv	a0,a0
ffffffffc0201ac8:	85be                	mv	a1,a5
ffffffffc0201aca:	863e                	mv	a2,a5
ffffffffc0201acc:	00000073          	ecall
ffffffffc0201ad0:	87aa                	mv	a5,a0
}
ffffffffc0201ad2:	8082                	ret

ffffffffc0201ad4 <sbi_console_getchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201ad4:	00004797          	auipc	a5,0x4
ffffffffc0201ad8:	52c78793          	addi	a5,a5,1324 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile (
ffffffffc0201adc:	639c                	ld	a5,0(a5)
ffffffffc0201ade:	4501                	li	a0,0
ffffffffc0201ae0:	88be                	mv	a7,a5
ffffffffc0201ae2:	852a                	mv	a0,a0
ffffffffc0201ae4:	85aa                	mv	a1,a0
ffffffffc0201ae6:	862a                	mv	a2,a0
ffffffffc0201ae8:	00000073          	ecall
ffffffffc0201aec:	852a                	mv	a0,a0
}
ffffffffc0201aee:	2501                	sext.w	a0,a0
ffffffffc0201af0:	8082                	ret
