
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02082b7          	lui	t0,0xc0208
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
ffffffffc0200028:	c0208137          	lui	sp,0xc0208

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:


int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	00009517          	auipc	a0,0x9
ffffffffc020003a:	00a50513          	addi	a0,a0,10 # ffffffffc0209040 <edata>
ffffffffc020003e:	00010617          	auipc	a2,0x10
ffffffffc0200042:	55260613          	addi	a2,a2,1362 # ffffffffc0210590 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	3ab030ef          	jal	ra,ffffffffc0203bf8 <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00004597          	auipc	a1,0x4
ffffffffc0200056:	08658593          	addi	a1,a1,134 # ffffffffc02040d8 <etext>
ffffffffc020005a:	00004517          	auipc	a0,0x4
ffffffffc020005e:	09e50513          	addi	a0,a0,158 # ffffffffc02040f8 <etext+0x20>
ffffffffc0200062:	05c000ef          	jal	ra,ffffffffc02000be <cprintf>

    print_kerninfo();
ffffffffc0200066:	100000ef          	jal	ra,ffffffffc0200166 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	51d020ef          	jal	ra,ffffffffc0202d86 <pmm_init>

    idt_init();                 // init interrupt descriptor table
ffffffffc020006e:	4e0000ef          	jal	ra,ffffffffc020054e <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200072:	41f000ef          	jal	ra,ffffffffc0200c90 <vmm_init>

    ide_init();                 // init ide devices
ffffffffc0200076:	35e000ef          	jal	ra,ffffffffc02003d4 <ide_init>
    swap_init();                // init swap
ffffffffc020007a:	204010ef          	jal	ra,ffffffffc020127e <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020007e:	38a000ef          	jal	ra,ffffffffc0200408 <clock_init>
    // intr_enable();              // enable irq interrupt



    /* do nothing */
    while (1);
ffffffffc0200082:	a001                	j	ffffffffc0200082 <kern_init+0x4c>

ffffffffc0200084 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200084:	1141                	addi	sp,sp,-16
ffffffffc0200086:	e022                	sd	s0,0(sp)
ffffffffc0200088:	e406                	sd	ra,8(sp)
ffffffffc020008a:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020008c:	3d2000ef          	jal	ra,ffffffffc020045e <cons_putc>
    (*cnt) ++;
ffffffffc0200090:	401c                	lw	a5,0(s0)
}
ffffffffc0200092:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200094:	2785                	addiw	a5,a5,1
ffffffffc0200096:	c01c                	sw	a5,0(s0)
}
ffffffffc0200098:	6402                	ld	s0,0(sp)
ffffffffc020009a:	0141                	addi	sp,sp,16
ffffffffc020009c:	8082                	ret

ffffffffc020009e <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020009e:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a0:	86ae                	mv	a3,a1
ffffffffc02000a2:	862a                	mv	a2,a0
ffffffffc02000a4:	006c                	addi	a1,sp,12
ffffffffc02000a6:	00000517          	auipc	a0,0x0
ffffffffc02000aa:	fde50513          	addi	a0,a0,-34 # ffffffffc0200084 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ae:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000b0:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	3dd030ef          	jal	ra,ffffffffc0203c8e <vprintfmt>
    return cnt;
}
ffffffffc02000b6:	60e2                	ld	ra,24(sp)
ffffffffc02000b8:	4532                	lw	a0,12(sp)
ffffffffc02000ba:	6105                	addi	sp,sp,32
ffffffffc02000bc:	8082                	ret

ffffffffc02000be <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000be:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000c0:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000c4:	f42e                	sd	a1,40(sp)
ffffffffc02000c6:	f832                	sd	a2,48(sp)
ffffffffc02000c8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ca:	862a                	mv	a2,a0
ffffffffc02000cc:	004c                	addi	a1,sp,4
ffffffffc02000ce:	00000517          	auipc	a0,0x0
ffffffffc02000d2:	fb650513          	addi	a0,a0,-74 # ffffffffc0200084 <cputch>
ffffffffc02000d6:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	ec06                	sd	ra,24(sp)
ffffffffc02000da:	e0ba                	sd	a4,64(sp)
ffffffffc02000dc:	e4be                	sd	a5,72(sp)
ffffffffc02000de:	e8c2                	sd	a6,80(sp)
ffffffffc02000e0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000e2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000e4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	3a9030ef          	jal	ra,ffffffffc0203c8e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000ea:	60e2                	ld	ra,24(sp)
ffffffffc02000ec:	4512                	lw	a0,4(sp)
ffffffffc02000ee:	6125                	addi	sp,sp,96
ffffffffc02000f0:	8082                	ret

ffffffffc02000f2 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000f2:	36c0006f          	j	ffffffffc020045e <cons_putc>

ffffffffc02000f6 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02000f6:	1141                	addi	sp,sp,-16
ffffffffc02000f8:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02000fa:	39a000ef          	jal	ra,ffffffffc0200494 <cons_getc>
ffffffffc02000fe:	dd75                	beqz	a0,ffffffffc02000fa <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200100:	60a2                	ld	ra,8(sp)
ffffffffc0200102:	0141                	addi	sp,sp,16
ffffffffc0200104:	8082                	ret

ffffffffc0200106 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200106:	00010317          	auipc	t1,0x10
ffffffffc020010a:	33a30313          	addi	t1,t1,826 # ffffffffc0210440 <is_panic>
ffffffffc020010e:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200112:	715d                	addi	sp,sp,-80
ffffffffc0200114:	ec06                	sd	ra,24(sp)
ffffffffc0200116:	e822                	sd	s0,16(sp)
ffffffffc0200118:	f436                	sd	a3,40(sp)
ffffffffc020011a:	f83a                	sd	a4,48(sp)
ffffffffc020011c:	fc3e                	sd	a5,56(sp)
ffffffffc020011e:	e0c2                	sd	a6,64(sp)
ffffffffc0200120:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200122:	02031c63          	bnez	t1,ffffffffc020015a <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200126:	4785                	li	a5,1
ffffffffc0200128:	8432                	mv	s0,a2
ffffffffc020012a:	00010717          	auipc	a4,0x10
ffffffffc020012e:	30f72b23          	sw	a5,790(a4) # ffffffffc0210440 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200132:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc0200134:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200136:	85aa                	mv	a1,a0
ffffffffc0200138:	00004517          	auipc	a0,0x4
ffffffffc020013c:	fc850513          	addi	a0,a0,-56 # ffffffffc0204100 <etext+0x28>
    va_start(ap, fmt);
ffffffffc0200140:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200142:	f7dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200146:	65a2                	ld	a1,8(sp)
ffffffffc0200148:	8522                	mv	a0,s0
ffffffffc020014a:	f55ff0ef          	jal	ra,ffffffffc020009e <vcprintf>
    cprintf("\n");
ffffffffc020014e:	00006517          	auipc	a0,0x6
ffffffffc0200152:	8c250513          	addi	a0,a0,-1854 # ffffffffc0205a10 <default_pmm_manager+0x550>
ffffffffc0200156:	f69ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020015a:	37c000ef          	jal	ra,ffffffffc02004d6 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020015e:	4501                	li	a0,0
ffffffffc0200160:	132000ef          	jal	ra,ffffffffc0200292 <kmonitor>
ffffffffc0200164:	bfed                	j	ffffffffc020015e <__panic+0x58>

ffffffffc0200166 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200166:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200168:	00004517          	auipc	a0,0x4
ffffffffc020016c:	fe850513          	addi	a0,a0,-24 # ffffffffc0204150 <etext+0x78>
void print_kerninfo(void) {
ffffffffc0200170:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200172:	f4dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200176:	00000597          	auipc	a1,0x0
ffffffffc020017a:	ec058593          	addi	a1,a1,-320 # ffffffffc0200036 <kern_init>
ffffffffc020017e:	00004517          	auipc	a0,0x4
ffffffffc0200182:	ff250513          	addi	a0,a0,-14 # ffffffffc0204170 <etext+0x98>
ffffffffc0200186:	f39ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020018a:	00004597          	auipc	a1,0x4
ffffffffc020018e:	f4e58593          	addi	a1,a1,-178 # ffffffffc02040d8 <etext>
ffffffffc0200192:	00004517          	auipc	a0,0x4
ffffffffc0200196:	ffe50513          	addi	a0,a0,-2 # ffffffffc0204190 <etext+0xb8>
ffffffffc020019a:	f25ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020019e:	00009597          	auipc	a1,0x9
ffffffffc02001a2:	ea258593          	addi	a1,a1,-350 # ffffffffc0209040 <edata>
ffffffffc02001a6:	00004517          	auipc	a0,0x4
ffffffffc02001aa:	00a50513          	addi	a0,a0,10 # ffffffffc02041b0 <etext+0xd8>
ffffffffc02001ae:	f11ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc02001b2:	00010597          	auipc	a1,0x10
ffffffffc02001b6:	3de58593          	addi	a1,a1,990 # ffffffffc0210590 <end>
ffffffffc02001ba:	00004517          	auipc	a0,0x4
ffffffffc02001be:	01650513          	addi	a0,a0,22 # ffffffffc02041d0 <etext+0xf8>
ffffffffc02001c2:	efdff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c6:	00010597          	auipc	a1,0x10
ffffffffc02001ca:	7c958593          	addi	a1,a1,1993 # ffffffffc021098f <end+0x3ff>
ffffffffc02001ce:	00000797          	auipc	a5,0x0
ffffffffc02001d2:	e6878793          	addi	a5,a5,-408 # ffffffffc0200036 <kern_init>
ffffffffc02001d6:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001da:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001de:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e0:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e4:	95be                	add	a1,a1,a5
ffffffffc02001e6:	85a9                	srai	a1,a1,0xa
ffffffffc02001e8:	00004517          	auipc	a0,0x4
ffffffffc02001ec:	00850513          	addi	a0,a0,8 # ffffffffc02041f0 <etext+0x118>
}
ffffffffc02001f0:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f2:	ecdff06f          	j	ffffffffc02000be <cprintf>

ffffffffc02001f6 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f6:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001f8:	00004617          	auipc	a2,0x4
ffffffffc02001fc:	f2860613          	addi	a2,a2,-216 # ffffffffc0204120 <etext+0x48>
ffffffffc0200200:	04e00593          	li	a1,78
ffffffffc0200204:	00004517          	auipc	a0,0x4
ffffffffc0200208:	f3450513          	addi	a0,a0,-204 # ffffffffc0204138 <etext+0x60>
void print_stackframe(void) {
ffffffffc020020c:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020020e:	ef9ff0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0200212 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200212:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200214:	00004617          	auipc	a2,0x4
ffffffffc0200218:	0e460613          	addi	a2,a2,228 # ffffffffc02042f8 <commands+0xd8>
ffffffffc020021c:	00004597          	auipc	a1,0x4
ffffffffc0200220:	0fc58593          	addi	a1,a1,252 # ffffffffc0204318 <commands+0xf8>
ffffffffc0200224:	00004517          	auipc	a0,0x4
ffffffffc0200228:	0fc50513          	addi	a0,a0,252 # ffffffffc0204320 <commands+0x100>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020022c:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020022e:	e91ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0200232:	00004617          	auipc	a2,0x4
ffffffffc0200236:	0fe60613          	addi	a2,a2,254 # ffffffffc0204330 <commands+0x110>
ffffffffc020023a:	00004597          	auipc	a1,0x4
ffffffffc020023e:	11e58593          	addi	a1,a1,286 # ffffffffc0204358 <commands+0x138>
ffffffffc0200242:	00004517          	auipc	a0,0x4
ffffffffc0200246:	0de50513          	addi	a0,a0,222 # ffffffffc0204320 <commands+0x100>
ffffffffc020024a:	e75ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc020024e:	00004617          	auipc	a2,0x4
ffffffffc0200252:	11a60613          	addi	a2,a2,282 # ffffffffc0204368 <commands+0x148>
ffffffffc0200256:	00004597          	auipc	a1,0x4
ffffffffc020025a:	13258593          	addi	a1,a1,306 # ffffffffc0204388 <commands+0x168>
ffffffffc020025e:	00004517          	auipc	a0,0x4
ffffffffc0200262:	0c250513          	addi	a0,a0,194 # ffffffffc0204320 <commands+0x100>
ffffffffc0200266:	e59ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    }
    return 0;
}
ffffffffc020026a:	60a2                	ld	ra,8(sp)
ffffffffc020026c:	4501                	li	a0,0
ffffffffc020026e:	0141                	addi	sp,sp,16
ffffffffc0200270:	8082                	ret

ffffffffc0200272 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200272:	1141                	addi	sp,sp,-16
ffffffffc0200274:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200276:	ef1ff0ef          	jal	ra,ffffffffc0200166 <print_kerninfo>
    return 0;
}
ffffffffc020027a:	60a2                	ld	ra,8(sp)
ffffffffc020027c:	4501                	li	a0,0
ffffffffc020027e:	0141                	addi	sp,sp,16
ffffffffc0200280:	8082                	ret

ffffffffc0200282 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200282:	1141                	addi	sp,sp,-16
ffffffffc0200284:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200286:	f71ff0ef          	jal	ra,ffffffffc02001f6 <print_stackframe>
    return 0;
}
ffffffffc020028a:	60a2                	ld	ra,8(sp)
ffffffffc020028c:	4501                	li	a0,0
ffffffffc020028e:	0141                	addi	sp,sp,16
ffffffffc0200290:	8082                	ret

ffffffffc0200292 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200292:	7115                	addi	sp,sp,-224
ffffffffc0200294:	e962                	sd	s8,144(sp)
ffffffffc0200296:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200298:	00004517          	auipc	a0,0x4
ffffffffc020029c:	fd050513          	addi	a0,a0,-48 # ffffffffc0204268 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc02002a0:	ed86                	sd	ra,216(sp)
ffffffffc02002a2:	e9a2                	sd	s0,208(sp)
ffffffffc02002a4:	e5a6                	sd	s1,200(sp)
ffffffffc02002a6:	e1ca                	sd	s2,192(sp)
ffffffffc02002a8:	fd4e                	sd	s3,184(sp)
ffffffffc02002aa:	f952                	sd	s4,176(sp)
ffffffffc02002ac:	f556                	sd	s5,168(sp)
ffffffffc02002ae:	f15a                	sd	s6,160(sp)
ffffffffc02002b0:	ed5e                	sd	s7,152(sp)
ffffffffc02002b2:	e566                	sd	s9,136(sp)
ffffffffc02002b4:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b6:	e09ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002ba:	00004517          	auipc	a0,0x4
ffffffffc02002be:	fd650513          	addi	a0,a0,-42 # ffffffffc0204290 <commands+0x70>
ffffffffc02002c2:	dfdff0ef          	jal	ra,ffffffffc02000be <cprintf>
    if (tf != NULL) {
ffffffffc02002c6:	000c0563          	beqz	s8,ffffffffc02002d0 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002ca:	8562                	mv	a0,s8
ffffffffc02002cc:	46e000ef          	jal	ra,ffffffffc020073a <print_trapframe>
ffffffffc02002d0:	00004c97          	auipc	s9,0x4
ffffffffc02002d4:	f50c8c93          	addi	s9,s9,-176 # ffffffffc0204220 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc02002d8:	00005997          	auipc	s3,0x5
ffffffffc02002dc:	de898993          	addi	s3,s3,-536 # ffffffffc02050c0 <commands+0xea0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e0:	00004917          	auipc	s2,0x4
ffffffffc02002e4:	fd890913          	addi	s2,s2,-40 # ffffffffc02042b8 <commands+0x98>
        if (argc == MAXARGS - 1) {
ffffffffc02002e8:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002ea:	00004b17          	auipc	s6,0x4
ffffffffc02002ee:	fd6b0b13          	addi	s6,s6,-42 # ffffffffc02042c0 <commands+0xa0>
    if (argc == 0) {
ffffffffc02002f2:	00004a97          	auipc	s5,0x4
ffffffffc02002f6:	026a8a93          	addi	s5,s5,38 # ffffffffc0204318 <commands+0xf8>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fa:	4b8d                	li	s7,3
        if ((buf = readline("")) != NULL) {
ffffffffc02002fc:	854e                	mv	a0,s3
ffffffffc02002fe:	51d030ef          	jal	ra,ffffffffc020401a <readline>
ffffffffc0200302:	842a                	mv	s0,a0
ffffffffc0200304:	dd65                	beqz	a0,ffffffffc02002fc <kmonitor+0x6a>
ffffffffc0200306:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020030a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030c:	c999                	beqz	a1,ffffffffc0200322 <kmonitor+0x90>
ffffffffc020030e:	854a                	mv	a0,s2
ffffffffc0200310:	0cb030ef          	jal	ra,ffffffffc0203bda <strchr>
ffffffffc0200314:	c925                	beqz	a0,ffffffffc0200384 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc0200316:	00144583          	lbu	a1,1(s0)
ffffffffc020031a:	00040023          	sb	zero,0(s0)
ffffffffc020031e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200320:	f5fd                	bnez	a1,ffffffffc020030e <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc0200322:	dce9                	beqz	s1,ffffffffc02002fc <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200324:	6582                	ld	a1,0(sp)
ffffffffc0200326:	00004d17          	auipc	s10,0x4
ffffffffc020032a:	efad0d13          	addi	s10,s10,-262 # ffffffffc0204220 <commands>
    if (argc == 0) {
ffffffffc020032e:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200330:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200332:	0d61                	addi	s10,s10,24
ffffffffc0200334:	07d030ef          	jal	ra,ffffffffc0203bb0 <strcmp>
ffffffffc0200338:	c919                	beqz	a0,ffffffffc020034e <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020033a:	2405                	addiw	s0,s0,1
ffffffffc020033c:	09740463          	beq	s0,s7,ffffffffc02003c4 <kmonitor+0x132>
ffffffffc0200340:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200344:	6582                	ld	a1,0(sp)
ffffffffc0200346:	0d61                	addi	s10,s10,24
ffffffffc0200348:	069030ef          	jal	ra,ffffffffc0203bb0 <strcmp>
ffffffffc020034c:	f57d                	bnez	a0,ffffffffc020033a <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020034e:	00141793          	slli	a5,s0,0x1
ffffffffc0200352:	97a2                	add	a5,a5,s0
ffffffffc0200354:	078e                	slli	a5,a5,0x3
ffffffffc0200356:	97e6                	add	a5,a5,s9
ffffffffc0200358:	6b9c                	ld	a5,16(a5)
ffffffffc020035a:	8662                	mv	a2,s8
ffffffffc020035c:	002c                	addi	a1,sp,8
ffffffffc020035e:	fff4851b          	addiw	a0,s1,-1
ffffffffc0200362:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200364:	f8055ce3          	bgez	a0,ffffffffc02002fc <kmonitor+0x6a>
}
ffffffffc0200368:	60ee                	ld	ra,216(sp)
ffffffffc020036a:	644e                	ld	s0,208(sp)
ffffffffc020036c:	64ae                	ld	s1,200(sp)
ffffffffc020036e:	690e                	ld	s2,192(sp)
ffffffffc0200370:	79ea                	ld	s3,184(sp)
ffffffffc0200372:	7a4a                	ld	s4,176(sp)
ffffffffc0200374:	7aaa                	ld	s5,168(sp)
ffffffffc0200376:	7b0a                	ld	s6,160(sp)
ffffffffc0200378:	6bea                	ld	s7,152(sp)
ffffffffc020037a:	6c4a                	ld	s8,144(sp)
ffffffffc020037c:	6caa                	ld	s9,136(sp)
ffffffffc020037e:	6d0a                	ld	s10,128(sp)
ffffffffc0200380:	612d                	addi	sp,sp,224
ffffffffc0200382:	8082                	ret
        if (*buf == '\0') {
ffffffffc0200384:	00044783          	lbu	a5,0(s0)
ffffffffc0200388:	dfc9                	beqz	a5,ffffffffc0200322 <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc020038a:	03448863          	beq	s1,s4,ffffffffc02003ba <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc020038e:	00349793          	slli	a5,s1,0x3
ffffffffc0200392:	0118                	addi	a4,sp,128
ffffffffc0200394:	97ba                	add	a5,a5,a4
ffffffffc0200396:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020039e:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a0:	e591                	bnez	a1,ffffffffc02003ac <kmonitor+0x11a>
ffffffffc02003a2:	b749                	j	ffffffffc0200324 <kmonitor+0x92>
            buf ++;
ffffffffc02003a4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a6:	00044583          	lbu	a1,0(s0)
ffffffffc02003aa:	ddad                	beqz	a1,ffffffffc0200324 <kmonitor+0x92>
ffffffffc02003ac:	854a                	mv	a0,s2
ffffffffc02003ae:	02d030ef          	jal	ra,ffffffffc0203bda <strchr>
ffffffffc02003b2:	d96d                	beqz	a0,ffffffffc02003a4 <kmonitor+0x112>
ffffffffc02003b4:	00044583          	lbu	a1,0(s0)
ffffffffc02003b8:	bf91                	j	ffffffffc020030c <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003ba:	45c1                	li	a1,16
ffffffffc02003bc:	855a                	mv	a0,s6
ffffffffc02003be:	d01ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02003c2:	b7f1                	j	ffffffffc020038e <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003c4:	6582                	ld	a1,0(sp)
ffffffffc02003c6:	00004517          	auipc	a0,0x4
ffffffffc02003ca:	f1a50513          	addi	a0,a0,-230 # ffffffffc02042e0 <commands+0xc0>
ffffffffc02003ce:	cf1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    return 0;
ffffffffc02003d2:	b72d                	j	ffffffffc02002fc <kmonitor+0x6a>

ffffffffc02003d4 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02003d4:	8082                	ret

ffffffffc02003d6 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02003d6:	00253513          	sltiu	a0,a0,2
ffffffffc02003da:	8082                	ret

ffffffffc02003dc <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02003dc:	03800513          	li	a0,56
ffffffffc02003e0:	8082                	ret

ffffffffc02003e2 <ide_write_secs>:
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
    return 0;
}

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc02003e2:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02003e4:	0095979b          	slliw	a5,a1,0x9
ffffffffc02003e8:	00009517          	auipc	a0,0x9
ffffffffc02003ec:	c5850513          	addi	a0,a0,-936 # ffffffffc0209040 <edata>
                   size_t nsecs) {
ffffffffc02003f0:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02003f2:	00969613          	slli	a2,a3,0x9
ffffffffc02003f6:	85ba                	mv	a1,a4
ffffffffc02003f8:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc02003fa:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02003fc:	00f030ef          	jal	ra,ffffffffc0203c0a <memcpy>
    return 0;
}
ffffffffc0200400:	60a2                	ld	ra,8(sp)
ffffffffc0200402:	4501                	li	a0,0
ffffffffc0200404:	0141                	addi	sp,sp,16
ffffffffc0200406:	8082                	ret

ffffffffc0200408 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200408:	67e1                	lui	a5,0x18
ffffffffc020040a:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020040e:	00010717          	auipc	a4,0x10
ffffffffc0200412:	02f73d23          	sd	a5,58(a4) # ffffffffc0210448 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200416:	c0102573          	rdtime	a0
static inline void sbi_set_timer(uint64_t stime_value)
{
#if __riscv_xlen == 32
	SBI_CALL_2(SBI_SET_TIMER, stime_value, stime_value >> 32);
#else
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020041a:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020041c:	953e                	add	a0,a0,a5
ffffffffc020041e:	4601                	li	a2,0
ffffffffc0200420:	4881                	li	a7,0
ffffffffc0200422:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200426:	02000793          	li	a5,32
ffffffffc020042a:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00004517          	auipc	a0,0x4
ffffffffc0200432:	f6a50513          	addi	a0,a0,-150 # ffffffffc0204398 <commands+0x178>
    ticks = 0;
ffffffffc0200436:	00010797          	auipc	a5,0x10
ffffffffc020043a:	0407b123          	sd	zero,66(a5) # ffffffffc0210478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020043e:	c81ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc0200442 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200442:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200446:	00010797          	auipc	a5,0x10
ffffffffc020044a:	00278793          	addi	a5,a5,2 # ffffffffc0210448 <timebase>
ffffffffc020044e:	639c                	ld	a5,0(a5)
ffffffffc0200450:	4581                	li	a1,0
ffffffffc0200452:	4601                	li	a2,0
ffffffffc0200454:	953e                	add	a0,a0,a5
ffffffffc0200456:	4881                	li	a7,0
ffffffffc0200458:	00000073          	ecall
ffffffffc020045c:	8082                	ret

ffffffffc020045e <cons_putc>:
#include <intr.h>
#include <mmu.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020045e:	100027f3          	csrr	a5,sstatus
ffffffffc0200462:	8b89                	andi	a5,a5,2
ffffffffc0200464:	0ff57513          	andi	a0,a0,255
ffffffffc0200468:	e799                	bnez	a5,ffffffffc0200476 <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020046a:	4581                	li	a1,0
ffffffffc020046c:	4601                	li	a2,0
ffffffffc020046e:	4885                	li	a7,1
ffffffffc0200470:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200474:	8082                	ret

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200476:	1101                	addi	sp,sp,-32
ffffffffc0200478:	ec06                	sd	ra,24(sp)
ffffffffc020047a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020047c:	05a000ef          	jal	ra,ffffffffc02004d6 <intr_disable>
ffffffffc0200480:	6522                	ld	a0,8(sp)
ffffffffc0200482:	4581                	li	a1,0
ffffffffc0200484:	4601                	li	a2,0
ffffffffc0200486:	4885                	li	a7,1
ffffffffc0200488:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc020048c:	60e2                	ld	ra,24(sp)
ffffffffc020048e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200490:	0400006f          	j	ffffffffc02004d0 <intr_enable>

ffffffffc0200494 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200494:	100027f3          	csrr	a5,sstatus
ffffffffc0200498:	8b89                	andi	a5,a5,2
ffffffffc020049a:	eb89                	bnez	a5,ffffffffc02004ac <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc020049c:	4501                	li	a0,0
ffffffffc020049e:	4581                	li	a1,0
ffffffffc02004a0:	4601                	li	a2,0
ffffffffc02004a2:	4889                	li	a7,2
ffffffffc02004a4:	00000073          	ecall
ffffffffc02004a8:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02004aa:	8082                	ret
int cons_getc(void) {
ffffffffc02004ac:	1101                	addi	sp,sp,-32
ffffffffc02004ae:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02004b0:	026000ef          	jal	ra,ffffffffc02004d6 <intr_disable>
ffffffffc02004b4:	4501                	li	a0,0
ffffffffc02004b6:	4581                	li	a1,0
ffffffffc02004b8:	4601                	li	a2,0
ffffffffc02004ba:	4889                	li	a7,2
ffffffffc02004bc:	00000073          	ecall
ffffffffc02004c0:	2501                	sext.w	a0,a0
ffffffffc02004c2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02004c4:	00c000ef          	jal	ra,ffffffffc02004d0 <intr_enable>
}
ffffffffc02004c8:	60e2                	ld	ra,24(sp)
ffffffffc02004ca:	6522                	ld	a0,8(sp)
ffffffffc02004cc:	6105                	addi	sp,sp,32
ffffffffc02004ce:	8082                	ret

ffffffffc02004d0 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004d0:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02004d4:	8082                	ret

ffffffffc02004d6 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004d6:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02004da:	8082                	ret

ffffffffc02004dc <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004dc:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc02004e0:	1141                	addi	sp,sp,-16
ffffffffc02004e2:	e022                	sd	s0,0(sp)
ffffffffc02004e4:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004e6:	1007f793          	andi	a5,a5,256
static int pgfault_handler(struct trapframe *tf) {
ffffffffc02004ea:	842a                	mv	s0,a0
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02004ec:	11053583          	ld	a1,272(a0)
ffffffffc02004f0:	05500613          	li	a2,85
ffffffffc02004f4:	c399                	beqz	a5,ffffffffc02004fa <pgfault_handler+0x1e>
ffffffffc02004f6:	04b00613          	li	a2,75
ffffffffc02004fa:	11843703          	ld	a4,280(s0)
ffffffffc02004fe:	47bd                	li	a5,15
ffffffffc0200500:	05700693          	li	a3,87
ffffffffc0200504:	00f70463          	beq	a4,a5,ffffffffc020050c <pgfault_handler+0x30>
ffffffffc0200508:	05200693          	li	a3,82
ffffffffc020050c:	00004517          	auipc	a0,0x4
ffffffffc0200510:	18450513          	addi	a0,a0,388 # ffffffffc0204690 <commands+0x470>
ffffffffc0200514:	babff0ef          	jal	ra,ffffffffc02000be <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc0200518:	00010797          	auipc	a5,0x10
ffffffffc020051c:	f6878793          	addi	a5,a5,-152 # ffffffffc0210480 <check_mm_struct>
ffffffffc0200520:	6388                	ld	a0,0(a5)
ffffffffc0200522:	c911                	beqz	a0,ffffffffc0200536 <pgfault_handler+0x5a>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200524:	11043603          	ld	a2,272(s0)
ffffffffc0200528:	11843583          	ld	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc020052c:	6402                	ld	s0,0(sp)
ffffffffc020052e:	60a2                	ld	ra,8(sp)
ffffffffc0200530:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200532:	49d0006f          	j	ffffffffc02011ce <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc0200536:	00004617          	auipc	a2,0x4
ffffffffc020053a:	17a60613          	addi	a2,a2,378 # ffffffffc02046b0 <commands+0x490>
ffffffffc020053e:	07800593          	li	a1,120
ffffffffc0200542:	00004517          	auipc	a0,0x4
ffffffffc0200546:	18650513          	addi	a0,a0,390 # ffffffffc02046c8 <commands+0x4a8>
ffffffffc020054a:	bbdff0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc020054e <idt_init>:
    write_csr(sscratch, 0);
ffffffffc020054e:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200552:	00000797          	auipc	a5,0x0
ffffffffc0200556:	49e78793          	addi	a5,a5,1182 # ffffffffc02009f0 <__alltraps>
ffffffffc020055a:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SIE);
ffffffffc020055e:	100167f3          	csrrsi	a5,sstatus,2
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200562:	000407b7          	lui	a5,0x40
ffffffffc0200566:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020056a:	8082                	ret

ffffffffc020056c <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020056c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020056e:	1141                	addi	sp,sp,-16
ffffffffc0200570:	e022                	sd	s0,0(sp)
ffffffffc0200572:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200574:	00004517          	auipc	a0,0x4
ffffffffc0200578:	16c50513          	addi	a0,a0,364 # ffffffffc02046e0 <commands+0x4c0>
void print_regs(struct pushregs *gpr) {
ffffffffc020057c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020057e:	b41ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200582:	640c                	ld	a1,8(s0)
ffffffffc0200584:	00004517          	auipc	a0,0x4
ffffffffc0200588:	17450513          	addi	a0,a0,372 # ffffffffc02046f8 <commands+0x4d8>
ffffffffc020058c:	b33ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200590:	680c                	ld	a1,16(s0)
ffffffffc0200592:	00004517          	auipc	a0,0x4
ffffffffc0200596:	17e50513          	addi	a0,a0,382 # ffffffffc0204710 <commands+0x4f0>
ffffffffc020059a:	b25ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020059e:	6c0c                	ld	a1,24(s0)
ffffffffc02005a0:	00004517          	auipc	a0,0x4
ffffffffc02005a4:	18850513          	addi	a0,a0,392 # ffffffffc0204728 <commands+0x508>
ffffffffc02005a8:	b17ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02005ac:	700c                	ld	a1,32(s0)
ffffffffc02005ae:	00004517          	auipc	a0,0x4
ffffffffc02005b2:	19250513          	addi	a0,a0,402 # ffffffffc0204740 <commands+0x520>
ffffffffc02005b6:	b09ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02005ba:	740c                	ld	a1,40(s0)
ffffffffc02005bc:	00004517          	auipc	a0,0x4
ffffffffc02005c0:	19c50513          	addi	a0,a0,412 # ffffffffc0204758 <commands+0x538>
ffffffffc02005c4:	afbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005c8:	780c                	ld	a1,48(s0)
ffffffffc02005ca:	00004517          	auipc	a0,0x4
ffffffffc02005ce:	1a650513          	addi	a0,a0,422 # ffffffffc0204770 <commands+0x550>
ffffffffc02005d2:	aedff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005d6:	7c0c                	ld	a1,56(s0)
ffffffffc02005d8:	00004517          	auipc	a0,0x4
ffffffffc02005dc:	1b050513          	addi	a0,a0,432 # ffffffffc0204788 <commands+0x568>
ffffffffc02005e0:	adfff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02005e4:	602c                	ld	a1,64(s0)
ffffffffc02005e6:	00004517          	auipc	a0,0x4
ffffffffc02005ea:	1ba50513          	addi	a0,a0,442 # ffffffffc02047a0 <commands+0x580>
ffffffffc02005ee:	ad1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02005f2:	642c                	ld	a1,72(s0)
ffffffffc02005f4:	00004517          	auipc	a0,0x4
ffffffffc02005f8:	1c450513          	addi	a0,a0,452 # ffffffffc02047b8 <commands+0x598>
ffffffffc02005fc:	ac3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200600:	682c                	ld	a1,80(s0)
ffffffffc0200602:	00004517          	auipc	a0,0x4
ffffffffc0200606:	1ce50513          	addi	a0,a0,462 # ffffffffc02047d0 <commands+0x5b0>
ffffffffc020060a:	ab5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020060e:	6c2c                	ld	a1,88(s0)
ffffffffc0200610:	00004517          	auipc	a0,0x4
ffffffffc0200614:	1d850513          	addi	a0,a0,472 # ffffffffc02047e8 <commands+0x5c8>
ffffffffc0200618:	aa7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020061c:	702c                	ld	a1,96(s0)
ffffffffc020061e:	00004517          	auipc	a0,0x4
ffffffffc0200622:	1e250513          	addi	a0,a0,482 # ffffffffc0204800 <commands+0x5e0>
ffffffffc0200626:	a99ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020062a:	742c                	ld	a1,104(s0)
ffffffffc020062c:	00004517          	auipc	a0,0x4
ffffffffc0200630:	1ec50513          	addi	a0,a0,492 # ffffffffc0204818 <commands+0x5f8>
ffffffffc0200634:	a8bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200638:	782c                	ld	a1,112(s0)
ffffffffc020063a:	00004517          	auipc	a0,0x4
ffffffffc020063e:	1f650513          	addi	a0,a0,502 # ffffffffc0204830 <commands+0x610>
ffffffffc0200642:	a7dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200646:	7c2c                	ld	a1,120(s0)
ffffffffc0200648:	00004517          	auipc	a0,0x4
ffffffffc020064c:	20050513          	addi	a0,a0,512 # ffffffffc0204848 <commands+0x628>
ffffffffc0200650:	a6fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200654:	604c                	ld	a1,128(s0)
ffffffffc0200656:	00004517          	auipc	a0,0x4
ffffffffc020065a:	20a50513          	addi	a0,a0,522 # ffffffffc0204860 <commands+0x640>
ffffffffc020065e:	a61ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200662:	644c                	ld	a1,136(s0)
ffffffffc0200664:	00004517          	auipc	a0,0x4
ffffffffc0200668:	21450513          	addi	a0,a0,532 # ffffffffc0204878 <commands+0x658>
ffffffffc020066c:	a53ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200670:	684c                	ld	a1,144(s0)
ffffffffc0200672:	00004517          	auipc	a0,0x4
ffffffffc0200676:	21e50513          	addi	a0,a0,542 # ffffffffc0204890 <commands+0x670>
ffffffffc020067a:	a45ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020067e:	6c4c                	ld	a1,152(s0)
ffffffffc0200680:	00004517          	auipc	a0,0x4
ffffffffc0200684:	22850513          	addi	a0,a0,552 # ffffffffc02048a8 <commands+0x688>
ffffffffc0200688:	a37ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020068c:	704c                	ld	a1,160(s0)
ffffffffc020068e:	00004517          	auipc	a0,0x4
ffffffffc0200692:	23250513          	addi	a0,a0,562 # ffffffffc02048c0 <commands+0x6a0>
ffffffffc0200696:	a29ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020069a:	744c                	ld	a1,168(s0)
ffffffffc020069c:	00004517          	auipc	a0,0x4
ffffffffc02006a0:	23c50513          	addi	a0,a0,572 # ffffffffc02048d8 <commands+0x6b8>
ffffffffc02006a4:	a1bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02006a8:	784c                	ld	a1,176(s0)
ffffffffc02006aa:	00004517          	auipc	a0,0x4
ffffffffc02006ae:	24650513          	addi	a0,a0,582 # ffffffffc02048f0 <commands+0x6d0>
ffffffffc02006b2:	a0dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02006b6:	7c4c                	ld	a1,184(s0)
ffffffffc02006b8:	00004517          	auipc	a0,0x4
ffffffffc02006bc:	25050513          	addi	a0,a0,592 # ffffffffc0204908 <commands+0x6e8>
ffffffffc02006c0:	9ffff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006c4:	606c                	ld	a1,192(s0)
ffffffffc02006c6:	00004517          	auipc	a0,0x4
ffffffffc02006ca:	25a50513          	addi	a0,a0,602 # ffffffffc0204920 <commands+0x700>
ffffffffc02006ce:	9f1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006d2:	646c                	ld	a1,200(s0)
ffffffffc02006d4:	00004517          	auipc	a0,0x4
ffffffffc02006d8:	26450513          	addi	a0,a0,612 # ffffffffc0204938 <commands+0x718>
ffffffffc02006dc:	9e3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02006e0:	686c                	ld	a1,208(s0)
ffffffffc02006e2:	00004517          	auipc	a0,0x4
ffffffffc02006e6:	26e50513          	addi	a0,a0,622 # ffffffffc0204950 <commands+0x730>
ffffffffc02006ea:	9d5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02006ee:	6c6c                	ld	a1,216(s0)
ffffffffc02006f0:	00004517          	auipc	a0,0x4
ffffffffc02006f4:	27850513          	addi	a0,a0,632 # ffffffffc0204968 <commands+0x748>
ffffffffc02006f8:	9c7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02006fc:	706c                	ld	a1,224(s0)
ffffffffc02006fe:	00004517          	auipc	a0,0x4
ffffffffc0200702:	28250513          	addi	a0,a0,642 # ffffffffc0204980 <commands+0x760>
ffffffffc0200706:	9b9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020070a:	746c                	ld	a1,232(s0)
ffffffffc020070c:	00004517          	auipc	a0,0x4
ffffffffc0200710:	28c50513          	addi	a0,a0,652 # ffffffffc0204998 <commands+0x778>
ffffffffc0200714:	9abff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200718:	786c                	ld	a1,240(s0)
ffffffffc020071a:	00004517          	auipc	a0,0x4
ffffffffc020071e:	29650513          	addi	a0,a0,662 # ffffffffc02049b0 <commands+0x790>
ffffffffc0200722:	99dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200726:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200728:	6402                	ld	s0,0(sp)
ffffffffc020072a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020072c:	00004517          	auipc	a0,0x4
ffffffffc0200730:	29c50513          	addi	a0,a0,668 # ffffffffc02049c8 <commands+0x7a8>
}
ffffffffc0200734:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200736:	989ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc020073a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020073a:	1141                	addi	sp,sp,-16
ffffffffc020073c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020073e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200740:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200742:	00004517          	auipc	a0,0x4
ffffffffc0200746:	29e50513          	addi	a0,a0,670 # ffffffffc02049e0 <commands+0x7c0>
void print_trapframe(struct trapframe *tf) {
ffffffffc020074a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020074c:	973ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200750:	8522                	mv	a0,s0
ffffffffc0200752:	e1bff0ef          	jal	ra,ffffffffc020056c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200756:	10043583          	ld	a1,256(s0)
ffffffffc020075a:	00004517          	auipc	a0,0x4
ffffffffc020075e:	29e50513          	addi	a0,a0,670 # ffffffffc02049f8 <commands+0x7d8>
ffffffffc0200762:	95dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200766:	10843583          	ld	a1,264(s0)
ffffffffc020076a:	00004517          	auipc	a0,0x4
ffffffffc020076e:	2a650513          	addi	a0,a0,678 # ffffffffc0204a10 <commands+0x7f0>
ffffffffc0200772:	94dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200776:	11043583          	ld	a1,272(s0)
ffffffffc020077a:	00004517          	auipc	a0,0x4
ffffffffc020077e:	2ae50513          	addi	a0,a0,686 # ffffffffc0204a28 <commands+0x808>
ffffffffc0200782:	93dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200786:	11843583          	ld	a1,280(s0)
}
ffffffffc020078a:	6402                	ld	s0,0(sp)
ffffffffc020078c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020078e:	00004517          	auipc	a0,0x4
ffffffffc0200792:	2b250513          	addi	a0,a0,690 # ffffffffc0204a40 <commands+0x820>
}
ffffffffc0200796:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200798:	927ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc020079c <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc020079c:	11853783          	ld	a5,280(a0)
ffffffffc02007a0:	577d                	li	a4,-1
ffffffffc02007a2:	8305                	srli	a4,a4,0x1
ffffffffc02007a4:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02007a6:	472d                	li	a4,11
ffffffffc02007a8:	06f76f63          	bltu	a4,a5,ffffffffc0200826 <interrupt_handler+0x8a>
ffffffffc02007ac:	00004717          	auipc	a4,0x4
ffffffffc02007b0:	c0870713          	addi	a4,a4,-1016 # ffffffffc02043b4 <commands+0x194>
ffffffffc02007b4:	078a                	slli	a5,a5,0x2
ffffffffc02007b6:	97ba                	add	a5,a5,a4
ffffffffc02007b8:	439c                	lw	a5,0(a5)
ffffffffc02007ba:	97ba                	add	a5,a5,a4
ffffffffc02007bc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02007be:	00004517          	auipc	a0,0x4
ffffffffc02007c2:	e8250513          	addi	a0,a0,-382 # ffffffffc0204640 <commands+0x420>
ffffffffc02007c6:	8f9ff06f          	j	ffffffffc02000be <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02007ca:	00004517          	auipc	a0,0x4
ffffffffc02007ce:	e5650513          	addi	a0,a0,-426 # ffffffffc0204620 <commands+0x400>
ffffffffc02007d2:	8edff06f          	j	ffffffffc02000be <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02007d6:	00004517          	auipc	a0,0x4
ffffffffc02007da:	e0a50513          	addi	a0,a0,-502 # ffffffffc02045e0 <commands+0x3c0>
ffffffffc02007de:	8e1ff06f          	j	ffffffffc02000be <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02007e2:	00004517          	auipc	a0,0x4
ffffffffc02007e6:	e1e50513          	addi	a0,a0,-482 # ffffffffc0204600 <commands+0x3e0>
ffffffffc02007ea:	8d5ff06f          	j	ffffffffc02000be <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
ffffffffc02007ee:	00004517          	auipc	a0,0x4
ffffffffc02007f2:	e8250513          	addi	a0,a0,-382 # ffffffffc0204670 <commands+0x450>
ffffffffc02007f6:	8c9ff06f          	j	ffffffffc02000be <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02007fa:	1141                	addi	sp,sp,-16
ffffffffc02007fc:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc02007fe:	c45ff0ef          	jal	ra,ffffffffc0200442 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200802:	00010797          	auipc	a5,0x10
ffffffffc0200806:	c7678793          	addi	a5,a5,-906 # ffffffffc0210478 <ticks>
ffffffffc020080a:	639c                	ld	a5,0(a5)
ffffffffc020080c:	06400713          	li	a4,100
ffffffffc0200810:	0785                	addi	a5,a5,1
ffffffffc0200812:	02e7f733          	remu	a4,a5,a4
ffffffffc0200816:	00010697          	auipc	a3,0x10
ffffffffc020081a:	c6f6b123          	sd	a5,-926(a3) # ffffffffc0210478 <ticks>
ffffffffc020081e:	c711                	beqz	a4,ffffffffc020082a <interrupt_handler+0x8e>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200820:	60a2                	ld	ra,8(sp)
ffffffffc0200822:	0141                	addi	sp,sp,16
ffffffffc0200824:	8082                	ret
            print_trapframe(tf);
ffffffffc0200826:	f15ff06f          	j	ffffffffc020073a <print_trapframe>
}
ffffffffc020082a:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020082c:	06400593          	li	a1,100
ffffffffc0200830:	00004517          	auipc	a0,0x4
ffffffffc0200834:	e3050513          	addi	a0,a0,-464 # ffffffffc0204660 <commands+0x440>
}
ffffffffc0200838:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020083a:	885ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc020083e <exception_handler>:


void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc020083e:	11853783          	ld	a5,280(a0)
ffffffffc0200842:	473d                	li	a4,15
ffffffffc0200844:	16f76563          	bltu	a4,a5,ffffffffc02009ae <exception_handler+0x170>
ffffffffc0200848:	00004717          	auipc	a4,0x4
ffffffffc020084c:	b9c70713          	addi	a4,a4,-1124 # ffffffffc02043e4 <commands+0x1c4>
ffffffffc0200850:	078a                	slli	a5,a5,0x2
ffffffffc0200852:	97ba                	add	a5,a5,a4
ffffffffc0200854:	439c                	lw	a5,0(a5)
void exception_handler(struct trapframe *tf) {
ffffffffc0200856:	1101                	addi	sp,sp,-32
ffffffffc0200858:	e822                	sd	s0,16(sp)
ffffffffc020085a:	ec06                	sd	ra,24(sp)
ffffffffc020085c:	e426                	sd	s1,8(sp)
    switch (tf->cause) {
ffffffffc020085e:	97ba                	add	a5,a5,a4
ffffffffc0200860:	842a                	mv	s0,a0
ffffffffc0200862:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc0200864:	00004517          	auipc	a0,0x4
ffffffffc0200868:	d6450513          	addi	a0,a0,-668 # ffffffffc02045c8 <commands+0x3a8>
ffffffffc020086c:	853ff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200870:	8522                	mv	a0,s0
ffffffffc0200872:	c6bff0ef          	jal	ra,ffffffffc02004dc <pgfault_handler>
ffffffffc0200876:	84aa                	mv	s1,a0
ffffffffc0200878:	12051d63          	bnez	a0,ffffffffc02009b2 <exception_handler+0x174>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020087c:	60e2                	ld	ra,24(sp)
ffffffffc020087e:	6442                	ld	s0,16(sp)
ffffffffc0200880:	64a2                	ld	s1,8(sp)
ffffffffc0200882:	6105                	addi	sp,sp,32
ffffffffc0200884:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc0200886:	00004517          	auipc	a0,0x4
ffffffffc020088a:	ba250513          	addi	a0,a0,-1118 # ffffffffc0204428 <commands+0x208>
}
ffffffffc020088e:	6442                	ld	s0,16(sp)
ffffffffc0200890:	60e2                	ld	ra,24(sp)
ffffffffc0200892:	64a2                	ld	s1,8(sp)
ffffffffc0200894:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200896:	829ff06f          	j	ffffffffc02000be <cprintf>
ffffffffc020089a:	00004517          	auipc	a0,0x4
ffffffffc020089e:	bae50513          	addi	a0,a0,-1106 # ffffffffc0204448 <commands+0x228>
ffffffffc02008a2:	b7f5                	j	ffffffffc020088e <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc02008a4:	00004517          	auipc	a0,0x4
ffffffffc02008a8:	bc450513          	addi	a0,a0,-1084 # ffffffffc0204468 <commands+0x248>
ffffffffc02008ac:	b7cd                	j	ffffffffc020088e <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc02008ae:	00004517          	auipc	a0,0x4
ffffffffc02008b2:	bd250513          	addi	a0,a0,-1070 # ffffffffc0204480 <commands+0x260>
ffffffffc02008b6:	bfe1                	j	ffffffffc020088e <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc02008b8:	00004517          	auipc	a0,0x4
ffffffffc02008bc:	bd850513          	addi	a0,a0,-1064 # ffffffffc0204490 <commands+0x270>
ffffffffc02008c0:	b7f9                	j	ffffffffc020088e <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02008c2:	00004517          	auipc	a0,0x4
ffffffffc02008c6:	bee50513          	addi	a0,a0,-1042 # ffffffffc02044b0 <commands+0x290>
ffffffffc02008ca:	ff4ff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02008ce:	8522                	mv	a0,s0
ffffffffc02008d0:	c0dff0ef          	jal	ra,ffffffffc02004dc <pgfault_handler>
ffffffffc02008d4:	84aa                	mv	s1,a0
ffffffffc02008d6:	d15d                	beqz	a0,ffffffffc020087c <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02008d8:	8522                	mv	a0,s0
ffffffffc02008da:	e61ff0ef          	jal	ra,ffffffffc020073a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02008de:	86a6                	mv	a3,s1
ffffffffc02008e0:	00004617          	auipc	a2,0x4
ffffffffc02008e4:	be860613          	addi	a2,a2,-1048 # ffffffffc02044c8 <commands+0x2a8>
ffffffffc02008e8:	0ca00593          	li	a1,202
ffffffffc02008ec:	00004517          	auipc	a0,0x4
ffffffffc02008f0:	ddc50513          	addi	a0,a0,-548 # ffffffffc02046c8 <commands+0x4a8>
ffffffffc02008f4:	813ff0ef          	jal	ra,ffffffffc0200106 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc02008f8:	00004517          	auipc	a0,0x4
ffffffffc02008fc:	bf050513          	addi	a0,a0,-1040 # ffffffffc02044e8 <commands+0x2c8>
ffffffffc0200900:	b779                	j	ffffffffc020088e <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc0200902:	00004517          	auipc	a0,0x4
ffffffffc0200906:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0204500 <commands+0x2e0>
ffffffffc020090a:	fb4ff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc020090e:	8522                	mv	a0,s0
ffffffffc0200910:	bcdff0ef          	jal	ra,ffffffffc02004dc <pgfault_handler>
ffffffffc0200914:	84aa                	mv	s1,a0
ffffffffc0200916:	d13d                	beqz	a0,ffffffffc020087c <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200918:	8522                	mv	a0,s0
ffffffffc020091a:	e21ff0ef          	jal	ra,ffffffffc020073a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc020091e:	86a6                	mv	a3,s1
ffffffffc0200920:	00004617          	auipc	a2,0x4
ffffffffc0200924:	ba860613          	addi	a2,a2,-1112 # ffffffffc02044c8 <commands+0x2a8>
ffffffffc0200928:	0d400593          	li	a1,212
ffffffffc020092c:	00004517          	auipc	a0,0x4
ffffffffc0200930:	d9c50513          	addi	a0,a0,-612 # ffffffffc02046c8 <commands+0x4a8>
ffffffffc0200934:	fd2ff0ef          	jal	ra,ffffffffc0200106 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc0200938:	00004517          	auipc	a0,0x4
ffffffffc020093c:	be050513          	addi	a0,a0,-1056 # ffffffffc0204518 <commands+0x2f8>
ffffffffc0200940:	b7b9                	j	ffffffffc020088e <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200942:	00004517          	auipc	a0,0x4
ffffffffc0200946:	bf650513          	addi	a0,a0,-1034 # ffffffffc0204538 <commands+0x318>
ffffffffc020094a:	b791                	j	ffffffffc020088e <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc020094c:	00004517          	auipc	a0,0x4
ffffffffc0200950:	c0c50513          	addi	a0,a0,-1012 # ffffffffc0204558 <commands+0x338>
ffffffffc0200954:	bf2d                	j	ffffffffc020088e <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc0200956:	00004517          	auipc	a0,0x4
ffffffffc020095a:	c2250513          	addi	a0,a0,-990 # ffffffffc0204578 <commands+0x358>
ffffffffc020095e:	bf05                	j	ffffffffc020088e <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200960:	00004517          	auipc	a0,0x4
ffffffffc0200964:	c3850513          	addi	a0,a0,-968 # ffffffffc0204598 <commands+0x378>
ffffffffc0200968:	b71d                	j	ffffffffc020088e <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc020096a:	00004517          	auipc	a0,0x4
ffffffffc020096e:	c4650513          	addi	a0,a0,-954 # ffffffffc02045b0 <commands+0x390>
ffffffffc0200972:	f4cff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200976:	8522                	mv	a0,s0
ffffffffc0200978:	b65ff0ef          	jal	ra,ffffffffc02004dc <pgfault_handler>
ffffffffc020097c:	84aa                	mv	s1,a0
ffffffffc020097e:	ee050fe3          	beqz	a0,ffffffffc020087c <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200982:	8522                	mv	a0,s0
ffffffffc0200984:	db7ff0ef          	jal	ra,ffffffffc020073a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200988:	86a6                	mv	a3,s1
ffffffffc020098a:	00004617          	auipc	a2,0x4
ffffffffc020098e:	b3e60613          	addi	a2,a2,-1218 # ffffffffc02044c8 <commands+0x2a8>
ffffffffc0200992:	0ea00593          	li	a1,234
ffffffffc0200996:	00004517          	auipc	a0,0x4
ffffffffc020099a:	d3250513          	addi	a0,a0,-718 # ffffffffc02046c8 <commands+0x4a8>
ffffffffc020099e:	f68ff0ef          	jal	ra,ffffffffc0200106 <__panic>
}
ffffffffc02009a2:	6442                	ld	s0,16(sp)
ffffffffc02009a4:	60e2                	ld	ra,24(sp)
ffffffffc02009a6:	64a2                	ld	s1,8(sp)
ffffffffc02009a8:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc02009aa:	d91ff06f          	j	ffffffffc020073a <print_trapframe>
ffffffffc02009ae:	d8dff06f          	j	ffffffffc020073a <print_trapframe>
                print_trapframe(tf);
ffffffffc02009b2:	8522                	mv	a0,s0
ffffffffc02009b4:	d87ff0ef          	jal	ra,ffffffffc020073a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009b8:	86a6                	mv	a3,s1
ffffffffc02009ba:	00004617          	auipc	a2,0x4
ffffffffc02009be:	b0e60613          	addi	a2,a2,-1266 # ffffffffc02044c8 <commands+0x2a8>
ffffffffc02009c2:	0f100593          	li	a1,241
ffffffffc02009c6:	00004517          	auipc	a0,0x4
ffffffffc02009ca:	d0250513          	addi	a0,a0,-766 # ffffffffc02046c8 <commands+0x4a8>
ffffffffc02009ce:	f38ff0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc02009d2 <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc02009d2:	11853783          	ld	a5,280(a0)
ffffffffc02009d6:	0007c463          	bltz	a5,ffffffffc02009de <trap+0xc>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02009da:	e65ff06f          	j	ffffffffc020083e <exception_handler>
        interrupt_handler(tf);
ffffffffc02009de:	dbfff06f          	j	ffffffffc020079c <interrupt_handler>
	...

ffffffffc02009f0 <__alltraps>:
    .endm

    .align 4
    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc02009f0:	14011073          	csrw	sscratch,sp
ffffffffc02009f4:	712d                	addi	sp,sp,-288
ffffffffc02009f6:	e406                	sd	ra,8(sp)
ffffffffc02009f8:	ec0e                	sd	gp,24(sp)
ffffffffc02009fa:	f012                	sd	tp,32(sp)
ffffffffc02009fc:	f416                	sd	t0,40(sp)
ffffffffc02009fe:	f81a                	sd	t1,48(sp)
ffffffffc0200a00:	fc1e                	sd	t2,56(sp)
ffffffffc0200a02:	e0a2                	sd	s0,64(sp)
ffffffffc0200a04:	e4a6                	sd	s1,72(sp)
ffffffffc0200a06:	e8aa                	sd	a0,80(sp)
ffffffffc0200a08:	ecae                	sd	a1,88(sp)
ffffffffc0200a0a:	f0b2                	sd	a2,96(sp)
ffffffffc0200a0c:	f4b6                	sd	a3,104(sp)
ffffffffc0200a0e:	f8ba                	sd	a4,112(sp)
ffffffffc0200a10:	fcbe                	sd	a5,120(sp)
ffffffffc0200a12:	e142                	sd	a6,128(sp)
ffffffffc0200a14:	e546                	sd	a7,136(sp)
ffffffffc0200a16:	e94a                	sd	s2,144(sp)
ffffffffc0200a18:	ed4e                	sd	s3,152(sp)
ffffffffc0200a1a:	f152                	sd	s4,160(sp)
ffffffffc0200a1c:	f556                	sd	s5,168(sp)
ffffffffc0200a1e:	f95a                	sd	s6,176(sp)
ffffffffc0200a20:	fd5e                	sd	s7,184(sp)
ffffffffc0200a22:	e1e2                	sd	s8,192(sp)
ffffffffc0200a24:	e5e6                	sd	s9,200(sp)
ffffffffc0200a26:	e9ea                	sd	s10,208(sp)
ffffffffc0200a28:	edee                	sd	s11,216(sp)
ffffffffc0200a2a:	f1f2                	sd	t3,224(sp)
ffffffffc0200a2c:	f5f6                	sd	t4,232(sp)
ffffffffc0200a2e:	f9fa                	sd	t5,240(sp)
ffffffffc0200a30:	fdfe                	sd	t6,248(sp)
ffffffffc0200a32:	14002473          	csrr	s0,sscratch
ffffffffc0200a36:	100024f3          	csrr	s1,sstatus
ffffffffc0200a3a:	14102973          	csrr	s2,sepc
ffffffffc0200a3e:	143029f3          	csrr	s3,stval
ffffffffc0200a42:	14202a73          	csrr	s4,scause
ffffffffc0200a46:	e822                	sd	s0,16(sp)
ffffffffc0200a48:	e226                	sd	s1,256(sp)
ffffffffc0200a4a:	e64a                	sd	s2,264(sp)
ffffffffc0200a4c:	ea4e                	sd	s3,272(sp)
ffffffffc0200a4e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200a50:	850a                	mv	a0,sp
    jal trap
ffffffffc0200a52:	f81ff0ef          	jal	ra,ffffffffc02009d2 <trap>

ffffffffc0200a56 <__trapret>:
    // sp should be the same as before "jal trap"
    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200a56:	6492                	ld	s1,256(sp)
ffffffffc0200a58:	6932                	ld	s2,264(sp)
ffffffffc0200a5a:	10049073          	csrw	sstatus,s1
ffffffffc0200a5e:	14191073          	csrw	sepc,s2
ffffffffc0200a62:	60a2                	ld	ra,8(sp)
ffffffffc0200a64:	61e2                	ld	gp,24(sp)
ffffffffc0200a66:	7202                	ld	tp,32(sp)
ffffffffc0200a68:	72a2                	ld	t0,40(sp)
ffffffffc0200a6a:	7342                	ld	t1,48(sp)
ffffffffc0200a6c:	73e2                	ld	t2,56(sp)
ffffffffc0200a6e:	6406                	ld	s0,64(sp)
ffffffffc0200a70:	64a6                	ld	s1,72(sp)
ffffffffc0200a72:	6546                	ld	a0,80(sp)
ffffffffc0200a74:	65e6                	ld	a1,88(sp)
ffffffffc0200a76:	7606                	ld	a2,96(sp)
ffffffffc0200a78:	76a6                	ld	a3,104(sp)
ffffffffc0200a7a:	7746                	ld	a4,112(sp)
ffffffffc0200a7c:	77e6                	ld	a5,120(sp)
ffffffffc0200a7e:	680a                	ld	a6,128(sp)
ffffffffc0200a80:	68aa                	ld	a7,136(sp)
ffffffffc0200a82:	694a                	ld	s2,144(sp)
ffffffffc0200a84:	69ea                	ld	s3,152(sp)
ffffffffc0200a86:	7a0a                	ld	s4,160(sp)
ffffffffc0200a88:	7aaa                	ld	s5,168(sp)
ffffffffc0200a8a:	7b4a                	ld	s6,176(sp)
ffffffffc0200a8c:	7bea                	ld	s7,184(sp)
ffffffffc0200a8e:	6c0e                	ld	s8,192(sp)
ffffffffc0200a90:	6cae                	ld	s9,200(sp)
ffffffffc0200a92:	6d4e                	ld	s10,208(sp)
ffffffffc0200a94:	6dee                	ld	s11,216(sp)
ffffffffc0200a96:	7e0e                	ld	t3,224(sp)
ffffffffc0200a98:	7eae                	ld	t4,232(sp)
ffffffffc0200a9a:	7f4e                	ld	t5,240(sp)
ffffffffc0200a9c:	7fee                	ld	t6,248(sp)
ffffffffc0200a9e:	6142                	ld	sp,16(sp)
    // go back from supervisor call
    sret
ffffffffc0200aa0:	10200073          	sret
	...

ffffffffc0200ab0 <check_vma_overlap.isra.0.part.1>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0200ab0:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0200ab2:	00004697          	auipc	a3,0x4
ffffffffc0200ab6:	fa668693          	addi	a3,a3,-90 # ffffffffc0204a58 <commands+0x838>
ffffffffc0200aba:	00004617          	auipc	a2,0x4
ffffffffc0200abe:	fbe60613          	addi	a2,a2,-66 # ffffffffc0204a78 <commands+0x858>
ffffffffc0200ac2:	07d00593          	li	a1,125
ffffffffc0200ac6:	00004517          	auipc	a0,0x4
ffffffffc0200aca:	fca50513          	addi	a0,a0,-54 # ffffffffc0204a90 <commands+0x870>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0200ace:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0200ad0:	e36ff0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0200ad4 <mm_create>:
mm_create(void) {
ffffffffc0200ad4:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200ad6:	03000513          	li	a0,48
mm_create(void) {
ffffffffc0200ada:	e022                	sd	s0,0(sp)
ffffffffc0200adc:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200ade:	61d020ef          	jal	ra,ffffffffc02038fa <kmalloc>
ffffffffc0200ae2:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0200ae4:	c115                	beqz	a0,ffffffffc0200b08 <mm_create+0x34>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200ae6:	00010797          	auipc	a5,0x10
ffffffffc0200aea:	97a78793          	addi	a5,a5,-1670 # ffffffffc0210460 <swap_init_ok>
ffffffffc0200aee:	439c                	lw	a5,0(a5)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200af0:	e408                	sd	a0,8(s0)
ffffffffc0200af2:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0200af4:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0200af8:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0200afc:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200b00:	2781                	sext.w	a5,a5
ffffffffc0200b02:	eb81                	bnez	a5,ffffffffc0200b12 <mm_create+0x3e>
        else mm->sm_priv = NULL;
ffffffffc0200b04:	02053423          	sd	zero,40(a0)
}
ffffffffc0200b08:	8522                	mv	a0,s0
ffffffffc0200b0a:	60a2                	ld	ra,8(sp)
ffffffffc0200b0c:	6402                	ld	s0,0(sp)
ffffffffc0200b0e:	0141                	addi	sp,sp,16
ffffffffc0200b10:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200b12:	60d000ef          	jal	ra,ffffffffc020191e <swap_init_mm>
}
ffffffffc0200b16:	8522                	mv	a0,s0
ffffffffc0200b18:	60a2                	ld	ra,8(sp)
ffffffffc0200b1a:	6402                	ld	s0,0(sp)
ffffffffc0200b1c:	0141                	addi	sp,sp,16
ffffffffc0200b1e:	8082                	ret

ffffffffc0200b20 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0200b20:	1101                	addi	sp,sp,-32
ffffffffc0200b22:	e04a                	sd	s2,0(sp)
ffffffffc0200b24:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200b26:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0200b2a:	e822                	sd	s0,16(sp)
ffffffffc0200b2c:	e426                	sd	s1,8(sp)
ffffffffc0200b2e:	ec06                	sd	ra,24(sp)
ffffffffc0200b30:	84ae                	mv	s1,a1
ffffffffc0200b32:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200b34:	5c7020ef          	jal	ra,ffffffffc02038fa <kmalloc>
    if (vma != NULL) {
ffffffffc0200b38:	c509                	beqz	a0,ffffffffc0200b42 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0200b3a:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0200b3e:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0200b40:	ed00                	sd	s0,24(a0)
}
ffffffffc0200b42:	60e2                	ld	ra,24(sp)
ffffffffc0200b44:	6442                	ld	s0,16(sp)
ffffffffc0200b46:	64a2                	ld	s1,8(sp)
ffffffffc0200b48:	6902                	ld	s2,0(sp)
ffffffffc0200b4a:	6105                	addi	sp,sp,32
ffffffffc0200b4c:	8082                	ret

ffffffffc0200b4e <find_vma>:
    if (mm != NULL) {
ffffffffc0200b4e:	c51d                	beqz	a0,ffffffffc0200b7c <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc0200b50:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0200b52:	c781                	beqz	a5,ffffffffc0200b5a <find_vma+0xc>
ffffffffc0200b54:	6798                	ld	a4,8(a5)
ffffffffc0200b56:	02e5f663          	bleu	a4,a1,ffffffffc0200b82 <find_vma+0x34>
                list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc0200b5a:	87aa                	mv	a5,a0
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200b5c:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0200b5e:	00f50f63          	beq	a0,a5,ffffffffc0200b7c <find_vma+0x2e>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0200b62:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200b66:	fee5ebe3          	bltu	a1,a4,ffffffffc0200b5c <find_vma+0xe>
ffffffffc0200b6a:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200b6e:	fee5f7e3          	bleu	a4,a1,ffffffffc0200b5c <find_vma+0xe>
                    vma = le2vma(le, list_link);
ffffffffc0200b72:	1781                	addi	a5,a5,-32
        if (vma != NULL) {
ffffffffc0200b74:	c781                	beqz	a5,ffffffffc0200b7c <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc0200b76:	e91c                	sd	a5,16(a0)
}
ffffffffc0200b78:	853e                	mv	a0,a5
ffffffffc0200b7a:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc0200b7c:	4781                	li	a5,0
}
ffffffffc0200b7e:	853e                	mv	a0,a5
ffffffffc0200b80:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0200b82:	6b98                	ld	a4,16(a5)
ffffffffc0200b84:	fce5fbe3          	bleu	a4,a1,ffffffffc0200b5a <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0200b88:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc0200b8a:	b7fd                	j	ffffffffc0200b78 <find_vma+0x2a>

ffffffffc0200b8c <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200b8c:	6590                	ld	a2,8(a1)
ffffffffc0200b8e:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0200b92:	1141                	addi	sp,sp,-16
ffffffffc0200b94:	e406                	sd	ra,8(sp)
ffffffffc0200b96:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200b98:	01066863          	bltu	a2,a6,ffffffffc0200ba8 <insert_vma_struct+0x1c>
ffffffffc0200b9c:	a8b9                	j	ffffffffc0200bfa <insert_vma_struct+0x6e>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0200b9e:	fe87b683          	ld	a3,-24(a5)
ffffffffc0200ba2:	04d66763          	bltu	a2,a3,ffffffffc0200bf0 <insert_vma_struct+0x64>
ffffffffc0200ba6:	873e                	mv	a4,a5
ffffffffc0200ba8:	671c                	ld	a5,8(a4)
        while ((le = list_next(le)) != list) {
ffffffffc0200baa:	fef51ae3          	bne	a0,a5,ffffffffc0200b9e <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0200bae:	02a70463          	beq	a4,a0,ffffffffc0200bd6 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0200bb2:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0200bb6:	fe873883          	ld	a7,-24(a4)
ffffffffc0200bba:	08d8f063          	bleu	a3,a7,ffffffffc0200c3a <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0200bbe:	04d66e63          	bltu	a2,a3,ffffffffc0200c1a <insert_vma_struct+0x8e>
    }
    if (le_next != list) {
ffffffffc0200bc2:	00f50a63          	beq	a0,a5,ffffffffc0200bd6 <insert_vma_struct+0x4a>
ffffffffc0200bc6:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0200bca:	0506e863          	bltu	a3,a6,ffffffffc0200c1a <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0200bce:	ff07b603          	ld	a2,-16(a5)
ffffffffc0200bd2:	02c6f263          	bleu	a2,a3,ffffffffc0200bf6 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc0200bd6:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc0200bd8:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0200bda:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0200bde:	e390                	sd	a2,0(a5)
ffffffffc0200be0:	e710                	sd	a2,8(a4)
}
ffffffffc0200be2:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0200be4:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0200be6:	f198                	sd	a4,32(a1)
    mm->map_count ++;
ffffffffc0200be8:	2685                	addiw	a3,a3,1
ffffffffc0200bea:	d114                	sw	a3,32(a0)
}
ffffffffc0200bec:	0141                	addi	sp,sp,16
ffffffffc0200bee:	8082                	ret
    if (le_prev != list) {
ffffffffc0200bf0:	fca711e3          	bne	a4,a0,ffffffffc0200bb2 <insert_vma_struct+0x26>
ffffffffc0200bf4:	bfd9                	j	ffffffffc0200bca <insert_vma_struct+0x3e>
ffffffffc0200bf6:	ebbff0ef          	jal	ra,ffffffffc0200ab0 <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200bfa:	00004697          	auipc	a3,0x4
ffffffffc0200bfe:	f2668693          	addi	a3,a3,-218 # ffffffffc0204b20 <commands+0x900>
ffffffffc0200c02:	00004617          	auipc	a2,0x4
ffffffffc0200c06:	e7660613          	addi	a2,a2,-394 # ffffffffc0204a78 <commands+0x858>
ffffffffc0200c0a:	08400593          	li	a1,132
ffffffffc0200c0e:	00004517          	auipc	a0,0x4
ffffffffc0200c12:	e8250513          	addi	a0,a0,-382 # ffffffffc0204a90 <commands+0x870>
ffffffffc0200c16:	cf0ff0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0200c1a:	00004697          	auipc	a3,0x4
ffffffffc0200c1e:	f4668693          	addi	a3,a3,-186 # ffffffffc0204b60 <commands+0x940>
ffffffffc0200c22:	00004617          	auipc	a2,0x4
ffffffffc0200c26:	e5660613          	addi	a2,a2,-426 # ffffffffc0204a78 <commands+0x858>
ffffffffc0200c2a:	07c00593          	li	a1,124
ffffffffc0200c2e:	00004517          	auipc	a0,0x4
ffffffffc0200c32:	e6250513          	addi	a0,a0,-414 # ffffffffc0204a90 <commands+0x870>
ffffffffc0200c36:	cd0ff0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0200c3a:	00004697          	auipc	a3,0x4
ffffffffc0200c3e:	f0668693          	addi	a3,a3,-250 # ffffffffc0204b40 <commands+0x920>
ffffffffc0200c42:	00004617          	auipc	a2,0x4
ffffffffc0200c46:	e3660613          	addi	a2,a2,-458 # ffffffffc0204a78 <commands+0x858>
ffffffffc0200c4a:	07b00593          	li	a1,123
ffffffffc0200c4e:	00004517          	auipc	a0,0x4
ffffffffc0200c52:	e4250513          	addi	a0,a0,-446 # ffffffffc0204a90 <commands+0x870>
ffffffffc0200c56:	cb0ff0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0200c5a <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
ffffffffc0200c5a:	1141                	addi	sp,sp,-16
ffffffffc0200c5c:	e022                	sd	s0,0(sp)
ffffffffc0200c5e:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0200c60:	6508                	ld	a0,8(a0)
ffffffffc0200c62:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc0200c64:	00a40e63          	beq	s0,a0,ffffffffc0200c80 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200c68:	6118                	ld	a4,0(a0)
ffffffffc0200c6a:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc0200c6c:	03000593          	li	a1,48
ffffffffc0200c70:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200c72:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200c74:	e398                	sd	a4,0(a5)
ffffffffc0200c76:	547020ef          	jal	ra,ffffffffc02039bc <kfree>
    return listelm->next;
ffffffffc0200c7a:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0200c7c:	fea416e3          	bne	s0,a0,ffffffffc0200c68 <mm_destroy+0xe>
    }
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0200c80:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0200c82:	6402                	ld	s0,0(sp)
ffffffffc0200c84:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0200c86:	03000593          	li	a1,48
}
ffffffffc0200c8a:	0141                	addi	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0200c8c:	5310206f          	j	ffffffffc02039bc <kfree>

ffffffffc0200c90 <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0200c90:	715d                	addi	sp,sp,-80
ffffffffc0200c92:	e486                	sd	ra,72(sp)
ffffffffc0200c94:	e0a2                	sd	s0,64(sp)
ffffffffc0200c96:	fc26                	sd	s1,56(sp)
ffffffffc0200c98:	f84a                	sd	s2,48(sp)
ffffffffc0200c9a:	f052                	sd	s4,32(sp)
ffffffffc0200c9c:	f44e                	sd	s3,40(sp)
ffffffffc0200c9e:	ec56                	sd	s5,24(sp)
ffffffffc0200ca0:	e85a                	sd	s6,16(sp)
ffffffffc0200ca2:	e45e                	sd	s7,8(sp)
}

// check_vmm - check correctness of vmm
static void
check_vmm(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0200ca4:	4f9010ef          	jal	ra,ffffffffc020299c <nr_free_pages>
ffffffffc0200ca8:	892a                	mv	s2,a0
    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0200caa:	4f3010ef          	jal	ra,ffffffffc020299c <nr_free_pages>
ffffffffc0200cae:	8a2a                	mv	s4,a0

    struct mm_struct *mm = mm_create();
ffffffffc0200cb0:	e25ff0ef          	jal	ra,ffffffffc0200ad4 <mm_create>
    assert(mm != NULL);
ffffffffc0200cb4:	842a                	mv	s0,a0
ffffffffc0200cb6:	03200493          	li	s1,50
ffffffffc0200cba:	e919                	bnez	a0,ffffffffc0200cd0 <vmm_init+0x40>
ffffffffc0200cbc:	aeed                	j	ffffffffc02010b6 <vmm_init+0x426>
        vma->vm_start = vm_start;
ffffffffc0200cbe:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0200cc0:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0200cc2:	00053c23          	sd	zero,24(a0)

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0200cc6:	14ed                	addi	s1,s1,-5
ffffffffc0200cc8:	8522                	mv	a0,s0
ffffffffc0200cca:	ec3ff0ef          	jal	ra,ffffffffc0200b8c <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0200cce:	c88d                	beqz	s1,ffffffffc0200d00 <vmm_init+0x70>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200cd0:	03000513          	li	a0,48
ffffffffc0200cd4:	427020ef          	jal	ra,ffffffffc02038fa <kmalloc>
ffffffffc0200cd8:	85aa                	mv	a1,a0
ffffffffc0200cda:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0200cde:	f165                	bnez	a0,ffffffffc0200cbe <vmm_init+0x2e>
        assert(vma != NULL);
ffffffffc0200ce0:	00004697          	auipc	a3,0x4
ffffffffc0200ce4:	0f868693          	addi	a3,a3,248 # ffffffffc0204dd8 <commands+0xbb8>
ffffffffc0200ce8:	00004617          	auipc	a2,0x4
ffffffffc0200cec:	d9060613          	addi	a2,a2,-624 # ffffffffc0204a78 <commands+0x858>
ffffffffc0200cf0:	0ce00593          	li	a1,206
ffffffffc0200cf4:	00004517          	auipc	a0,0x4
ffffffffc0200cf8:	d9c50513          	addi	a0,a0,-612 # ffffffffc0204a90 <commands+0x870>
ffffffffc0200cfc:	c0aff0ef          	jal	ra,ffffffffc0200106 <__panic>
    for (i = step1; i >= 1; i --) {
ffffffffc0200d00:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0200d04:	1f900993          	li	s3,505
ffffffffc0200d08:	a819                	j	ffffffffc0200d1e <vmm_init+0x8e>
        vma->vm_start = vm_start;
ffffffffc0200d0a:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0200d0c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0200d0e:	00053c23          	sd	zero,24(a0)
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0200d12:	0495                	addi	s1,s1,5
ffffffffc0200d14:	8522                	mv	a0,s0
ffffffffc0200d16:	e77ff0ef          	jal	ra,ffffffffc0200b8c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0200d1a:	03348a63          	beq	s1,s3,ffffffffc0200d4e <vmm_init+0xbe>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200d1e:	03000513          	li	a0,48
ffffffffc0200d22:	3d9020ef          	jal	ra,ffffffffc02038fa <kmalloc>
ffffffffc0200d26:	85aa                	mv	a1,a0
ffffffffc0200d28:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0200d2c:	fd79                	bnez	a0,ffffffffc0200d0a <vmm_init+0x7a>
        assert(vma != NULL);
ffffffffc0200d2e:	00004697          	auipc	a3,0x4
ffffffffc0200d32:	0aa68693          	addi	a3,a3,170 # ffffffffc0204dd8 <commands+0xbb8>
ffffffffc0200d36:	00004617          	auipc	a2,0x4
ffffffffc0200d3a:	d4260613          	addi	a2,a2,-702 # ffffffffc0204a78 <commands+0x858>
ffffffffc0200d3e:	0d400593          	li	a1,212
ffffffffc0200d42:	00004517          	auipc	a0,0x4
ffffffffc0200d46:	d4e50513          	addi	a0,a0,-690 # ffffffffc0204a90 <commands+0x870>
ffffffffc0200d4a:	bbcff0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc0200d4e:	6418                	ld	a4,8(s0)
ffffffffc0200d50:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc0200d52:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0200d56:	2ae40063          	beq	s0,a4,ffffffffc0200ff6 <vmm_init+0x366>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0200d5a:	fe873603          	ld	a2,-24(a4)
ffffffffc0200d5e:	ffe78693          	addi	a3,a5,-2
ffffffffc0200d62:	20d61a63          	bne	a2,a3,ffffffffc0200f76 <vmm_init+0x2e6>
ffffffffc0200d66:	ff073683          	ld	a3,-16(a4)
ffffffffc0200d6a:	20d79663          	bne	a5,a3,ffffffffc0200f76 <vmm_init+0x2e6>
ffffffffc0200d6e:	0795                	addi	a5,a5,5
ffffffffc0200d70:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i ++) {
ffffffffc0200d72:	feb792e3          	bne	a5,a1,ffffffffc0200d56 <vmm_init+0xc6>
ffffffffc0200d76:	499d                	li	s3,7
ffffffffc0200d78:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0200d7a:	1f900b93          	li	s7,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0200d7e:	85a6                	mv	a1,s1
ffffffffc0200d80:	8522                	mv	a0,s0
ffffffffc0200d82:	dcdff0ef          	jal	ra,ffffffffc0200b4e <find_vma>
ffffffffc0200d86:	8b2a                	mv	s6,a0
        assert(vma1 != NULL);
ffffffffc0200d88:	2e050763          	beqz	a0,ffffffffc0201076 <vmm_init+0x3e6>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0200d8c:	00148593          	addi	a1,s1,1
ffffffffc0200d90:	8522                	mv	a0,s0
ffffffffc0200d92:	dbdff0ef          	jal	ra,ffffffffc0200b4e <find_vma>
ffffffffc0200d96:	8aaa                	mv	s5,a0
        assert(vma2 != NULL);
ffffffffc0200d98:	2a050f63          	beqz	a0,ffffffffc0201056 <vmm_init+0x3c6>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0200d9c:	85ce                	mv	a1,s3
ffffffffc0200d9e:	8522                	mv	a0,s0
ffffffffc0200da0:	dafff0ef          	jal	ra,ffffffffc0200b4e <find_vma>
        assert(vma3 == NULL);
ffffffffc0200da4:	28051963          	bnez	a0,ffffffffc0201036 <vmm_init+0x3a6>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0200da8:	00348593          	addi	a1,s1,3
ffffffffc0200dac:	8522                	mv	a0,s0
ffffffffc0200dae:	da1ff0ef          	jal	ra,ffffffffc0200b4e <find_vma>
        assert(vma4 == NULL);
ffffffffc0200db2:	26051263          	bnez	a0,ffffffffc0201016 <vmm_init+0x386>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0200db6:	00448593          	addi	a1,s1,4
ffffffffc0200dba:	8522                	mv	a0,s0
ffffffffc0200dbc:	d93ff0ef          	jal	ra,ffffffffc0200b4e <find_vma>
        assert(vma5 == NULL);
ffffffffc0200dc0:	2c051b63          	bnez	a0,ffffffffc0201096 <vmm_init+0x406>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0200dc4:	008b3783          	ld	a5,8(s6)
ffffffffc0200dc8:	1c979763          	bne	a5,s1,ffffffffc0200f96 <vmm_init+0x306>
ffffffffc0200dcc:	010b3783          	ld	a5,16(s6)
ffffffffc0200dd0:	1d379363          	bne	a5,s3,ffffffffc0200f96 <vmm_init+0x306>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0200dd4:	008ab783          	ld	a5,8(s5)
ffffffffc0200dd8:	1c979f63          	bne	a5,s1,ffffffffc0200fb6 <vmm_init+0x326>
ffffffffc0200ddc:	010ab783          	ld	a5,16(s5)
ffffffffc0200de0:	1d379b63          	bne	a5,s3,ffffffffc0200fb6 <vmm_init+0x326>
ffffffffc0200de4:	0495                	addi	s1,s1,5
ffffffffc0200de6:	0995                	addi	s3,s3,5
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0200de8:	f9749be3          	bne	s1,s7,ffffffffc0200d7e <vmm_init+0xee>
ffffffffc0200dec:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0200dee:	59fd                	li	s3,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0200df0:	85a6                	mv	a1,s1
ffffffffc0200df2:	8522                	mv	a0,s0
ffffffffc0200df4:	d5bff0ef          	jal	ra,ffffffffc0200b4e <find_vma>
ffffffffc0200df8:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL ) {
ffffffffc0200dfc:	c90d                	beqz	a0,ffffffffc0200e2e <vmm_init+0x19e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0200dfe:	6914                	ld	a3,16(a0)
ffffffffc0200e00:	6510                	ld	a2,8(a0)
ffffffffc0200e02:	00004517          	auipc	a0,0x4
ffffffffc0200e06:	e8e50513          	addi	a0,a0,-370 # ffffffffc0204c90 <commands+0xa70>
ffffffffc0200e0a:	ab4ff0ef          	jal	ra,ffffffffc02000be <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0200e0e:	00004697          	auipc	a3,0x4
ffffffffc0200e12:	eaa68693          	addi	a3,a3,-342 # ffffffffc0204cb8 <commands+0xa98>
ffffffffc0200e16:	00004617          	auipc	a2,0x4
ffffffffc0200e1a:	c6260613          	addi	a2,a2,-926 # ffffffffc0204a78 <commands+0x858>
ffffffffc0200e1e:	0f600593          	li	a1,246
ffffffffc0200e22:	00004517          	auipc	a0,0x4
ffffffffc0200e26:	c6e50513          	addi	a0,a0,-914 # ffffffffc0204a90 <commands+0x870>
ffffffffc0200e2a:	adcff0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc0200e2e:	14fd                	addi	s1,s1,-1
    for (i =4; i>=0; i--) {
ffffffffc0200e30:	fd3490e3          	bne	s1,s3,ffffffffc0200df0 <vmm_init+0x160>
    }

    mm_destroy(mm);
ffffffffc0200e34:	8522                	mv	a0,s0
ffffffffc0200e36:	e25ff0ef          	jal	ra,ffffffffc0200c5a <mm_destroy>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0200e3a:	363010ef          	jal	ra,ffffffffc020299c <nr_free_pages>
ffffffffc0200e3e:	28aa1c63          	bne	s4,a0,ffffffffc02010d6 <vmm_init+0x446>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0200e42:	00004517          	auipc	a0,0x4
ffffffffc0200e46:	eb650513          	addi	a0,a0,-330 # ffffffffc0204cf8 <commands+0xad8>
ffffffffc0200e4a:	a74ff0ef          	jal	ra,ffffffffc02000be <cprintf>

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
	// char *name = "check_pgfault";
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0200e4e:	34f010ef          	jal	ra,ffffffffc020299c <nr_free_pages>
ffffffffc0200e52:	89aa                	mv	s3,a0

    check_mm_struct = mm_create();
ffffffffc0200e54:	c81ff0ef          	jal	ra,ffffffffc0200ad4 <mm_create>
ffffffffc0200e58:	0000f797          	auipc	a5,0xf
ffffffffc0200e5c:	62a7b423          	sd	a0,1576(a5) # ffffffffc0210480 <check_mm_struct>
ffffffffc0200e60:	842a                	mv	s0,a0

    assert(check_mm_struct != NULL);
ffffffffc0200e62:	2a050a63          	beqz	a0,ffffffffc0201116 <vmm_init+0x486>
    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0200e66:	0000f797          	auipc	a5,0xf
ffffffffc0200e6a:	60278793          	addi	a5,a5,1538 # ffffffffc0210468 <boot_pgdir>
ffffffffc0200e6e:	6384                	ld	s1,0(a5)
    assert(pgdir[0] == 0);
ffffffffc0200e70:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0200e72:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0200e74:	32079d63          	bnez	a5,ffffffffc02011ae <vmm_init+0x51e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200e78:	03000513          	li	a0,48
ffffffffc0200e7c:	27f020ef          	jal	ra,ffffffffc02038fa <kmalloc>
ffffffffc0200e80:	8a2a                	mv	s4,a0
    if (vma != NULL) {
ffffffffc0200e82:	14050a63          	beqz	a0,ffffffffc0200fd6 <vmm_init+0x346>
        vma->vm_end = vm_end;
ffffffffc0200e86:	002007b7          	lui	a5,0x200
ffffffffc0200e8a:	00fa3823          	sd	a5,16(s4)
        vma->vm_flags = vm_flags;
ffffffffc0200e8e:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);

    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0200e90:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0200e92:	00fa3c23          	sd	a5,24(s4)
    insert_vma_struct(mm, vma);
ffffffffc0200e96:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc0200e98:	000a3423          	sd	zero,8(s4)
    insert_vma_struct(mm, vma);
ffffffffc0200e9c:	cf1ff0ef          	jal	ra,ffffffffc0200b8c <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0200ea0:	10000593          	li	a1,256
ffffffffc0200ea4:	8522                	mv	a0,s0
ffffffffc0200ea6:	ca9ff0ef          	jal	ra,ffffffffc0200b4e <find_vma>
ffffffffc0200eaa:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc0200eae:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0200eb2:	2aaa1263          	bne	s4,a0,ffffffffc0201156 <vmm_init+0x4c6>
        *(char *)(addr + i) = i;
ffffffffc0200eb6:	00f78023          	sb	a5,0(a5) # 200000 <BASE_ADDRESS-0xffffffffc0000000>
        sum += i;
ffffffffc0200eba:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i ++) {
ffffffffc0200ebc:	fee79de3          	bne	a5,a4,ffffffffc0200eb6 <vmm_init+0x226>
        sum += i;
ffffffffc0200ec0:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i ++) {
ffffffffc0200ec2:	10000793          	li	a5,256
        sum += i;
ffffffffc0200ec6:	35670713          	addi	a4,a4,854 # 1356 <BASE_ADDRESS-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0200eca:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0200ece:	0007c683          	lbu	a3,0(a5)
ffffffffc0200ed2:	0785                	addi	a5,a5,1
ffffffffc0200ed4:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0200ed6:	fec79ce3          	bne	a5,a2,ffffffffc0200ece <vmm_init+0x23e>
    }
    assert(sum == 0);
ffffffffc0200eda:	2a071a63          	bnez	a4,ffffffffc020118e <vmm_init+0x4fe>

    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0200ede:	4581                	li	a1,0
ffffffffc0200ee0:	8526                	mv	a0,s1
ffffffffc0200ee2:	561010ef          	jal	ra,ffffffffc0202c42 <page_remove>
    }
    return pa2page(PTE_ADDR(pte));
}

static inline struct Page *pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
ffffffffc0200ee6:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc0200ee8:	0000f717          	auipc	a4,0xf
ffffffffc0200eec:	58870713          	addi	a4,a4,1416 # ffffffffc0210470 <npage>
ffffffffc0200ef0:	6318                	ld	a4,0(a4)
    return pa2page(PDE_ADDR(pde));
ffffffffc0200ef2:	078a                	slli	a5,a5,0x2
ffffffffc0200ef4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200ef6:	28e7f063          	bleu	a4,a5,ffffffffc0201176 <vmm_init+0x4e6>
    return &pages[PPN(pa) - nbase];
ffffffffc0200efa:	00005717          	auipc	a4,0x5
ffffffffc0200efe:	f6e70713          	addi	a4,a4,-146 # ffffffffc0205e68 <nbase>
ffffffffc0200f02:	6318                	ld	a4,0(a4)
ffffffffc0200f04:	0000f697          	auipc	a3,0xf
ffffffffc0200f08:	68468693          	addi	a3,a3,1668 # ffffffffc0210588 <pages>
ffffffffc0200f0c:	6288                	ld	a0,0(a3)
ffffffffc0200f0e:	8f99                	sub	a5,a5,a4
ffffffffc0200f10:	00379713          	slli	a4,a5,0x3
ffffffffc0200f14:	97ba                	add	a5,a5,a4
ffffffffc0200f16:	078e                	slli	a5,a5,0x3

    free_page(pde2page(pgdir[0]));
ffffffffc0200f18:	953e                	add	a0,a0,a5
ffffffffc0200f1a:	4585                	li	a1,1
ffffffffc0200f1c:	23b010ef          	jal	ra,ffffffffc0202956 <free_pages>

    pgdir[0] = 0;
ffffffffc0200f20:	0004b023          	sd	zero,0(s1)

    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc0200f24:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc0200f26:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc0200f2a:	d31ff0ef          	jal	ra,ffffffffc0200c5a <mm_destroy>

    check_mm_struct = NULL;
    nr_free_pages_store--;	// szx : Sv39第二级页表多占了一个内存页，所以执行此操作
ffffffffc0200f2e:	19fd                	addi	s3,s3,-1
    check_mm_struct = NULL;
ffffffffc0200f30:	0000f797          	auipc	a5,0xf
ffffffffc0200f34:	5407b823          	sd	zero,1360(a5) # ffffffffc0210480 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0200f38:	265010ef          	jal	ra,ffffffffc020299c <nr_free_pages>
ffffffffc0200f3c:	1aa99d63          	bne	s3,a0,ffffffffc02010f6 <vmm_init+0x466>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0200f40:	00004517          	auipc	a0,0x4
ffffffffc0200f44:	e6050513          	addi	a0,a0,-416 # ffffffffc0204da0 <commands+0xb80>
ffffffffc0200f48:	976ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0200f4c:	251010ef          	jal	ra,ffffffffc020299c <nr_free_pages>
    nr_free_pages_store--;	// szx : Sv39三级页表多占一个内存页，所以执行此操作
ffffffffc0200f50:	197d                	addi	s2,s2,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0200f52:	1ea91263          	bne	s2,a0,ffffffffc0201136 <vmm_init+0x4a6>
}
ffffffffc0200f56:	6406                	ld	s0,64(sp)
ffffffffc0200f58:	60a6                	ld	ra,72(sp)
ffffffffc0200f5a:	74e2                	ld	s1,56(sp)
ffffffffc0200f5c:	7942                	ld	s2,48(sp)
ffffffffc0200f5e:	79a2                	ld	s3,40(sp)
ffffffffc0200f60:	7a02                	ld	s4,32(sp)
ffffffffc0200f62:	6ae2                	ld	s5,24(sp)
ffffffffc0200f64:	6b42                	ld	s6,16(sp)
ffffffffc0200f66:	6ba2                	ld	s7,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0200f68:	00004517          	auipc	a0,0x4
ffffffffc0200f6c:	e5850513          	addi	a0,a0,-424 # ffffffffc0204dc0 <commands+0xba0>
}
ffffffffc0200f70:	6161                	addi	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc0200f72:	94cff06f          	j	ffffffffc02000be <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0200f76:	00004697          	auipc	a3,0x4
ffffffffc0200f7a:	c3268693          	addi	a3,a3,-974 # ffffffffc0204ba8 <commands+0x988>
ffffffffc0200f7e:	00004617          	auipc	a2,0x4
ffffffffc0200f82:	afa60613          	addi	a2,a2,-1286 # ffffffffc0204a78 <commands+0x858>
ffffffffc0200f86:	0dd00593          	li	a1,221
ffffffffc0200f8a:	00004517          	auipc	a0,0x4
ffffffffc0200f8e:	b0650513          	addi	a0,a0,-1274 # ffffffffc0204a90 <commands+0x870>
ffffffffc0200f92:	974ff0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0200f96:	00004697          	auipc	a3,0x4
ffffffffc0200f9a:	c9a68693          	addi	a3,a3,-870 # ffffffffc0204c30 <commands+0xa10>
ffffffffc0200f9e:	00004617          	auipc	a2,0x4
ffffffffc0200fa2:	ada60613          	addi	a2,a2,-1318 # ffffffffc0204a78 <commands+0x858>
ffffffffc0200fa6:	0ed00593          	li	a1,237
ffffffffc0200faa:	00004517          	auipc	a0,0x4
ffffffffc0200fae:	ae650513          	addi	a0,a0,-1306 # ffffffffc0204a90 <commands+0x870>
ffffffffc0200fb2:	954ff0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0200fb6:	00004697          	auipc	a3,0x4
ffffffffc0200fba:	caa68693          	addi	a3,a3,-854 # ffffffffc0204c60 <commands+0xa40>
ffffffffc0200fbe:	00004617          	auipc	a2,0x4
ffffffffc0200fc2:	aba60613          	addi	a2,a2,-1350 # ffffffffc0204a78 <commands+0x858>
ffffffffc0200fc6:	0ee00593          	li	a1,238
ffffffffc0200fca:	00004517          	auipc	a0,0x4
ffffffffc0200fce:	ac650513          	addi	a0,a0,-1338 # ffffffffc0204a90 <commands+0x870>
ffffffffc0200fd2:	934ff0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(vma != NULL);
ffffffffc0200fd6:	00004697          	auipc	a3,0x4
ffffffffc0200fda:	e0268693          	addi	a3,a3,-510 # ffffffffc0204dd8 <commands+0xbb8>
ffffffffc0200fde:	00004617          	auipc	a2,0x4
ffffffffc0200fe2:	a9a60613          	addi	a2,a2,-1382 # ffffffffc0204a78 <commands+0x858>
ffffffffc0200fe6:	11100593          	li	a1,273
ffffffffc0200fea:	00004517          	auipc	a0,0x4
ffffffffc0200fee:	aa650513          	addi	a0,a0,-1370 # ffffffffc0204a90 <commands+0x870>
ffffffffc0200ff2:	914ff0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0200ff6:	00004697          	auipc	a3,0x4
ffffffffc0200ffa:	b9a68693          	addi	a3,a3,-1126 # ffffffffc0204b90 <commands+0x970>
ffffffffc0200ffe:	00004617          	auipc	a2,0x4
ffffffffc0201002:	a7a60613          	addi	a2,a2,-1414 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201006:	0db00593          	li	a1,219
ffffffffc020100a:	00004517          	auipc	a0,0x4
ffffffffc020100e:	a8650513          	addi	a0,a0,-1402 # ffffffffc0204a90 <commands+0x870>
ffffffffc0201012:	8f4ff0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma4 == NULL);
ffffffffc0201016:	00004697          	auipc	a3,0x4
ffffffffc020101a:	bfa68693          	addi	a3,a3,-1030 # ffffffffc0204c10 <commands+0x9f0>
ffffffffc020101e:	00004617          	auipc	a2,0x4
ffffffffc0201022:	a5a60613          	addi	a2,a2,-1446 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201026:	0e900593          	li	a1,233
ffffffffc020102a:	00004517          	auipc	a0,0x4
ffffffffc020102e:	a6650513          	addi	a0,a0,-1434 # ffffffffc0204a90 <commands+0x870>
ffffffffc0201032:	8d4ff0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma3 == NULL);
ffffffffc0201036:	00004697          	auipc	a3,0x4
ffffffffc020103a:	bca68693          	addi	a3,a3,-1078 # ffffffffc0204c00 <commands+0x9e0>
ffffffffc020103e:	00004617          	auipc	a2,0x4
ffffffffc0201042:	a3a60613          	addi	a2,a2,-1478 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201046:	0e700593          	li	a1,231
ffffffffc020104a:	00004517          	auipc	a0,0x4
ffffffffc020104e:	a4650513          	addi	a0,a0,-1466 # ffffffffc0204a90 <commands+0x870>
ffffffffc0201052:	8b4ff0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma2 != NULL);
ffffffffc0201056:	00004697          	auipc	a3,0x4
ffffffffc020105a:	b9a68693          	addi	a3,a3,-1126 # ffffffffc0204bf0 <commands+0x9d0>
ffffffffc020105e:	00004617          	auipc	a2,0x4
ffffffffc0201062:	a1a60613          	addi	a2,a2,-1510 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201066:	0e500593          	li	a1,229
ffffffffc020106a:	00004517          	auipc	a0,0x4
ffffffffc020106e:	a2650513          	addi	a0,a0,-1498 # ffffffffc0204a90 <commands+0x870>
ffffffffc0201072:	894ff0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma1 != NULL);
ffffffffc0201076:	00004697          	auipc	a3,0x4
ffffffffc020107a:	b6a68693          	addi	a3,a3,-1174 # ffffffffc0204be0 <commands+0x9c0>
ffffffffc020107e:	00004617          	auipc	a2,0x4
ffffffffc0201082:	9fa60613          	addi	a2,a2,-1542 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201086:	0e300593          	li	a1,227
ffffffffc020108a:	00004517          	auipc	a0,0x4
ffffffffc020108e:	a0650513          	addi	a0,a0,-1530 # ffffffffc0204a90 <commands+0x870>
ffffffffc0201092:	874ff0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(vma5 == NULL);
ffffffffc0201096:	00004697          	auipc	a3,0x4
ffffffffc020109a:	b8a68693          	addi	a3,a3,-1142 # ffffffffc0204c20 <commands+0xa00>
ffffffffc020109e:	00004617          	auipc	a2,0x4
ffffffffc02010a2:	9da60613          	addi	a2,a2,-1574 # ffffffffc0204a78 <commands+0x858>
ffffffffc02010a6:	0eb00593          	li	a1,235
ffffffffc02010aa:	00004517          	auipc	a0,0x4
ffffffffc02010ae:	9e650513          	addi	a0,a0,-1562 # ffffffffc0204a90 <commands+0x870>
ffffffffc02010b2:	854ff0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(mm != NULL);
ffffffffc02010b6:	00004697          	auipc	a3,0x4
ffffffffc02010ba:	aca68693          	addi	a3,a3,-1334 # ffffffffc0204b80 <commands+0x960>
ffffffffc02010be:	00004617          	auipc	a2,0x4
ffffffffc02010c2:	9ba60613          	addi	a2,a2,-1606 # ffffffffc0204a78 <commands+0x858>
ffffffffc02010c6:	0c700593          	li	a1,199
ffffffffc02010ca:	00004517          	auipc	a0,0x4
ffffffffc02010ce:	9c650513          	addi	a0,a0,-1594 # ffffffffc0204a90 <commands+0x870>
ffffffffc02010d2:	834ff0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02010d6:	00004697          	auipc	a3,0x4
ffffffffc02010da:	bfa68693          	addi	a3,a3,-1030 # ffffffffc0204cd0 <commands+0xab0>
ffffffffc02010de:	00004617          	auipc	a2,0x4
ffffffffc02010e2:	99a60613          	addi	a2,a2,-1638 # ffffffffc0204a78 <commands+0x858>
ffffffffc02010e6:	0fb00593          	li	a1,251
ffffffffc02010ea:	00004517          	auipc	a0,0x4
ffffffffc02010ee:	9a650513          	addi	a0,a0,-1626 # ffffffffc0204a90 <commands+0x870>
ffffffffc02010f2:	814ff0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02010f6:	00004697          	auipc	a3,0x4
ffffffffc02010fa:	bda68693          	addi	a3,a3,-1062 # ffffffffc0204cd0 <commands+0xab0>
ffffffffc02010fe:	00004617          	auipc	a2,0x4
ffffffffc0201102:	97a60613          	addi	a2,a2,-1670 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201106:	12e00593          	li	a1,302
ffffffffc020110a:	00004517          	auipc	a0,0x4
ffffffffc020110e:	98650513          	addi	a0,a0,-1658 # ffffffffc0204a90 <commands+0x870>
ffffffffc0201112:	ff5fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0201116:	00004697          	auipc	a3,0x4
ffffffffc020111a:	c0268693          	addi	a3,a3,-1022 # ffffffffc0204d18 <commands+0xaf8>
ffffffffc020111e:	00004617          	auipc	a2,0x4
ffffffffc0201122:	95a60613          	addi	a2,a2,-1702 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201126:	10a00593          	li	a1,266
ffffffffc020112a:	00004517          	auipc	a0,0x4
ffffffffc020112e:	96650513          	addi	a0,a0,-1690 # ffffffffc0204a90 <commands+0x870>
ffffffffc0201132:	fd5fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0201136:	00004697          	auipc	a3,0x4
ffffffffc020113a:	b9a68693          	addi	a3,a3,-1126 # ffffffffc0204cd0 <commands+0xab0>
ffffffffc020113e:	00004617          	auipc	a2,0x4
ffffffffc0201142:	93a60613          	addi	a2,a2,-1734 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201146:	0bd00593          	li	a1,189
ffffffffc020114a:	00004517          	auipc	a0,0x4
ffffffffc020114e:	94650513          	addi	a0,a0,-1722 # ffffffffc0204a90 <commands+0x870>
ffffffffc0201152:	fb5fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0201156:	00004697          	auipc	a3,0x4
ffffffffc020115a:	bea68693          	addi	a3,a3,-1046 # ffffffffc0204d40 <commands+0xb20>
ffffffffc020115e:	00004617          	auipc	a2,0x4
ffffffffc0201162:	91a60613          	addi	a2,a2,-1766 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201166:	11600593          	li	a1,278
ffffffffc020116a:	00004517          	auipc	a0,0x4
ffffffffc020116e:	92650513          	addi	a0,a0,-1754 # ffffffffc0204a90 <commands+0x870>
ffffffffc0201172:	f95fe0ef          	jal	ra,ffffffffc0200106 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201176:	00004617          	auipc	a2,0x4
ffffffffc020117a:	bfa60613          	addi	a2,a2,-1030 # ffffffffc0204d70 <commands+0xb50>
ffffffffc020117e:	06500593          	li	a1,101
ffffffffc0201182:	00004517          	auipc	a0,0x4
ffffffffc0201186:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0204d90 <commands+0xb70>
ffffffffc020118a:	f7dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(sum == 0);
ffffffffc020118e:	00004697          	auipc	a3,0x4
ffffffffc0201192:	bd268693          	addi	a3,a3,-1070 # ffffffffc0204d60 <commands+0xb40>
ffffffffc0201196:	00004617          	auipc	a2,0x4
ffffffffc020119a:	8e260613          	addi	a2,a2,-1822 # ffffffffc0204a78 <commands+0x858>
ffffffffc020119e:	12000593          	li	a1,288
ffffffffc02011a2:	00004517          	auipc	a0,0x4
ffffffffc02011a6:	8ee50513          	addi	a0,a0,-1810 # ffffffffc0204a90 <commands+0x870>
ffffffffc02011aa:	f5dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgdir[0] == 0);
ffffffffc02011ae:	00004697          	auipc	a3,0x4
ffffffffc02011b2:	b8268693          	addi	a3,a3,-1150 # ffffffffc0204d30 <commands+0xb10>
ffffffffc02011b6:	00004617          	auipc	a2,0x4
ffffffffc02011ba:	8c260613          	addi	a2,a2,-1854 # ffffffffc0204a78 <commands+0x858>
ffffffffc02011be:	10d00593          	li	a1,269
ffffffffc02011c2:	00004517          	auipc	a0,0x4
ffffffffc02011c6:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0204a90 <commands+0x870>
ffffffffc02011ca:	f3dfe0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc02011ce <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02011ce:	1101                	addi	sp,sp,-32
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02011d0:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02011d2:	e822                	sd	s0,16(sp)
ffffffffc02011d4:	e426                	sd	s1,8(sp)
ffffffffc02011d6:	ec06                	sd	ra,24(sp)
ffffffffc02011d8:	e04a                	sd	s2,0(sp)
ffffffffc02011da:	8432                	mv	s0,a2
ffffffffc02011dc:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02011de:	971ff0ef          	jal	ra,ffffffffc0200b4e <find_vma>

    pgfault_num++;
ffffffffc02011e2:	0000f797          	auipc	a5,0xf
ffffffffc02011e6:	26e78793          	addi	a5,a5,622 # ffffffffc0210450 <pgfault_num>
ffffffffc02011ea:	439c                	lw	a5,0(a5)
ffffffffc02011ec:	2785                	addiw	a5,a5,1
ffffffffc02011ee:	0000f717          	auipc	a4,0xf
ffffffffc02011f2:	26f72123          	sw	a5,610(a4) # ffffffffc0210450 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc02011f6:	c939                	beqz	a0,ffffffffc020124c <do_pgfault+0x7e>
ffffffffc02011f8:	651c                	ld	a5,8(a0)
ffffffffc02011fa:	04f46963          	bltu	s0,a5,ffffffffc020124c <do_pgfault+0x7e>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc02011fe:	6d1c                	ld	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0201200:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0201202:	8b89                	andi	a5,a5,2
ffffffffc0201204:	e785                	bnez	a5,ffffffffc020122c <do_pgfault+0x5e>
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0201206:	767d                	lui	a2,0xfffff
    *   mm->pgdir : the PDT of these vma
    *
    */


    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc0201208:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc020120a:	8c71                	and	s0,s0,a2
    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc020120c:	85a2                	mv	a1,s0
ffffffffc020120e:	4605                	li	a2,1
ffffffffc0201210:	7cc010ef          	jal	ra,ffffffffc02029dc <get_pte>
                                         //PT(Page Table) isn't existed, then
                                         //create a PT.
    if (*ptep == 0) {
ffffffffc0201214:	610c                	ld	a1,0(a0)
ffffffffc0201216:	cd89                	beqz	a1,ffffffffc0201230 <do_pgfault+0x62>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc0201218:	0000f797          	auipc	a5,0xf
ffffffffc020121c:	24878793          	addi	a5,a5,584 # ffffffffc0210460 <swap_init_ok>
ffffffffc0201220:	439c                	lw	a5,0(a5)
ffffffffc0201222:	2781                	sext.w	a5,a5
ffffffffc0201224:	cf8d                	beqz	a5,ffffffffc020125e <do_pgfault+0x90>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            page->pra_vaddr = addr;
ffffffffc0201226:	04003023          	sd	zero,64(zero) # 40 <BASE_ADDRESS-0xffffffffc01fffc0>
ffffffffc020122a:	9002                	ebreak
        perm |= (PTE_R | PTE_W);
ffffffffc020122c:	4959                	li	s2,22
ffffffffc020122e:	bfe1                	j	ffffffffc0201206 <do_pgfault+0x38>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0201230:	6c88                	ld	a0,24(s1)
ffffffffc0201232:	864a                	mv	a2,s2
ffffffffc0201234:	85a2                	mv	a1,s0
ffffffffc0201236:	632020ef          	jal	ra,ffffffffc0203868 <pgdir_alloc_page>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
ffffffffc020123a:	4781                	li	a5,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc020123c:	c90d                	beqz	a0,ffffffffc020126e <do_pgfault+0xa0>
failed:
    return ret;
}
ffffffffc020123e:	60e2                	ld	ra,24(sp)
ffffffffc0201240:	6442                	ld	s0,16(sp)
ffffffffc0201242:	64a2                	ld	s1,8(sp)
ffffffffc0201244:	6902                	ld	s2,0(sp)
ffffffffc0201246:	853e                	mv	a0,a5
ffffffffc0201248:	6105                	addi	sp,sp,32
ffffffffc020124a:	8082                	ret
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc020124c:	85a2                	mv	a1,s0
ffffffffc020124e:	00004517          	auipc	a0,0x4
ffffffffc0201252:	85250513          	addi	a0,a0,-1966 # ffffffffc0204aa0 <commands+0x880>
ffffffffc0201256:	e69fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    int ret = -E_INVAL;
ffffffffc020125a:	57f5                	li	a5,-3
        goto failed;
ffffffffc020125c:	b7cd                	j	ffffffffc020123e <do_pgfault+0x70>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc020125e:	00004517          	auipc	a0,0x4
ffffffffc0201262:	89a50513          	addi	a0,a0,-1894 # ffffffffc0204af8 <commands+0x8d8>
ffffffffc0201266:	e59fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc020126a:	57f1                	li	a5,-4
            goto failed;
ffffffffc020126c:	bfc9                	j	ffffffffc020123e <do_pgfault+0x70>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc020126e:	00004517          	auipc	a0,0x4
ffffffffc0201272:	86250513          	addi	a0,a0,-1950 # ffffffffc0204ad0 <commands+0x8b0>
ffffffffc0201276:	e49fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc020127a:	57f1                	li	a5,-4
            goto failed;
ffffffffc020127c:	b7c9                	j	ffffffffc020123e <do_pgfault+0x70>

ffffffffc020127e <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc020127e:	7135                	addi	sp,sp,-160
ffffffffc0201280:	ed06                	sd	ra,152(sp)
ffffffffc0201282:	e922                	sd	s0,144(sp)
ffffffffc0201284:	e526                	sd	s1,136(sp)
ffffffffc0201286:	e14a                	sd	s2,128(sp)
ffffffffc0201288:	fcce                	sd	s3,120(sp)
ffffffffc020128a:	f8d2                	sd	s4,112(sp)
ffffffffc020128c:	f4d6                	sd	s5,104(sp)
ffffffffc020128e:	f0da                	sd	s6,96(sp)
ffffffffc0201290:	ecde                	sd	s7,88(sp)
ffffffffc0201292:	e8e2                	sd	s8,80(sp)
ffffffffc0201294:	e4e6                	sd	s9,72(sp)
ffffffffc0201296:	e0ea                	sd	s10,64(sp)
ffffffffc0201298:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc020129a:	7e2020ef          	jal	ra,ffffffffc0203a7c <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc020129e:	0000f797          	auipc	a5,0xf
ffffffffc02012a2:	27278793          	addi	a5,a5,626 # ffffffffc0210510 <max_swap_offset>
ffffffffc02012a6:	6394                	ld	a3,0(a5)
ffffffffc02012a8:	010007b7          	lui	a5,0x1000
ffffffffc02012ac:	17e1                	addi	a5,a5,-8
ffffffffc02012ae:	ff968713          	addi	a4,a3,-7
ffffffffc02012b2:	42e7ea63          	bltu	a5,a4,ffffffffc02016e6 <swap_init+0x468>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
ffffffffc02012b6:	00008797          	auipc	a5,0x8
ffffffffc02012ba:	d4a78793          	addi	a5,a5,-694 # ffffffffc0209000 <swap_manager_clock>
     int r = sm->init();
ffffffffc02012be:	6798                	ld	a4,8(a5)
     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
ffffffffc02012c0:	0000f697          	auipc	a3,0xf
ffffffffc02012c4:	18f6bc23          	sd	a5,408(a3) # ffffffffc0210458 <sm>
     int r = sm->init();
ffffffffc02012c8:	9702                	jalr	a4
ffffffffc02012ca:	8b2a                	mv	s6,a0
     
     if (r == 0)
ffffffffc02012cc:	c10d                	beqz	a0,ffffffffc02012ee <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02012ce:	60ea                	ld	ra,152(sp)
ffffffffc02012d0:	644a                	ld	s0,144(sp)
ffffffffc02012d2:	855a                	mv	a0,s6
ffffffffc02012d4:	64aa                	ld	s1,136(sp)
ffffffffc02012d6:	690a                	ld	s2,128(sp)
ffffffffc02012d8:	79e6                	ld	s3,120(sp)
ffffffffc02012da:	7a46                	ld	s4,112(sp)
ffffffffc02012dc:	7aa6                	ld	s5,104(sp)
ffffffffc02012de:	7b06                	ld	s6,96(sp)
ffffffffc02012e0:	6be6                	ld	s7,88(sp)
ffffffffc02012e2:	6c46                	ld	s8,80(sp)
ffffffffc02012e4:	6ca6                	ld	s9,72(sp)
ffffffffc02012e6:	6d06                	ld	s10,64(sp)
ffffffffc02012e8:	7de2                	ld	s11,56(sp)
ffffffffc02012ea:	610d                	addi	sp,sp,160
ffffffffc02012ec:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02012ee:	0000f797          	auipc	a5,0xf
ffffffffc02012f2:	16a78793          	addi	a5,a5,362 # ffffffffc0210458 <sm>
ffffffffc02012f6:	639c                	ld	a5,0(a5)
ffffffffc02012f8:	00004517          	auipc	a0,0x4
ffffffffc02012fc:	b2050513          	addi	a0,a0,-1248 # ffffffffc0204e18 <commands+0xbf8>
ffffffffc0201300:	0000f417          	auipc	s0,0xf
ffffffffc0201304:	25040413          	addi	s0,s0,592 # ffffffffc0210550 <free_area>
ffffffffc0201308:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc020130a:	4785                	li	a5,1
ffffffffc020130c:	0000f717          	auipc	a4,0xf
ffffffffc0201310:	14f72a23          	sw	a5,340(a4) # ffffffffc0210460 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0201314:	dabfe0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0201318:	641c                	ld	a5,8(s0)
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc020131a:	2e878a63          	beq	a5,s0,ffffffffc020160e <swap_init+0x390>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020131e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201322:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201324:	8b05                	andi	a4,a4,1
ffffffffc0201326:	2e070863          	beqz	a4,ffffffffc0201616 <swap_init+0x398>
     int ret, count = 0, total = 0, i;
ffffffffc020132a:	4481                	li	s1,0
ffffffffc020132c:	4901                	li	s2,0
ffffffffc020132e:	a031                	j	ffffffffc020133a <swap_init+0xbc>
ffffffffc0201330:	fe87b703          	ld	a4,-24(a5)
        assert(PageProperty(p));
ffffffffc0201334:	8b09                	andi	a4,a4,2
ffffffffc0201336:	2e070063          	beqz	a4,ffffffffc0201616 <swap_init+0x398>
        count ++, total += p->property;
ffffffffc020133a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020133e:	679c                	ld	a5,8(a5)
ffffffffc0201340:	2905                	addiw	s2,s2,1
ffffffffc0201342:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201344:	fe8796e3          	bne	a5,s0,ffffffffc0201330 <swap_init+0xb2>
ffffffffc0201348:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc020134a:	652010ef          	jal	ra,ffffffffc020299c <nr_free_pages>
ffffffffc020134e:	5b351863          	bne	a0,s3,ffffffffc02018fe <swap_init+0x680>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0201352:	8626                	mv	a2,s1
ffffffffc0201354:	85ca                	mv	a1,s2
ffffffffc0201356:	00004517          	auipc	a0,0x4
ffffffffc020135a:	b0a50513          	addi	a0,a0,-1270 # ffffffffc0204e60 <commands+0xc40>
ffffffffc020135e:	d61fe0ef          	jal	ra,ffffffffc02000be <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0201362:	f72ff0ef          	jal	ra,ffffffffc0200ad4 <mm_create>
ffffffffc0201366:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc0201368:	50050b63          	beqz	a0,ffffffffc020187e <swap_init+0x600>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc020136c:	0000f797          	auipc	a5,0xf
ffffffffc0201370:	11478793          	addi	a5,a5,276 # ffffffffc0210480 <check_mm_struct>
ffffffffc0201374:	639c                	ld	a5,0(a5)
ffffffffc0201376:	52079463          	bnez	a5,ffffffffc020189e <swap_init+0x620>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020137a:	0000f797          	auipc	a5,0xf
ffffffffc020137e:	0ee78793          	addi	a5,a5,238 # ffffffffc0210468 <boot_pgdir>
ffffffffc0201382:	6398                	ld	a4,0(a5)
     check_mm_struct = mm;
ffffffffc0201384:	0000f797          	auipc	a5,0xf
ffffffffc0201388:	0ea7be23          	sd	a0,252(a5) # ffffffffc0210480 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc020138c:	631c                	ld	a5,0(a4)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020138e:	ec3a                	sd	a4,24(sp)
ffffffffc0201390:	ed18                	sd	a4,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0201392:	52079663          	bnez	a5,ffffffffc02018be <swap_init+0x640>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0201396:	6599                	lui	a1,0x6
ffffffffc0201398:	460d                	li	a2,3
ffffffffc020139a:	6505                	lui	a0,0x1
ffffffffc020139c:	f84ff0ef          	jal	ra,ffffffffc0200b20 <vma_create>
ffffffffc02013a0:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc02013a2:	52050e63          	beqz	a0,ffffffffc02018de <swap_init+0x660>

     insert_vma_struct(mm, vma);
ffffffffc02013a6:	855e                	mv	a0,s7
ffffffffc02013a8:	fe4ff0ef          	jal	ra,ffffffffc0200b8c <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc02013ac:	00004517          	auipc	a0,0x4
ffffffffc02013b0:	af450513          	addi	a0,a0,-1292 # ffffffffc0204ea0 <commands+0xc80>
ffffffffc02013b4:	d0bfe0ef          	jal	ra,ffffffffc02000be <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc02013b8:	018bb503          	ld	a0,24(s7)
ffffffffc02013bc:	4605                	li	a2,1
ffffffffc02013be:	6585                	lui	a1,0x1
ffffffffc02013c0:	61c010ef          	jal	ra,ffffffffc02029dc <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc02013c4:	40050d63          	beqz	a0,ffffffffc02017de <swap_init+0x560>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02013c8:	00004517          	auipc	a0,0x4
ffffffffc02013cc:	b2850513          	addi	a0,a0,-1240 # ffffffffc0204ef0 <commands+0xcd0>
ffffffffc02013d0:	0000fa17          	auipc	s4,0xf
ffffffffc02013d4:	0b8a0a13          	addi	s4,s4,184 # ffffffffc0210488 <check_rp>
ffffffffc02013d8:	ce7fe0ef          	jal	ra,ffffffffc02000be <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02013dc:	0000fa97          	auipc	s5,0xf
ffffffffc02013e0:	0cca8a93          	addi	s5,s5,204 # ffffffffc02104a8 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02013e4:	89d2                	mv	s3,s4
          check_rp[i] = alloc_page();
ffffffffc02013e6:	4505                	li	a0,1
ffffffffc02013e8:	4e6010ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc02013ec:	00a9b023          	sd	a0,0(s3)
          assert(check_rp[i] != NULL );
ffffffffc02013f0:	2a050b63          	beqz	a0,ffffffffc02016a6 <swap_init+0x428>
ffffffffc02013f4:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc02013f6:	8b89                	andi	a5,a5,2
ffffffffc02013f8:	28079763          	bnez	a5,ffffffffc0201686 <swap_init+0x408>
ffffffffc02013fc:	09a1                	addi	s3,s3,8
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02013fe:	ff5994e3          	bne	s3,s5,ffffffffc02013e6 <swap_init+0x168>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0201402:	601c                	ld	a5,0(s0)
ffffffffc0201404:	00843983          	ld	s3,8(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0201408:	0000fd17          	auipc	s10,0xf
ffffffffc020140c:	080d0d13          	addi	s10,s10,128 # ffffffffc0210488 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc0201410:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0201412:	481c                	lw	a5,16(s0)
ffffffffc0201414:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc0201416:	0000f797          	auipc	a5,0xf
ffffffffc020141a:	1487b123          	sd	s0,322(a5) # ffffffffc0210558 <free_area+0x8>
ffffffffc020141e:	0000f797          	auipc	a5,0xf
ffffffffc0201422:	1287b923          	sd	s0,306(a5) # ffffffffc0210550 <free_area>
     nr_free = 0;
ffffffffc0201426:	0000f797          	auipc	a5,0xf
ffffffffc020142a:	1207ad23          	sw	zero,314(a5) # ffffffffc0210560 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc020142e:	000d3503          	ld	a0,0(s10)
ffffffffc0201432:	4585                	li	a1,1
ffffffffc0201434:	0d21                	addi	s10,s10,8
ffffffffc0201436:	520010ef          	jal	ra,ffffffffc0202956 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020143a:	ff5d1ae3          	bne	s10,s5,ffffffffc020142e <swap_init+0x1b0>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc020143e:	01042d03          	lw	s10,16(s0)
ffffffffc0201442:	4791                	li	a5,4
ffffffffc0201444:	36fd1d63          	bne	s10,a5,ffffffffc02017be <swap_init+0x540>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0201448:	00004517          	auipc	a0,0x4
ffffffffc020144c:	b3050513          	addi	a0,a0,-1232 # ffffffffc0204f78 <commands+0xd58>
ffffffffc0201450:	c6ffe0ef          	jal	ra,ffffffffc02000be <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201454:	6685                	lui	a3,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0201456:	0000f797          	auipc	a5,0xf
ffffffffc020145a:	fe07ad23          	sw	zero,-6(a5) # ffffffffc0210450 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc020145e:	4629                	li	a2,10
     pgfault_num=0;
ffffffffc0201460:	0000f797          	auipc	a5,0xf
ffffffffc0201464:	ff078793          	addi	a5,a5,-16 # ffffffffc0210450 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201468:	00c68023          	sb	a2,0(a3) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
     assert(pgfault_num==1);
ffffffffc020146c:	4398                	lw	a4,0(a5)
ffffffffc020146e:	4585                	li	a1,1
ffffffffc0201470:	2701                	sext.w	a4,a4
ffffffffc0201472:	30b71663          	bne	a4,a1,ffffffffc020177e <swap_init+0x500>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0201476:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==1);
ffffffffc020147a:	4394                	lw	a3,0(a5)
ffffffffc020147c:	2681                	sext.w	a3,a3
ffffffffc020147e:	32e69063          	bne	a3,a4,ffffffffc020179e <swap_init+0x520>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201482:	6689                	lui	a3,0x2
ffffffffc0201484:	462d                	li	a2,11
ffffffffc0201486:	00c68023          	sb	a2,0(a3) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc020148a:	4398                	lw	a4,0(a5)
ffffffffc020148c:	4589                	li	a1,2
ffffffffc020148e:	2701                	sext.w	a4,a4
ffffffffc0201490:	26b71763          	bne	a4,a1,ffffffffc02016fe <swap_init+0x480>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0201494:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc0201498:	4394                	lw	a3,0(a5)
ffffffffc020149a:	2681                	sext.w	a3,a3
ffffffffc020149c:	28e69163          	bne	a3,a4,ffffffffc020171e <swap_init+0x4a0>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc02014a0:	668d                	lui	a3,0x3
ffffffffc02014a2:	4631                	li	a2,12
ffffffffc02014a4:	00c68023          	sb	a2,0(a3) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc02014a8:	4398                	lw	a4,0(a5)
ffffffffc02014aa:	458d                	li	a1,3
ffffffffc02014ac:	2701                	sext.w	a4,a4
ffffffffc02014ae:	28b71863          	bne	a4,a1,ffffffffc020173e <swap_init+0x4c0>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc02014b2:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc02014b6:	4394                	lw	a3,0(a5)
ffffffffc02014b8:	2681                	sext.w	a3,a3
ffffffffc02014ba:	2ae69263          	bne	a3,a4,ffffffffc020175e <swap_init+0x4e0>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc02014be:	6691                	lui	a3,0x4
ffffffffc02014c0:	4635                	li	a2,13
ffffffffc02014c2:	00c68023          	sb	a2,0(a3) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc02014c6:	4398                	lw	a4,0(a5)
ffffffffc02014c8:	2701                	sext.w	a4,a4
ffffffffc02014ca:	33a71a63          	bne	a4,s10,ffffffffc02017fe <swap_init+0x580>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc02014ce:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc02014d2:	439c                	lw	a5,0(a5)
ffffffffc02014d4:	2781                	sext.w	a5,a5
ffffffffc02014d6:	34e79463          	bne	a5,a4,ffffffffc020181e <swap_init+0x5a0>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc02014da:	481c                	lw	a5,16(s0)
ffffffffc02014dc:	36079163          	bnez	a5,ffffffffc020183e <swap_init+0x5c0>
ffffffffc02014e0:	0000f797          	auipc	a5,0xf
ffffffffc02014e4:	fc878793          	addi	a5,a5,-56 # ffffffffc02104a8 <swap_in_seq_no>
ffffffffc02014e8:	0000f717          	auipc	a4,0xf
ffffffffc02014ec:	fe870713          	addi	a4,a4,-24 # ffffffffc02104d0 <swap_out_seq_no>
ffffffffc02014f0:	0000f617          	auipc	a2,0xf
ffffffffc02014f4:	fe060613          	addi	a2,a2,-32 # ffffffffc02104d0 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc02014f8:	56fd                	li	a3,-1
ffffffffc02014fa:	c394                	sw	a3,0(a5)
ffffffffc02014fc:	c314                	sw	a3,0(a4)
ffffffffc02014fe:	0791                	addi	a5,a5,4
ffffffffc0201500:	0711                	addi	a4,a4,4
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0201502:	fec79ce3          	bne	a5,a2,ffffffffc02014fa <swap_init+0x27c>
ffffffffc0201506:	0000f697          	auipc	a3,0xf
ffffffffc020150a:	02a68693          	addi	a3,a3,42 # ffffffffc0210530 <check_ptep>
ffffffffc020150e:	0000f817          	auipc	a6,0xf
ffffffffc0201512:	f7a80813          	addi	a6,a6,-134 # ffffffffc0210488 <check_rp>
ffffffffc0201516:	6c05                	lui	s8,0x1
    if (PPN(pa) >= npage) {
ffffffffc0201518:	0000fc97          	auipc	s9,0xf
ffffffffc020151c:	f58c8c93          	addi	s9,s9,-168 # ffffffffc0210470 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0201520:	0000fd97          	auipc	s11,0xf
ffffffffc0201524:	068d8d93          	addi	s11,s11,104 # ffffffffc0210588 <pages>
ffffffffc0201528:	00005d17          	auipc	s10,0x5
ffffffffc020152c:	940d0d13          	addi	s10,s10,-1728 # ffffffffc0205e68 <nbase>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0201530:	6562                	ld	a0,24(sp)
         check_ptep[i]=0;
ffffffffc0201532:	0006b023          	sd	zero,0(a3)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0201536:	4601                	li	a2,0
ffffffffc0201538:	85e2                	mv	a1,s8
ffffffffc020153a:	e842                	sd	a6,16(sp)
         check_ptep[i]=0;
ffffffffc020153c:	e436                	sd	a3,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc020153e:	49e010ef          	jal	ra,ffffffffc02029dc <get_pte>
ffffffffc0201542:	66a2                	ld	a3,8(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0201544:	6842                	ld	a6,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0201546:	e288                	sd	a0,0(a3)
         assert(check_ptep[i] != NULL);
ffffffffc0201548:	16050f63          	beqz	a0,ffffffffc02016c6 <swap_init+0x448>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc020154c:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020154e:	0017f613          	andi	a2,a5,1
ffffffffc0201552:	10060263          	beqz	a2,ffffffffc0201656 <swap_init+0x3d8>
    if (PPN(pa) >= npage) {
ffffffffc0201556:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020155a:	078a                	slli	a5,a5,0x2
ffffffffc020155c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020155e:	10c7f863          	bleu	a2,a5,ffffffffc020166e <swap_init+0x3f0>
    return &pages[PPN(pa) - nbase];
ffffffffc0201562:	000d3603          	ld	a2,0(s10)
ffffffffc0201566:	000db583          	ld	a1,0(s11)
ffffffffc020156a:	00083503          	ld	a0,0(a6)
ffffffffc020156e:	8f91                	sub	a5,a5,a2
ffffffffc0201570:	00379613          	slli	a2,a5,0x3
ffffffffc0201574:	97b2                	add	a5,a5,a2
ffffffffc0201576:	078e                	slli	a5,a5,0x3
ffffffffc0201578:	97ae                	add	a5,a5,a1
ffffffffc020157a:	0af51e63          	bne	a0,a5,ffffffffc0201636 <swap_init+0x3b8>
ffffffffc020157e:	6785                	lui	a5,0x1
ffffffffc0201580:	9c3e                	add	s8,s8,a5
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201582:	6795                	lui	a5,0x5
ffffffffc0201584:	06a1                	addi	a3,a3,8
ffffffffc0201586:	0821                	addi	a6,a6,8
ffffffffc0201588:	fafc14e3          	bne	s8,a5,ffffffffc0201530 <swap_init+0x2b2>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc020158c:	00004517          	auipc	a0,0x4
ffffffffc0201590:	acc50513          	addi	a0,a0,-1332 # ffffffffc0205058 <commands+0xe38>
ffffffffc0201594:	b2bfe0ef          	jal	ra,ffffffffc02000be <cprintf>
    int ret = sm->check_swap();
ffffffffc0201598:	0000f797          	auipc	a5,0xf
ffffffffc020159c:	ec078793          	addi	a5,a5,-320 # ffffffffc0210458 <sm>
ffffffffc02015a0:	639c                	ld	a5,0(a5)
ffffffffc02015a2:	7f9c                	ld	a5,56(a5)
ffffffffc02015a4:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc02015a6:	2a051c63          	bnez	a0,ffffffffc020185e <swap_init+0x5e0>
     
     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc02015aa:	000a3503          	ld	a0,0(s4)
ffffffffc02015ae:	4585                	li	a1,1
ffffffffc02015b0:	0a21                	addi	s4,s4,8
ffffffffc02015b2:	3a4010ef          	jal	ra,ffffffffc0202956 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02015b6:	ff5a1ae3          	bne	s4,s5,ffffffffc02015aa <swap_init+0x32c>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc02015ba:	855e                	mv	a0,s7
ffffffffc02015bc:	e9eff0ef          	jal	ra,ffffffffc0200c5a <mm_destroy>
         
     nr_free = nr_free_store;
ffffffffc02015c0:	77a2                	ld	a5,40(sp)
ffffffffc02015c2:	0000f717          	auipc	a4,0xf
ffffffffc02015c6:	f8f72f23          	sw	a5,-98(a4) # ffffffffc0210560 <free_area+0x10>
     free_list = free_list_store;
ffffffffc02015ca:	7782                	ld	a5,32(sp)
ffffffffc02015cc:	0000f717          	auipc	a4,0xf
ffffffffc02015d0:	f8f73223          	sd	a5,-124(a4) # ffffffffc0210550 <free_area>
ffffffffc02015d4:	0000f797          	auipc	a5,0xf
ffffffffc02015d8:	f937b223          	sd	s3,-124(a5) # ffffffffc0210558 <free_area+0x8>

     
     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc02015dc:	00898a63          	beq	s3,s0,ffffffffc02015f0 <swap_init+0x372>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc02015e0:	ff89a783          	lw	a5,-8(s3)
    return listelm->next;
ffffffffc02015e4:	0089b983          	ld	s3,8(s3)
ffffffffc02015e8:	397d                	addiw	s2,s2,-1
ffffffffc02015ea:	9c9d                	subw	s1,s1,a5
     while ((le = list_next(le)) != &free_list) {
ffffffffc02015ec:	fe899ae3          	bne	s3,s0,ffffffffc02015e0 <swap_init+0x362>
     }
     cprintf("count is %d, total is %d\n",count,total);
ffffffffc02015f0:	8626                	mv	a2,s1
ffffffffc02015f2:	85ca                	mv	a1,s2
ffffffffc02015f4:	00004517          	auipc	a0,0x4
ffffffffc02015f8:	a9450513          	addi	a0,a0,-1388 # ffffffffc0205088 <commands+0xe68>
ffffffffc02015fc:	ac3fe0ef          	jal	ra,ffffffffc02000be <cprintf>
     //assert(count == 0);
     
     cprintf("check_swap() succeeded!\n");
ffffffffc0201600:	00004517          	auipc	a0,0x4
ffffffffc0201604:	aa850513          	addi	a0,a0,-1368 # ffffffffc02050a8 <commands+0xe88>
ffffffffc0201608:	ab7fe0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc020160c:	b1c9                	j	ffffffffc02012ce <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc020160e:	4481                	li	s1,0
ffffffffc0201610:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201612:	4981                	li	s3,0
ffffffffc0201614:	bb1d                	j	ffffffffc020134a <swap_init+0xcc>
        assert(PageProperty(p));
ffffffffc0201616:	00004697          	auipc	a3,0x4
ffffffffc020161a:	81a68693          	addi	a3,a3,-2022 # ffffffffc0204e30 <commands+0xc10>
ffffffffc020161e:	00003617          	auipc	a2,0x3
ffffffffc0201622:	45a60613          	addi	a2,a2,1114 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201626:	0ba00593          	li	a1,186
ffffffffc020162a:	00003517          	auipc	a0,0x3
ffffffffc020162e:	7de50513          	addi	a0,a0,2014 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc0201632:	ad5fe0ef          	jal	ra,ffffffffc0200106 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0201636:	00004697          	auipc	a3,0x4
ffffffffc020163a:	9fa68693          	addi	a3,a3,-1542 # ffffffffc0205030 <commands+0xe10>
ffffffffc020163e:	00003617          	auipc	a2,0x3
ffffffffc0201642:	43a60613          	addi	a2,a2,1082 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201646:	0fa00593          	li	a1,250
ffffffffc020164a:	00003517          	auipc	a0,0x3
ffffffffc020164e:	7be50513          	addi	a0,a0,1982 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc0201652:	ab5fe0ef          	jal	ra,ffffffffc0200106 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0201656:	00004617          	auipc	a2,0x4
ffffffffc020165a:	9b260613          	addi	a2,a2,-1614 # ffffffffc0205008 <commands+0xde8>
ffffffffc020165e:	07000593          	li	a1,112
ffffffffc0201662:	00003517          	auipc	a0,0x3
ffffffffc0201666:	72e50513          	addi	a0,a0,1838 # ffffffffc0204d90 <commands+0xb70>
ffffffffc020166a:	a9dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020166e:	00003617          	auipc	a2,0x3
ffffffffc0201672:	70260613          	addi	a2,a2,1794 # ffffffffc0204d70 <commands+0xb50>
ffffffffc0201676:	06500593          	li	a1,101
ffffffffc020167a:	00003517          	auipc	a0,0x3
ffffffffc020167e:	71650513          	addi	a0,a0,1814 # ffffffffc0204d90 <commands+0xb70>
ffffffffc0201682:	a85fe0ef          	jal	ra,ffffffffc0200106 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0201686:	00004697          	auipc	a3,0x4
ffffffffc020168a:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0204f30 <commands+0xd10>
ffffffffc020168e:	00003617          	auipc	a2,0x3
ffffffffc0201692:	3ea60613          	addi	a2,a2,1002 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201696:	0db00593          	li	a1,219
ffffffffc020169a:	00003517          	auipc	a0,0x3
ffffffffc020169e:	76e50513          	addi	a0,a0,1902 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc02016a2:	a65fe0ef          	jal	ra,ffffffffc0200106 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc02016a6:	00004697          	auipc	a3,0x4
ffffffffc02016aa:	87268693          	addi	a3,a3,-1934 # ffffffffc0204f18 <commands+0xcf8>
ffffffffc02016ae:	00003617          	auipc	a2,0x3
ffffffffc02016b2:	3ca60613          	addi	a2,a2,970 # ffffffffc0204a78 <commands+0x858>
ffffffffc02016b6:	0da00593          	li	a1,218
ffffffffc02016ba:	00003517          	auipc	a0,0x3
ffffffffc02016be:	74e50513          	addi	a0,a0,1870 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc02016c2:	a45fe0ef          	jal	ra,ffffffffc0200106 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc02016c6:	00004697          	auipc	a3,0x4
ffffffffc02016ca:	92a68693          	addi	a3,a3,-1750 # ffffffffc0204ff0 <commands+0xdd0>
ffffffffc02016ce:	00003617          	auipc	a2,0x3
ffffffffc02016d2:	3aa60613          	addi	a2,a2,938 # ffffffffc0204a78 <commands+0x858>
ffffffffc02016d6:	0f900593          	li	a1,249
ffffffffc02016da:	00003517          	auipc	a0,0x3
ffffffffc02016de:	72e50513          	addi	a0,a0,1838 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc02016e2:	a25fe0ef          	jal	ra,ffffffffc0200106 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc02016e6:	00003617          	auipc	a2,0x3
ffffffffc02016ea:	70260613          	addi	a2,a2,1794 # ffffffffc0204de8 <commands+0xbc8>
ffffffffc02016ee:	02700593          	li	a1,39
ffffffffc02016f2:	00003517          	auipc	a0,0x3
ffffffffc02016f6:	71650513          	addi	a0,a0,1814 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc02016fa:	a0dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==2);
ffffffffc02016fe:	00004697          	auipc	a3,0x4
ffffffffc0201702:	8b268693          	addi	a3,a3,-1870 # ffffffffc0204fb0 <commands+0xd90>
ffffffffc0201706:	00003617          	auipc	a2,0x3
ffffffffc020170a:	37260613          	addi	a2,a2,882 # ffffffffc0204a78 <commands+0x858>
ffffffffc020170e:	09500593          	li	a1,149
ffffffffc0201712:	00003517          	auipc	a0,0x3
ffffffffc0201716:	6f650513          	addi	a0,a0,1782 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc020171a:	9edfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==2);
ffffffffc020171e:	00004697          	auipc	a3,0x4
ffffffffc0201722:	89268693          	addi	a3,a3,-1902 # ffffffffc0204fb0 <commands+0xd90>
ffffffffc0201726:	00003617          	auipc	a2,0x3
ffffffffc020172a:	35260613          	addi	a2,a2,850 # ffffffffc0204a78 <commands+0x858>
ffffffffc020172e:	09700593          	li	a1,151
ffffffffc0201732:	00003517          	auipc	a0,0x3
ffffffffc0201736:	6d650513          	addi	a0,a0,1750 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc020173a:	9cdfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==3);
ffffffffc020173e:	00004697          	auipc	a3,0x4
ffffffffc0201742:	88268693          	addi	a3,a3,-1918 # ffffffffc0204fc0 <commands+0xda0>
ffffffffc0201746:	00003617          	auipc	a2,0x3
ffffffffc020174a:	33260613          	addi	a2,a2,818 # ffffffffc0204a78 <commands+0x858>
ffffffffc020174e:	09900593          	li	a1,153
ffffffffc0201752:	00003517          	auipc	a0,0x3
ffffffffc0201756:	6b650513          	addi	a0,a0,1718 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc020175a:	9adfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==3);
ffffffffc020175e:	00004697          	auipc	a3,0x4
ffffffffc0201762:	86268693          	addi	a3,a3,-1950 # ffffffffc0204fc0 <commands+0xda0>
ffffffffc0201766:	00003617          	auipc	a2,0x3
ffffffffc020176a:	31260613          	addi	a2,a2,786 # ffffffffc0204a78 <commands+0x858>
ffffffffc020176e:	09b00593          	li	a1,155
ffffffffc0201772:	00003517          	auipc	a0,0x3
ffffffffc0201776:	69650513          	addi	a0,a0,1686 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc020177a:	98dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==1);
ffffffffc020177e:	00004697          	auipc	a3,0x4
ffffffffc0201782:	82268693          	addi	a3,a3,-2014 # ffffffffc0204fa0 <commands+0xd80>
ffffffffc0201786:	00003617          	auipc	a2,0x3
ffffffffc020178a:	2f260613          	addi	a2,a2,754 # ffffffffc0204a78 <commands+0x858>
ffffffffc020178e:	09100593          	li	a1,145
ffffffffc0201792:	00003517          	auipc	a0,0x3
ffffffffc0201796:	67650513          	addi	a0,a0,1654 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc020179a:	96dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==1);
ffffffffc020179e:	00004697          	auipc	a3,0x4
ffffffffc02017a2:	80268693          	addi	a3,a3,-2046 # ffffffffc0204fa0 <commands+0xd80>
ffffffffc02017a6:	00003617          	auipc	a2,0x3
ffffffffc02017aa:	2d260613          	addi	a2,a2,722 # ffffffffc0204a78 <commands+0x858>
ffffffffc02017ae:	09300593          	li	a1,147
ffffffffc02017b2:	00003517          	auipc	a0,0x3
ffffffffc02017b6:	65650513          	addi	a0,a0,1622 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc02017ba:	94dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc02017be:	00003697          	auipc	a3,0x3
ffffffffc02017c2:	79268693          	addi	a3,a3,1938 # ffffffffc0204f50 <commands+0xd30>
ffffffffc02017c6:	00003617          	auipc	a2,0x3
ffffffffc02017ca:	2b260613          	addi	a2,a2,690 # ffffffffc0204a78 <commands+0x858>
ffffffffc02017ce:	0e800593          	li	a1,232
ffffffffc02017d2:	00003517          	auipc	a0,0x3
ffffffffc02017d6:	63650513          	addi	a0,a0,1590 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc02017da:	92dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc02017de:	00003697          	auipc	a3,0x3
ffffffffc02017e2:	6fa68693          	addi	a3,a3,1786 # ffffffffc0204ed8 <commands+0xcb8>
ffffffffc02017e6:	00003617          	auipc	a2,0x3
ffffffffc02017ea:	29260613          	addi	a2,a2,658 # ffffffffc0204a78 <commands+0x858>
ffffffffc02017ee:	0d500593          	li	a1,213
ffffffffc02017f2:	00003517          	auipc	a0,0x3
ffffffffc02017f6:	61650513          	addi	a0,a0,1558 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc02017fa:	90dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==4);
ffffffffc02017fe:	00003697          	auipc	a3,0x3
ffffffffc0201802:	7d268693          	addi	a3,a3,2002 # ffffffffc0204fd0 <commands+0xdb0>
ffffffffc0201806:	00003617          	auipc	a2,0x3
ffffffffc020180a:	27260613          	addi	a2,a2,626 # ffffffffc0204a78 <commands+0x858>
ffffffffc020180e:	09d00593          	li	a1,157
ffffffffc0201812:	00003517          	auipc	a0,0x3
ffffffffc0201816:	5f650513          	addi	a0,a0,1526 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc020181a:	8edfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgfault_num==4);
ffffffffc020181e:	00003697          	auipc	a3,0x3
ffffffffc0201822:	7b268693          	addi	a3,a3,1970 # ffffffffc0204fd0 <commands+0xdb0>
ffffffffc0201826:	00003617          	auipc	a2,0x3
ffffffffc020182a:	25260613          	addi	a2,a2,594 # ffffffffc0204a78 <commands+0x858>
ffffffffc020182e:	09f00593          	li	a1,159
ffffffffc0201832:	00003517          	auipc	a0,0x3
ffffffffc0201836:	5d650513          	addi	a0,a0,1494 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc020183a:	8cdfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert( nr_free == 0);         
ffffffffc020183e:	00003697          	auipc	a3,0x3
ffffffffc0201842:	7a268693          	addi	a3,a3,1954 # ffffffffc0204fe0 <commands+0xdc0>
ffffffffc0201846:	00003617          	auipc	a2,0x3
ffffffffc020184a:	23260613          	addi	a2,a2,562 # ffffffffc0204a78 <commands+0x858>
ffffffffc020184e:	0f100593          	li	a1,241
ffffffffc0201852:	00003517          	auipc	a0,0x3
ffffffffc0201856:	5b650513          	addi	a0,a0,1462 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc020185a:	8adfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(ret==0);
ffffffffc020185e:	00004697          	auipc	a3,0x4
ffffffffc0201862:	82268693          	addi	a3,a3,-2014 # ffffffffc0205080 <commands+0xe60>
ffffffffc0201866:	00003617          	auipc	a2,0x3
ffffffffc020186a:	21260613          	addi	a2,a2,530 # ffffffffc0204a78 <commands+0x858>
ffffffffc020186e:	10000593          	li	a1,256
ffffffffc0201872:	00003517          	auipc	a0,0x3
ffffffffc0201876:	59650513          	addi	a0,a0,1430 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc020187a:	88dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(mm != NULL);
ffffffffc020187e:	00003697          	auipc	a3,0x3
ffffffffc0201882:	30268693          	addi	a3,a3,770 # ffffffffc0204b80 <commands+0x960>
ffffffffc0201886:	00003617          	auipc	a2,0x3
ffffffffc020188a:	1f260613          	addi	a2,a2,498 # ffffffffc0204a78 <commands+0x858>
ffffffffc020188e:	0c200593          	li	a1,194
ffffffffc0201892:	00003517          	auipc	a0,0x3
ffffffffc0201896:	57650513          	addi	a0,a0,1398 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc020189a:	86dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc020189e:	00003697          	auipc	a3,0x3
ffffffffc02018a2:	5ea68693          	addi	a3,a3,1514 # ffffffffc0204e88 <commands+0xc68>
ffffffffc02018a6:	00003617          	auipc	a2,0x3
ffffffffc02018aa:	1d260613          	addi	a2,a2,466 # ffffffffc0204a78 <commands+0x858>
ffffffffc02018ae:	0c500593          	li	a1,197
ffffffffc02018b2:	00003517          	auipc	a0,0x3
ffffffffc02018b6:	55650513          	addi	a0,a0,1366 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc02018ba:	84dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(pgdir[0] == 0);
ffffffffc02018be:	00003697          	auipc	a3,0x3
ffffffffc02018c2:	47268693          	addi	a3,a3,1138 # ffffffffc0204d30 <commands+0xb10>
ffffffffc02018c6:	00003617          	auipc	a2,0x3
ffffffffc02018ca:	1b260613          	addi	a2,a2,434 # ffffffffc0204a78 <commands+0x858>
ffffffffc02018ce:	0ca00593          	li	a1,202
ffffffffc02018d2:	00003517          	auipc	a0,0x3
ffffffffc02018d6:	53650513          	addi	a0,a0,1334 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc02018da:	82dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(vma != NULL);
ffffffffc02018de:	00003697          	auipc	a3,0x3
ffffffffc02018e2:	4fa68693          	addi	a3,a3,1274 # ffffffffc0204dd8 <commands+0xbb8>
ffffffffc02018e6:	00003617          	auipc	a2,0x3
ffffffffc02018ea:	19260613          	addi	a2,a2,402 # ffffffffc0204a78 <commands+0x858>
ffffffffc02018ee:	0cd00593          	li	a1,205
ffffffffc02018f2:	00003517          	auipc	a0,0x3
ffffffffc02018f6:	51650513          	addi	a0,a0,1302 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc02018fa:	80dfe0ef          	jal	ra,ffffffffc0200106 <__panic>
     assert(total == nr_free_pages());
ffffffffc02018fe:	00003697          	auipc	a3,0x3
ffffffffc0201902:	54268693          	addi	a3,a3,1346 # ffffffffc0204e40 <commands+0xc20>
ffffffffc0201906:	00003617          	auipc	a2,0x3
ffffffffc020190a:	17260613          	addi	a2,a2,370 # ffffffffc0204a78 <commands+0x858>
ffffffffc020190e:	0bd00593          	li	a1,189
ffffffffc0201912:	00003517          	auipc	a0,0x3
ffffffffc0201916:	4f650513          	addi	a0,a0,1270 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc020191a:	fecfe0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc020191e <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc020191e:	0000f797          	auipc	a5,0xf
ffffffffc0201922:	b3a78793          	addi	a5,a5,-1222 # ffffffffc0210458 <sm>
ffffffffc0201926:	639c                	ld	a5,0(a5)
ffffffffc0201928:	0107b303          	ld	t1,16(a5)
ffffffffc020192c:	8302                	jr	t1

ffffffffc020192e <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc020192e:	0000f797          	auipc	a5,0xf
ffffffffc0201932:	b2a78793          	addi	a5,a5,-1238 # ffffffffc0210458 <sm>
ffffffffc0201936:	639c                	ld	a5,0(a5)
ffffffffc0201938:	0207b303          	ld	t1,32(a5)
ffffffffc020193c:	8302                	jr	t1

ffffffffc020193e <swap_out>:
{
ffffffffc020193e:	711d                	addi	sp,sp,-96
ffffffffc0201940:	ec86                	sd	ra,88(sp)
ffffffffc0201942:	e8a2                	sd	s0,80(sp)
ffffffffc0201944:	e4a6                	sd	s1,72(sp)
ffffffffc0201946:	e0ca                	sd	s2,64(sp)
ffffffffc0201948:	fc4e                	sd	s3,56(sp)
ffffffffc020194a:	f852                	sd	s4,48(sp)
ffffffffc020194c:	f456                	sd	s5,40(sp)
ffffffffc020194e:	f05a                	sd	s6,32(sp)
ffffffffc0201950:	ec5e                	sd	s7,24(sp)
ffffffffc0201952:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0201954:	cde9                	beqz	a1,ffffffffc0201a2e <swap_out+0xf0>
ffffffffc0201956:	8ab2                	mv	s5,a2
ffffffffc0201958:	892a                	mv	s2,a0
ffffffffc020195a:	8a2e                	mv	s4,a1
ffffffffc020195c:	4401                	li	s0,0
ffffffffc020195e:	0000f997          	auipc	s3,0xf
ffffffffc0201962:	afa98993          	addi	s3,s3,-1286 # ffffffffc0210458 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0201966:	00003b17          	auipc	s6,0x3
ffffffffc020196a:	7c2b0b13          	addi	s6,s6,1986 # ffffffffc0205128 <commands+0xf08>
                    cprintf("SWAP: failed to save\n");
ffffffffc020196e:	00003b97          	auipc	s7,0x3
ffffffffc0201972:	7a2b8b93          	addi	s7,s7,1954 # ffffffffc0205110 <commands+0xef0>
ffffffffc0201976:	a825                	j	ffffffffc02019ae <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0201978:	67a2                	ld	a5,8(sp)
ffffffffc020197a:	8626                	mv	a2,s1
ffffffffc020197c:	85a2                	mv	a1,s0
ffffffffc020197e:	63b4                	ld	a3,64(a5)
ffffffffc0201980:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0201982:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0201984:	82b1                	srli	a3,a3,0xc
ffffffffc0201986:	0685                	addi	a3,a3,1
ffffffffc0201988:	f36fe0ef          	jal	ra,ffffffffc02000be <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020198c:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc020198e:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0201990:	613c                	ld	a5,64(a0)
ffffffffc0201992:	83b1                	srli	a5,a5,0xc
ffffffffc0201994:	0785                	addi	a5,a5,1
ffffffffc0201996:	07a2                	slli	a5,a5,0x8
ffffffffc0201998:	00fc3023          	sd	a5,0(s8) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
                    free_page(page);
ffffffffc020199c:	7bb000ef          	jal	ra,ffffffffc0202956 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc02019a0:	01893503          	ld	a0,24(s2)
ffffffffc02019a4:	85a6                	mv	a1,s1
ffffffffc02019a6:	6bd010ef          	jal	ra,ffffffffc0203862 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc02019aa:	048a0d63          	beq	s4,s0,ffffffffc0201a04 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc02019ae:	0009b783          	ld	a5,0(s3)
ffffffffc02019b2:	8656                	mv	a2,s5
ffffffffc02019b4:	002c                	addi	a1,sp,8
ffffffffc02019b6:	7b9c                	ld	a5,48(a5)
ffffffffc02019b8:	854a                	mv	a0,s2
ffffffffc02019ba:	9782                	jalr	a5
          if (r != 0) {
ffffffffc02019bc:	e12d                	bnez	a0,ffffffffc0201a1e <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc02019be:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02019c0:	01893503          	ld	a0,24(s2)
ffffffffc02019c4:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc02019c6:	63a4                	ld	s1,64(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02019c8:	85a6                	mv	a1,s1
ffffffffc02019ca:	012010ef          	jal	ra,ffffffffc02029dc <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc02019ce:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02019d0:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc02019d2:	8b85                	andi	a5,a5,1
ffffffffc02019d4:	cfb9                	beqz	a5,ffffffffc0201a32 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc02019d6:	65a2                	ld	a1,8(sp)
ffffffffc02019d8:	61bc                	ld	a5,64(a1)
ffffffffc02019da:	83b1                	srli	a5,a5,0xc
ffffffffc02019dc:	00178513          	addi	a0,a5,1
ffffffffc02019e0:	0522                	slli	a0,a0,0x8
ffffffffc02019e2:	0d2020ef          	jal	ra,ffffffffc0203ab4 <swapfs_write>
ffffffffc02019e6:	d949                	beqz	a0,ffffffffc0201978 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc02019e8:	855e                	mv	a0,s7
ffffffffc02019ea:	ed4fe0ef          	jal	ra,ffffffffc02000be <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02019ee:	0009b783          	ld	a5,0(s3)
ffffffffc02019f2:	6622                	ld	a2,8(sp)
ffffffffc02019f4:	4681                	li	a3,0
ffffffffc02019f6:	739c                	ld	a5,32(a5)
ffffffffc02019f8:	85a6                	mv	a1,s1
ffffffffc02019fa:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc02019fc:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02019fe:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0201a00:	fa8a17e3          	bne	s4,s0,ffffffffc02019ae <swap_out+0x70>
}
ffffffffc0201a04:	8522                	mv	a0,s0
ffffffffc0201a06:	60e6                	ld	ra,88(sp)
ffffffffc0201a08:	6446                	ld	s0,80(sp)
ffffffffc0201a0a:	64a6                	ld	s1,72(sp)
ffffffffc0201a0c:	6906                	ld	s2,64(sp)
ffffffffc0201a0e:	79e2                	ld	s3,56(sp)
ffffffffc0201a10:	7a42                	ld	s4,48(sp)
ffffffffc0201a12:	7aa2                	ld	s5,40(sp)
ffffffffc0201a14:	7b02                	ld	s6,32(sp)
ffffffffc0201a16:	6be2                	ld	s7,24(sp)
ffffffffc0201a18:	6c42                	ld	s8,16(sp)
ffffffffc0201a1a:	6125                	addi	sp,sp,96
ffffffffc0201a1c:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0201a1e:	85a2                	mv	a1,s0
ffffffffc0201a20:	00003517          	auipc	a0,0x3
ffffffffc0201a24:	6a850513          	addi	a0,a0,1704 # ffffffffc02050c8 <commands+0xea8>
ffffffffc0201a28:	e96fe0ef          	jal	ra,ffffffffc02000be <cprintf>
                  break;
ffffffffc0201a2c:	bfe1                	j	ffffffffc0201a04 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0201a2e:	4401                	li	s0,0
ffffffffc0201a30:	bfd1                	j	ffffffffc0201a04 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0201a32:	00003697          	auipc	a3,0x3
ffffffffc0201a36:	6c668693          	addi	a3,a3,1734 # ffffffffc02050f8 <commands+0xed8>
ffffffffc0201a3a:	00003617          	auipc	a2,0x3
ffffffffc0201a3e:	03e60613          	addi	a2,a2,62 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201a42:	06600593          	li	a1,102
ffffffffc0201a46:	00003517          	auipc	a0,0x3
ffffffffc0201a4a:	3c250513          	addi	a0,a0,962 # ffffffffc0204e08 <commands+0xbe8>
ffffffffc0201a4e:	eb8fe0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0201a52 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc0201a52:	0000f797          	auipc	a5,0xf
ffffffffc0201a56:	afe78793          	addi	a5,a5,-1282 # ffffffffc0210550 <free_area>
ffffffffc0201a5a:	e79c                	sd	a5,8(a5)
ffffffffc0201a5c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0201a5e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0201a62:	8082                	ret

ffffffffc0201a64 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0201a64:	0000f517          	auipc	a0,0xf
ffffffffc0201a68:	afc56503          	lwu	a0,-1284(a0) # ffffffffc0210560 <free_area+0x10>
ffffffffc0201a6c:	8082                	ret

ffffffffc0201a6e <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0201a6e:	715d                	addi	sp,sp,-80
ffffffffc0201a70:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc0201a72:	0000f917          	auipc	s2,0xf
ffffffffc0201a76:	ade90913          	addi	s2,s2,-1314 # ffffffffc0210550 <free_area>
ffffffffc0201a7a:	00893783          	ld	a5,8(s2)
ffffffffc0201a7e:	e486                	sd	ra,72(sp)
ffffffffc0201a80:	e0a2                	sd	s0,64(sp)
ffffffffc0201a82:	fc26                	sd	s1,56(sp)
ffffffffc0201a84:	f44e                	sd	s3,40(sp)
ffffffffc0201a86:	f052                	sd	s4,32(sp)
ffffffffc0201a88:	ec56                	sd	s5,24(sp)
ffffffffc0201a8a:	e85a                	sd	s6,16(sp)
ffffffffc0201a8c:	e45e                	sd	s7,8(sp)
ffffffffc0201a8e:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201a90:	31278f63          	beq	a5,s2,ffffffffc0201dae <default_check+0x340>
ffffffffc0201a94:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201a98:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201a9a:	8b05                	andi	a4,a4,1
ffffffffc0201a9c:	30070d63          	beqz	a4,ffffffffc0201db6 <default_check+0x348>
    int count = 0, total = 0;
ffffffffc0201aa0:	4401                	li	s0,0
ffffffffc0201aa2:	4481                	li	s1,0
ffffffffc0201aa4:	a031                	j	ffffffffc0201ab0 <default_check+0x42>
ffffffffc0201aa6:	fe87b703          	ld	a4,-24(a5)
        assert(PageProperty(p));
ffffffffc0201aaa:	8b09                	andi	a4,a4,2
ffffffffc0201aac:	30070563          	beqz	a4,ffffffffc0201db6 <default_check+0x348>
        count ++, total += p->property;
ffffffffc0201ab0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201ab4:	679c                	ld	a5,8(a5)
ffffffffc0201ab6:	2485                	addiw	s1,s1,1
ffffffffc0201ab8:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201aba:	ff2796e3          	bne	a5,s2,ffffffffc0201aa6 <default_check+0x38>
ffffffffc0201abe:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0201ac0:	6dd000ef          	jal	ra,ffffffffc020299c <nr_free_pages>
ffffffffc0201ac4:	75351963          	bne	a0,s3,ffffffffc0202216 <default_check+0x7a8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201ac8:	4505                	li	a0,1
ffffffffc0201aca:	605000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201ace:	8a2a                	mv	s4,a0
ffffffffc0201ad0:	48050363          	beqz	a0,ffffffffc0201f56 <default_check+0x4e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201ad4:	4505                	li	a0,1
ffffffffc0201ad6:	5f9000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201ada:	89aa                	mv	s3,a0
ffffffffc0201adc:	74050d63          	beqz	a0,ffffffffc0202236 <default_check+0x7c8>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201ae0:	4505                	li	a0,1
ffffffffc0201ae2:	5ed000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201ae6:	8aaa                	mv	s5,a0
ffffffffc0201ae8:	4e050763          	beqz	a0,ffffffffc0201fd6 <default_check+0x568>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201aec:	2f3a0563          	beq	s4,s3,ffffffffc0201dd6 <default_check+0x368>
ffffffffc0201af0:	2eaa0363          	beq	s4,a0,ffffffffc0201dd6 <default_check+0x368>
ffffffffc0201af4:	2ea98163          	beq	s3,a0,ffffffffc0201dd6 <default_check+0x368>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201af8:	000a2783          	lw	a5,0(s4)
ffffffffc0201afc:	2e079d63          	bnez	a5,ffffffffc0201df6 <default_check+0x388>
ffffffffc0201b00:	0009a783          	lw	a5,0(s3)
ffffffffc0201b04:	2e079963          	bnez	a5,ffffffffc0201df6 <default_check+0x388>
ffffffffc0201b08:	411c                	lw	a5,0(a0)
ffffffffc0201b0a:	2e079663          	bnez	a5,ffffffffc0201df6 <default_check+0x388>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201b0e:	0000f797          	auipc	a5,0xf
ffffffffc0201b12:	a7a78793          	addi	a5,a5,-1414 # ffffffffc0210588 <pages>
ffffffffc0201b16:	639c                	ld	a5,0(a5)
ffffffffc0201b18:	00003717          	auipc	a4,0x3
ffffffffc0201b1c:	65070713          	addi	a4,a4,1616 # ffffffffc0205168 <commands+0xf48>
ffffffffc0201b20:	630c                	ld	a1,0(a4)
ffffffffc0201b22:	40fa0733          	sub	a4,s4,a5
ffffffffc0201b26:	870d                	srai	a4,a4,0x3
ffffffffc0201b28:	02b70733          	mul	a4,a4,a1
ffffffffc0201b2c:	00004697          	auipc	a3,0x4
ffffffffc0201b30:	33c68693          	addi	a3,a3,828 # ffffffffc0205e68 <nbase>
ffffffffc0201b34:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201b36:	0000f697          	auipc	a3,0xf
ffffffffc0201b3a:	93a68693          	addi	a3,a3,-1734 # ffffffffc0210470 <npage>
ffffffffc0201b3e:	6294                	ld	a3,0(a3)
ffffffffc0201b40:	06b2                	slli	a3,a3,0xc
ffffffffc0201b42:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b44:	0732                	slli	a4,a4,0xc
ffffffffc0201b46:	2cd77863          	bleu	a3,a4,ffffffffc0201e16 <default_check+0x3a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201b4a:	40f98733          	sub	a4,s3,a5
ffffffffc0201b4e:	870d                	srai	a4,a4,0x3
ffffffffc0201b50:	02b70733          	mul	a4,a4,a1
ffffffffc0201b54:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b56:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201b58:	4ed77f63          	bleu	a3,a4,ffffffffc0202056 <default_check+0x5e8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201b5c:	40f507b3          	sub	a5,a0,a5
ffffffffc0201b60:	878d                	srai	a5,a5,0x3
ffffffffc0201b62:	02b787b3          	mul	a5,a5,a1
ffffffffc0201b66:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b68:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201b6a:	34d7f663          	bleu	a3,a5,ffffffffc0201eb6 <default_check+0x448>
    assert(alloc_page() == NULL);
ffffffffc0201b6e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201b70:	00093c03          	ld	s8,0(s2)
ffffffffc0201b74:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0201b78:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0201b7c:	0000f797          	auipc	a5,0xf
ffffffffc0201b80:	9d27be23          	sd	s2,-1572(a5) # ffffffffc0210558 <free_area+0x8>
ffffffffc0201b84:	0000f797          	auipc	a5,0xf
ffffffffc0201b88:	9d27b623          	sd	s2,-1588(a5) # ffffffffc0210550 <free_area>
    nr_free = 0;
ffffffffc0201b8c:	0000f797          	auipc	a5,0xf
ffffffffc0201b90:	9c07aa23          	sw	zero,-1580(a5) # ffffffffc0210560 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201b94:	53b000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201b98:	2e051f63          	bnez	a0,ffffffffc0201e96 <default_check+0x428>
    free_page(p0);
ffffffffc0201b9c:	4585                	li	a1,1
ffffffffc0201b9e:	8552                	mv	a0,s4
ffffffffc0201ba0:	5b7000ef          	jal	ra,ffffffffc0202956 <free_pages>
    free_page(p1);
ffffffffc0201ba4:	4585                	li	a1,1
ffffffffc0201ba6:	854e                	mv	a0,s3
ffffffffc0201ba8:	5af000ef          	jal	ra,ffffffffc0202956 <free_pages>
    free_page(p2);
ffffffffc0201bac:	4585                	li	a1,1
ffffffffc0201bae:	8556                	mv	a0,s5
ffffffffc0201bb0:	5a7000ef          	jal	ra,ffffffffc0202956 <free_pages>
    assert(nr_free == 3);
ffffffffc0201bb4:	01092703          	lw	a4,16(s2)
ffffffffc0201bb8:	478d                	li	a5,3
ffffffffc0201bba:	2af71e63          	bne	a4,a5,ffffffffc0201e76 <default_check+0x408>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201bbe:	4505                	li	a0,1
ffffffffc0201bc0:	50f000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201bc4:	89aa                	mv	s3,a0
ffffffffc0201bc6:	28050863          	beqz	a0,ffffffffc0201e56 <default_check+0x3e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201bca:	4505                	li	a0,1
ffffffffc0201bcc:	503000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201bd0:	8aaa                	mv	s5,a0
ffffffffc0201bd2:	3e050263          	beqz	a0,ffffffffc0201fb6 <default_check+0x548>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201bd6:	4505                	li	a0,1
ffffffffc0201bd8:	4f7000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201bdc:	8a2a                	mv	s4,a0
ffffffffc0201bde:	3a050c63          	beqz	a0,ffffffffc0201f96 <default_check+0x528>
    assert(alloc_page() == NULL);
ffffffffc0201be2:	4505                	li	a0,1
ffffffffc0201be4:	4eb000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201be8:	38051763          	bnez	a0,ffffffffc0201f76 <default_check+0x508>
    free_page(p0);
ffffffffc0201bec:	4585                	li	a1,1
ffffffffc0201bee:	854e                	mv	a0,s3
ffffffffc0201bf0:	567000ef          	jal	ra,ffffffffc0202956 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201bf4:	00893783          	ld	a5,8(s2)
ffffffffc0201bf8:	23278f63          	beq	a5,s2,ffffffffc0201e36 <default_check+0x3c8>
    assert((p = alloc_page()) == p0);
ffffffffc0201bfc:	4505                	li	a0,1
ffffffffc0201bfe:	4d1000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201c02:	32a99a63          	bne	s3,a0,ffffffffc0201f36 <default_check+0x4c8>
    assert(alloc_page() == NULL);
ffffffffc0201c06:	4505                	li	a0,1
ffffffffc0201c08:	4c7000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201c0c:	30051563          	bnez	a0,ffffffffc0201f16 <default_check+0x4a8>
    assert(nr_free == 0);
ffffffffc0201c10:	01092783          	lw	a5,16(s2)
ffffffffc0201c14:	2e079163          	bnez	a5,ffffffffc0201ef6 <default_check+0x488>
    free_page(p);
ffffffffc0201c18:	854e                	mv	a0,s3
ffffffffc0201c1a:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201c1c:	0000f797          	auipc	a5,0xf
ffffffffc0201c20:	9387ba23          	sd	s8,-1740(a5) # ffffffffc0210550 <free_area>
ffffffffc0201c24:	0000f797          	auipc	a5,0xf
ffffffffc0201c28:	9377ba23          	sd	s7,-1740(a5) # ffffffffc0210558 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0201c2c:	0000f797          	auipc	a5,0xf
ffffffffc0201c30:	9367aa23          	sw	s6,-1740(a5) # ffffffffc0210560 <free_area+0x10>
    free_page(p);
ffffffffc0201c34:	523000ef          	jal	ra,ffffffffc0202956 <free_pages>
    free_page(p1);
ffffffffc0201c38:	4585                	li	a1,1
ffffffffc0201c3a:	8556                	mv	a0,s5
ffffffffc0201c3c:	51b000ef          	jal	ra,ffffffffc0202956 <free_pages>
    free_page(p2);
ffffffffc0201c40:	4585                	li	a1,1
ffffffffc0201c42:	8552                	mv	a0,s4
ffffffffc0201c44:	513000ef          	jal	ra,ffffffffc0202956 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201c48:	4515                	li	a0,5
ffffffffc0201c4a:	485000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201c4e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201c50:	28050363          	beqz	a0,ffffffffc0201ed6 <default_check+0x468>
ffffffffc0201c54:	651c                	ld	a5,8(a0)
ffffffffc0201c56:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0201c58:	8b85                	andi	a5,a5,1
ffffffffc0201c5a:	54079e63          	bnez	a5,ffffffffc02021b6 <default_check+0x748>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201c5e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201c60:	00093b03          	ld	s6,0(s2)
ffffffffc0201c64:	00893a83          	ld	s5,8(s2)
ffffffffc0201c68:	0000f797          	auipc	a5,0xf
ffffffffc0201c6c:	8f27b423          	sd	s2,-1816(a5) # ffffffffc0210550 <free_area>
ffffffffc0201c70:	0000f797          	auipc	a5,0xf
ffffffffc0201c74:	8f27b423          	sd	s2,-1816(a5) # ffffffffc0210558 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0201c78:	457000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201c7c:	50051d63          	bnez	a0,ffffffffc0202196 <default_check+0x728>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201c80:	09098a13          	addi	s4,s3,144
ffffffffc0201c84:	8552                	mv	a0,s4
ffffffffc0201c86:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201c88:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc0201c8c:	0000f797          	auipc	a5,0xf
ffffffffc0201c90:	8c07aa23          	sw	zero,-1836(a5) # ffffffffc0210560 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201c94:	4c3000ef          	jal	ra,ffffffffc0202956 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201c98:	4511                	li	a0,4
ffffffffc0201c9a:	435000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201c9e:	4c051c63          	bnez	a0,ffffffffc0202176 <default_check+0x708>
ffffffffc0201ca2:	0989b783          	ld	a5,152(s3)
ffffffffc0201ca6:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201ca8:	8b85                	andi	a5,a5,1
ffffffffc0201caa:	4a078663          	beqz	a5,ffffffffc0202156 <default_check+0x6e8>
ffffffffc0201cae:	0a89a703          	lw	a4,168(s3)
ffffffffc0201cb2:	478d                	li	a5,3
ffffffffc0201cb4:	4af71163          	bne	a4,a5,ffffffffc0202156 <default_check+0x6e8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201cb8:	450d                	li	a0,3
ffffffffc0201cba:	415000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201cbe:	8c2a                	mv	s8,a0
ffffffffc0201cc0:	46050b63          	beqz	a0,ffffffffc0202136 <default_check+0x6c8>
    assert(alloc_page() == NULL);
ffffffffc0201cc4:	4505                	li	a0,1
ffffffffc0201cc6:	409000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201cca:	44051663          	bnez	a0,ffffffffc0202116 <default_check+0x6a8>
    assert(p0 + 2 == p1);
ffffffffc0201cce:	438a1463          	bne	s4,s8,ffffffffc02020f6 <default_check+0x688>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201cd2:	4585                	li	a1,1
ffffffffc0201cd4:	854e                	mv	a0,s3
ffffffffc0201cd6:	481000ef          	jal	ra,ffffffffc0202956 <free_pages>
    free_pages(p1, 3);
ffffffffc0201cda:	458d                	li	a1,3
ffffffffc0201cdc:	8552                	mv	a0,s4
ffffffffc0201cde:	479000ef          	jal	ra,ffffffffc0202956 <free_pages>
ffffffffc0201ce2:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201ce6:	04898c13          	addi	s8,s3,72
ffffffffc0201cea:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201cec:	8b85                	andi	a5,a5,1
ffffffffc0201cee:	3e078463          	beqz	a5,ffffffffc02020d6 <default_check+0x668>
ffffffffc0201cf2:	0189a703          	lw	a4,24(s3)
ffffffffc0201cf6:	4785                	li	a5,1
ffffffffc0201cf8:	3cf71f63          	bne	a4,a5,ffffffffc02020d6 <default_check+0x668>
ffffffffc0201cfc:	008a3783          	ld	a5,8(s4)
ffffffffc0201d00:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201d02:	8b85                	andi	a5,a5,1
ffffffffc0201d04:	3a078963          	beqz	a5,ffffffffc02020b6 <default_check+0x648>
ffffffffc0201d08:	018a2703          	lw	a4,24(s4)
ffffffffc0201d0c:	478d                	li	a5,3
ffffffffc0201d0e:	3af71463          	bne	a4,a5,ffffffffc02020b6 <default_check+0x648>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201d12:	4505                	li	a0,1
ffffffffc0201d14:	3bb000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201d18:	36a99f63          	bne	s3,a0,ffffffffc0202096 <default_check+0x628>
    free_page(p0);
ffffffffc0201d1c:	4585                	li	a1,1
ffffffffc0201d1e:	439000ef          	jal	ra,ffffffffc0202956 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201d22:	4509                	li	a0,2
ffffffffc0201d24:	3ab000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201d28:	34aa1763          	bne	s4,a0,ffffffffc0202076 <default_check+0x608>

    free_pages(p0, 2);
ffffffffc0201d2c:	4589                	li	a1,2
ffffffffc0201d2e:	429000ef          	jal	ra,ffffffffc0202956 <free_pages>
    free_page(p2);
ffffffffc0201d32:	4585                	li	a1,1
ffffffffc0201d34:	8562                	mv	a0,s8
ffffffffc0201d36:	421000ef          	jal	ra,ffffffffc0202956 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201d3a:	4515                	li	a0,5
ffffffffc0201d3c:	393000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201d40:	89aa                	mv	s3,a0
ffffffffc0201d42:	48050a63          	beqz	a0,ffffffffc02021d6 <default_check+0x768>
    assert(alloc_page() == NULL);
ffffffffc0201d46:	4505                	li	a0,1
ffffffffc0201d48:	387000ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0201d4c:	2e051563          	bnez	a0,ffffffffc0202036 <default_check+0x5c8>

    assert(nr_free == 0);
ffffffffc0201d50:	01092783          	lw	a5,16(s2)
ffffffffc0201d54:	2c079163          	bnez	a5,ffffffffc0202016 <default_check+0x5a8>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201d58:	4595                	li	a1,5
ffffffffc0201d5a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201d5c:	0000f797          	auipc	a5,0xf
ffffffffc0201d60:	8177a223          	sw	s7,-2044(a5) # ffffffffc0210560 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0201d64:	0000e797          	auipc	a5,0xe
ffffffffc0201d68:	7f67b623          	sd	s6,2028(a5) # ffffffffc0210550 <free_area>
ffffffffc0201d6c:	0000e797          	auipc	a5,0xe
ffffffffc0201d70:	7f57b623          	sd	s5,2028(a5) # ffffffffc0210558 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0201d74:	3e3000ef          	jal	ra,ffffffffc0202956 <free_pages>
    return listelm->next;
ffffffffc0201d78:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201d7c:	01278963          	beq	a5,s2,ffffffffc0201d8e <default_check+0x320>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201d80:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201d84:	679c                	ld	a5,8(a5)
ffffffffc0201d86:	34fd                	addiw	s1,s1,-1
ffffffffc0201d88:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201d8a:	ff279be3          	bne	a5,s2,ffffffffc0201d80 <default_check+0x312>
    }
    assert(count == 0);
ffffffffc0201d8e:	26049463          	bnez	s1,ffffffffc0201ff6 <default_check+0x588>
    assert(total == 0);
ffffffffc0201d92:	46041263          	bnez	s0,ffffffffc02021f6 <default_check+0x788>
}
ffffffffc0201d96:	60a6                	ld	ra,72(sp)
ffffffffc0201d98:	6406                	ld	s0,64(sp)
ffffffffc0201d9a:	74e2                	ld	s1,56(sp)
ffffffffc0201d9c:	7942                	ld	s2,48(sp)
ffffffffc0201d9e:	79a2                	ld	s3,40(sp)
ffffffffc0201da0:	7a02                	ld	s4,32(sp)
ffffffffc0201da2:	6ae2                	ld	s5,24(sp)
ffffffffc0201da4:	6b42                	ld	s6,16(sp)
ffffffffc0201da6:	6ba2                	ld	s7,8(sp)
ffffffffc0201da8:	6c02                	ld	s8,0(sp)
ffffffffc0201daa:	6161                	addi	sp,sp,80
ffffffffc0201dac:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201dae:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201db0:	4401                	li	s0,0
ffffffffc0201db2:	4481                	li	s1,0
ffffffffc0201db4:	b331                	j	ffffffffc0201ac0 <default_check+0x52>
        assert(PageProperty(p));
ffffffffc0201db6:	00003697          	auipc	a3,0x3
ffffffffc0201dba:	07a68693          	addi	a3,a3,122 # ffffffffc0204e30 <commands+0xc10>
ffffffffc0201dbe:	00003617          	auipc	a2,0x3
ffffffffc0201dc2:	cba60613          	addi	a2,a2,-838 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201dc6:	0f000593          	li	a1,240
ffffffffc0201dca:	00003517          	auipc	a0,0x3
ffffffffc0201dce:	3a650513          	addi	a0,a0,934 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201dd2:	b34fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201dd6:	00003697          	auipc	a3,0x3
ffffffffc0201dda:	41268693          	addi	a3,a3,1042 # ffffffffc02051e8 <commands+0xfc8>
ffffffffc0201dde:	00003617          	auipc	a2,0x3
ffffffffc0201de2:	c9a60613          	addi	a2,a2,-870 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201de6:	0bd00593          	li	a1,189
ffffffffc0201dea:	00003517          	auipc	a0,0x3
ffffffffc0201dee:	38650513          	addi	a0,a0,902 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201df2:	b14fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201df6:	00003697          	auipc	a3,0x3
ffffffffc0201dfa:	41a68693          	addi	a3,a3,1050 # ffffffffc0205210 <commands+0xff0>
ffffffffc0201dfe:	00003617          	auipc	a2,0x3
ffffffffc0201e02:	c7a60613          	addi	a2,a2,-902 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201e06:	0be00593          	li	a1,190
ffffffffc0201e0a:	00003517          	auipc	a0,0x3
ffffffffc0201e0e:	36650513          	addi	a0,a0,870 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201e12:	af4fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201e16:	00003697          	auipc	a3,0x3
ffffffffc0201e1a:	43a68693          	addi	a3,a3,1082 # ffffffffc0205250 <commands+0x1030>
ffffffffc0201e1e:	00003617          	auipc	a2,0x3
ffffffffc0201e22:	c5a60613          	addi	a2,a2,-934 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201e26:	0c000593          	li	a1,192
ffffffffc0201e2a:	00003517          	auipc	a0,0x3
ffffffffc0201e2e:	34650513          	addi	a0,a0,838 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201e32:	ad4fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201e36:	00003697          	auipc	a3,0x3
ffffffffc0201e3a:	4a268693          	addi	a3,a3,1186 # ffffffffc02052d8 <commands+0x10b8>
ffffffffc0201e3e:	00003617          	auipc	a2,0x3
ffffffffc0201e42:	c3a60613          	addi	a2,a2,-966 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201e46:	0d900593          	li	a1,217
ffffffffc0201e4a:	00003517          	auipc	a0,0x3
ffffffffc0201e4e:	32650513          	addi	a0,a0,806 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201e52:	ab4fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201e56:	00003697          	auipc	a3,0x3
ffffffffc0201e5a:	33268693          	addi	a3,a3,818 # ffffffffc0205188 <commands+0xf68>
ffffffffc0201e5e:	00003617          	auipc	a2,0x3
ffffffffc0201e62:	c1a60613          	addi	a2,a2,-998 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201e66:	0d200593          	li	a1,210
ffffffffc0201e6a:	00003517          	auipc	a0,0x3
ffffffffc0201e6e:	30650513          	addi	a0,a0,774 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201e72:	a94fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free == 3);
ffffffffc0201e76:	00003697          	auipc	a3,0x3
ffffffffc0201e7a:	45268693          	addi	a3,a3,1106 # ffffffffc02052c8 <commands+0x10a8>
ffffffffc0201e7e:	00003617          	auipc	a2,0x3
ffffffffc0201e82:	bfa60613          	addi	a2,a2,-1030 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201e86:	0d000593          	li	a1,208
ffffffffc0201e8a:	00003517          	auipc	a0,0x3
ffffffffc0201e8e:	2e650513          	addi	a0,a0,742 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201e92:	a74fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201e96:	00003697          	auipc	a3,0x3
ffffffffc0201e9a:	41a68693          	addi	a3,a3,1050 # ffffffffc02052b0 <commands+0x1090>
ffffffffc0201e9e:	00003617          	auipc	a2,0x3
ffffffffc0201ea2:	bda60613          	addi	a2,a2,-1062 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201ea6:	0cb00593          	li	a1,203
ffffffffc0201eaa:	00003517          	auipc	a0,0x3
ffffffffc0201eae:	2c650513          	addi	a0,a0,710 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201eb2:	a54fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201eb6:	00003697          	auipc	a3,0x3
ffffffffc0201eba:	3da68693          	addi	a3,a3,986 # ffffffffc0205290 <commands+0x1070>
ffffffffc0201ebe:	00003617          	auipc	a2,0x3
ffffffffc0201ec2:	bba60613          	addi	a2,a2,-1094 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201ec6:	0c200593          	li	a1,194
ffffffffc0201eca:	00003517          	auipc	a0,0x3
ffffffffc0201ece:	2a650513          	addi	a0,a0,678 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201ed2:	a34fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(p0 != NULL);
ffffffffc0201ed6:	00003697          	auipc	a3,0x3
ffffffffc0201eda:	43a68693          	addi	a3,a3,1082 # ffffffffc0205310 <commands+0x10f0>
ffffffffc0201ede:	00003617          	auipc	a2,0x3
ffffffffc0201ee2:	b9a60613          	addi	a2,a2,-1126 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201ee6:	0f800593          	li	a1,248
ffffffffc0201eea:	00003517          	auipc	a0,0x3
ffffffffc0201eee:	28650513          	addi	a0,a0,646 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201ef2:	a14fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free == 0);
ffffffffc0201ef6:	00003697          	auipc	a3,0x3
ffffffffc0201efa:	0ea68693          	addi	a3,a3,234 # ffffffffc0204fe0 <commands+0xdc0>
ffffffffc0201efe:	00003617          	auipc	a2,0x3
ffffffffc0201f02:	b7a60613          	addi	a2,a2,-1158 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201f06:	0df00593          	li	a1,223
ffffffffc0201f0a:	00003517          	auipc	a0,0x3
ffffffffc0201f0e:	26650513          	addi	a0,a0,614 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201f12:	9f4fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201f16:	00003697          	auipc	a3,0x3
ffffffffc0201f1a:	39a68693          	addi	a3,a3,922 # ffffffffc02052b0 <commands+0x1090>
ffffffffc0201f1e:	00003617          	auipc	a2,0x3
ffffffffc0201f22:	b5a60613          	addi	a2,a2,-1190 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201f26:	0dd00593          	li	a1,221
ffffffffc0201f2a:	00003517          	auipc	a0,0x3
ffffffffc0201f2e:	24650513          	addi	a0,a0,582 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201f32:	9d4fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201f36:	00003697          	auipc	a3,0x3
ffffffffc0201f3a:	3ba68693          	addi	a3,a3,954 # ffffffffc02052f0 <commands+0x10d0>
ffffffffc0201f3e:	00003617          	auipc	a2,0x3
ffffffffc0201f42:	b3a60613          	addi	a2,a2,-1222 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201f46:	0dc00593          	li	a1,220
ffffffffc0201f4a:	00003517          	auipc	a0,0x3
ffffffffc0201f4e:	22650513          	addi	a0,a0,550 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201f52:	9b4fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201f56:	00003697          	auipc	a3,0x3
ffffffffc0201f5a:	23268693          	addi	a3,a3,562 # ffffffffc0205188 <commands+0xf68>
ffffffffc0201f5e:	00003617          	auipc	a2,0x3
ffffffffc0201f62:	b1a60613          	addi	a2,a2,-1254 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201f66:	0b900593          	li	a1,185
ffffffffc0201f6a:	00003517          	auipc	a0,0x3
ffffffffc0201f6e:	20650513          	addi	a0,a0,518 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201f72:	994fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201f76:	00003697          	auipc	a3,0x3
ffffffffc0201f7a:	33a68693          	addi	a3,a3,826 # ffffffffc02052b0 <commands+0x1090>
ffffffffc0201f7e:	00003617          	auipc	a2,0x3
ffffffffc0201f82:	afa60613          	addi	a2,a2,-1286 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201f86:	0d600593          	li	a1,214
ffffffffc0201f8a:	00003517          	auipc	a0,0x3
ffffffffc0201f8e:	1e650513          	addi	a0,a0,486 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201f92:	974fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201f96:	00003697          	auipc	a3,0x3
ffffffffc0201f9a:	23268693          	addi	a3,a3,562 # ffffffffc02051c8 <commands+0xfa8>
ffffffffc0201f9e:	00003617          	auipc	a2,0x3
ffffffffc0201fa2:	ada60613          	addi	a2,a2,-1318 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201fa6:	0d400593          	li	a1,212
ffffffffc0201faa:	00003517          	auipc	a0,0x3
ffffffffc0201fae:	1c650513          	addi	a0,a0,454 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201fb2:	954fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201fb6:	00003697          	auipc	a3,0x3
ffffffffc0201fba:	1f268693          	addi	a3,a3,498 # ffffffffc02051a8 <commands+0xf88>
ffffffffc0201fbe:	00003617          	auipc	a2,0x3
ffffffffc0201fc2:	aba60613          	addi	a2,a2,-1350 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201fc6:	0d300593          	li	a1,211
ffffffffc0201fca:	00003517          	auipc	a0,0x3
ffffffffc0201fce:	1a650513          	addi	a0,a0,422 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201fd2:	934fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201fd6:	00003697          	auipc	a3,0x3
ffffffffc0201fda:	1f268693          	addi	a3,a3,498 # ffffffffc02051c8 <commands+0xfa8>
ffffffffc0201fde:	00003617          	auipc	a2,0x3
ffffffffc0201fe2:	a9a60613          	addi	a2,a2,-1382 # ffffffffc0204a78 <commands+0x858>
ffffffffc0201fe6:	0bb00593          	li	a1,187
ffffffffc0201fea:	00003517          	auipc	a0,0x3
ffffffffc0201fee:	18650513          	addi	a0,a0,390 # ffffffffc0205170 <commands+0xf50>
ffffffffc0201ff2:	914fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(count == 0);
ffffffffc0201ff6:	00003697          	auipc	a3,0x3
ffffffffc0201ffa:	46a68693          	addi	a3,a3,1130 # ffffffffc0205460 <commands+0x1240>
ffffffffc0201ffe:	00003617          	auipc	a2,0x3
ffffffffc0202002:	a7a60613          	addi	a2,a2,-1414 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202006:	12500593          	li	a1,293
ffffffffc020200a:	00003517          	auipc	a0,0x3
ffffffffc020200e:	16650513          	addi	a0,a0,358 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202012:	8f4fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free == 0);
ffffffffc0202016:	00003697          	auipc	a3,0x3
ffffffffc020201a:	fca68693          	addi	a3,a3,-54 # ffffffffc0204fe0 <commands+0xdc0>
ffffffffc020201e:	00003617          	auipc	a2,0x3
ffffffffc0202022:	a5a60613          	addi	a2,a2,-1446 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202026:	11a00593          	li	a1,282
ffffffffc020202a:	00003517          	auipc	a0,0x3
ffffffffc020202e:	14650513          	addi	a0,a0,326 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202032:	8d4fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202036:	00003697          	auipc	a3,0x3
ffffffffc020203a:	27a68693          	addi	a3,a3,634 # ffffffffc02052b0 <commands+0x1090>
ffffffffc020203e:	00003617          	auipc	a2,0x3
ffffffffc0202042:	a3a60613          	addi	a2,a2,-1478 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202046:	11800593          	li	a1,280
ffffffffc020204a:	00003517          	auipc	a0,0x3
ffffffffc020204e:	12650513          	addi	a0,a0,294 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202052:	8b4fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202056:	00003697          	auipc	a3,0x3
ffffffffc020205a:	21a68693          	addi	a3,a3,538 # ffffffffc0205270 <commands+0x1050>
ffffffffc020205e:	00003617          	auipc	a2,0x3
ffffffffc0202062:	a1a60613          	addi	a2,a2,-1510 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202066:	0c100593          	li	a1,193
ffffffffc020206a:	00003517          	auipc	a0,0x3
ffffffffc020206e:	10650513          	addi	a0,a0,262 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202072:	894fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202076:	00003697          	auipc	a3,0x3
ffffffffc020207a:	3aa68693          	addi	a3,a3,938 # ffffffffc0205420 <commands+0x1200>
ffffffffc020207e:	00003617          	auipc	a2,0x3
ffffffffc0202082:	9fa60613          	addi	a2,a2,-1542 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202086:	11200593          	li	a1,274
ffffffffc020208a:	00003517          	auipc	a0,0x3
ffffffffc020208e:	0e650513          	addi	a0,a0,230 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202092:	874fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202096:	00003697          	auipc	a3,0x3
ffffffffc020209a:	36a68693          	addi	a3,a3,874 # ffffffffc0205400 <commands+0x11e0>
ffffffffc020209e:	00003617          	auipc	a2,0x3
ffffffffc02020a2:	9da60613          	addi	a2,a2,-1574 # ffffffffc0204a78 <commands+0x858>
ffffffffc02020a6:	11000593          	li	a1,272
ffffffffc02020aa:	00003517          	auipc	a0,0x3
ffffffffc02020ae:	0c650513          	addi	a0,a0,198 # ffffffffc0205170 <commands+0xf50>
ffffffffc02020b2:	854fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02020b6:	00003697          	auipc	a3,0x3
ffffffffc02020ba:	32268693          	addi	a3,a3,802 # ffffffffc02053d8 <commands+0x11b8>
ffffffffc02020be:	00003617          	auipc	a2,0x3
ffffffffc02020c2:	9ba60613          	addi	a2,a2,-1606 # ffffffffc0204a78 <commands+0x858>
ffffffffc02020c6:	10e00593          	li	a1,270
ffffffffc02020ca:	00003517          	auipc	a0,0x3
ffffffffc02020ce:	0a650513          	addi	a0,a0,166 # ffffffffc0205170 <commands+0xf50>
ffffffffc02020d2:	834fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02020d6:	00003697          	auipc	a3,0x3
ffffffffc02020da:	2da68693          	addi	a3,a3,730 # ffffffffc02053b0 <commands+0x1190>
ffffffffc02020de:	00003617          	auipc	a2,0x3
ffffffffc02020e2:	99a60613          	addi	a2,a2,-1638 # ffffffffc0204a78 <commands+0x858>
ffffffffc02020e6:	10d00593          	li	a1,269
ffffffffc02020ea:	00003517          	auipc	a0,0x3
ffffffffc02020ee:	08650513          	addi	a0,a0,134 # ffffffffc0205170 <commands+0xf50>
ffffffffc02020f2:	814fe0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02020f6:	00003697          	auipc	a3,0x3
ffffffffc02020fa:	2aa68693          	addi	a3,a3,682 # ffffffffc02053a0 <commands+0x1180>
ffffffffc02020fe:	00003617          	auipc	a2,0x3
ffffffffc0202102:	97a60613          	addi	a2,a2,-1670 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202106:	10800593          	li	a1,264
ffffffffc020210a:	00003517          	auipc	a0,0x3
ffffffffc020210e:	06650513          	addi	a0,a0,102 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202112:	ff5fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202116:	00003697          	auipc	a3,0x3
ffffffffc020211a:	19a68693          	addi	a3,a3,410 # ffffffffc02052b0 <commands+0x1090>
ffffffffc020211e:	00003617          	auipc	a2,0x3
ffffffffc0202122:	95a60613          	addi	a2,a2,-1702 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202126:	10700593          	li	a1,263
ffffffffc020212a:	00003517          	auipc	a0,0x3
ffffffffc020212e:	04650513          	addi	a0,a0,70 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202132:	fd5fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202136:	00003697          	auipc	a3,0x3
ffffffffc020213a:	24a68693          	addi	a3,a3,586 # ffffffffc0205380 <commands+0x1160>
ffffffffc020213e:	00003617          	auipc	a2,0x3
ffffffffc0202142:	93a60613          	addi	a2,a2,-1734 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202146:	10600593          	li	a1,262
ffffffffc020214a:	00003517          	auipc	a0,0x3
ffffffffc020214e:	02650513          	addi	a0,a0,38 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202152:	fb5fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202156:	00003697          	auipc	a3,0x3
ffffffffc020215a:	1fa68693          	addi	a3,a3,506 # ffffffffc0205350 <commands+0x1130>
ffffffffc020215e:	00003617          	auipc	a2,0x3
ffffffffc0202162:	91a60613          	addi	a2,a2,-1766 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202166:	10500593          	li	a1,261
ffffffffc020216a:	00003517          	auipc	a0,0x3
ffffffffc020216e:	00650513          	addi	a0,a0,6 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202172:	f95fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0202176:	00003697          	auipc	a3,0x3
ffffffffc020217a:	1c268693          	addi	a3,a3,450 # ffffffffc0205338 <commands+0x1118>
ffffffffc020217e:	00003617          	auipc	a2,0x3
ffffffffc0202182:	8fa60613          	addi	a2,a2,-1798 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202186:	10400593          	li	a1,260
ffffffffc020218a:	00003517          	auipc	a0,0x3
ffffffffc020218e:	fe650513          	addi	a0,a0,-26 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202192:	f75fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202196:	00003697          	auipc	a3,0x3
ffffffffc020219a:	11a68693          	addi	a3,a3,282 # ffffffffc02052b0 <commands+0x1090>
ffffffffc020219e:	00003617          	auipc	a2,0x3
ffffffffc02021a2:	8da60613          	addi	a2,a2,-1830 # ffffffffc0204a78 <commands+0x858>
ffffffffc02021a6:	0fe00593          	li	a1,254
ffffffffc02021aa:	00003517          	auipc	a0,0x3
ffffffffc02021ae:	fc650513          	addi	a0,a0,-58 # ffffffffc0205170 <commands+0xf50>
ffffffffc02021b2:	f55fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(!PageProperty(p0));
ffffffffc02021b6:	00003697          	auipc	a3,0x3
ffffffffc02021ba:	16a68693          	addi	a3,a3,362 # ffffffffc0205320 <commands+0x1100>
ffffffffc02021be:	00003617          	auipc	a2,0x3
ffffffffc02021c2:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0204a78 <commands+0x858>
ffffffffc02021c6:	0f900593          	li	a1,249
ffffffffc02021ca:	00003517          	auipc	a0,0x3
ffffffffc02021ce:	fa650513          	addi	a0,a0,-90 # ffffffffc0205170 <commands+0xf50>
ffffffffc02021d2:	f35fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02021d6:	00003697          	auipc	a3,0x3
ffffffffc02021da:	26a68693          	addi	a3,a3,618 # ffffffffc0205440 <commands+0x1220>
ffffffffc02021de:	00003617          	auipc	a2,0x3
ffffffffc02021e2:	89a60613          	addi	a2,a2,-1894 # ffffffffc0204a78 <commands+0x858>
ffffffffc02021e6:	11700593          	li	a1,279
ffffffffc02021ea:	00003517          	auipc	a0,0x3
ffffffffc02021ee:	f8650513          	addi	a0,a0,-122 # ffffffffc0205170 <commands+0xf50>
ffffffffc02021f2:	f15fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(total == 0);
ffffffffc02021f6:	00003697          	auipc	a3,0x3
ffffffffc02021fa:	27a68693          	addi	a3,a3,634 # ffffffffc0205470 <commands+0x1250>
ffffffffc02021fe:	00003617          	auipc	a2,0x3
ffffffffc0202202:	87a60613          	addi	a2,a2,-1926 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202206:	12600593          	li	a1,294
ffffffffc020220a:	00003517          	auipc	a0,0x3
ffffffffc020220e:	f6650513          	addi	a0,a0,-154 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202212:	ef5fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(total == nr_free_pages());
ffffffffc0202216:	00003697          	auipc	a3,0x3
ffffffffc020221a:	c2a68693          	addi	a3,a3,-982 # ffffffffc0204e40 <commands+0xc20>
ffffffffc020221e:	00003617          	auipc	a2,0x3
ffffffffc0202222:	85a60613          	addi	a2,a2,-1958 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202226:	0f300593          	li	a1,243
ffffffffc020222a:	00003517          	auipc	a0,0x3
ffffffffc020222e:	f4650513          	addi	a0,a0,-186 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202232:	ed5fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202236:	00003697          	auipc	a3,0x3
ffffffffc020223a:	f7268693          	addi	a3,a3,-142 # ffffffffc02051a8 <commands+0xf88>
ffffffffc020223e:	00003617          	auipc	a2,0x3
ffffffffc0202242:	83a60613          	addi	a2,a2,-1990 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202246:	0ba00593          	li	a1,186
ffffffffc020224a:	00003517          	auipc	a0,0x3
ffffffffc020224e:	f2650513          	addi	a0,a0,-218 # ffffffffc0205170 <commands+0xf50>
ffffffffc0202252:	eb5fd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0202256 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0202256:	1141                	addi	sp,sp,-16
ffffffffc0202258:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020225a:	18058063          	beqz	a1,ffffffffc02023da <default_free_pages+0x184>
    for (; p != base + n; p ++) {
ffffffffc020225e:	00359693          	slli	a3,a1,0x3
ffffffffc0202262:	96ae                	add	a3,a3,a1
ffffffffc0202264:	068e                	slli	a3,a3,0x3
ffffffffc0202266:	96aa                	add	a3,a3,a0
ffffffffc0202268:	02d50d63          	beq	a0,a3,ffffffffc02022a2 <default_free_pages+0x4c>
ffffffffc020226c:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020226e:	8b85                	andi	a5,a5,1
ffffffffc0202270:	14079563          	bnez	a5,ffffffffc02023ba <default_free_pages+0x164>
ffffffffc0202274:	651c                	ld	a5,8(a0)
ffffffffc0202276:	8385                	srli	a5,a5,0x1
ffffffffc0202278:	8b85                	andi	a5,a5,1
ffffffffc020227a:	14079063          	bnez	a5,ffffffffc02023ba <default_free_pages+0x164>
ffffffffc020227e:	87aa                	mv	a5,a0
ffffffffc0202280:	a809                	j	ffffffffc0202292 <default_free_pages+0x3c>
ffffffffc0202282:	6798                	ld	a4,8(a5)
ffffffffc0202284:	8b05                	andi	a4,a4,1
ffffffffc0202286:	12071a63          	bnez	a4,ffffffffc02023ba <default_free_pages+0x164>
ffffffffc020228a:	6798                	ld	a4,8(a5)
ffffffffc020228c:	8b09                	andi	a4,a4,2
ffffffffc020228e:	12071663          	bnez	a4,ffffffffc02023ba <default_free_pages+0x164>
        p->flags = 0;
ffffffffc0202292:	0007b423          	sd	zero,8(a5)
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0202296:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020229a:	04878793          	addi	a5,a5,72
ffffffffc020229e:	fed792e3          	bne	a5,a3,ffffffffc0202282 <default_free_pages+0x2c>
    base->property = n;
ffffffffc02022a2:	2581                	sext.w	a1,a1
ffffffffc02022a4:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc02022a6:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02022aa:	4789                	li	a5,2
ffffffffc02022ac:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02022b0:	0000e697          	auipc	a3,0xe
ffffffffc02022b4:	2a068693          	addi	a3,a3,672 # ffffffffc0210550 <free_area>
ffffffffc02022b8:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02022ba:	669c                	ld	a5,8(a3)
ffffffffc02022bc:	9db9                	addw	a1,a1,a4
ffffffffc02022be:	0000e717          	auipc	a4,0xe
ffffffffc02022c2:	2ab72123          	sw	a1,674(a4) # ffffffffc0210560 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc02022c6:	08d78f63          	beq	a5,a3,ffffffffc0202364 <default_free_pages+0x10e>
            struct Page* page = le2page(le, page_link);
ffffffffc02022ca:	fe078713          	addi	a4,a5,-32
ffffffffc02022ce:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02022d0:	4801                	li	a6,0
ffffffffc02022d2:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc02022d6:	00e56a63          	bltu	a0,a4,ffffffffc02022ea <default_free_pages+0x94>
    return listelm->next;
ffffffffc02022da:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02022dc:	02d70563          	beq	a4,a3,ffffffffc0202306 <default_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc02022e0:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02022e2:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc02022e6:	fee57ae3          	bleu	a4,a0,ffffffffc02022da <default_free_pages+0x84>
ffffffffc02022ea:	00080663          	beqz	a6,ffffffffc02022f6 <default_free_pages+0xa0>
ffffffffc02022ee:	0000e817          	auipc	a6,0xe
ffffffffc02022f2:	26b83123          	sd	a1,610(a6) # ffffffffc0210550 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02022f6:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc02022f8:	e390                	sd	a2,0(a5)
ffffffffc02022fa:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc02022fc:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02022fe:	f10c                	sd	a1,32(a0)
    if (le != &free_list) {
ffffffffc0202300:	02d59163          	bne	a1,a3,ffffffffc0202322 <default_free_pages+0xcc>
ffffffffc0202304:	a091                	j	ffffffffc0202348 <default_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc0202306:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202308:	f514                	sd	a3,40(a0)
ffffffffc020230a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020230c:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc020230e:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202310:	00d70563          	beq	a4,a3,ffffffffc020231a <default_free_pages+0xc4>
ffffffffc0202314:	4805                	li	a6,1
ffffffffc0202316:	87ba                	mv	a5,a4
ffffffffc0202318:	b7e9                	j	ffffffffc02022e2 <default_free_pages+0x8c>
ffffffffc020231a:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020231c:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc020231e:	02d78163          	beq	a5,a3,ffffffffc0202340 <default_free_pages+0xea>
        if (p + p->property == base) {
ffffffffc0202322:	ff85a803          	lw	a6,-8(a1) # ff8 <BASE_ADDRESS-0xffffffffc01ff008>
        p = le2page(le, page_link);
ffffffffc0202326:	fe058613          	addi	a2,a1,-32
        if (p + p->property == base) {
ffffffffc020232a:	02081713          	slli	a4,a6,0x20
ffffffffc020232e:	9301                	srli	a4,a4,0x20
ffffffffc0202330:	00371793          	slli	a5,a4,0x3
ffffffffc0202334:	97ba                	add	a5,a5,a4
ffffffffc0202336:	078e                	slli	a5,a5,0x3
ffffffffc0202338:	97b2                	add	a5,a5,a2
ffffffffc020233a:	02f50e63          	beq	a0,a5,ffffffffc0202376 <default_free_pages+0x120>
ffffffffc020233e:	751c                	ld	a5,40(a0)
    if (le != &free_list) {
ffffffffc0202340:	fe078713          	addi	a4,a5,-32
ffffffffc0202344:	00d78d63          	beq	a5,a3,ffffffffc020235e <default_free_pages+0x108>
        if (base + base->property == p) {
ffffffffc0202348:	4d0c                	lw	a1,24(a0)
ffffffffc020234a:	02059613          	slli	a2,a1,0x20
ffffffffc020234e:	9201                	srli	a2,a2,0x20
ffffffffc0202350:	00361693          	slli	a3,a2,0x3
ffffffffc0202354:	96b2                	add	a3,a3,a2
ffffffffc0202356:	068e                	slli	a3,a3,0x3
ffffffffc0202358:	96aa                	add	a3,a3,a0
ffffffffc020235a:	04d70063          	beq	a4,a3,ffffffffc020239a <default_free_pages+0x144>
}
ffffffffc020235e:	60a2                	ld	ra,8(sp)
ffffffffc0202360:	0141                	addi	sp,sp,16
ffffffffc0202362:	8082                	ret
ffffffffc0202364:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0202366:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc020236a:	e398                	sd	a4,0(a5)
ffffffffc020236c:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020236e:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0202370:	f11c                	sd	a5,32(a0)
}
ffffffffc0202372:	0141                	addi	sp,sp,16
ffffffffc0202374:	8082                	ret
            p->property += base->property;
ffffffffc0202376:	4d1c                	lw	a5,24(a0)
ffffffffc0202378:	0107883b          	addw	a6,a5,a6
ffffffffc020237c:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0202380:	57f5                	li	a5,-3
ffffffffc0202382:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202386:	02053803          	ld	a6,32(a0)
ffffffffc020238a:	7518                	ld	a4,40(a0)
            base = p;
ffffffffc020238c:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc020238e:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0202392:	659c                	ld	a5,8(a1)
ffffffffc0202394:	01073023          	sd	a6,0(a4)
ffffffffc0202398:	b765                	j	ffffffffc0202340 <default_free_pages+0xea>
            base->property += p->property;
ffffffffc020239a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020239e:	fe878693          	addi	a3,a5,-24
ffffffffc02023a2:	9db9                	addw	a1,a1,a4
ffffffffc02023a4:	cd0c                	sw	a1,24(a0)
ffffffffc02023a6:	5775                	li	a4,-3
ffffffffc02023a8:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02023ac:	6398                	ld	a4,0(a5)
ffffffffc02023ae:	679c                	ld	a5,8(a5)
}
ffffffffc02023b0:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02023b2:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02023b4:	e398                	sd	a4,0(a5)
ffffffffc02023b6:	0141                	addi	sp,sp,16
ffffffffc02023b8:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02023ba:	00003697          	auipc	a3,0x3
ffffffffc02023be:	0c668693          	addi	a3,a3,198 # ffffffffc0205480 <commands+0x1260>
ffffffffc02023c2:	00002617          	auipc	a2,0x2
ffffffffc02023c6:	6b660613          	addi	a2,a2,1718 # ffffffffc0204a78 <commands+0x858>
ffffffffc02023ca:	08300593          	li	a1,131
ffffffffc02023ce:	00003517          	auipc	a0,0x3
ffffffffc02023d2:	da250513          	addi	a0,a0,-606 # ffffffffc0205170 <commands+0xf50>
ffffffffc02023d6:	d31fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(n > 0);
ffffffffc02023da:	00003697          	auipc	a3,0x3
ffffffffc02023de:	0ce68693          	addi	a3,a3,206 # ffffffffc02054a8 <commands+0x1288>
ffffffffc02023e2:	00002617          	auipc	a2,0x2
ffffffffc02023e6:	69660613          	addi	a2,a2,1686 # ffffffffc0204a78 <commands+0x858>
ffffffffc02023ea:	08000593          	li	a1,128
ffffffffc02023ee:	00003517          	auipc	a0,0x3
ffffffffc02023f2:	d8250513          	addi	a0,a0,-638 # ffffffffc0205170 <commands+0xf50>
ffffffffc02023f6:	d11fd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc02023fa <default_alloc_pages>:
    assert(n > 0);
ffffffffc02023fa:	cd51                	beqz	a0,ffffffffc0202496 <default_alloc_pages+0x9c>
    if (n > nr_free) {
ffffffffc02023fc:	0000e597          	auipc	a1,0xe
ffffffffc0202400:	15458593          	addi	a1,a1,340 # ffffffffc0210550 <free_area>
ffffffffc0202404:	0105a803          	lw	a6,16(a1)
ffffffffc0202408:	862a                	mv	a2,a0
ffffffffc020240a:	02081793          	slli	a5,a6,0x20
ffffffffc020240e:	9381                	srli	a5,a5,0x20
ffffffffc0202410:	00a7ee63          	bltu	a5,a0,ffffffffc020242c <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0202414:	87ae                	mv	a5,a1
ffffffffc0202416:	a801                	j	ffffffffc0202426 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0202418:	ff87a703          	lw	a4,-8(a5)
ffffffffc020241c:	02071693          	slli	a3,a4,0x20
ffffffffc0202420:	9281                	srli	a3,a3,0x20
ffffffffc0202422:	00c6f763          	bleu	a2,a3,ffffffffc0202430 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0202426:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202428:	feb798e3          	bne	a5,a1,ffffffffc0202418 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020242c:	4501                	li	a0,0
}
ffffffffc020242e:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc0202430:	fe078513          	addi	a0,a5,-32
    if (page != NULL) {
ffffffffc0202434:	dd6d                	beqz	a0,ffffffffc020242e <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc0202436:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020243a:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc020243e:	00060e1b          	sext.w	t3,a2
ffffffffc0202442:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0202446:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc020244a:	02d67b63          	bleu	a3,a2,ffffffffc0202480 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc020244e:	00361693          	slli	a3,a2,0x3
ffffffffc0202452:	96b2                	add	a3,a3,a2
ffffffffc0202454:	068e                	slli	a3,a3,0x3
ffffffffc0202456:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0202458:	41c7073b          	subw	a4,a4,t3
ffffffffc020245c:	ce98                	sw	a4,24(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020245e:	00868613          	addi	a2,a3,8
ffffffffc0202462:	4709                	li	a4,2
ffffffffc0202464:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0202468:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020246c:	02068613          	addi	a2,a3,32
    prev->next = next->prev = elm;
ffffffffc0202470:	0105a803          	lw	a6,16(a1)
ffffffffc0202474:	e310                	sd	a2,0(a4)
ffffffffc0202476:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020247a:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc020247c:	0316b023          	sd	a7,32(a3)
        nr_free -= n;
ffffffffc0202480:	41c8083b          	subw	a6,a6,t3
ffffffffc0202484:	0000e717          	auipc	a4,0xe
ffffffffc0202488:	0d072e23          	sw	a6,220(a4) # ffffffffc0210560 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020248c:	5775                	li	a4,-3
ffffffffc020248e:	17a1                	addi	a5,a5,-24
ffffffffc0202490:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0202494:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0202496:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0202498:	00003697          	auipc	a3,0x3
ffffffffc020249c:	01068693          	addi	a3,a3,16 # ffffffffc02054a8 <commands+0x1288>
ffffffffc02024a0:	00002617          	auipc	a2,0x2
ffffffffc02024a4:	5d860613          	addi	a2,a2,1496 # ffffffffc0204a78 <commands+0x858>
ffffffffc02024a8:	06200593          	li	a1,98
ffffffffc02024ac:	00003517          	auipc	a0,0x3
ffffffffc02024b0:	cc450513          	addi	a0,a0,-828 # ffffffffc0205170 <commands+0xf50>
default_alloc_pages(size_t n) {
ffffffffc02024b4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02024b6:	c51fd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc02024ba <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02024ba:	1141                	addi	sp,sp,-16
ffffffffc02024bc:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02024be:	c1fd                	beqz	a1,ffffffffc02025a4 <default_init_memmap+0xea>
    for (; p != base + n; p ++) {
ffffffffc02024c0:	00359693          	slli	a3,a1,0x3
ffffffffc02024c4:	96ae                	add	a3,a3,a1
ffffffffc02024c6:	068e                	slli	a3,a3,0x3
ffffffffc02024c8:	96aa                	add	a3,a3,a0
ffffffffc02024ca:	02d50463          	beq	a0,a3,ffffffffc02024f2 <default_init_memmap+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02024ce:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc02024d0:	87aa                	mv	a5,a0
ffffffffc02024d2:	8b05                	andi	a4,a4,1
ffffffffc02024d4:	e709                	bnez	a4,ffffffffc02024de <default_init_memmap+0x24>
ffffffffc02024d6:	a07d                	j	ffffffffc0202584 <default_init_memmap+0xca>
ffffffffc02024d8:	6798                	ld	a4,8(a5)
ffffffffc02024da:	8b05                	andi	a4,a4,1
ffffffffc02024dc:	c745                	beqz	a4,ffffffffc0202584 <default_init_memmap+0xca>
        p->flags = p->property = 0;
ffffffffc02024de:	0007ac23          	sw	zero,24(a5)
ffffffffc02024e2:	0007b423          	sd	zero,8(a5)
ffffffffc02024e6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02024ea:	04878793          	addi	a5,a5,72
ffffffffc02024ee:	fed795e3          	bne	a5,a3,ffffffffc02024d8 <default_init_memmap+0x1e>
    base->property = n;
ffffffffc02024f2:	2581                	sext.w	a1,a1
ffffffffc02024f4:	cd0c                	sw	a1,24(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02024f6:	4789                	li	a5,2
ffffffffc02024f8:	00850713          	addi	a4,a0,8
ffffffffc02024fc:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0202500:	0000e697          	auipc	a3,0xe
ffffffffc0202504:	05068693          	addi	a3,a3,80 # ffffffffc0210550 <free_area>
ffffffffc0202508:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020250a:	669c                	ld	a5,8(a3)
ffffffffc020250c:	9db9                	addw	a1,a1,a4
ffffffffc020250e:	0000e717          	auipc	a4,0xe
ffffffffc0202512:	04b72923          	sw	a1,82(a4) # ffffffffc0210560 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0202516:	04d78a63          	beq	a5,a3,ffffffffc020256a <default_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc020251a:	fe078713          	addi	a4,a5,-32
ffffffffc020251e:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0202520:	4801                	li	a6,0
ffffffffc0202522:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc0202526:	00e56a63          	bltu	a0,a4,ffffffffc020253a <default_init_memmap+0x80>
    return listelm->next;
ffffffffc020252a:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020252c:	02d70563          	beq	a4,a3,ffffffffc0202556 <default_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202530:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0202532:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0202536:	fee57ae3          	bleu	a4,a0,ffffffffc020252a <default_init_memmap+0x70>
ffffffffc020253a:	00080663          	beqz	a6,ffffffffc0202546 <default_init_memmap+0x8c>
ffffffffc020253e:	0000e717          	auipc	a4,0xe
ffffffffc0202542:	00b73923          	sd	a1,18(a4) # ffffffffc0210550 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0202546:	6398                	ld	a4,0(a5)
}
ffffffffc0202548:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020254a:	e390                	sd	a2,0(a5)
ffffffffc020254c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020254e:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0202550:	f118                	sd	a4,32(a0)
ffffffffc0202552:	0141                	addi	sp,sp,16
ffffffffc0202554:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0202556:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202558:	f514                	sd	a3,40(a0)
ffffffffc020255a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020255c:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc020255e:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202560:	00d70e63          	beq	a4,a3,ffffffffc020257c <default_init_memmap+0xc2>
ffffffffc0202564:	4805                	li	a6,1
ffffffffc0202566:	87ba                	mv	a5,a4
ffffffffc0202568:	b7e9                	j	ffffffffc0202532 <default_init_memmap+0x78>
}
ffffffffc020256a:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020256c:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc0202570:	e398                	sd	a4,0(a5)
ffffffffc0202572:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0202574:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0202576:	f11c                	sd	a5,32(a0)
}
ffffffffc0202578:	0141                	addi	sp,sp,16
ffffffffc020257a:	8082                	ret
ffffffffc020257c:	60a2                	ld	ra,8(sp)
ffffffffc020257e:	e290                	sd	a2,0(a3)
ffffffffc0202580:	0141                	addi	sp,sp,16
ffffffffc0202582:	8082                	ret
        assert(PageReserved(p));
ffffffffc0202584:	00003697          	auipc	a3,0x3
ffffffffc0202588:	f2c68693          	addi	a3,a3,-212 # ffffffffc02054b0 <commands+0x1290>
ffffffffc020258c:	00002617          	auipc	a2,0x2
ffffffffc0202590:	4ec60613          	addi	a2,a2,1260 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202594:	04900593          	li	a1,73
ffffffffc0202598:	00003517          	auipc	a0,0x3
ffffffffc020259c:	bd850513          	addi	a0,a0,-1064 # ffffffffc0205170 <commands+0xf50>
ffffffffc02025a0:	b67fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(n > 0);
ffffffffc02025a4:	00003697          	auipc	a3,0x3
ffffffffc02025a8:	f0468693          	addi	a3,a3,-252 # ffffffffc02054a8 <commands+0x1288>
ffffffffc02025ac:	00002617          	auipc	a2,0x2
ffffffffc02025b0:	4cc60613          	addi	a2,a2,1228 # ffffffffc0204a78 <commands+0x858>
ffffffffc02025b4:	04600593          	li	a1,70
ffffffffc02025b8:	00003517          	auipc	a0,0x3
ffffffffc02025bc:	bb850513          	addi	a0,a0,-1096 # ffffffffc0205170 <commands+0xf50>
ffffffffc02025c0:	b47fd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc02025c4 <_clock_init_mm>:
     // 初始化pra_list_head为空链表
     // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
     // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc02025c4:	4501                	li	a0,0
ffffffffc02025c6:	8082                	ret

ffffffffc02025c8 <_clock_init>:

static int
_clock_init(void)
{
    return 0;
}
ffffffffc02025c8:	4501                	li	a0,0
ffffffffc02025ca:	8082                	ret

ffffffffc02025cc <_clock_set_unswappable>:

static int
_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc02025cc:	4501                	li	a0,0
ffffffffc02025ce:	8082                	ret

ffffffffc02025d0 <_clock_check_swap>:
_clock_check_swap(void) {
ffffffffc02025d0:	1141                	addi	sp,sp,-16
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02025d2:	678d                	lui	a5,0x3
ffffffffc02025d4:	4731                	li	a4,12
_clock_check_swap(void) {
ffffffffc02025d6:	e406                	sd	ra,8(sp)
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02025d8:	00e78023          	sb	a4,0(a5) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc02025dc:	0000e797          	auipc	a5,0xe
ffffffffc02025e0:	e7478793          	addi	a5,a5,-396 # ffffffffc0210450 <pgfault_num>
ffffffffc02025e4:	4398                	lw	a4,0(a5)
ffffffffc02025e6:	4691                	li	a3,4
ffffffffc02025e8:	2701                	sext.w	a4,a4
ffffffffc02025ea:	08d71f63          	bne	a4,a3,ffffffffc0202688 <_clock_check_swap+0xb8>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02025ee:	6685                	lui	a3,0x1
ffffffffc02025f0:	4629                	li	a2,10
ffffffffc02025f2:	00c68023          	sb	a2,0(a3) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
    assert(pgfault_num==4);
ffffffffc02025f6:	4394                	lw	a3,0(a5)
ffffffffc02025f8:	2681                	sext.w	a3,a3
ffffffffc02025fa:	20e69763          	bne	a3,a4,ffffffffc0202808 <_clock_check_swap+0x238>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02025fe:	6711                	lui	a4,0x4
ffffffffc0202600:	4635                	li	a2,13
ffffffffc0202602:	00c70023          	sb	a2,0(a4) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc0202606:	4398                	lw	a4,0(a5)
ffffffffc0202608:	2701                	sext.w	a4,a4
ffffffffc020260a:	1cd71f63          	bne	a4,a3,ffffffffc02027e8 <_clock_check_swap+0x218>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020260e:	6689                	lui	a3,0x2
ffffffffc0202610:	462d                	li	a2,11
ffffffffc0202612:	00c68023          	sb	a2,0(a3) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc0202616:	4394                	lw	a3,0(a5)
ffffffffc0202618:	2681                	sext.w	a3,a3
ffffffffc020261a:	1ae69763          	bne	a3,a4,ffffffffc02027c8 <_clock_check_swap+0x1f8>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc020261e:	6715                	lui	a4,0x5
ffffffffc0202620:	46b9                	li	a3,14
ffffffffc0202622:	00d70023          	sb	a3,0(a4) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc0202626:	4398                	lw	a4,0(a5)
ffffffffc0202628:	4695                	li	a3,5
ffffffffc020262a:	2701                	sext.w	a4,a4
ffffffffc020262c:	16d71e63          	bne	a4,a3,ffffffffc02027a8 <_clock_check_swap+0x1d8>
    assert(pgfault_num==5);
ffffffffc0202630:	4394                	lw	a3,0(a5)
ffffffffc0202632:	2681                	sext.w	a3,a3
ffffffffc0202634:	14e69a63          	bne	a3,a4,ffffffffc0202788 <_clock_check_swap+0x1b8>
    assert(pgfault_num==5);
ffffffffc0202638:	4398                	lw	a4,0(a5)
ffffffffc020263a:	2701                	sext.w	a4,a4
ffffffffc020263c:	12d71663          	bne	a4,a3,ffffffffc0202768 <_clock_check_swap+0x198>
    assert(pgfault_num==5);
ffffffffc0202640:	4394                	lw	a3,0(a5)
ffffffffc0202642:	2681                	sext.w	a3,a3
ffffffffc0202644:	10e69263          	bne	a3,a4,ffffffffc0202748 <_clock_check_swap+0x178>
    assert(pgfault_num==5);
ffffffffc0202648:	4398                	lw	a4,0(a5)
ffffffffc020264a:	2701                	sext.w	a4,a4
ffffffffc020264c:	0cd71e63          	bne	a4,a3,ffffffffc0202728 <_clock_check_swap+0x158>
    assert(pgfault_num==5);
ffffffffc0202650:	4394                	lw	a3,0(a5)
ffffffffc0202652:	2681                	sext.w	a3,a3
ffffffffc0202654:	0ae69a63          	bne	a3,a4,ffffffffc0202708 <_clock_check_swap+0x138>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0202658:	6715                	lui	a4,0x5
ffffffffc020265a:	46b9                	li	a3,14
ffffffffc020265c:	00d70023          	sb	a3,0(a4) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc0202660:	4398                	lw	a4,0(a5)
ffffffffc0202662:	4695                	li	a3,5
ffffffffc0202664:	2701                	sext.w	a4,a4
ffffffffc0202666:	08d71163          	bne	a4,a3,ffffffffc02026e8 <_clock_check_swap+0x118>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc020266a:	6705                	lui	a4,0x1
ffffffffc020266c:	00074683          	lbu	a3,0(a4) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc0202670:	4729                	li	a4,10
ffffffffc0202672:	04e69b63          	bne	a3,a4,ffffffffc02026c8 <_clock_check_swap+0xf8>
    assert(pgfault_num==6);
ffffffffc0202676:	439c                	lw	a5,0(a5)
ffffffffc0202678:	4719                	li	a4,6
ffffffffc020267a:	2781                	sext.w	a5,a5
ffffffffc020267c:	02e79663          	bne	a5,a4,ffffffffc02026a8 <_clock_check_swap+0xd8>
}
ffffffffc0202680:	60a2                	ld	ra,8(sp)
ffffffffc0202682:	4501                	li	a0,0
ffffffffc0202684:	0141                	addi	sp,sp,16
ffffffffc0202686:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0202688:	00003697          	auipc	a3,0x3
ffffffffc020268c:	94868693          	addi	a3,a3,-1720 # ffffffffc0204fd0 <commands+0xdb0>
ffffffffc0202690:	00002617          	auipc	a2,0x2
ffffffffc0202694:	3e860613          	addi	a2,a2,1000 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202698:	07700593          	li	a1,119
ffffffffc020269c:	00003517          	auipc	a0,0x3
ffffffffc02026a0:	e7450513          	addi	a0,a0,-396 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc02026a4:	a63fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==6);
ffffffffc02026a8:	00003697          	auipc	a3,0x3
ffffffffc02026ac:	eb868693          	addi	a3,a3,-328 # ffffffffc0205560 <default_pmm_manager+0xa0>
ffffffffc02026b0:	00002617          	auipc	a2,0x2
ffffffffc02026b4:	3c860613          	addi	a2,a2,968 # ffffffffc0204a78 <commands+0x858>
ffffffffc02026b8:	08e00593          	li	a1,142
ffffffffc02026bc:	00003517          	auipc	a0,0x3
ffffffffc02026c0:	e5450513          	addi	a0,a0,-428 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc02026c4:	a43fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02026c8:	00003697          	auipc	a3,0x3
ffffffffc02026cc:	e7068693          	addi	a3,a3,-400 # ffffffffc0205538 <default_pmm_manager+0x78>
ffffffffc02026d0:	00002617          	auipc	a2,0x2
ffffffffc02026d4:	3a860613          	addi	a2,a2,936 # ffffffffc0204a78 <commands+0x858>
ffffffffc02026d8:	08c00593          	li	a1,140
ffffffffc02026dc:	00003517          	auipc	a0,0x3
ffffffffc02026e0:	e3450513          	addi	a0,a0,-460 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc02026e4:	a23fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==5);
ffffffffc02026e8:	00003697          	auipc	a3,0x3
ffffffffc02026ec:	e4068693          	addi	a3,a3,-448 # ffffffffc0205528 <default_pmm_manager+0x68>
ffffffffc02026f0:	00002617          	auipc	a2,0x2
ffffffffc02026f4:	38860613          	addi	a2,a2,904 # ffffffffc0204a78 <commands+0x858>
ffffffffc02026f8:	08b00593          	li	a1,139
ffffffffc02026fc:	00003517          	auipc	a0,0x3
ffffffffc0202700:	e1450513          	addi	a0,a0,-492 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc0202704:	a03fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==5);
ffffffffc0202708:	00003697          	auipc	a3,0x3
ffffffffc020270c:	e2068693          	addi	a3,a3,-480 # ffffffffc0205528 <default_pmm_manager+0x68>
ffffffffc0202710:	00002617          	auipc	a2,0x2
ffffffffc0202714:	36860613          	addi	a2,a2,872 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202718:	08900593          	li	a1,137
ffffffffc020271c:	00003517          	auipc	a0,0x3
ffffffffc0202720:	df450513          	addi	a0,a0,-524 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc0202724:	9e3fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==5);
ffffffffc0202728:	00003697          	auipc	a3,0x3
ffffffffc020272c:	e0068693          	addi	a3,a3,-512 # ffffffffc0205528 <default_pmm_manager+0x68>
ffffffffc0202730:	00002617          	auipc	a2,0x2
ffffffffc0202734:	34860613          	addi	a2,a2,840 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202738:	08700593          	li	a1,135
ffffffffc020273c:	00003517          	auipc	a0,0x3
ffffffffc0202740:	dd450513          	addi	a0,a0,-556 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc0202744:	9c3fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==5);
ffffffffc0202748:	00003697          	auipc	a3,0x3
ffffffffc020274c:	de068693          	addi	a3,a3,-544 # ffffffffc0205528 <default_pmm_manager+0x68>
ffffffffc0202750:	00002617          	auipc	a2,0x2
ffffffffc0202754:	32860613          	addi	a2,a2,808 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202758:	08500593          	li	a1,133
ffffffffc020275c:	00003517          	auipc	a0,0x3
ffffffffc0202760:	db450513          	addi	a0,a0,-588 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc0202764:	9a3fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==5);
ffffffffc0202768:	00003697          	auipc	a3,0x3
ffffffffc020276c:	dc068693          	addi	a3,a3,-576 # ffffffffc0205528 <default_pmm_manager+0x68>
ffffffffc0202770:	00002617          	auipc	a2,0x2
ffffffffc0202774:	30860613          	addi	a2,a2,776 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202778:	08300593          	li	a1,131
ffffffffc020277c:	00003517          	auipc	a0,0x3
ffffffffc0202780:	d9450513          	addi	a0,a0,-620 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc0202784:	983fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==5);
ffffffffc0202788:	00003697          	auipc	a3,0x3
ffffffffc020278c:	da068693          	addi	a3,a3,-608 # ffffffffc0205528 <default_pmm_manager+0x68>
ffffffffc0202790:	00002617          	auipc	a2,0x2
ffffffffc0202794:	2e860613          	addi	a2,a2,744 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202798:	08100593          	li	a1,129
ffffffffc020279c:	00003517          	auipc	a0,0x3
ffffffffc02027a0:	d7450513          	addi	a0,a0,-652 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc02027a4:	963fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==5);
ffffffffc02027a8:	00003697          	auipc	a3,0x3
ffffffffc02027ac:	d8068693          	addi	a3,a3,-640 # ffffffffc0205528 <default_pmm_manager+0x68>
ffffffffc02027b0:	00002617          	auipc	a2,0x2
ffffffffc02027b4:	2c860613          	addi	a2,a2,712 # ffffffffc0204a78 <commands+0x858>
ffffffffc02027b8:	07f00593          	li	a1,127
ffffffffc02027bc:	00003517          	auipc	a0,0x3
ffffffffc02027c0:	d5450513          	addi	a0,a0,-684 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc02027c4:	943fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==4);
ffffffffc02027c8:	00003697          	auipc	a3,0x3
ffffffffc02027cc:	80868693          	addi	a3,a3,-2040 # ffffffffc0204fd0 <commands+0xdb0>
ffffffffc02027d0:	00002617          	auipc	a2,0x2
ffffffffc02027d4:	2a860613          	addi	a2,a2,680 # ffffffffc0204a78 <commands+0x858>
ffffffffc02027d8:	07d00593          	li	a1,125
ffffffffc02027dc:	00003517          	auipc	a0,0x3
ffffffffc02027e0:	d3450513          	addi	a0,a0,-716 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc02027e4:	923fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==4);
ffffffffc02027e8:	00002697          	auipc	a3,0x2
ffffffffc02027ec:	7e868693          	addi	a3,a3,2024 # ffffffffc0204fd0 <commands+0xdb0>
ffffffffc02027f0:	00002617          	auipc	a2,0x2
ffffffffc02027f4:	28860613          	addi	a2,a2,648 # ffffffffc0204a78 <commands+0x858>
ffffffffc02027f8:	07b00593          	li	a1,123
ffffffffc02027fc:	00003517          	auipc	a0,0x3
ffffffffc0202800:	d1450513          	addi	a0,a0,-748 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc0202804:	903fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pgfault_num==4);
ffffffffc0202808:	00002697          	auipc	a3,0x2
ffffffffc020280c:	7c868693          	addi	a3,a3,1992 # ffffffffc0204fd0 <commands+0xdb0>
ffffffffc0202810:	00002617          	auipc	a2,0x2
ffffffffc0202814:	26860613          	addi	a2,a2,616 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202818:	07900593          	li	a1,121
ffffffffc020281c:	00003517          	auipc	a0,0x3
ffffffffc0202820:	cf450513          	addi	a0,a0,-780 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc0202824:	8e3fd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0202828 <_clock_swap_out_victim>:
         assert(head != NULL);
ffffffffc0202828:	751c                	ld	a5,40(a0)
{
ffffffffc020282a:	1141                	addi	sp,sp,-16
ffffffffc020282c:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc020282e:	c39d                	beqz	a5,ffffffffc0202854 <_clock_swap_out_victim+0x2c>
     assert(in_tick==0);
ffffffffc0202830:	e211                	bnez	a2,ffffffffc0202834 <_clock_swap_out_victim+0xc>
    }
ffffffffc0202832:	a001                	j	ffffffffc0202832 <_clock_swap_out_victim+0xa>
     assert(in_tick==0);
ffffffffc0202834:	00003697          	auipc	a3,0x3
ffffffffc0202838:	d7468693          	addi	a3,a3,-652 # ffffffffc02055a8 <default_pmm_manager+0xe8>
ffffffffc020283c:	00002617          	auipc	a2,0x2
ffffffffc0202840:	23c60613          	addi	a2,a2,572 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202844:	04400593          	li	a1,68
ffffffffc0202848:	00003517          	auipc	a0,0x3
ffffffffc020284c:	cc850513          	addi	a0,a0,-824 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc0202850:	8b7fd0ef          	jal	ra,ffffffffc0200106 <__panic>
         assert(head != NULL);
ffffffffc0202854:	00003697          	auipc	a3,0x3
ffffffffc0202858:	d4468693          	addi	a3,a3,-700 # ffffffffc0205598 <default_pmm_manager+0xd8>
ffffffffc020285c:	00002617          	auipc	a2,0x2
ffffffffc0202860:	21c60613          	addi	a2,a2,540 # ffffffffc0204a78 <commands+0x858>
ffffffffc0202864:	04300593          	li	a1,67
ffffffffc0202868:	00003517          	auipc	a0,0x3
ffffffffc020286c:	ca850513          	addi	a0,a0,-856 # ffffffffc0205510 <default_pmm_manager+0x50>
ffffffffc0202870:	897fd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0202874 <_clock_map_swappable>:
    list_entry_t *entry=&(page->pra_page_link);
ffffffffc0202874:	03060613          	addi	a2,a2,48
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0202878:	ca09                	beqz	a2,ffffffffc020288a <_clock_map_swappable+0x16>
ffffffffc020287a:	0000e797          	auipc	a5,0xe
ffffffffc020287e:	cee78793          	addi	a5,a5,-786 # ffffffffc0210568 <curr_ptr>
ffffffffc0202882:	639c                	ld	a5,0(a5)
ffffffffc0202884:	c399                	beqz	a5,ffffffffc020288a <_clock_map_swappable+0x16>
}
ffffffffc0202886:	4501                	li	a0,0
ffffffffc0202888:	8082                	ret
{
ffffffffc020288a:	1141                	addi	sp,sp,-16
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc020288c:	00003697          	auipc	a3,0x3
ffffffffc0202890:	ce468693          	addi	a3,a3,-796 # ffffffffc0205570 <default_pmm_manager+0xb0>
ffffffffc0202894:	00002617          	auipc	a2,0x2
ffffffffc0202898:	1e460613          	addi	a2,a2,484 # ffffffffc0204a78 <commands+0x858>
ffffffffc020289c:	03300593          	li	a1,51
ffffffffc02028a0:	00003517          	auipc	a0,0x3
ffffffffc02028a4:	c7050513          	addi	a0,a0,-912 # ffffffffc0205510 <default_pmm_manager+0x50>
{
ffffffffc02028a8:	e406                	sd	ra,8(sp)
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc02028aa:	85dfd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc02028ae <_clock_tick_event>:
ffffffffc02028ae:	4501                	li	a0,0
ffffffffc02028b0:	8082                	ret

ffffffffc02028b2 <pa2page.part.4>:
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc02028b2:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc02028b4:	00002617          	auipc	a2,0x2
ffffffffc02028b8:	4bc60613          	addi	a2,a2,1212 # ffffffffc0204d70 <commands+0xb50>
ffffffffc02028bc:	06500593          	li	a1,101
ffffffffc02028c0:	00002517          	auipc	a0,0x2
ffffffffc02028c4:	4d050513          	addi	a0,a0,1232 # ffffffffc0204d90 <commands+0xb70>
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc02028c8:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc02028ca:	83dfd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc02028ce <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc02028ce:	715d                	addi	sp,sp,-80
ffffffffc02028d0:	e0a2                	sd	s0,64(sp)
ffffffffc02028d2:	fc26                	sd	s1,56(sp)
ffffffffc02028d4:	f84a                	sd	s2,48(sp)
ffffffffc02028d6:	f44e                	sd	s3,40(sp)
ffffffffc02028d8:	f052                	sd	s4,32(sp)
ffffffffc02028da:	ec56                	sd	s5,24(sp)
ffffffffc02028dc:	e486                	sd	ra,72(sp)
ffffffffc02028de:	842a                	mv	s0,a0
ffffffffc02028e0:	0000e497          	auipc	s1,0xe
ffffffffc02028e4:	c9048493          	addi	s1,s1,-880 # ffffffffc0210570 <pmm_manager>
    while (1) {
        local_intr_save(intr_flag);
        { page = pmm_manager->alloc_pages(n); }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc02028e8:	4985                	li	s3,1
ffffffffc02028ea:	0000ea17          	auipc	s4,0xe
ffffffffc02028ee:	b76a0a13          	addi	s4,s4,-1162 # ffffffffc0210460 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc02028f2:	0005091b          	sext.w	s2,a0
ffffffffc02028f6:	0000ea97          	auipc	s5,0xe
ffffffffc02028fa:	b8aa8a93          	addi	s5,s5,-1142 # ffffffffc0210480 <check_mm_struct>
ffffffffc02028fe:	a00d                	j	ffffffffc0202920 <alloc_pages+0x52>
        { page = pmm_manager->alloc_pages(n); }
ffffffffc0202900:	609c                	ld	a5,0(s1)
ffffffffc0202902:	6f9c                	ld	a5,24(a5)
ffffffffc0202904:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0);
ffffffffc0202906:	4601                	li	a2,0
ffffffffc0202908:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc020290a:	ed0d                	bnez	a0,ffffffffc0202944 <alloc_pages+0x76>
ffffffffc020290c:	0289ec63          	bltu	s3,s0,ffffffffc0202944 <alloc_pages+0x76>
ffffffffc0202910:	000a2783          	lw	a5,0(s4)
ffffffffc0202914:	2781                	sext.w	a5,a5
ffffffffc0202916:	c79d                	beqz	a5,ffffffffc0202944 <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0);
ffffffffc0202918:	000ab503          	ld	a0,0(s5)
ffffffffc020291c:	822ff0ef          	jal	ra,ffffffffc020193e <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202920:	100027f3          	csrr	a5,sstatus
ffffffffc0202924:	8b89                	andi	a5,a5,2
        { page = pmm_manager->alloc_pages(n); }
ffffffffc0202926:	8522                	mv	a0,s0
ffffffffc0202928:	dfe1                	beqz	a5,ffffffffc0202900 <alloc_pages+0x32>
        intr_disable();
ffffffffc020292a:	badfd0ef          	jal	ra,ffffffffc02004d6 <intr_disable>
ffffffffc020292e:	609c                	ld	a5,0(s1)
ffffffffc0202930:	8522                	mv	a0,s0
ffffffffc0202932:	6f9c                	ld	a5,24(a5)
ffffffffc0202934:	9782                	jalr	a5
ffffffffc0202936:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202938:	b99fd0ef          	jal	ra,ffffffffc02004d0 <intr_enable>
ffffffffc020293c:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0);
ffffffffc020293e:	4601                	li	a2,0
ffffffffc0202940:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0202942:	d569                	beqz	a0,ffffffffc020290c <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0202944:	60a6                	ld	ra,72(sp)
ffffffffc0202946:	6406                	ld	s0,64(sp)
ffffffffc0202948:	74e2                	ld	s1,56(sp)
ffffffffc020294a:	7942                	ld	s2,48(sp)
ffffffffc020294c:	79a2                	ld	s3,40(sp)
ffffffffc020294e:	7a02                	ld	s4,32(sp)
ffffffffc0202950:	6ae2                	ld	s5,24(sp)
ffffffffc0202952:	6161                	addi	sp,sp,80
ffffffffc0202954:	8082                	ret

ffffffffc0202956 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202956:	100027f3          	csrr	a5,sstatus
ffffffffc020295a:	8b89                	andi	a5,a5,2
ffffffffc020295c:	eb89                	bnez	a5,ffffffffc020296e <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;

    local_intr_save(intr_flag);
    { pmm_manager->free_pages(base, n); }
ffffffffc020295e:	0000e797          	auipc	a5,0xe
ffffffffc0202962:	c1278793          	addi	a5,a5,-1006 # ffffffffc0210570 <pmm_manager>
ffffffffc0202966:	639c                	ld	a5,0(a5)
ffffffffc0202968:	0207b303          	ld	t1,32(a5)
ffffffffc020296c:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc020296e:	1101                	addi	sp,sp,-32
ffffffffc0202970:	ec06                	sd	ra,24(sp)
ffffffffc0202972:	e822                	sd	s0,16(sp)
ffffffffc0202974:	e426                	sd	s1,8(sp)
ffffffffc0202976:	842a                	mv	s0,a0
ffffffffc0202978:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020297a:	b5dfd0ef          	jal	ra,ffffffffc02004d6 <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc020297e:	0000e797          	auipc	a5,0xe
ffffffffc0202982:	bf278793          	addi	a5,a5,-1038 # ffffffffc0210570 <pmm_manager>
ffffffffc0202986:	639c                	ld	a5,0(a5)
ffffffffc0202988:	85a6                	mv	a1,s1
ffffffffc020298a:	8522                	mv	a0,s0
ffffffffc020298c:	739c                	ld	a5,32(a5)
ffffffffc020298e:	9782                	jalr	a5
    local_intr_restore(intr_flag);
}
ffffffffc0202990:	6442                	ld	s0,16(sp)
ffffffffc0202992:	60e2                	ld	ra,24(sp)
ffffffffc0202994:	64a2                	ld	s1,8(sp)
ffffffffc0202996:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0202998:	b39fd06f          	j	ffffffffc02004d0 <intr_enable>

ffffffffc020299c <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020299c:	100027f3          	csrr	a5,sstatus
ffffffffc02029a0:	8b89                	andi	a5,a5,2
ffffffffc02029a2:	eb89                	bnez	a5,ffffffffc02029b4 <nr_free_pages+0x18>
// of current free memory
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02029a4:	0000e797          	auipc	a5,0xe
ffffffffc02029a8:	bcc78793          	addi	a5,a5,-1076 # ffffffffc0210570 <pmm_manager>
ffffffffc02029ac:	639c                	ld	a5,0(a5)
ffffffffc02029ae:	0287b303          	ld	t1,40(a5)
ffffffffc02029b2:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc02029b4:	1141                	addi	sp,sp,-16
ffffffffc02029b6:	e406                	sd	ra,8(sp)
ffffffffc02029b8:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02029ba:	b1dfd0ef          	jal	ra,ffffffffc02004d6 <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02029be:	0000e797          	auipc	a5,0xe
ffffffffc02029c2:	bb278793          	addi	a5,a5,-1102 # ffffffffc0210570 <pmm_manager>
ffffffffc02029c6:	639c                	ld	a5,0(a5)
ffffffffc02029c8:	779c                	ld	a5,40(a5)
ffffffffc02029ca:	9782                	jalr	a5
ffffffffc02029cc:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02029ce:	b03fd0ef          	jal	ra,ffffffffc02004d0 <intr_enable>
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02029d2:	8522                	mv	a0,s0
ffffffffc02029d4:	60a2                	ld	ra,8(sp)
ffffffffc02029d6:	6402                	ld	s0,0(sp)
ffffffffc02029d8:	0141                	addi	sp,sp,16
ffffffffc02029da:	8082                	ret

ffffffffc02029dc <get_pte>:
// parameter:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02029dc:	715d                	addi	sp,sp,-80
ffffffffc02029de:	fc26                	sd	s1,56(sp)
     *   PTE_W           0x002                   // page table/directory entry
     * flags bit : Writeable
     *   PTE_U           0x004                   // page table/directory entry
     * flags bit : User can access
     */
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02029e0:	01e5d493          	srli	s1,a1,0x1e
ffffffffc02029e4:	1ff4f493          	andi	s1,s1,511
ffffffffc02029e8:	048e                	slli	s1,s1,0x3
ffffffffc02029ea:	94aa                	add	s1,s1,a0
    if (!(*pdep1 & PTE_V)) {
ffffffffc02029ec:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02029ee:	f84a                	sd	s2,48(sp)
ffffffffc02029f0:	f44e                	sd	s3,40(sp)
ffffffffc02029f2:	f052                	sd	s4,32(sp)
ffffffffc02029f4:	e486                	sd	ra,72(sp)
ffffffffc02029f6:	e0a2                	sd	s0,64(sp)
ffffffffc02029f8:	ec56                	sd	s5,24(sp)
ffffffffc02029fa:	e85a                	sd	s6,16(sp)
ffffffffc02029fc:	e45e                	sd	s7,8(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc02029fe:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0202a02:	892e                	mv	s2,a1
ffffffffc0202a04:	8a32                	mv	s4,a2
ffffffffc0202a06:	0000e997          	auipc	s3,0xe
ffffffffc0202a0a:	a6a98993          	addi	s3,s3,-1430 # ffffffffc0210470 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0202a0e:	e3c9                	bnez	a5,ffffffffc0202a90 <get_pte+0xb4>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0202a10:	16060163          	beqz	a2,ffffffffc0202b72 <get_pte+0x196>
ffffffffc0202a14:	4505                	li	a0,1
ffffffffc0202a16:	eb9ff0ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0202a1a:	842a                	mv	s0,a0
ffffffffc0202a1c:	14050b63          	beqz	a0,ffffffffc0202b72 <get_pte+0x196>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202a20:	0000eb97          	auipc	s7,0xe
ffffffffc0202a24:	b68b8b93          	addi	s7,s7,-1176 # ffffffffc0210588 <pages>
ffffffffc0202a28:	000bb503          	ld	a0,0(s7)
ffffffffc0202a2c:	00002797          	auipc	a5,0x2
ffffffffc0202a30:	73c78793          	addi	a5,a5,1852 # ffffffffc0205168 <commands+0xf48>
ffffffffc0202a34:	0007bb03          	ld	s6,0(a5)
ffffffffc0202a38:	40a40533          	sub	a0,s0,a0
ffffffffc0202a3c:	850d                	srai	a0,a0,0x3
ffffffffc0202a3e:	03650533          	mul	a0,a0,s6
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0202a42:	4785                	li	a5,1
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202a44:	0000e997          	auipc	s3,0xe
ffffffffc0202a48:	a2c98993          	addi	s3,s3,-1492 # ffffffffc0210470 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202a4c:	00080ab7          	lui	s5,0x80
ffffffffc0202a50:	0009b703          	ld	a4,0(s3)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0202a54:	c01c                	sw	a5,0(s0)
ffffffffc0202a56:	57fd                	li	a5,-1
ffffffffc0202a58:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202a5a:	9556                	add	a0,a0,s5
ffffffffc0202a5c:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a5e:	0532                	slli	a0,a0,0xc
ffffffffc0202a60:	16e7f063          	bleu	a4,a5,ffffffffc0202bc0 <get_pte+0x1e4>
ffffffffc0202a64:	0000e797          	auipc	a5,0xe
ffffffffc0202a68:	b1478793          	addi	a5,a5,-1260 # ffffffffc0210578 <va_pa_offset>
ffffffffc0202a6c:	639c                	ld	a5,0(a5)
ffffffffc0202a6e:	6605                	lui	a2,0x1
ffffffffc0202a70:	4581                	li	a1,0
ffffffffc0202a72:	953e                	add	a0,a0,a5
ffffffffc0202a74:	184010ef          	jal	ra,ffffffffc0203bf8 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202a78:	000bb683          	ld	a3,0(s7)
ffffffffc0202a7c:	40d406b3          	sub	a3,s0,a3
ffffffffc0202a80:	868d                	srai	a3,a3,0x3
ffffffffc0202a82:	036686b3          	mul	a3,a3,s6
ffffffffc0202a86:	96d6                	add	a3,a3,s5

static inline void flush_tlb() { asm volatile("sfence.vma"); }

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202a88:	06aa                	slli	a3,a3,0xa
ffffffffc0202a8a:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202a8e:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202a90:	77fd                	lui	a5,0xfffff
ffffffffc0202a92:	068a                	slli	a3,a3,0x2
ffffffffc0202a94:	0009b703          	ld	a4,0(s3)
ffffffffc0202a98:	8efd                	and	a3,a3,a5
ffffffffc0202a9a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202a9e:	0ce7fc63          	bleu	a4,a5,ffffffffc0202b76 <get_pte+0x19a>
ffffffffc0202aa2:	0000ea97          	auipc	s5,0xe
ffffffffc0202aa6:	ad6a8a93          	addi	s5,s5,-1322 # ffffffffc0210578 <va_pa_offset>
ffffffffc0202aaa:	000ab403          	ld	s0,0(s5)
ffffffffc0202aae:	01595793          	srli	a5,s2,0x15
ffffffffc0202ab2:	1ff7f793          	andi	a5,a5,511
ffffffffc0202ab6:	96a2                	add	a3,a3,s0
ffffffffc0202ab8:	00379413          	slli	s0,a5,0x3
ffffffffc0202abc:	9436                	add	s0,s0,a3
//    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
ffffffffc0202abe:	6014                	ld	a3,0(s0)
ffffffffc0202ac0:	0016f793          	andi	a5,a3,1
ffffffffc0202ac4:	ebbd                	bnez	a5,ffffffffc0202b3a <get_pte+0x15e>
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
ffffffffc0202ac6:	0a0a0663          	beqz	s4,ffffffffc0202b72 <get_pte+0x196>
ffffffffc0202aca:	4505                	li	a0,1
ffffffffc0202acc:	e03ff0ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0202ad0:	84aa                	mv	s1,a0
ffffffffc0202ad2:	c145                	beqz	a0,ffffffffc0202b72 <get_pte+0x196>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202ad4:	0000eb97          	auipc	s7,0xe
ffffffffc0202ad8:	ab4b8b93          	addi	s7,s7,-1356 # ffffffffc0210588 <pages>
ffffffffc0202adc:	000bb503          	ld	a0,0(s7)
ffffffffc0202ae0:	00002797          	auipc	a5,0x2
ffffffffc0202ae4:	68878793          	addi	a5,a5,1672 # ffffffffc0205168 <commands+0xf48>
ffffffffc0202ae8:	0007bb03          	ld	s6,0(a5)
ffffffffc0202aec:	40a48533          	sub	a0,s1,a0
ffffffffc0202af0:	850d                	srai	a0,a0,0x3
ffffffffc0202af2:	03650533          	mul	a0,a0,s6
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0202af6:	4785                	li	a5,1
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202af8:	00080a37          	lui	s4,0x80
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202afc:	0009b703          	ld	a4,0(s3)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0202b00:	c09c                	sw	a5,0(s1)
ffffffffc0202b02:	57fd                	li	a5,-1
ffffffffc0202b04:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202b06:	9552                	add	a0,a0,s4
ffffffffc0202b08:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b0a:	0532                	slli	a0,a0,0xc
ffffffffc0202b0c:	08e7fd63          	bleu	a4,a5,ffffffffc0202ba6 <get_pte+0x1ca>
ffffffffc0202b10:	000ab783          	ld	a5,0(s5)
ffffffffc0202b14:	6605                	lui	a2,0x1
ffffffffc0202b16:	4581                	li	a1,0
ffffffffc0202b18:	953e                	add	a0,a0,a5
ffffffffc0202b1a:	0de010ef          	jal	ra,ffffffffc0203bf8 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202b1e:	000bb683          	ld	a3,0(s7)
ffffffffc0202b22:	40d486b3          	sub	a3,s1,a3
ffffffffc0202b26:	868d                	srai	a3,a3,0x3
ffffffffc0202b28:	036686b3          	mul	a3,a3,s6
ffffffffc0202b2c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202b2e:	06aa                	slli	a3,a3,0xa
ffffffffc0202b30:	0116e693          	ori	a3,a3,17
 //   	memset(pa, 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202b34:	e014                	sd	a3,0(s0)
ffffffffc0202b36:	0009b703          	ld	a4,0(s3)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202b3a:	068a                	slli	a3,a3,0x2
ffffffffc0202b3c:	757d                	lui	a0,0xfffff
ffffffffc0202b3e:	8ee9                	and	a3,a3,a0
ffffffffc0202b40:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202b44:	04e7f563          	bleu	a4,a5,ffffffffc0202b8e <get_pte+0x1b2>
ffffffffc0202b48:	000ab503          	ld	a0,0(s5)
ffffffffc0202b4c:	00c95793          	srli	a5,s2,0xc
ffffffffc0202b50:	1ff7f793          	andi	a5,a5,511
ffffffffc0202b54:	96aa                	add	a3,a3,a0
ffffffffc0202b56:	00379513          	slli	a0,a5,0x3
ffffffffc0202b5a:	9536                	add	a0,a0,a3
}
ffffffffc0202b5c:	60a6                	ld	ra,72(sp)
ffffffffc0202b5e:	6406                	ld	s0,64(sp)
ffffffffc0202b60:	74e2                	ld	s1,56(sp)
ffffffffc0202b62:	7942                	ld	s2,48(sp)
ffffffffc0202b64:	79a2                	ld	s3,40(sp)
ffffffffc0202b66:	7a02                	ld	s4,32(sp)
ffffffffc0202b68:	6ae2                	ld	s5,24(sp)
ffffffffc0202b6a:	6b42                	ld	s6,16(sp)
ffffffffc0202b6c:	6ba2                	ld	s7,8(sp)
ffffffffc0202b6e:	6161                	addi	sp,sp,80
ffffffffc0202b70:	8082                	ret
            return NULL;
ffffffffc0202b72:	4501                	li	a0,0
ffffffffc0202b74:	b7e5                	j	ffffffffc0202b5c <get_pte+0x180>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202b76:	00003617          	auipc	a2,0x3
ffffffffc0202b7a:	a5a60613          	addi	a2,a2,-1446 # ffffffffc02055d0 <default_pmm_manager+0x110>
ffffffffc0202b7e:	10200593          	li	a1,258
ffffffffc0202b82:	00003517          	auipc	a0,0x3
ffffffffc0202b86:	a7650513          	addi	a0,a0,-1418 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0202b8a:	d7cfd0ef          	jal	ra,ffffffffc0200106 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202b8e:	00003617          	auipc	a2,0x3
ffffffffc0202b92:	a4260613          	addi	a2,a2,-1470 # ffffffffc02055d0 <default_pmm_manager+0x110>
ffffffffc0202b96:	10f00593          	li	a1,271
ffffffffc0202b9a:	00003517          	auipc	a0,0x3
ffffffffc0202b9e:	a5e50513          	addi	a0,a0,-1442 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0202ba2:	d64fd0ef          	jal	ra,ffffffffc0200106 <__panic>
    	memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202ba6:	86aa                	mv	a3,a0
ffffffffc0202ba8:	00003617          	auipc	a2,0x3
ffffffffc0202bac:	a2860613          	addi	a2,a2,-1496 # ffffffffc02055d0 <default_pmm_manager+0x110>
ffffffffc0202bb0:	10b00593          	li	a1,267
ffffffffc0202bb4:	00003517          	auipc	a0,0x3
ffffffffc0202bb8:	a4450513          	addi	a0,a0,-1468 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0202bbc:	d4afd0ef          	jal	ra,ffffffffc0200106 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202bc0:	86aa                	mv	a3,a0
ffffffffc0202bc2:	00003617          	auipc	a2,0x3
ffffffffc0202bc6:	a0e60613          	addi	a2,a2,-1522 # ffffffffc02055d0 <default_pmm_manager+0x110>
ffffffffc0202bca:	0ff00593          	li	a1,255
ffffffffc0202bce:	00003517          	auipc	a0,0x3
ffffffffc0202bd2:	a2a50513          	addi	a0,a0,-1494 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0202bd6:	d30fd0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0202bda <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0202bda:	1141                	addi	sp,sp,-16
ffffffffc0202bdc:	e022                	sd	s0,0(sp)
ffffffffc0202bde:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202be0:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0202be2:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202be4:	df9ff0ef          	jal	ra,ffffffffc02029dc <get_pte>
    if (ptep_store != NULL) {
ffffffffc0202be8:	c011                	beqz	s0,ffffffffc0202bec <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0202bea:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0202bec:	c521                	beqz	a0,ffffffffc0202c34 <get_page+0x5a>
ffffffffc0202bee:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202bf0:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0202bf2:	0017f713          	andi	a4,a5,1
ffffffffc0202bf6:	e709                	bnez	a4,ffffffffc0202c00 <get_page+0x26>
}
ffffffffc0202bf8:	60a2                	ld	ra,8(sp)
ffffffffc0202bfa:	6402                	ld	s0,0(sp)
ffffffffc0202bfc:	0141                	addi	sp,sp,16
ffffffffc0202bfe:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0202c00:	0000e717          	auipc	a4,0xe
ffffffffc0202c04:	87070713          	addi	a4,a4,-1936 # ffffffffc0210470 <npage>
ffffffffc0202c08:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202c0a:	078a                	slli	a5,a5,0x2
ffffffffc0202c0c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202c0e:	02e7f863          	bleu	a4,a5,ffffffffc0202c3e <get_page+0x64>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c12:	fff80537          	lui	a0,0xfff80
ffffffffc0202c16:	97aa                	add	a5,a5,a0
ffffffffc0202c18:	0000e697          	auipc	a3,0xe
ffffffffc0202c1c:	97068693          	addi	a3,a3,-1680 # ffffffffc0210588 <pages>
ffffffffc0202c20:	6288                	ld	a0,0(a3)
ffffffffc0202c22:	60a2                	ld	ra,8(sp)
ffffffffc0202c24:	6402                	ld	s0,0(sp)
ffffffffc0202c26:	00379713          	slli	a4,a5,0x3
ffffffffc0202c2a:	97ba                	add	a5,a5,a4
ffffffffc0202c2c:	078e                	slli	a5,a5,0x3
ffffffffc0202c2e:	953e                	add	a0,a0,a5
ffffffffc0202c30:	0141                	addi	sp,sp,16
ffffffffc0202c32:	8082                	ret
ffffffffc0202c34:	60a2                	ld	ra,8(sp)
ffffffffc0202c36:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc0202c38:	4501                	li	a0,0
}
ffffffffc0202c3a:	0141                	addi	sp,sp,16
ffffffffc0202c3c:	8082                	ret
ffffffffc0202c3e:	c75ff0ef          	jal	ra,ffffffffc02028b2 <pa2page.part.4>

ffffffffc0202c42 <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202c42:	1141                	addi	sp,sp,-16
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202c44:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202c46:	e406                	sd	ra,8(sp)
ffffffffc0202c48:	e022                	sd	s0,0(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202c4a:	d93ff0ef          	jal	ra,ffffffffc02029dc <get_pte>
    if (ptep != NULL) {
ffffffffc0202c4e:	c511                	beqz	a0,ffffffffc0202c5a <page_remove+0x18>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0202c50:	611c                	ld	a5,0(a0)
ffffffffc0202c52:	842a                	mv	s0,a0
ffffffffc0202c54:	0017f713          	andi	a4,a5,1
ffffffffc0202c58:	e709                	bnez	a4,ffffffffc0202c62 <page_remove+0x20>
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0202c5a:	60a2                	ld	ra,8(sp)
ffffffffc0202c5c:	6402                	ld	s0,0(sp)
ffffffffc0202c5e:	0141                	addi	sp,sp,16
ffffffffc0202c60:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0202c62:	0000e717          	auipc	a4,0xe
ffffffffc0202c66:	80e70713          	addi	a4,a4,-2034 # ffffffffc0210470 <npage>
ffffffffc0202c6a:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202c6c:	078a                	slli	a5,a5,0x2
ffffffffc0202c6e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202c70:	04e7f063          	bleu	a4,a5,ffffffffc0202cb0 <page_remove+0x6e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c74:	fff80737          	lui	a4,0xfff80
ffffffffc0202c78:	97ba                	add	a5,a5,a4
ffffffffc0202c7a:	0000e717          	auipc	a4,0xe
ffffffffc0202c7e:	90e70713          	addi	a4,a4,-1778 # ffffffffc0210588 <pages>
ffffffffc0202c82:	6308                	ld	a0,0(a4)
ffffffffc0202c84:	00379713          	slli	a4,a5,0x3
ffffffffc0202c88:	97ba                	add	a5,a5,a4
ffffffffc0202c8a:	078e                	slli	a5,a5,0x3
ffffffffc0202c8c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202c8e:	411c                	lw	a5,0(a0)
ffffffffc0202c90:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202c94:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202c96:	cb09                	beqz	a4,ffffffffc0202ca8 <page_remove+0x66>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0202c98:	00043023          	sd	zero,0(s0)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0202c9c:	12000073          	sfence.vma
}
ffffffffc0202ca0:	60a2                	ld	ra,8(sp)
ffffffffc0202ca2:	6402                	ld	s0,0(sp)
ffffffffc0202ca4:	0141                	addi	sp,sp,16
ffffffffc0202ca6:	8082                	ret
            free_page(page);
ffffffffc0202ca8:	4585                	li	a1,1
ffffffffc0202caa:	cadff0ef          	jal	ra,ffffffffc0202956 <free_pages>
ffffffffc0202cae:	b7ed                	j	ffffffffc0202c98 <page_remove+0x56>
ffffffffc0202cb0:	c03ff0ef          	jal	ra,ffffffffc02028b2 <pa2page.part.4>

ffffffffc0202cb4 <page_insert>:
//  page:  the Page which need to map
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202cb4:	7179                	addi	sp,sp,-48
ffffffffc0202cb6:	87b2                	mv	a5,a2
ffffffffc0202cb8:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202cba:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202cbc:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202cbe:	85be                	mv	a1,a5
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202cc0:	ec26                	sd	s1,24(sp)
ffffffffc0202cc2:	f406                	sd	ra,40(sp)
ffffffffc0202cc4:	e84a                	sd	s2,16(sp)
ffffffffc0202cc6:	e44e                	sd	s3,8(sp)
ffffffffc0202cc8:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202cca:	d13ff0ef          	jal	ra,ffffffffc02029dc <get_pte>
    if (ptep == NULL) {
ffffffffc0202cce:	c945                	beqz	a0,ffffffffc0202d7e <page_insert+0xca>
    page->ref += 1;
ffffffffc0202cd0:	4014                	lw	a3,0(s0)
        return -E_NO_MEM;
    }
    page_ref_inc(page);
    if (*ptep & PTE_V) {
ffffffffc0202cd2:	611c                	ld	a5,0(a0)
ffffffffc0202cd4:	892a                	mv	s2,a0
ffffffffc0202cd6:	0016871b          	addiw	a4,a3,1
ffffffffc0202cda:	c018                	sw	a4,0(s0)
ffffffffc0202cdc:	0017f713          	andi	a4,a5,1
ffffffffc0202ce0:	e339                	bnez	a4,ffffffffc0202d26 <page_insert+0x72>
ffffffffc0202ce2:	0000e797          	auipc	a5,0xe
ffffffffc0202ce6:	8a678793          	addi	a5,a5,-1882 # ffffffffc0210588 <pages>
ffffffffc0202cea:	639c                	ld	a5,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202cec:	00002717          	auipc	a4,0x2
ffffffffc0202cf0:	47c70713          	addi	a4,a4,1148 # ffffffffc0205168 <commands+0xf48>
ffffffffc0202cf4:	40f407b3          	sub	a5,s0,a5
ffffffffc0202cf8:	6300                	ld	s0,0(a4)
ffffffffc0202cfa:	878d                	srai	a5,a5,0x3
ffffffffc0202cfc:	000806b7          	lui	a3,0x80
ffffffffc0202d00:	028787b3          	mul	a5,a5,s0
ffffffffc0202d04:	97b6                	add	a5,a5,a3
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202d06:	07aa                	slli	a5,a5,0xa
ffffffffc0202d08:	8fc5                	or	a5,a5,s1
ffffffffc0202d0a:	0017e793          	ori	a5,a5,1
            page_ref_dec(page);
        } else {
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202d0e:	00f93023          	sd	a5,0(s2)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0202d12:	12000073          	sfence.vma
    tlb_invalidate(pgdir, la);
    return 0;
ffffffffc0202d16:	4501                	li	a0,0
}
ffffffffc0202d18:	70a2                	ld	ra,40(sp)
ffffffffc0202d1a:	7402                	ld	s0,32(sp)
ffffffffc0202d1c:	64e2                	ld	s1,24(sp)
ffffffffc0202d1e:	6942                	ld	s2,16(sp)
ffffffffc0202d20:	69a2                	ld	s3,8(sp)
ffffffffc0202d22:	6145                	addi	sp,sp,48
ffffffffc0202d24:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0202d26:	0000d717          	auipc	a4,0xd
ffffffffc0202d2a:	74a70713          	addi	a4,a4,1866 # ffffffffc0210470 <npage>
ffffffffc0202d2e:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202d30:	00279513          	slli	a0,a5,0x2
ffffffffc0202d34:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202d36:	04e57663          	bleu	a4,a0,ffffffffc0202d82 <page_insert+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d3a:	fff807b7          	lui	a5,0xfff80
ffffffffc0202d3e:	953e                	add	a0,a0,a5
ffffffffc0202d40:	0000e997          	auipc	s3,0xe
ffffffffc0202d44:	84898993          	addi	s3,s3,-1976 # ffffffffc0210588 <pages>
ffffffffc0202d48:	0009b783          	ld	a5,0(s3)
ffffffffc0202d4c:	00351713          	slli	a4,a0,0x3
ffffffffc0202d50:	953a                	add	a0,a0,a4
ffffffffc0202d52:	050e                	slli	a0,a0,0x3
ffffffffc0202d54:	953e                	add	a0,a0,a5
        if (p == page) {
ffffffffc0202d56:	00a40e63          	beq	s0,a0,ffffffffc0202d72 <page_insert+0xbe>
    page->ref -= 1;
ffffffffc0202d5a:	411c                	lw	a5,0(a0)
ffffffffc0202d5c:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202d60:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202d62:	cb11                	beqz	a4,ffffffffc0202d76 <page_insert+0xc2>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0202d64:	00093023          	sd	zero,0(s2)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0202d68:	12000073          	sfence.vma
ffffffffc0202d6c:	0009b783          	ld	a5,0(s3)
ffffffffc0202d70:	bfb5                	j	ffffffffc0202cec <page_insert+0x38>
    page->ref -= 1;
ffffffffc0202d72:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202d74:	bfa5                	j	ffffffffc0202cec <page_insert+0x38>
            free_page(page);
ffffffffc0202d76:	4585                	li	a1,1
ffffffffc0202d78:	bdfff0ef          	jal	ra,ffffffffc0202956 <free_pages>
ffffffffc0202d7c:	b7e5                	j	ffffffffc0202d64 <page_insert+0xb0>
        return -E_NO_MEM;
ffffffffc0202d7e:	5571                	li	a0,-4
ffffffffc0202d80:	bf61                	j	ffffffffc0202d18 <page_insert+0x64>
ffffffffc0202d82:	b31ff0ef          	jal	ra,ffffffffc02028b2 <pa2page.part.4>

ffffffffc0202d86 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202d86:	00002797          	auipc	a5,0x2
ffffffffc0202d8a:	73a78793          	addi	a5,a5,1850 # ffffffffc02054c0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202d8e:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0202d90:	711d                	addi	sp,sp,-96
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202d92:	00003517          	auipc	a0,0x3
ffffffffc0202d96:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0205660 <default_pmm_manager+0x1a0>
void pmm_init(void) {
ffffffffc0202d9a:	ec86                	sd	ra,88(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202d9c:	0000d717          	auipc	a4,0xd
ffffffffc0202da0:	7cf73a23          	sd	a5,2004(a4) # ffffffffc0210570 <pmm_manager>
void pmm_init(void) {
ffffffffc0202da4:	e8a2                	sd	s0,80(sp)
ffffffffc0202da6:	e4a6                	sd	s1,72(sp)
ffffffffc0202da8:	e0ca                	sd	s2,64(sp)
ffffffffc0202daa:	fc4e                	sd	s3,56(sp)
ffffffffc0202dac:	f852                	sd	s4,48(sp)
ffffffffc0202dae:	f456                	sd	s5,40(sp)
ffffffffc0202db0:	f05a                	sd	s6,32(sp)
ffffffffc0202db2:	ec5e                	sd	s7,24(sp)
ffffffffc0202db4:	e862                	sd	s8,16(sp)
ffffffffc0202db6:	e466                	sd	s9,8(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202db8:	0000d417          	auipc	s0,0xd
ffffffffc0202dbc:	7b840413          	addi	s0,s0,1976 # ffffffffc0210570 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202dc0:	afefd0ef          	jal	ra,ffffffffc02000be <cprintf>
    pmm_manager->init();
ffffffffc0202dc4:	601c                	ld	a5,0(s0)
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0202dc6:	49c5                	li	s3,17
ffffffffc0202dc8:	40100a13          	li	s4,1025
    pmm_manager->init();
ffffffffc0202dcc:	679c                	ld	a5,8(a5)
ffffffffc0202dce:	0000d497          	auipc	s1,0xd
ffffffffc0202dd2:	6a248493          	addi	s1,s1,1698 # ffffffffc0210470 <npage>
ffffffffc0202dd6:	0000d917          	auipc	s2,0xd
ffffffffc0202dda:	7b290913          	addi	s2,s2,1970 # ffffffffc0210588 <pages>
ffffffffc0202dde:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0202de0:	57f5                	li	a5,-3
ffffffffc0202de2:	07fa                	slli	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0202de4:	07e006b7          	lui	a3,0x7e00
ffffffffc0202de8:	01b99613          	slli	a2,s3,0x1b
ffffffffc0202dec:	015a1593          	slli	a1,s4,0x15
ffffffffc0202df0:	00003517          	auipc	a0,0x3
ffffffffc0202df4:	88850513          	addi	a0,a0,-1912 # ffffffffc0205678 <default_pmm_manager+0x1b8>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0202df8:	0000d717          	auipc	a4,0xd
ffffffffc0202dfc:	78f73023          	sd	a5,1920(a4) # ffffffffc0210578 <va_pa_offset>
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0202e00:	abefd0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("physcial memory map:\n");
ffffffffc0202e04:	00003517          	auipc	a0,0x3
ffffffffc0202e08:	8a450513          	addi	a0,a0,-1884 # ffffffffc02056a8 <default_pmm_manager+0x1e8>
ffffffffc0202e0c:	ab2fd0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202e10:	01b99693          	slli	a3,s3,0x1b
ffffffffc0202e14:	16fd                	addi	a3,a3,-1
ffffffffc0202e16:	015a1613          	slli	a2,s4,0x15
ffffffffc0202e1a:	07e005b7          	lui	a1,0x7e00
ffffffffc0202e1e:	00003517          	auipc	a0,0x3
ffffffffc0202e22:	8a250513          	addi	a0,a0,-1886 # ffffffffc02056c0 <default_pmm_manager+0x200>
ffffffffc0202e26:	a98fd0ef          	jal	ra,ffffffffc02000be <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202e2a:	777d                	lui	a4,0xfffff
ffffffffc0202e2c:	0000e797          	auipc	a5,0xe
ffffffffc0202e30:	76378793          	addi	a5,a5,1891 # ffffffffc021158f <end+0xfff>
ffffffffc0202e34:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0202e36:	00088737          	lui	a4,0x88
ffffffffc0202e3a:	0000d697          	auipc	a3,0xd
ffffffffc0202e3e:	62e6bb23          	sd	a4,1590(a3) # ffffffffc0210470 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202e42:	0000d717          	auipc	a4,0xd
ffffffffc0202e46:	74f73323          	sd	a5,1862(a4) # ffffffffc0210588 <pages>
ffffffffc0202e4a:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0202e4c:	4701                	li	a4,0
ffffffffc0202e4e:	4585                	li	a1,1
ffffffffc0202e50:	fff80637          	lui	a2,0xfff80
ffffffffc0202e54:	a019                	j	ffffffffc0202e5a <pmm_init+0xd4>
ffffffffc0202e56:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc0202e5a:	97b6                	add	a5,a5,a3
ffffffffc0202e5c:	07a1                	addi	a5,a5,8
ffffffffc0202e5e:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0202e62:	609c                	ld	a5,0(s1)
ffffffffc0202e64:	0705                	addi	a4,a4,1
ffffffffc0202e66:	04868693          	addi	a3,a3,72
ffffffffc0202e6a:	00c78533          	add	a0,a5,a2
ffffffffc0202e6e:	fea764e3          	bltu	a4,a0,ffffffffc0202e56 <pmm_init+0xd0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202e72:	00093503          	ld	a0,0(s2)
ffffffffc0202e76:	00379693          	slli	a3,a5,0x3
ffffffffc0202e7a:	96be                	add	a3,a3,a5
ffffffffc0202e7c:	fdc00737          	lui	a4,0xfdc00
ffffffffc0202e80:	972a                	add	a4,a4,a0
ffffffffc0202e82:	068e                	slli	a3,a3,0x3
ffffffffc0202e84:	96ba                	add	a3,a3,a4
ffffffffc0202e86:	c0200737          	lui	a4,0xc0200
ffffffffc0202e8a:	58e6ea63          	bltu	a3,a4,ffffffffc020341e <pmm_init+0x698>
ffffffffc0202e8e:	0000d997          	auipc	s3,0xd
ffffffffc0202e92:	6ea98993          	addi	s3,s3,1770 # ffffffffc0210578 <va_pa_offset>
ffffffffc0202e96:	0009b703          	ld	a4,0(s3)
    if (freemem < mem_end) {
ffffffffc0202e9a:	45c5                	li	a1,17
ffffffffc0202e9c:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202e9e:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0202ea0:	44b6ef63          	bltu	a3,a1,ffffffffc02032fe <pmm_init+0x578>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0202ea4:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0202ea6:	0000d417          	auipc	s0,0xd
ffffffffc0202eaa:	5c240413          	addi	s0,s0,1474 # ffffffffc0210468 <boot_pgdir>
    pmm_manager->check();
ffffffffc0202eae:	7b9c                	ld	a5,48(a5)
ffffffffc0202eb0:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202eb2:	00003517          	auipc	a0,0x3
ffffffffc0202eb6:	85e50513          	addi	a0,a0,-1954 # ffffffffc0205710 <default_pmm_manager+0x250>
ffffffffc0202eba:	a04fd0ef          	jal	ra,ffffffffc02000be <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0202ebe:	00005697          	auipc	a3,0x5
ffffffffc0202ec2:	14268693          	addi	a3,a3,322 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0202ec6:	0000d797          	auipc	a5,0xd
ffffffffc0202eca:	5ad7b123          	sd	a3,1442(a5) # ffffffffc0210468 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0202ece:	c02007b7          	lui	a5,0xc0200
ffffffffc0202ed2:	0ef6ece3          	bltu	a3,a5,ffffffffc02037ca <pmm_init+0xa44>
ffffffffc0202ed6:	0009b783          	ld	a5,0(s3)
ffffffffc0202eda:	8e9d                	sub	a3,a3,a5
ffffffffc0202edc:	0000d797          	auipc	a5,0xd
ffffffffc0202ee0:	6ad7b223          	sd	a3,1700(a5) # ffffffffc0210580 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();
ffffffffc0202ee4:	ab9ff0ef          	jal	ra,ffffffffc020299c <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202ee8:	6098                	ld	a4,0(s1)
ffffffffc0202eea:	c80007b7          	lui	a5,0xc8000
ffffffffc0202eee:	83b1                	srli	a5,a5,0xc
    nr_free_store=nr_free_pages();
ffffffffc0202ef0:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202ef2:	0ae7ece3          	bltu	a5,a4,ffffffffc02037aa <pmm_init+0xa24>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202ef6:	6008                	ld	a0,0(s0)
ffffffffc0202ef8:	4c050363          	beqz	a0,ffffffffc02033be <pmm_init+0x638>
ffffffffc0202efc:	6785                	lui	a5,0x1
ffffffffc0202efe:	17fd                	addi	a5,a5,-1
ffffffffc0202f00:	8fe9                	and	a5,a5,a0
ffffffffc0202f02:	2781                	sext.w	a5,a5
ffffffffc0202f04:	4a079d63          	bnez	a5,ffffffffc02033be <pmm_init+0x638>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202f08:	4601                	li	a2,0
ffffffffc0202f0a:	4581                	li	a1,0
ffffffffc0202f0c:	ccfff0ef          	jal	ra,ffffffffc0202bda <get_page>
ffffffffc0202f10:	4c051763          	bnez	a0,ffffffffc02033de <pmm_init+0x658>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0202f14:	4505                	li	a0,1
ffffffffc0202f16:	9b9ff0ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0202f1a:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202f1c:	6008                	ld	a0,0(s0)
ffffffffc0202f1e:	4681                	li	a3,0
ffffffffc0202f20:	4601                	li	a2,0
ffffffffc0202f22:	85d6                	mv	a1,s5
ffffffffc0202f24:	d91ff0ef          	jal	ra,ffffffffc0202cb4 <page_insert>
ffffffffc0202f28:	52051763          	bnez	a0,ffffffffc0203456 <pmm_init+0x6d0>
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202f2c:	6008                	ld	a0,0(s0)
ffffffffc0202f2e:	4601                	li	a2,0
ffffffffc0202f30:	4581                	li	a1,0
ffffffffc0202f32:	aabff0ef          	jal	ra,ffffffffc02029dc <get_pte>
ffffffffc0202f36:	50050063          	beqz	a0,ffffffffc0203436 <pmm_init+0x6b0>
    assert(pte2page(*ptep) == p1);
ffffffffc0202f3a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202f3c:	0017f713          	andi	a4,a5,1
ffffffffc0202f40:	46070363          	beqz	a4,ffffffffc02033a6 <pmm_init+0x620>
    if (PPN(pa) >= npage) {
ffffffffc0202f44:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202f46:	078a                	slli	a5,a5,0x2
ffffffffc0202f48:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202f4a:	44c7f063          	bleu	a2,a5,ffffffffc020338a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0202f4e:	fff80737          	lui	a4,0xfff80
ffffffffc0202f52:	97ba                	add	a5,a5,a4
ffffffffc0202f54:	00379713          	slli	a4,a5,0x3
ffffffffc0202f58:	00093683          	ld	a3,0(s2)
ffffffffc0202f5c:	97ba                	add	a5,a5,a4
ffffffffc0202f5e:	078e                	slli	a5,a5,0x3
ffffffffc0202f60:	97b6                	add	a5,a5,a3
ffffffffc0202f62:	5efa9463          	bne	s5,a5,ffffffffc020354a <pmm_init+0x7c4>
    assert(page_ref(p1) == 1);
ffffffffc0202f66:	000aab83          	lw	s7,0(s5)
ffffffffc0202f6a:	4785                	li	a5,1
ffffffffc0202f6c:	5afb9f63          	bne	s7,a5,ffffffffc020352a <pmm_init+0x7a4>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0202f70:	6008                	ld	a0,0(s0)
ffffffffc0202f72:	76fd                	lui	a3,0xfffff
ffffffffc0202f74:	611c                	ld	a5,0(a0)
ffffffffc0202f76:	078a                	slli	a5,a5,0x2
ffffffffc0202f78:	8ff5                	and	a5,a5,a3
ffffffffc0202f7a:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202f7e:	58c77963          	bleu	a2,a4,ffffffffc0203510 <pmm_init+0x78a>
ffffffffc0202f82:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202f86:	97e2                	add	a5,a5,s8
ffffffffc0202f88:	0007bb03          	ld	s6,0(a5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc0202f8c:	0b0a                	slli	s6,s6,0x2
ffffffffc0202f8e:	00db7b33          	and	s6,s6,a3
ffffffffc0202f92:	00cb5793          	srli	a5,s6,0xc
ffffffffc0202f96:	56c7f063          	bleu	a2,a5,ffffffffc02034f6 <pmm_init+0x770>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202f9a:	4601                	li	a2,0
ffffffffc0202f9c:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202f9e:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202fa0:	a3dff0ef          	jal	ra,ffffffffc02029dc <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202fa4:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202fa6:	53651863          	bne	a0,s6,ffffffffc02034d6 <pmm_init+0x750>

    p2 = alloc_page();
ffffffffc0202faa:	4505                	li	a0,1
ffffffffc0202fac:	923ff0ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0202fb0:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202fb2:	6008                	ld	a0,0(s0)
ffffffffc0202fb4:	46d1                	li	a3,20
ffffffffc0202fb6:	6605                	lui	a2,0x1
ffffffffc0202fb8:	85da                	mv	a1,s6
ffffffffc0202fba:	cfbff0ef          	jal	ra,ffffffffc0202cb4 <page_insert>
ffffffffc0202fbe:	4e051c63          	bnez	a0,ffffffffc02034b6 <pmm_init+0x730>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202fc2:	6008                	ld	a0,0(s0)
ffffffffc0202fc4:	4601                	li	a2,0
ffffffffc0202fc6:	6585                	lui	a1,0x1
ffffffffc0202fc8:	a15ff0ef          	jal	ra,ffffffffc02029dc <get_pte>
ffffffffc0202fcc:	4c050563          	beqz	a0,ffffffffc0203496 <pmm_init+0x710>
    assert(*ptep & PTE_U);
ffffffffc0202fd0:	611c                	ld	a5,0(a0)
ffffffffc0202fd2:	0107f713          	andi	a4,a5,16
ffffffffc0202fd6:	4a070063          	beqz	a4,ffffffffc0203476 <pmm_init+0x6f0>
    assert(*ptep & PTE_W);
ffffffffc0202fda:	8b91                	andi	a5,a5,4
ffffffffc0202fdc:	66078763          	beqz	a5,ffffffffc020364a <pmm_init+0x8c4>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202fe0:	6008                	ld	a0,0(s0)
ffffffffc0202fe2:	611c                	ld	a5,0(a0)
ffffffffc0202fe4:	8bc1                	andi	a5,a5,16
ffffffffc0202fe6:	64078263          	beqz	a5,ffffffffc020362a <pmm_init+0x8a4>
    assert(page_ref(p2) == 1);
ffffffffc0202fea:	000b2783          	lw	a5,0(s6)
ffffffffc0202fee:	61779e63          	bne	a5,s7,ffffffffc020360a <pmm_init+0x884>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202ff2:	4681                	li	a3,0
ffffffffc0202ff4:	6605                	lui	a2,0x1
ffffffffc0202ff6:	85d6                	mv	a1,s5
ffffffffc0202ff8:	cbdff0ef          	jal	ra,ffffffffc0202cb4 <page_insert>
ffffffffc0202ffc:	5e051763          	bnez	a0,ffffffffc02035ea <pmm_init+0x864>
    assert(page_ref(p1) == 2);
ffffffffc0203000:	000aa703          	lw	a4,0(s5)
ffffffffc0203004:	4789                	li	a5,2
ffffffffc0203006:	5cf71263          	bne	a4,a5,ffffffffc02035ca <pmm_init+0x844>
    assert(page_ref(p2) == 0);
ffffffffc020300a:	000b2783          	lw	a5,0(s6)
ffffffffc020300e:	58079e63          	bnez	a5,ffffffffc02035aa <pmm_init+0x824>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203012:	6008                	ld	a0,0(s0)
ffffffffc0203014:	4601                	li	a2,0
ffffffffc0203016:	6585                	lui	a1,0x1
ffffffffc0203018:	9c5ff0ef          	jal	ra,ffffffffc02029dc <get_pte>
ffffffffc020301c:	56050763          	beqz	a0,ffffffffc020358a <pmm_init+0x804>
    assert(pte2page(*ptep) == p1);
ffffffffc0203020:	6114                	ld	a3,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0203022:	0016f793          	andi	a5,a3,1
ffffffffc0203026:	38078063          	beqz	a5,ffffffffc02033a6 <pmm_init+0x620>
    if (PPN(pa) >= npage) {
ffffffffc020302a:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020302c:	00269793          	slli	a5,a3,0x2
ffffffffc0203030:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203032:	34e7fc63          	bleu	a4,a5,ffffffffc020338a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0203036:	fff80737          	lui	a4,0xfff80
ffffffffc020303a:	97ba                	add	a5,a5,a4
ffffffffc020303c:	00379713          	slli	a4,a5,0x3
ffffffffc0203040:	00093603          	ld	a2,0(s2)
ffffffffc0203044:	97ba                	add	a5,a5,a4
ffffffffc0203046:	078e                	slli	a5,a5,0x3
ffffffffc0203048:	97b2                	add	a5,a5,a2
ffffffffc020304a:	52fa9063          	bne	s5,a5,ffffffffc020356a <pmm_init+0x7e4>
    assert((*ptep & PTE_U) == 0);
ffffffffc020304e:	8ac1                	andi	a3,a3,16
ffffffffc0203050:	6e069d63          	bnez	a3,ffffffffc020374a <pmm_init+0x9c4>

    page_remove(boot_pgdir, 0x0);
ffffffffc0203054:	6008                	ld	a0,0(s0)
ffffffffc0203056:	4581                	li	a1,0
ffffffffc0203058:	bebff0ef          	jal	ra,ffffffffc0202c42 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc020305c:	000aa703          	lw	a4,0(s5)
ffffffffc0203060:	4785                	li	a5,1
ffffffffc0203062:	6cf71463          	bne	a4,a5,ffffffffc020372a <pmm_init+0x9a4>
    assert(page_ref(p2) == 0);
ffffffffc0203066:	000b2783          	lw	a5,0(s6)
ffffffffc020306a:	6a079063          	bnez	a5,ffffffffc020370a <pmm_init+0x984>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc020306e:	6008                	ld	a0,0(s0)
ffffffffc0203070:	6585                	lui	a1,0x1
ffffffffc0203072:	bd1ff0ef          	jal	ra,ffffffffc0202c42 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0203076:	000aa783          	lw	a5,0(s5)
ffffffffc020307a:	66079863          	bnez	a5,ffffffffc02036ea <pmm_init+0x964>
    assert(page_ref(p2) == 0);
ffffffffc020307e:	000b2783          	lw	a5,0(s6)
ffffffffc0203082:	70079463          	bnez	a5,ffffffffc020378a <pmm_init+0xa04>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0203086:	00043b03          	ld	s6,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc020308a:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020308c:	000b3783          	ld	a5,0(s6)
ffffffffc0203090:	078a                	slli	a5,a5,0x2
ffffffffc0203092:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203094:	2eb7fb63          	bleu	a1,a5,ffffffffc020338a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0203098:	fff80737          	lui	a4,0xfff80
ffffffffc020309c:	973e                	add	a4,a4,a5
ffffffffc020309e:	00371793          	slli	a5,a4,0x3
ffffffffc02030a2:	00093603          	ld	a2,0(s2)
ffffffffc02030a6:	97ba                	add	a5,a5,a4
ffffffffc02030a8:	078e                	slli	a5,a5,0x3
ffffffffc02030aa:	00f60733          	add	a4,a2,a5
ffffffffc02030ae:	4314                	lw	a3,0(a4)
ffffffffc02030b0:	4705                	li	a4,1
ffffffffc02030b2:	6ae69c63          	bne	a3,a4,ffffffffc020376a <pmm_init+0x9e4>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02030b6:	00002a97          	auipc	s5,0x2
ffffffffc02030ba:	0b2a8a93          	addi	s5,s5,178 # ffffffffc0205168 <commands+0xf48>
ffffffffc02030be:	000ab703          	ld	a4,0(s5)
ffffffffc02030c2:	4037d693          	srai	a3,a5,0x3
ffffffffc02030c6:	00080bb7          	lui	s7,0x80
ffffffffc02030ca:	02e686b3          	mul	a3,a3,a4
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02030ce:	577d                	li	a4,-1
ffffffffc02030d0:	8331                	srli	a4,a4,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02030d2:	96de                	add	a3,a3,s7
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02030d4:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02030d6:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02030d8:	2ab77b63          	bleu	a1,a4,ffffffffc020338e <pmm_init+0x608>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02030dc:	0009b783          	ld	a5,0(s3)
ffffffffc02030e0:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02030e2:	629c                	ld	a5,0(a3)
ffffffffc02030e4:	078a                	slli	a5,a5,0x2
ffffffffc02030e6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02030e8:	2ab7f163          	bleu	a1,a5,ffffffffc020338a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc02030ec:	417787b3          	sub	a5,a5,s7
ffffffffc02030f0:	00379513          	slli	a0,a5,0x3
ffffffffc02030f4:	97aa                	add	a5,a5,a0
ffffffffc02030f6:	00379513          	slli	a0,a5,0x3
ffffffffc02030fa:	9532                	add	a0,a0,a2
ffffffffc02030fc:	4585                	li	a1,1
ffffffffc02030fe:	859ff0ef          	jal	ra,ffffffffc0202956 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203102:	000b3503          	ld	a0,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0203106:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203108:	050a                	slli	a0,a0,0x2
ffffffffc020310a:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc020310c:	26f57f63          	bleu	a5,a0,ffffffffc020338a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0203110:	417507b3          	sub	a5,a0,s7
ffffffffc0203114:	00379513          	slli	a0,a5,0x3
ffffffffc0203118:	00093703          	ld	a4,0(s2)
ffffffffc020311c:	953e                	add	a0,a0,a5
ffffffffc020311e:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc0203120:	4585                	li	a1,1
ffffffffc0203122:	953a                	add	a0,a0,a4
ffffffffc0203124:	833ff0ef          	jal	ra,ffffffffc0202956 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0203128:	601c                	ld	a5,0(s0)
ffffffffc020312a:	0007b023          	sd	zero,0(a5)

    assert(nr_free_store==nr_free_pages());
ffffffffc020312e:	86fff0ef          	jal	ra,ffffffffc020299c <nr_free_pages>
ffffffffc0203132:	2caa1663          	bne	s4,a0,ffffffffc02033fe <pmm_init+0x678>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0203136:	00003517          	auipc	a0,0x3
ffffffffc020313a:	8c250513          	addi	a0,a0,-1854 # ffffffffc02059f8 <default_pmm_manager+0x538>
ffffffffc020313e:	f81fc0ef          	jal	ra,ffffffffc02000be <cprintf>
static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();
ffffffffc0203142:	85bff0ef          	jal	ra,ffffffffc020299c <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0203146:	6098                	ld	a4,0(s1)
ffffffffc0203148:	c02007b7          	lui	a5,0xc0200
    nr_free_store=nr_free_pages();
ffffffffc020314c:	8b2a                	mv	s6,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020314e:	00c71693          	slli	a3,a4,0xc
ffffffffc0203152:	1cd7fd63          	bleu	a3,a5,ffffffffc020332c <pmm_init+0x5a6>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0203156:	83b1                	srli	a5,a5,0xc
ffffffffc0203158:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020315a:	c0200a37          	lui	s4,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020315e:	1ce7f963          	bleu	a4,a5,ffffffffc0203330 <pmm_init+0x5aa>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0203162:	7c7d                	lui	s8,0xfffff
ffffffffc0203164:	6b85                	lui	s7,0x1
ffffffffc0203166:	a029                	j	ffffffffc0203170 <pmm_init+0x3ea>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0203168:	00ca5713          	srli	a4,s4,0xc
ffffffffc020316c:	1cf77263          	bleu	a5,a4,ffffffffc0203330 <pmm_init+0x5aa>
ffffffffc0203170:	0009b583          	ld	a1,0(s3)
ffffffffc0203174:	4601                	li	a2,0
ffffffffc0203176:	95d2                	add	a1,a1,s4
ffffffffc0203178:	865ff0ef          	jal	ra,ffffffffc02029dc <get_pte>
ffffffffc020317c:	1c050763          	beqz	a0,ffffffffc020334a <pmm_init+0x5c4>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0203180:	611c                	ld	a5,0(a0)
ffffffffc0203182:	078a                	slli	a5,a5,0x2
ffffffffc0203184:	0187f7b3          	and	a5,a5,s8
ffffffffc0203188:	1f479163          	bne	a5,s4,ffffffffc020336a <pmm_init+0x5e4>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020318c:	609c                	ld	a5,0(s1)
ffffffffc020318e:	9a5e                	add	s4,s4,s7
ffffffffc0203190:	6008                	ld	a0,0(s0)
ffffffffc0203192:	00c79713          	slli	a4,a5,0xc
ffffffffc0203196:	fcea69e3          	bltu	s4,a4,ffffffffc0203168 <pmm_init+0x3e2>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc020319a:	611c                	ld	a5,0(a0)
ffffffffc020319c:	6a079363          	bnez	a5,ffffffffc0203842 <pmm_init+0xabc>

    struct Page *p;
    p = alloc_page();
ffffffffc02031a0:	4505                	li	a0,1
ffffffffc02031a2:	f2cff0ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc02031a6:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02031a8:	6008                	ld	a0,0(s0)
ffffffffc02031aa:	4699                	li	a3,6
ffffffffc02031ac:	10000613          	li	a2,256
ffffffffc02031b0:	85d2                	mv	a1,s4
ffffffffc02031b2:	b03ff0ef          	jal	ra,ffffffffc0202cb4 <page_insert>
ffffffffc02031b6:	66051663          	bnez	a0,ffffffffc0203822 <pmm_init+0xa9c>
    assert(page_ref(p) == 1);
ffffffffc02031ba:	000a2703          	lw	a4,0(s4) # ffffffffc0200000 <kern_entry>
ffffffffc02031be:	4785                	li	a5,1
ffffffffc02031c0:	64f71163          	bne	a4,a5,ffffffffc0203802 <pmm_init+0xa7c>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02031c4:	6008                	ld	a0,0(s0)
ffffffffc02031c6:	6b85                	lui	s7,0x1
ffffffffc02031c8:	4699                	li	a3,6
ffffffffc02031ca:	100b8613          	addi	a2,s7,256 # 1100 <BASE_ADDRESS-0xffffffffc01fef00>
ffffffffc02031ce:	85d2                	mv	a1,s4
ffffffffc02031d0:	ae5ff0ef          	jal	ra,ffffffffc0202cb4 <page_insert>
ffffffffc02031d4:	60051763          	bnez	a0,ffffffffc02037e2 <pmm_init+0xa5c>
    assert(page_ref(p) == 2);
ffffffffc02031d8:	000a2703          	lw	a4,0(s4)
ffffffffc02031dc:	4789                	li	a5,2
ffffffffc02031de:	4ef71663          	bne	a4,a5,ffffffffc02036ca <pmm_init+0x944>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02031e2:	00003597          	auipc	a1,0x3
ffffffffc02031e6:	94e58593          	addi	a1,a1,-1714 # ffffffffc0205b30 <default_pmm_manager+0x670>
ffffffffc02031ea:	10000513          	li	a0,256
ffffffffc02031ee:	1b1000ef          	jal	ra,ffffffffc0203b9e <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02031f2:	100b8593          	addi	a1,s7,256
ffffffffc02031f6:	10000513          	li	a0,256
ffffffffc02031fa:	1b7000ef          	jal	ra,ffffffffc0203bb0 <strcmp>
ffffffffc02031fe:	4a051663          	bnez	a0,ffffffffc02036aa <pmm_init+0x924>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203202:	00093683          	ld	a3,0(s2)
ffffffffc0203206:	000abc83          	ld	s9,0(s5)
ffffffffc020320a:	00080c37          	lui	s8,0x80
ffffffffc020320e:	40da06b3          	sub	a3,s4,a3
ffffffffc0203212:	868d                	srai	a3,a3,0x3
ffffffffc0203214:	039686b3          	mul	a3,a3,s9
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203218:	5afd                	li	s5,-1
ffffffffc020321a:	609c                	ld	a5,0(s1)
ffffffffc020321c:	00cada93          	srli	s5,s5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203220:	96e2                	add	a3,a3,s8
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203222:	0156f733          	and	a4,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0203226:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203228:	16f77363          	bleu	a5,a4,ffffffffc020338e <pmm_init+0x608>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020322c:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203230:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0203234:	96be                	add	a3,a3,a5
ffffffffc0203236:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fdeeb70>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020323a:	121000ef          	jal	ra,ffffffffc0203b5a <strlen>
ffffffffc020323e:	44051663          	bnez	a0,ffffffffc020368a <pmm_init+0x904>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0203242:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0203246:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203248:	000bb783          	ld	a5,0(s7)
ffffffffc020324c:	078a                	slli	a5,a5,0x2
ffffffffc020324e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203250:	12e7fd63          	bleu	a4,a5,ffffffffc020338a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0203254:	418787b3          	sub	a5,a5,s8
ffffffffc0203258:	00379693          	slli	a3,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020325c:	96be                	add	a3,a3,a5
ffffffffc020325e:	039686b3          	mul	a3,a3,s9
ffffffffc0203262:	96e2                	add	a3,a3,s8
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203264:	0156fab3          	and	s5,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0203268:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020326a:	12eaf263          	bleu	a4,s5,ffffffffc020338e <pmm_init+0x608>
ffffffffc020326e:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc0203272:	4585                	li	a1,1
ffffffffc0203274:	8552                	mv	a0,s4
ffffffffc0203276:	99b6                	add	s3,s3,a3
ffffffffc0203278:	edeff0ef          	jal	ra,ffffffffc0202956 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020327c:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0203280:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203282:	078a                	slli	a5,a5,0x2
ffffffffc0203284:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203286:	10e7f263          	bleu	a4,a5,ffffffffc020338a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc020328a:	fff809b7          	lui	s3,0xfff80
ffffffffc020328e:	97ce                	add	a5,a5,s3
ffffffffc0203290:	00379513          	slli	a0,a5,0x3
ffffffffc0203294:	00093703          	ld	a4,0(s2)
ffffffffc0203298:	97aa                	add	a5,a5,a0
ffffffffc020329a:	00379513          	slli	a0,a5,0x3
    free_page(pde2page(pd0[0]));
ffffffffc020329e:	953a                	add	a0,a0,a4
ffffffffc02032a0:	4585                	li	a1,1
ffffffffc02032a2:	eb4ff0ef          	jal	ra,ffffffffc0202956 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02032a6:	000bb503          	ld	a0,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc02032aa:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02032ac:	050a                	slli	a0,a0,0x2
ffffffffc02032ae:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc02032b0:	0cf57d63          	bleu	a5,a0,ffffffffc020338a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc02032b4:	013507b3          	add	a5,a0,s3
ffffffffc02032b8:	00379513          	slli	a0,a5,0x3
ffffffffc02032bc:	00093703          	ld	a4,0(s2)
ffffffffc02032c0:	953e                	add	a0,a0,a5
ffffffffc02032c2:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc02032c4:	4585                	li	a1,1
ffffffffc02032c6:	953a                	add	a0,a0,a4
ffffffffc02032c8:	e8eff0ef          	jal	ra,ffffffffc0202956 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc02032cc:	601c                	ld	a5,0(s0)
ffffffffc02032ce:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>

    assert(nr_free_store==nr_free_pages());
ffffffffc02032d2:	ecaff0ef          	jal	ra,ffffffffc020299c <nr_free_pages>
ffffffffc02032d6:	38ab1a63          	bne	s6,a0,ffffffffc020366a <pmm_init+0x8e4>
}
ffffffffc02032da:	6446                	ld	s0,80(sp)
ffffffffc02032dc:	60e6                	ld	ra,88(sp)
ffffffffc02032de:	64a6                	ld	s1,72(sp)
ffffffffc02032e0:	6906                	ld	s2,64(sp)
ffffffffc02032e2:	79e2                	ld	s3,56(sp)
ffffffffc02032e4:	7a42                	ld	s4,48(sp)
ffffffffc02032e6:	7aa2                	ld	s5,40(sp)
ffffffffc02032e8:	7b02                	ld	s6,32(sp)
ffffffffc02032ea:	6be2                	ld	s7,24(sp)
ffffffffc02032ec:	6c42                	ld	s8,16(sp)
ffffffffc02032ee:	6ca2                	ld	s9,8(sp)

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02032f0:	00003517          	auipc	a0,0x3
ffffffffc02032f4:	8b850513          	addi	a0,a0,-1864 # ffffffffc0205ba8 <default_pmm_manager+0x6e8>
}
ffffffffc02032f8:	6125                	addi	sp,sp,96
    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02032fa:	dc5fc06f          	j	ffffffffc02000be <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02032fe:	6705                	lui	a4,0x1
ffffffffc0203300:	177d                	addi	a4,a4,-1
ffffffffc0203302:	96ba                	add	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc0203304:	00c6d713          	srli	a4,a3,0xc
ffffffffc0203308:	08f77163          	bleu	a5,a4,ffffffffc020338a <pmm_init+0x604>
    pmm_manager->init_memmap(base, n);
ffffffffc020330c:	00043803          	ld	a6,0(s0)
    return &pages[PPN(pa) - nbase];
ffffffffc0203310:	9732                	add	a4,a4,a2
ffffffffc0203312:	00371793          	slli	a5,a4,0x3
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0203316:	767d                	lui	a2,0xfffff
ffffffffc0203318:	8ef1                	and	a3,a3,a2
ffffffffc020331a:	97ba                	add	a5,a5,a4
    pmm_manager->init_memmap(base, n);
ffffffffc020331c:	01083703          	ld	a4,16(a6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0203320:	8d95                	sub	a1,a1,a3
ffffffffc0203322:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0203324:	81b1                	srli	a1,a1,0xc
ffffffffc0203326:	953e                	add	a0,a0,a5
ffffffffc0203328:	9702                	jalr	a4
ffffffffc020332a:	bead                	j	ffffffffc0202ea4 <pmm_init+0x11e>
ffffffffc020332c:	6008                	ld	a0,0(s0)
ffffffffc020332e:	b5b5                	j	ffffffffc020319a <pmm_init+0x414>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0203330:	86d2                	mv	a3,s4
ffffffffc0203332:	00002617          	auipc	a2,0x2
ffffffffc0203336:	29e60613          	addi	a2,a2,670 # ffffffffc02055d0 <default_pmm_manager+0x110>
ffffffffc020333a:	1cd00593          	li	a1,461
ffffffffc020333e:	00002517          	auipc	a0,0x2
ffffffffc0203342:	2ba50513          	addi	a0,a0,698 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203346:	dc1fc0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc020334a:	00002697          	auipc	a3,0x2
ffffffffc020334e:	6ce68693          	addi	a3,a3,1742 # ffffffffc0205a18 <default_pmm_manager+0x558>
ffffffffc0203352:	00001617          	auipc	a2,0x1
ffffffffc0203356:	72660613          	addi	a2,a2,1830 # ffffffffc0204a78 <commands+0x858>
ffffffffc020335a:	1cd00593          	li	a1,461
ffffffffc020335e:	00002517          	auipc	a0,0x2
ffffffffc0203362:	29a50513          	addi	a0,a0,666 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203366:	da1fc0ef          	jal	ra,ffffffffc0200106 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020336a:	00002697          	auipc	a3,0x2
ffffffffc020336e:	6ee68693          	addi	a3,a3,1774 # ffffffffc0205a58 <default_pmm_manager+0x598>
ffffffffc0203372:	00001617          	auipc	a2,0x1
ffffffffc0203376:	70660613          	addi	a2,a2,1798 # ffffffffc0204a78 <commands+0x858>
ffffffffc020337a:	1ce00593          	li	a1,462
ffffffffc020337e:	00002517          	auipc	a0,0x2
ffffffffc0203382:	27a50513          	addi	a0,a0,634 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203386:	d81fc0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc020338a:	d28ff0ef          	jal	ra,ffffffffc02028b2 <pa2page.part.4>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020338e:	00002617          	auipc	a2,0x2
ffffffffc0203392:	24260613          	addi	a2,a2,578 # ffffffffc02055d0 <default_pmm_manager+0x110>
ffffffffc0203396:	06a00593          	li	a1,106
ffffffffc020339a:	00002517          	auipc	a0,0x2
ffffffffc020339e:	9f650513          	addi	a0,a0,-1546 # ffffffffc0204d90 <commands+0xb70>
ffffffffc02033a2:	d65fc0ef          	jal	ra,ffffffffc0200106 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02033a6:	00002617          	auipc	a2,0x2
ffffffffc02033aa:	c6260613          	addi	a2,a2,-926 # ffffffffc0205008 <commands+0xde8>
ffffffffc02033ae:	07000593          	li	a1,112
ffffffffc02033b2:	00002517          	auipc	a0,0x2
ffffffffc02033b6:	9de50513          	addi	a0,a0,-1570 # ffffffffc0204d90 <commands+0xb70>
ffffffffc02033ba:	d4dfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02033be:	00002697          	auipc	a3,0x2
ffffffffc02033c2:	39268693          	addi	a3,a3,914 # ffffffffc0205750 <default_pmm_manager+0x290>
ffffffffc02033c6:	00001617          	auipc	a2,0x1
ffffffffc02033ca:	6b260613          	addi	a2,a2,1714 # ffffffffc0204a78 <commands+0x858>
ffffffffc02033ce:	19300593          	li	a1,403
ffffffffc02033d2:	00002517          	auipc	a0,0x2
ffffffffc02033d6:	22650513          	addi	a0,a0,550 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02033da:	d2dfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02033de:	00002697          	auipc	a3,0x2
ffffffffc02033e2:	3aa68693          	addi	a3,a3,938 # ffffffffc0205788 <default_pmm_manager+0x2c8>
ffffffffc02033e6:	00001617          	auipc	a2,0x1
ffffffffc02033ea:	69260613          	addi	a2,a2,1682 # ffffffffc0204a78 <commands+0x858>
ffffffffc02033ee:	19400593          	li	a1,404
ffffffffc02033f2:	00002517          	auipc	a0,0x2
ffffffffc02033f6:	20650513          	addi	a0,a0,518 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02033fa:	d0dfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc02033fe:	00002697          	auipc	a3,0x2
ffffffffc0203402:	5da68693          	addi	a3,a3,1498 # ffffffffc02059d8 <default_pmm_manager+0x518>
ffffffffc0203406:	00001617          	auipc	a2,0x1
ffffffffc020340a:	67260613          	addi	a2,a2,1650 # ffffffffc0204a78 <commands+0x858>
ffffffffc020340e:	1c000593          	li	a1,448
ffffffffc0203412:	00002517          	auipc	a0,0x2
ffffffffc0203416:	1e650513          	addi	a0,a0,486 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc020341a:	cedfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020341e:	00002617          	auipc	a2,0x2
ffffffffc0203422:	2ca60613          	addi	a2,a2,714 # ffffffffc02056e8 <default_pmm_manager+0x228>
ffffffffc0203426:	07700593          	li	a1,119
ffffffffc020342a:	00002517          	auipc	a0,0x2
ffffffffc020342e:	1ce50513          	addi	a0,a0,462 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203432:	cd5fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0203436:	00002697          	auipc	a3,0x2
ffffffffc020343a:	3aa68693          	addi	a3,a3,938 # ffffffffc02057e0 <default_pmm_manager+0x320>
ffffffffc020343e:	00001617          	auipc	a2,0x1
ffffffffc0203442:	63a60613          	addi	a2,a2,1594 # ffffffffc0204a78 <commands+0x858>
ffffffffc0203446:	19a00593          	li	a1,410
ffffffffc020344a:	00002517          	auipc	a0,0x2
ffffffffc020344e:	1ae50513          	addi	a0,a0,430 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203452:	cb5fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0203456:	00002697          	auipc	a3,0x2
ffffffffc020345a:	35a68693          	addi	a3,a3,858 # ffffffffc02057b0 <default_pmm_manager+0x2f0>
ffffffffc020345e:	00001617          	auipc	a2,0x1
ffffffffc0203462:	61a60613          	addi	a2,a2,1562 # ffffffffc0204a78 <commands+0x858>
ffffffffc0203466:	19800593          	li	a1,408
ffffffffc020346a:	00002517          	auipc	a0,0x2
ffffffffc020346e:	18e50513          	addi	a0,a0,398 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203472:	c95fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203476:	00002697          	auipc	a3,0x2
ffffffffc020347a:	45a68693          	addi	a3,a3,1114 # ffffffffc02058d0 <default_pmm_manager+0x410>
ffffffffc020347e:	00001617          	auipc	a2,0x1
ffffffffc0203482:	5fa60613          	addi	a2,a2,1530 # ffffffffc0204a78 <commands+0x858>
ffffffffc0203486:	1a500593          	li	a1,421
ffffffffc020348a:	00002517          	auipc	a0,0x2
ffffffffc020348e:	16e50513          	addi	a0,a0,366 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203492:	c75fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203496:	00002697          	auipc	a3,0x2
ffffffffc020349a:	40a68693          	addi	a3,a3,1034 # ffffffffc02058a0 <default_pmm_manager+0x3e0>
ffffffffc020349e:	00001617          	auipc	a2,0x1
ffffffffc02034a2:	5da60613          	addi	a2,a2,1498 # ffffffffc0204a78 <commands+0x858>
ffffffffc02034a6:	1a400593          	li	a1,420
ffffffffc02034aa:	00002517          	auipc	a0,0x2
ffffffffc02034ae:	14e50513          	addi	a0,a0,334 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02034b2:	c55fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02034b6:	00002697          	auipc	a3,0x2
ffffffffc02034ba:	3b268693          	addi	a3,a3,946 # ffffffffc0205868 <default_pmm_manager+0x3a8>
ffffffffc02034be:	00001617          	auipc	a2,0x1
ffffffffc02034c2:	5ba60613          	addi	a2,a2,1466 # ffffffffc0204a78 <commands+0x858>
ffffffffc02034c6:	1a300593          	li	a1,419
ffffffffc02034ca:	00002517          	auipc	a0,0x2
ffffffffc02034ce:	12e50513          	addi	a0,a0,302 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02034d2:	c35fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02034d6:	00002697          	auipc	a3,0x2
ffffffffc02034da:	36a68693          	addi	a3,a3,874 # ffffffffc0205840 <default_pmm_manager+0x380>
ffffffffc02034de:	00001617          	auipc	a2,0x1
ffffffffc02034e2:	59a60613          	addi	a2,a2,1434 # ffffffffc0204a78 <commands+0x858>
ffffffffc02034e6:	1a000593          	li	a1,416
ffffffffc02034ea:	00002517          	auipc	a0,0x2
ffffffffc02034ee:	10e50513          	addi	a0,a0,270 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02034f2:	c15fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02034f6:	86da                	mv	a3,s6
ffffffffc02034f8:	00002617          	auipc	a2,0x2
ffffffffc02034fc:	0d860613          	addi	a2,a2,216 # ffffffffc02055d0 <default_pmm_manager+0x110>
ffffffffc0203500:	19f00593          	li	a1,415
ffffffffc0203504:	00002517          	auipc	a0,0x2
ffffffffc0203508:	0f450513          	addi	a0,a0,244 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc020350c:	bfbfc0ef          	jal	ra,ffffffffc0200106 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0203510:	86be                	mv	a3,a5
ffffffffc0203512:	00002617          	auipc	a2,0x2
ffffffffc0203516:	0be60613          	addi	a2,a2,190 # ffffffffc02055d0 <default_pmm_manager+0x110>
ffffffffc020351a:	19e00593          	li	a1,414
ffffffffc020351e:	00002517          	auipc	a0,0x2
ffffffffc0203522:	0da50513          	addi	a0,a0,218 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203526:	be1fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020352a:	00002697          	auipc	a3,0x2
ffffffffc020352e:	2fe68693          	addi	a3,a3,766 # ffffffffc0205828 <default_pmm_manager+0x368>
ffffffffc0203532:	00001617          	auipc	a2,0x1
ffffffffc0203536:	54660613          	addi	a2,a2,1350 # ffffffffc0204a78 <commands+0x858>
ffffffffc020353a:	19c00593          	li	a1,412
ffffffffc020353e:	00002517          	auipc	a0,0x2
ffffffffc0203542:	0ba50513          	addi	a0,a0,186 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203546:	bc1fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020354a:	00002697          	auipc	a3,0x2
ffffffffc020354e:	2c668693          	addi	a3,a3,710 # ffffffffc0205810 <default_pmm_manager+0x350>
ffffffffc0203552:	00001617          	auipc	a2,0x1
ffffffffc0203556:	52660613          	addi	a2,a2,1318 # ffffffffc0204a78 <commands+0x858>
ffffffffc020355a:	19b00593          	li	a1,411
ffffffffc020355e:	00002517          	auipc	a0,0x2
ffffffffc0203562:	09a50513          	addi	a0,a0,154 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203566:	ba1fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020356a:	00002697          	auipc	a3,0x2
ffffffffc020356e:	2a668693          	addi	a3,a3,678 # ffffffffc0205810 <default_pmm_manager+0x350>
ffffffffc0203572:	00001617          	auipc	a2,0x1
ffffffffc0203576:	50660613          	addi	a2,a2,1286 # ffffffffc0204a78 <commands+0x858>
ffffffffc020357a:	1ae00593          	li	a1,430
ffffffffc020357e:	00002517          	auipc	a0,0x2
ffffffffc0203582:	07a50513          	addi	a0,a0,122 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203586:	b81fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020358a:	00002697          	auipc	a3,0x2
ffffffffc020358e:	31668693          	addi	a3,a3,790 # ffffffffc02058a0 <default_pmm_manager+0x3e0>
ffffffffc0203592:	00001617          	auipc	a2,0x1
ffffffffc0203596:	4e660613          	addi	a2,a2,1254 # ffffffffc0204a78 <commands+0x858>
ffffffffc020359a:	1ad00593          	li	a1,429
ffffffffc020359e:	00002517          	auipc	a0,0x2
ffffffffc02035a2:	05a50513          	addi	a0,a0,90 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02035a6:	b61fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02035aa:	00002697          	auipc	a3,0x2
ffffffffc02035ae:	3be68693          	addi	a3,a3,958 # ffffffffc0205968 <default_pmm_manager+0x4a8>
ffffffffc02035b2:	00001617          	auipc	a2,0x1
ffffffffc02035b6:	4c660613          	addi	a2,a2,1222 # ffffffffc0204a78 <commands+0x858>
ffffffffc02035ba:	1ac00593          	li	a1,428
ffffffffc02035be:	00002517          	auipc	a0,0x2
ffffffffc02035c2:	03a50513          	addi	a0,a0,58 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02035c6:	b41fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02035ca:	00002697          	auipc	a3,0x2
ffffffffc02035ce:	38668693          	addi	a3,a3,902 # ffffffffc0205950 <default_pmm_manager+0x490>
ffffffffc02035d2:	00001617          	auipc	a2,0x1
ffffffffc02035d6:	4a660613          	addi	a2,a2,1190 # ffffffffc0204a78 <commands+0x858>
ffffffffc02035da:	1ab00593          	li	a1,427
ffffffffc02035de:	00002517          	auipc	a0,0x2
ffffffffc02035e2:	01a50513          	addi	a0,a0,26 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02035e6:	b21fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02035ea:	00002697          	auipc	a3,0x2
ffffffffc02035ee:	33668693          	addi	a3,a3,822 # ffffffffc0205920 <default_pmm_manager+0x460>
ffffffffc02035f2:	00001617          	auipc	a2,0x1
ffffffffc02035f6:	48660613          	addi	a2,a2,1158 # ffffffffc0204a78 <commands+0x858>
ffffffffc02035fa:	1aa00593          	li	a1,426
ffffffffc02035fe:	00002517          	auipc	a0,0x2
ffffffffc0203602:	ffa50513          	addi	a0,a0,-6 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203606:	b01fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020360a:	00002697          	auipc	a3,0x2
ffffffffc020360e:	2fe68693          	addi	a3,a3,766 # ffffffffc0205908 <default_pmm_manager+0x448>
ffffffffc0203612:	00001617          	auipc	a2,0x1
ffffffffc0203616:	46660613          	addi	a2,a2,1126 # ffffffffc0204a78 <commands+0x858>
ffffffffc020361a:	1a800593          	li	a1,424
ffffffffc020361e:	00002517          	auipc	a0,0x2
ffffffffc0203622:	fda50513          	addi	a0,a0,-38 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203626:	ae1fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc020362a:	00002697          	auipc	a3,0x2
ffffffffc020362e:	2c668693          	addi	a3,a3,710 # ffffffffc02058f0 <default_pmm_manager+0x430>
ffffffffc0203632:	00001617          	auipc	a2,0x1
ffffffffc0203636:	44660613          	addi	a2,a2,1094 # ffffffffc0204a78 <commands+0x858>
ffffffffc020363a:	1a700593          	li	a1,423
ffffffffc020363e:	00002517          	auipc	a0,0x2
ffffffffc0203642:	fba50513          	addi	a0,a0,-70 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203646:	ac1fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(*ptep & PTE_W);
ffffffffc020364a:	00002697          	auipc	a3,0x2
ffffffffc020364e:	29668693          	addi	a3,a3,662 # ffffffffc02058e0 <default_pmm_manager+0x420>
ffffffffc0203652:	00001617          	auipc	a2,0x1
ffffffffc0203656:	42660613          	addi	a2,a2,1062 # ffffffffc0204a78 <commands+0x858>
ffffffffc020365a:	1a600593          	li	a1,422
ffffffffc020365e:	00002517          	auipc	a0,0x2
ffffffffc0203662:	f9a50513          	addi	a0,a0,-102 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203666:	aa1fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020366a:	00002697          	auipc	a3,0x2
ffffffffc020366e:	36e68693          	addi	a3,a3,878 # ffffffffc02059d8 <default_pmm_manager+0x518>
ffffffffc0203672:	00001617          	auipc	a2,0x1
ffffffffc0203676:	40660613          	addi	a2,a2,1030 # ffffffffc0204a78 <commands+0x858>
ffffffffc020367a:	1e800593          	li	a1,488
ffffffffc020367e:	00002517          	auipc	a0,0x2
ffffffffc0203682:	f7a50513          	addi	a0,a0,-134 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203686:	a81fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020368a:	00002697          	auipc	a3,0x2
ffffffffc020368e:	4f668693          	addi	a3,a3,1270 # ffffffffc0205b80 <default_pmm_manager+0x6c0>
ffffffffc0203692:	00001617          	auipc	a2,0x1
ffffffffc0203696:	3e660613          	addi	a2,a2,998 # ffffffffc0204a78 <commands+0x858>
ffffffffc020369a:	1e000593          	li	a1,480
ffffffffc020369e:	00002517          	auipc	a0,0x2
ffffffffc02036a2:	f5a50513          	addi	a0,a0,-166 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02036a6:	a61fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02036aa:	00002697          	auipc	a3,0x2
ffffffffc02036ae:	49e68693          	addi	a3,a3,1182 # ffffffffc0205b48 <default_pmm_manager+0x688>
ffffffffc02036b2:	00001617          	auipc	a2,0x1
ffffffffc02036b6:	3c660613          	addi	a2,a2,966 # ffffffffc0204a78 <commands+0x858>
ffffffffc02036ba:	1dd00593          	li	a1,477
ffffffffc02036be:	00002517          	auipc	a0,0x2
ffffffffc02036c2:	f3a50513          	addi	a0,a0,-198 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02036c6:	a41fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02036ca:	00002697          	auipc	a3,0x2
ffffffffc02036ce:	44e68693          	addi	a3,a3,1102 # ffffffffc0205b18 <default_pmm_manager+0x658>
ffffffffc02036d2:	00001617          	auipc	a2,0x1
ffffffffc02036d6:	3a660613          	addi	a2,a2,934 # ffffffffc0204a78 <commands+0x858>
ffffffffc02036da:	1d900593          	li	a1,473
ffffffffc02036de:	00002517          	auipc	a0,0x2
ffffffffc02036e2:	f1a50513          	addi	a0,a0,-230 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02036e6:	a21fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02036ea:	00002697          	auipc	a3,0x2
ffffffffc02036ee:	2ae68693          	addi	a3,a3,686 # ffffffffc0205998 <default_pmm_manager+0x4d8>
ffffffffc02036f2:	00001617          	auipc	a2,0x1
ffffffffc02036f6:	38660613          	addi	a2,a2,902 # ffffffffc0204a78 <commands+0x858>
ffffffffc02036fa:	1b600593          	li	a1,438
ffffffffc02036fe:	00002517          	auipc	a0,0x2
ffffffffc0203702:	efa50513          	addi	a0,a0,-262 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203706:	a01fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020370a:	00002697          	auipc	a3,0x2
ffffffffc020370e:	25e68693          	addi	a3,a3,606 # ffffffffc0205968 <default_pmm_manager+0x4a8>
ffffffffc0203712:	00001617          	auipc	a2,0x1
ffffffffc0203716:	36660613          	addi	a2,a2,870 # ffffffffc0204a78 <commands+0x858>
ffffffffc020371a:	1b300593          	li	a1,435
ffffffffc020371e:	00002517          	auipc	a0,0x2
ffffffffc0203722:	eda50513          	addi	a0,a0,-294 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203726:	9e1fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020372a:	00002697          	auipc	a3,0x2
ffffffffc020372e:	0fe68693          	addi	a3,a3,254 # ffffffffc0205828 <default_pmm_manager+0x368>
ffffffffc0203732:	00001617          	auipc	a2,0x1
ffffffffc0203736:	34660613          	addi	a2,a2,838 # ffffffffc0204a78 <commands+0x858>
ffffffffc020373a:	1b200593          	li	a1,434
ffffffffc020373e:	00002517          	auipc	a0,0x2
ffffffffc0203742:	eba50513          	addi	a0,a0,-326 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203746:	9c1fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020374a:	00002697          	auipc	a3,0x2
ffffffffc020374e:	23668693          	addi	a3,a3,566 # ffffffffc0205980 <default_pmm_manager+0x4c0>
ffffffffc0203752:	00001617          	auipc	a2,0x1
ffffffffc0203756:	32660613          	addi	a2,a2,806 # ffffffffc0204a78 <commands+0x858>
ffffffffc020375a:	1af00593          	li	a1,431
ffffffffc020375e:	00002517          	auipc	a0,0x2
ffffffffc0203762:	e9a50513          	addi	a0,a0,-358 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203766:	9a1fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020376a:	00002697          	auipc	a3,0x2
ffffffffc020376e:	24668693          	addi	a3,a3,582 # ffffffffc02059b0 <default_pmm_manager+0x4f0>
ffffffffc0203772:	00001617          	auipc	a2,0x1
ffffffffc0203776:	30660613          	addi	a2,a2,774 # ffffffffc0204a78 <commands+0x858>
ffffffffc020377a:	1b900593          	li	a1,441
ffffffffc020377e:	00002517          	auipc	a0,0x2
ffffffffc0203782:	e7a50513          	addi	a0,a0,-390 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203786:	981fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020378a:	00002697          	auipc	a3,0x2
ffffffffc020378e:	1de68693          	addi	a3,a3,478 # ffffffffc0205968 <default_pmm_manager+0x4a8>
ffffffffc0203792:	00001617          	auipc	a2,0x1
ffffffffc0203796:	2e660613          	addi	a2,a2,742 # ffffffffc0204a78 <commands+0x858>
ffffffffc020379a:	1b700593          	li	a1,439
ffffffffc020379e:	00002517          	auipc	a0,0x2
ffffffffc02037a2:	e5a50513          	addi	a0,a0,-422 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02037a6:	961fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02037aa:	00002697          	auipc	a3,0x2
ffffffffc02037ae:	f8668693          	addi	a3,a3,-122 # ffffffffc0205730 <default_pmm_manager+0x270>
ffffffffc02037b2:	00001617          	auipc	a2,0x1
ffffffffc02037b6:	2c660613          	addi	a2,a2,710 # ffffffffc0204a78 <commands+0x858>
ffffffffc02037ba:	19200593          	li	a1,402
ffffffffc02037be:	00002517          	auipc	a0,0x2
ffffffffc02037c2:	e3a50513          	addi	a0,a0,-454 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02037c6:	941fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02037ca:	00002617          	auipc	a2,0x2
ffffffffc02037ce:	f1e60613          	addi	a2,a2,-226 # ffffffffc02056e8 <default_pmm_manager+0x228>
ffffffffc02037d2:	0bd00593          	li	a1,189
ffffffffc02037d6:	00002517          	auipc	a0,0x2
ffffffffc02037da:	e2250513          	addi	a0,a0,-478 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02037de:	929fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02037e2:	00002697          	auipc	a3,0x2
ffffffffc02037e6:	2f668693          	addi	a3,a3,758 # ffffffffc0205ad8 <default_pmm_manager+0x618>
ffffffffc02037ea:	00001617          	auipc	a2,0x1
ffffffffc02037ee:	28e60613          	addi	a2,a2,654 # ffffffffc0204a78 <commands+0x858>
ffffffffc02037f2:	1d800593          	li	a1,472
ffffffffc02037f6:	00002517          	auipc	a0,0x2
ffffffffc02037fa:	e0250513          	addi	a0,a0,-510 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02037fe:	909fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203802:	00002697          	auipc	a3,0x2
ffffffffc0203806:	2be68693          	addi	a3,a3,702 # ffffffffc0205ac0 <default_pmm_manager+0x600>
ffffffffc020380a:	00001617          	auipc	a2,0x1
ffffffffc020380e:	26e60613          	addi	a2,a2,622 # ffffffffc0204a78 <commands+0x858>
ffffffffc0203812:	1d700593          	li	a1,471
ffffffffc0203816:	00002517          	auipc	a0,0x2
ffffffffc020381a:	de250513          	addi	a0,a0,-542 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc020381e:	8e9fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203822:	00002697          	auipc	a3,0x2
ffffffffc0203826:	26668693          	addi	a3,a3,614 # ffffffffc0205a88 <default_pmm_manager+0x5c8>
ffffffffc020382a:	00001617          	auipc	a2,0x1
ffffffffc020382e:	24e60613          	addi	a2,a2,590 # ffffffffc0204a78 <commands+0x858>
ffffffffc0203832:	1d600593          	li	a1,470
ffffffffc0203836:	00002517          	auipc	a0,0x2
ffffffffc020383a:	dc250513          	addi	a0,a0,-574 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc020383e:	8c9fc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0203842:	00002697          	auipc	a3,0x2
ffffffffc0203846:	22e68693          	addi	a3,a3,558 # ffffffffc0205a70 <default_pmm_manager+0x5b0>
ffffffffc020384a:	00001617          	auipc	a2,0x1
ffffffffc020384e:	22e60613          	addi	a2,a2,558 # ffffffffc0204a78 <commands+0x858>
ffffffffc0203852:	1d200593          	li	a1,466
ffffffffc0203856:	00002517          	auipc	a0,0x2
ffffffffc020385a:	da250513          	addi	a0,a0,-606 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc020385e:	8a9fc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0203862 <tlb_invalidate>:
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0203862:	12000073          	sfence.vma
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }
ffffffffc0203866:	8082                	ret

ffffffffc0203868 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203868:	7179                	addi	sp,sp,-48
ffffffffc020386a:	e84a                	sd	s2,16(sp)
ffffffffc020386c:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc020386e:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203870:	f022                	sd	s0,32(sp)
ffffffffc0203872:	ec26                	sd	s1,24(sp)
ffffffffc0203874:	e44e                	sd	s3,8(sp)
ffffffffc0203876:	f406                	sd	ra,40(sp)
ffffffffc0203878:	84ae                	mv	s1,a1
ffffffffc020387a:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc020387c:	852ff0ef          	jal	ra,ffffffffc02028ce <alloc_pages>
ffffffffc0203880:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0203882:	cd19                	beqz	a0,ffffffffc02038a0 <pgdir_alloc_page+0x38>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0203884:	85aa                	mv	a1,a0
ffffffffc0203886:	86ce                	mv	a3,s3
ffffffffc0203888:	8626                	mv	a2,s1
ffffffffc020388a:	854a                	mv	a0,s2
ffffffffc020388c:	c28ff0ef          	jal	ra,ffffffffc0202cb4 <page_insert>
ffffffffc0203890:	ed39                	bnez	a0,ffffffffc02038ee <pgdir_alloc_page+0x86>
        if (swap_init_ok) {
ffffffffc0203892:	0000d797          	auipc	a5,0xd
ffffffffc0203896:	bce78793          	addi	a5,a5,-1074 # ffffffffc0210460 <swap_init_ok>
ffffffffc020389a:	439c                	lw	a5,0(a5)
ffffffffc020389c:	2781                	sext.w	a5,a5
ffffffffc020389e:	eb89                	bnez	a5,ffffffffc02038b0 <pgdir_alloc_page+0x48>
}
ffffffffc02038a0:	8522                	mv	a0,s0
ffffffffc02038a2:	70a2                	ld	ra,40(sp)
ffffffffc02038a4:	7402                	ld	s0,32(sp)
ffffffffc02038a6:	64e2                	ld	s1,24(sp)
ffffffffc02038a8:	6942                	ld	s2,16(sp)
ffffffffc02038aa:	69a2                	ld	s3,8(sp)
ffffffffc02038ac:	6145                	addi	sp,sp,48
ffffffffc02038ae:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc02038b0:	0000d797          	auipc	a5,0xd
ffffffffc02038b4:	bd078793          	addi	a5,a5,-1072 # ffffffffc0210480 <check_mm_struct>
ffffffffc02038b8:	6388                	ld	a0,0(a5)
ffffffffc02038ba:	4681                	li	a3,0
ffffffffc02038bc:	8622                	mv	a2,s0
ffffffffc02038be:	85a6                	mv	a1,s1
ffffffffc02038c0:	86efe0ef          	jal	ra,ffffffffc020192e <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc02038c4:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc02038c6:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1);
ffffffffc02038c8:	4785                	li	a5,1
ffffffffc02038ca:	fcf70be3          	beq	a4,a5,ffffffffc02038a0 <pgdir_alloc_page+0x38>
ffffffffc02038ce:	00002697          	auipc	a3,0x2
ffffffffc02038d2:	d7a68693          	addi	a3,a3,-646 # ffffffffc0205648 <default_pmm_manager+0x188>
ffffffffc02038d6:	00001617          	auipc	a2,0x1
ffffffffc02038da:	1a260613          	addi	a2,a2,418 # ffffffffc0204a78 <commands+0x858>
ffffffffc02038de:	17a00593          	li	a1,378
ffffffffc02038e2:	00002517          	auipc	a0,0x2
ffffffffc02038e6:	d1650513          	addi	a0,a0,-746 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02038ea:	81dfc0ef          	jal	ra,ffffffffc0200106 <__panic>
            free_page(page);
ffffffffc02038ee:	8522                	mv	a0,s0
ffffffffc02038f0:	4585                	li	a1,1
ffffffffc02038f2:	864ff0ef          	jal	ra,ffffffffc0202956 <free_pages>
            return NULL;
ffffffffc02038f6:	4401                	li	s0,0
ffffffffc02038f8:	b765                	j	ffffffffc02038a0 <pgdir_alloc_page+0x38>

ffffffffc02038fa <kmalloc>:
}

void *kmalloc(size_t n) {
ffffffffc02038fa:	1141                	addi	sp,sp,-16
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02038fc:	67d5                	lui	a5,0x15
void *kmalloc(size_t n) {
ffffffffc02038fe:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0203900:	fff50713          	addi	a4,a0,-1
ffffffffc0203904:	17f9                	addi	a5,a5,-2
ffffffffc0203906:	04e7ee63          	bltu	a5,a4,ffffffffc0203962 <kmalloc+0x68>
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc020390a:	6785                	lui	a5,0x1
ffffffffc020390c:	17fd                	addi	a5,a5,-1
ffffffffc020390e:	953e                	add	a0,a0,a5
    base = alloc_pages(num_pages);
ffffffffc0203910:	8131                	srli	a0,a0,0xc
ffffffffc0203912:	fbdfe0ef          	jal	ra,ffffffffc02028ce <alloc_pages>
    assert(base != NULL);
ffffffffc0203916:	c159                	beqz	a0,ffffffffc020399c <kmalloc+0xa2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203918:	0000d797          	auipc	a5,0xd
ffffffffc020391c:	c7078793          	addi	a5,a5,-912 # ffffffffc0210588 <pages>
ffffffffc0203920:	639c                	ld	a5,0(a5)
ffffffffc0203922:	8d1d                	sub	a0,a0,a5
ffffffffc0203924:	00002797          	auipc	a5,0x2
ffffffffc0203928:	84478793          	addi	a5,a5,-1980 # ffffffffc0205168 <commands+0xf48>
ffffffffc020392c:	6394                	ld	a3,0(a5)
ffffffffc020392e:	850d                	srai	a0,a0,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203930:	0000d797          	auipc	a5,0xd
ffffffffc0203934:	b4078793          	addi	a5,a5,-1216 # ffffffffc0210470 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203938:	02d50533          	mul	a0,a0,a3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020393c:	6398                	ld	a4,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020393e:	000806b7          	lui	a3,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203942:	57fd                	li	a5,-1
ffffffffc0203944:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203946:	9536                	add	a0,a0,a3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203948:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc020394a:	0532                	slli	a0,a0,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020394c:	02e7fb63          	bleu	a4,a5,ffffffffc0203982 <kmalloc+0x88>
ffffffffc0203950:	0000d797          	auipc	a5,0xd
ffffffffc0203954:	c2878793          	addi	a5,a5,-984 # ffffffffc0210578 <va_pa_offset>
ffffffffc0203958:	639c                	ld	a5,0(a5)
    ptr = page2kva(base);
    return ptr;
}
ffffffffc020395a:	60a2                	ld	ra,8(sp)
ffffffffc020395c:	953e                	add	a0,a0,a5
ffffffffc020395e:	0141                	addi	sp,sp,16
ffffffffc0203960:	8082                	ret
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0203962:	00002697          	auipc	a3,0x2
ffffffffc0203966:	cb668693          	addi	a3,a3,-842 # ffffffffc0205618 <default_pmm_manager+0x158>
ffffffffc020396a:	00001617          	auipc	a2,0x1
ffffffffc020396e:	10e60613          	addi	a2,a2,270 # ffffffffc0204a78 <commands+0x858>
ffffffffc0203972:	1f000593          	li	a1,496
ffffffffc0203976:	00002517          	auipc	a0,0x2
ffffffffc020397a:	c8250513          	addi	a0,a0,-894 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc020397e:	f88fc0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc0203982:	86aa                	mv	a3,a0
ffffffffc0203984:	00002617          	auipc	a2,0x2
ffffffffc0203988:	c4c60613          	addi	a2,a2,-948 # ffffffffc02055d0 <default_pmm_manager+0x110>
ffffffffc020398c:	06a00593          	li	a1,106
ffffffffc0203990:	00001517          	auipc	a0,0x1
ffffffffc0203994:	40050513          	addi	a0,a0,1024 # ffffffffc0204d90 <commands+0xb70>
ffffffffc0203998:	f6efc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(base != NULL);
ffffffffc020399c:	00002697          	auipc	a3,0x2
ffffffffc02039a0:	c9c68693          	addi	a3,a3,-868 # ffffffffc0205638 <default_pmm_manager+0x178>
ffffffffc02039a4:	00001617          	auipc	a2,0x1
ffffffffc02039a8:	0d460613          	addi	a2,a2,212 # ffffffffc0204a78 <commands+0x858>
ffffffffc02039ac:	1f300593          	li	a1,499
ffffffffc02039b0:	00002517          	auipc	a0,0x2
ffffffffc02039b4:	c4850513          	addi	a0,a0,-952 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc02039b8:	f4efc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc02039bc <kfree>:

void kfree(void *ptr, size_t n) {
ffffffffc02039bc:	1141                	addi	sp,sp,-16
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02039be:	67d5                	lui	a5,0x15
void kfree(void *ptr, size_t n) {
ffffffffc02039c0:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02039c2:	fff58713          	addi	a4,a1,-1
ffffffffc02039c6:	17f9                	addi	a5,a5,-2
ffffffffc02039c8:	04e7eb63          	bltu	a5,a4,ffffffffc0203a1e <kfree+0x62>
    assert(ptr != NULL);
ffffffffc02039cc:	c941                	beqz	a0,ffffffffc0203a5c <kfree+0xa0>
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc02039ce:	6785                	lui	a5,0x1
ffffffffc02039d0:	17fd                	addi	a5,a5,-1
ffffffffc02039d2:	95be                	add	a1,a1,a5
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc02039d4:	c02007b7          	lui	a5,0xc0200
ffffffffc02039d8:	81b1                	srli	a1,a1,0xc
ffffffffc02039da:	06f56463          	bltu	a0,a5,ffffffffc0203a42 <kfree+0x86>
ffffffffc02039de:	0000d797          	auipc	a5,0xd
ffffffffc02039e2:	b9a78793          	addi	a5,a5,-1126 # ffffffffc0210578 <va_pa_offset>
ffffffffc02039e6:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc02039e8:	0000d717          	auipc	a4,0xd
ffffffffc02039ec:	a8870713          	addi	a4,a4,-1400 # ffffffffc0210470 <npage>
ffffffffc02039f0:	6318                	ld	a4,0(a4)
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc02039f2:	40f507b3          	sub	a5,a0,a5
    if (PPN(pa) >= npage) {
ffffffffc02039f6:	83b1                	srli	a5,a5,0xc
ffffffffc02039f8:	04e7f363          	bleu	a4,a5,ffffffffc0203a3e <kfree+0x82>
    return &pages[PPN(pa) - nbase];
ffffffffc02039fc:	fff80537          	lui	a0,0xfff80
ffffffffc0203a00:	97aa                	add	a5,a5,a0
ffffffffc0203a02:	0000d697          	auipc	a3,0xd
ffffffffc0203a06:	b8668693          	addi	a3,a3,-1146 # ffffffffc0210588 <pages>
ffffffffc0203a0a:	6288                	ld	a0,0(a3)
ffffffffc0203a0c:	00379713          	slli	a4,a5,0x3
    base = kva2page(ptr);
    free_pages(base, num_pages);
}
ffffffffc0203a10:	60a2                	ld	ra,8(sp)
ffffffffc0203a12:	97ba                	add	a5,a5,a4
ffffffffc0203a14:	078e                	slli	a5,a5,0x3
    free_pages(base, num_pages);
ffffffffc0203a16:	953e                	add	a0,a0,a5
}
ffffffffc0203a18:	0141                	addi	sp,sp,16
    free_pages(base, num_pages);
ffffffffc0203a1a:	f3dfe06f          	j	ffffffffc0202956 <free_pages>
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0203a1e:	00002697          	auipc	a3,0x2
ffffffffc0203a22:	bfa68693          	addi	a3,a3,-1030 # ffffffffc0205618 <default_pmm_manager+0x158>
ffffffffc0203a26:	00001617          	auipc	a2,0x1
ffffffffc0203a2a:	05260613          	addi	a2,a2,82 # ffffffffc0204a78 <commands+0x858>
ffffffffc0203a2e:	1f900593          	li	a1,505
ffffffffc0203a32:	00002517          	auipc	a0,0x2
ffffffffc0203a36:	bc650513          	addi	a0,a0,-1082 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203a3a:	eccfc0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc0203a3e:	e75fe0ef          	jal	ra,ffffffffc02028b2 <pa2page.part.4>
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0203a42:	86aa                	mv	a3,a0
ffffffffc0203a44:	00002617          	auipc	a2,0x2
ffffffffc0203a48:	ca460613          	addi	a2,a2,-860 # ffffffffc02056e8 <default_pmm_manager+0x228>
ffffffffc0203a4c:	06c00593          	li	a1,108
ffffffffc0203a50:	00001517          	auipc	a0,0x1
ffffffffc0203a54:	34050513          	addi	a0,a0,832 # ffffffffc0204d90 <commands+0xb70>
ffffffffc0203a58:	eaefc0ef          	jal	ra,ffffffffc0200106 <__panic>
    assert(ptr != NULL);
ffffffffc0203a5c:	00002697          	auipc	a3,0x2
ffffffffc0203a60:	bac68693          	addi	a3,a3,-1108 # ffffffffc0205608 <default_pmm_manager+0x148>
ffffffffc0203a64:	00001617          	auipc	a2,0x1
ffffffffc0203a68:	01460613          	addi	a2,a2,20 # ffffffffc0204a78 <commands+0x858>
ffffffffc0203a6c:	1fa00593          	li	a1,506
ffffffffc0203a70:	00002517          	auipc	a0,0x2
ffffffffc0203a74:	b8850513          	addi	a0,a0,-1144 # ffffffffc02055f8 <default_pmm_manager+0x138>
ffffffffc0203a78:	e8efc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0203a7c <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0203a7c:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203a7e:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0203a80:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203a82:	955fc0ef          	jal	ra,ffffffffc02003d6 <ide_device_valid>
ffffffffc0203a86:	cd01                	beqz	a0,ffffffffc0203a9e <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203a88:	4505                	li	a0,1
ffffffffc0203a8a:	953fc0ef          	jal	ra,ffffffffc02003dc <ide_device_size>
}
ffffffffc0203a8e:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203a90:	810d                	srli	a0,a0,0x3
ffffffffc0203a92:	0000d797          	auipc	a5,0xd
ffffffffc0203a96:	a6a7bf23          	sd	a0,-1410(a5) # ffffffffc0210510 <max_swap_offset>
}
ffffffffc0203a9a:	0141                	addi	sp,sp,16
ffffffffc0203a9c:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0203a9e:	00002617          	auipc	a2,0x2
ffffffffc0203aa2:	12a60613          	addi	a2,a2,298 # ffffffffc0205bc8 <default_pmm_manager+0x708>
ffffffffc0203aa6:	45b5                	li	a1,13
ffffffffc0203aa8:	00002517          	auipc	a0,0x2
ffffffffc0203aac:	14050513          	addi	a0,a0,320 # ffffffffc0205be8 <default_pmm_manager+0x728>
ffffffffc0203ab0:	e56fc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0203ab4 <swapfs_write>:
swapfs_read(swap_entry_t entry, struct Page *page) {
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
}

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0203ab4:	1141                	addi	sp,sp,-16
ffffffffc0203ab6:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203ab8:	00855793          	srli	a5,a0,0x8
ffffffffc0203abc:	c7b5                	beqz	a5,ffffffffc0203b28 <swapfs_write+0x74>
ffffffffc0203abe:	0000d717          	auipc	a4,0xd
ffffffffc0203ac2:	a5270713          	addi	a4,a4,-1454 # ffffffffc0210510 <max_swap_offset>
ffffffffc0203ac6:	6318                	ld	a4,0(a4)
ffffffffc0203ac8:	06e7f063          	bleu	a4,a5,ffffffffc0203b28 <swapfs_write+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203acc:	0000d717          	auipc	a4,0xd
ffffffffc0203ad0:	abc70713          	addi	a4,a4,-1348 # ffffffffc0210588 <pages>
ffffffffc0203ad4:	6310                	ld	a2,0(a4)
ffffffffc0203ad6:	00001717          	auipc	a4,0x1
ffffffffc0203ada:	69270713          	addi	a4,a4,1682 # ffffffffc0205168 <commands+0xf48>
ffffffffc0203ade:	00002697          	auipc	a3,0x2
ffffffffc0203ae2:	38a68693          	addi	a3,a3,906 # ffffffffc0205e68 <nbase>
ffffffffc0203ae6:	40c58633          	sub	a2,a1,a2
ffffffffc0203aea:	630c                	ld	a1,0(a4)
ffffffffc0203aec:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203aee:	0000d717          	auipc	a4,0xd
ffffffffc0203af2:	98270713          	addi	a4,a4,-1662 # ffffffffc0210470 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203af6:	02b60633          	mul	a2,a2,a1
ffffffffc0203afa:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203afe:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203b00:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203b02:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203b04:	57fd                	li	a5,-1
ffffffffc0203b06:	83b1                	srli	a5,a5,0xc
ffffffffc0203b08:	8ff1                	and	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203b0a:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203b0c:	02e7fa63          	bleu	a4,a5,ffffffffc0203b40 <swapfs_write+0x8c>
ffffffffc0203b10:	0000d797          	auipc	a5,0xd
ffffffffc0203b14:	a6878793          	addi	a5,a5,-1432 # ffffffffc0210578 <va_pa_offset>
ffffffffc0203b18:	639c                	ld	a5,0(a5)
}
ffffffffc0203b1a:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203b1c:	46a1                	li	a3,8
ffffffffc0203b1e:	963e                	add	a2,a2,a5
ffffffffc0203b20:	4505                	li	a0,1
}
ffffffffc0203b22:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203b24:	8bffc06f          	j	ffffffffc02003e2 <ide_write_secs>
ffffffffc0203b28:	86aa                	mv	a3,a0
ffffffffc0203b2a:	00002617          	auipc	a2,0x2
ffffffffc0203b2e:	0d660613          	addi	a2,a2,214 # ffffffffc0205c00 <default_pmm_manager+0x740>
ffffffffc0203b32:	45e5                	li	a1,25
ffffffffc0203b34:	00002517          	auipc	a0,0x2
ffffffffc0203b38:	0b450513          	addi	a0,a0,180 # ffffffffc0205be8 <default_pmm_manager+0x728>
ffffffffc0203b3c:	dcafc0ef          	jal	ra,ffffffffc0200106 <__panic>
ffffffffc0203b40:	86b2                	mv	a3,a2
ffffffffc0203b42:	06a00593          	li	a1,106
ffffffffc0203b46:	00002617          	auipc	a2,0x2
ffffffffc0203b4a:	a8a60613          	addi	a2,a2,-1398 # ffffffffc02055d0 <default_pmm_manager+0x110>
ffffffffc0203b4e:	00001517          	auipc	a0,0x1
ffffffffc0203b52:	24250513          	addi	a0,a0,578 # ffffffffc0204d90 <commands+0xb70>
ffffffffc0203b56:	db0fc0ef          	jal	ra,ffffffffc0200106 <__panic>

ffffffffc0203b5a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203b5a:	00054783          	lbu	a5,0(a0)
ffffffffc0203b5e:	cb91                	beqz	a5,ffffffffc0203b72 <strlen+0x18>
    size_t cnt = 0;
ffffffffc0203b60:	4781                	li	a5,0
        cnt ++;
ffffffffc0203b62:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0203b64:	00f50733          	add	a4,a0,a5
ffffffffc0203b68:	00074703          	lbu	a4,0(a4)
ffffffffc0203b6c:	fb7d                	bnez	a4,ffffffffc0203b62 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0203b6e:	853e                	mv	a0,a5
ffffffffc0203b70:	8082                	ret
    size_t cnt = 0;
ffffffffc0203b72:	4781                	li	a5,0
}
ffffffffc0203b74:	853e                	mv	a0,a5
ffffffffc0203b76:	8082                	ret

ffffffffc0203b78 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203b78:	c185                	beqz	a1,ffffffffc0203b98 <strnlen+0x20>
ffffffffc0203b7a:	00054783          	lbu	a5,0(a0)
ffffffffc0203b7e:	cf89                	beqz	a5,ffffffffc0203b98 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0203b80:	4781                	li	a5,0
ffffffffc0203b82:	a021                	j	ffffffffc0203b8a <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203b84:	00074703          	lbu	a4,0(a4)
ffffffffc0203b88:	c711                	beqz	a4,ffffffffc0203b94 <strnlen+0x1c>
        cnt ++;
ffffffffc0203b8a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203b8c:	00f50733          	add	a4,a0,a5
ffffffffc0203b90:	fef59ae3          	bne	a1,a5,ffffffffc0203b84 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0203b94:	853e                	mv	a0,a5
ffffffffc0203b96:	8082                	ret
    size_t cnt = 0;
ffffffffc0203b98:	4781                	li	a5,0
}
ffffffffc0203b9a:	853e                	mv	a0,a5
ffffffffc0203b9c:	8082                	ret

ffffffffc0203b9e <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203b9e:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203ba0:	0585                	addi	a1,a1,1
ffffffffc0203ba2:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203ba6:	0785                	addi	a5,a5,1
ffffffffc0203ba8:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203bac:	fb75                	bnez	a4,ffffffffc0203ba0 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203bae:	8082                	ret

ffffffffc0203bb0 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203bb0:	00054783          	lbu	a5,0(a0)
ffffffffc0203bb4:	0005c703          	lbu	a4,0(a1)
ffffffffc0203bb8:	cb91                	beqz	a5,ffffffffc0203bcc <strcmp+0x1c>
ffffffffc0203bba:	00e79c63          	bne	a5,a4,ffffffffc0203bd2 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0203bbe:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203bc0:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0203bc4:	0585                	addi	a1,a1,1
ffffffffc0203bc6:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203bca:	fbe5                	bnez	a5,ffffffffc0203bba <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203bcc:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203bce:	9d19                	subw	a0,a0,a4
ffffffffc0203bd0:	8082                	ret
ffffffffc0203bd2:	0007851b          	sext.w	a0,a5
ffffffffc0203bd6:	9d19                	subw	a0,a0,a4
ffffffffc0203bd8:	8082                	ret

ffffffffc0203bda <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203bda:	00054783          	lbu	a5,0(a0)
ffffffffc0203bde:	cb91                	beqz	a5,ffffffffc0203bf2 <strchr+0x18>
        if (*s == c) {
ffffffffc0203be0:	00b79563          	bne	a5,a1,ffffffffc0203bea <strchr+0x10>
ffffffffc0203be4:	a809                	j	ffffffffc0203bf6 <strchr+0x1c>
ffffffffc0203be6:	00b78763          	beq	a5,a1,ffffffffc0203bf4 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0203bea:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203bec:	00054783          	lbu	a5,0(a0)
ffffffffc0203bf0:	fbfd                	bnez	a5,ffffffffc0203be6 <strchr+0xc>
    }
    return NULL;
ffffffffc0203bf2:	4501                	li	a0,0
}
ffffffffc0203bf4:	8082                	ret
ffffffffc0203bf6:	8082                	ret

ffffffffc0203bf8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203bf8:	ca01                	beqz	a2,ffffffffc0203c08 <memset+0x10>
ffffffffc0203bfa:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203bfc:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203bfe:	0785                	addi	a5,a5,1
ffffffffc0203c00:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203c04:	fec79de3          	bne	a5,a2,ffffffffc0203bfe <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203c08:	8082                	ret

ffffffffc0203c0a <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203c0a:	ca19                	beqz	a2,ffffffffc0203c20 <memcpy+0x16>
ffffffffc0203c0c:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203c0e:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203c10:	0585                	addi	a1,a1,1
ffffffffc0203c12:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203c16:	0785                	addi	a5,a5,1
ffffffffc0203c18:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203c1c:	fec59ae3          	bne	a1,a2,ffffffffc0203c10 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203c20:	8082                	ret

ffffffffc0203c22 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203c22:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203c26:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203c28:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203c2c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203c2e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203c32:	f022                	sd	s0,32(sp)
ffffffffc0203c34:	ec26                	sd	s1,24(sp)
ffffffffc0203c36:	e84a                	sd	s2,16(sp)
ffffffffc0203c38:	f406                	sd	ra,40(sp)
ffffffffc0203c3a:	e44e                	sd	s3,8(sp)
ffffffffc0203c3c:	84aa                	mv	s1,a0
ffffffffc0203c3e:	892e                	mv	s2,a1
ffffffffc0203c40:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203c44:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0203c46:	03067e63          	bleu	a6,a2,ffffffffc0203c82 <printnum+0x60>
ffffffffc0203c4a:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203c4c:	00805763          	blez	s0,ffffffffc0203c5a <printnum+0x38>
ffffffffc0203c50:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203c52:	85ca                	mv	a1,s2
ffffffffc0203c54:	854e                	mv	a0,s3
ffffffffc0203c56:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203c58:	fc65                	bnez	s0,ffffffffc0203c50 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203c5a:	1a02                	slli	s4,s4,0x20
ffffffffc0203c5c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203c60:	00002797          	auipc	a5,0x2
ffffffffc0203c64:	15078793          	addi	a5,a5,336 # ffffffffc0205db0 <error_string+0x38>
ffffffffc0203c68:	9a3e                	add	s4,s4,a5
}
ffffffffc0203c6a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203c6c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203c70:	70a2                	ld	ra,40(sp)
ffffffffc0203c72:	69a2                	ld	s3,8(sp)
ffffffffc0203c74:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203c76:	85ca                	mv	a1,s2
ffffffffc0203c78:	8326                	mv	t1,s1
}
ffffffffc0203c7a:	6942                	ld	s2,16(sp)
ffffffffc0203c7c:	64e2                	ld	s1,24(sp)
ffffffffc0203c7e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203c80:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203c82:	03065633          	divu	a2,a2,a6
ffffffffc0203c86:	8722                	mv	a4,s0
ffffffffc0203c88:	f9bff0ef          	jal	ra,ffffffffc0203c22 <printnum>
ffffffffc0203c8c:	b7f9                	j	ffffffffc0203c5a <printnum+0x38>

ffffffffc0203c8e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203c8e:	7119                	addi	sp,sp,-128
ffffffffc0203c90:	f4a6                	sd	s1,104(sp)
ffffffffc0203c92:	f0ca                	sd	s2,96(sp)
ffffffffc0203c94:	e8d2                	sd	s4,80(sp)
ffffffffc0203c96:	e4d6                	sd	s5,72(sp)
ffffffffc0203c98:	e0da                	sd	s6,64(sp)
ffffffffc0203c9a:	fc5e                	sd	s7,56(sp)
ffffffffc0203c9c:	f862                	sd	s8,48(sp)
ffffffffc0203c9e:	f06a                	sd	s10,32(sp)
ffffffffc0203ca0:	fc86                	sd	ra,120(sp)
ffffffffc0203ca2:	f8a2                	sd	s0,112(sp)
ffffffffc0203ca4:	ecce                	sd	s3,88(sp)
ffffffffc0203ca6:	f466                	sd	s9,40(sp)
ffffffffc0203ca8:	ec6e                	sd	s11,24(sp)
ffffffffc0203caa:	892a                	mv	s2,a0
ffffffffc0203cac:	84ae                	mv	s1,a1
ffffffffc0203cae:	8d32                	mv	s10,a2
ffffffffc0203cb0:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203cb2:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203cb4:	00002a17          	auipc	s4,0x2
ffffffffc0203cb8:	f6ca0a13          	addi	s4,s4,-148 # ffffffffc0205c20 <default_pmm_manager+0x760>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203cbc:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203cc0:	00002c17          	auipc	s8,0x2
ffffffffc0203cc4:	0b8c0c13          	addi	s8,s8,184 # ffffffffc0205d78 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203cc8:	000d4503          	lbu	a0,0(s10)
ffffffffc0203ccc:	02500793          	li	a5,37
ffffffffc0203cd0:	001d0413          	addi	s0,s10,1
ffffffffc0203cd4:	00f50e63          	beq	a0,a5,ffffffffc0203cf0 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0203cd8:	c521                	beqz	a0,ffffffffc0203d20 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203cda:	02500993          	li	s3,37
ffffffffc0203cde:	a011                	j	ffffffffc0203ce2 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0203ce0:	c121                	beqz	a0,ffffffffc0203d20 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0203ce2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ce4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203ce6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ce8:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203cec:	ff351ae3          	bne	a0,s3,ffffffffc0203ce0 <vprintfmt+0x52>
ffffffffc0203cf0:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203cf4:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203cf8:	4981                	li	s3,0
ffffffffc0203cfa:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0203cfc:	5cfd                	li	s9,-1
ffffffffc0203cfe:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203d00:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0203d04:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203d06:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0203d0a:	0ff6f693          	andi	a3,a3,255
ffffffffc0203d0e:	00140d13          	addi	s10,s0,1
ffffffffc0203d12:	20d5e563          	bltu	a1,a3,ffffffffc0203f1c <vprintfmt+0x28e>
ffffffffc0203d16:	068a                	slli	a3,a3,0x2
ffffffffc0203d18:	96d2                	add	a3,a3,s4
ffffffffc0203d1a:	4294                	lw	a3,0(a3)
ffffffffc0203d1c:	96d2                	add	a3,a3,s4
ffffffffc0203d1e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203d20:	70e6                	ld	ra,120(sp)
ffffffffc0203d22:	7446                	ld	s0,112(sp)
ffffffffc0203d24:	74a6                	ld	s1,104(sp)
ffffffffc0203d26:	7906                	ld	s2,96(sp)
ffffffffc0203d28:	69e6                	ld	s3,88(sp)
ffffffffc0203d2a:	6a46                	ld	s4,80(sp)
ffffffffc0203d2c:	6aa6                	ld	s5,72(sp)
ffffffffc0203d2e:	6b06                	ld	s6,64(sp)
ffffffffc0203d30:	7be2                	ld	s7,56(sp)
ffffffffc0203d32:	7c42                	ld	s8,48(sp)
ffffffffc0203d34:	7ca2                	ld	s9,40(sp)
ffffffffc0203d36:	7d02                	ld	s10,32(sp)
ffffffffc0203d38:	6de2                	ld	s11,24(sp)
ffffffffc0203d3a:	6109                	addi	sp,sp,128
ffffffffc0203d3c:	8082                	ret
    if (lflag >= 2) {
ffffffffc0203d3e:	4705                	li	a4,1
ffffffffc0203d40:	008a8593          	addi	a1,s5,8
ffffffffc0203d44:	01074463          	blt	a4,a6,ffffffffc0203d4c <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0203d48:	26080363          	beqz	a6,ffffffffc0203fae <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc0203d4c:	000ab603          	ld	a2,0(s5)
ffffffffc0203d50:	46c1                	li	a3,16
ffffffffc0203d52:	8aae                	mv	s5,a1
ffffffffc0203d54:	a06d                	j	ffffffffc0203dfe <vprintfmt+0x170>
            goto reswitch;
ffffffffc0203d56:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203d5a:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203d5c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203d5e:	b765                	j	ffffffffc0203d06 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0203d60:	000aa503          	lw	a0,0(s5)
ffffffffc0203d64:	85a6                	mv	a1,s1
ffffffffc0203d66:	0aa1                	addi	s5,s5,8
ffffffffc0203d68:	9902                	jalr	s2
            break;
ffffffffc0203d6a:	bfb9                	j	ffffffffc0203cc8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203d6c:	4705                	li	a4,1
ffffffffc0203d6e:	008a8993          	addi	s3,s5,8
ffffffffc0203d72:	01074463          	blt	a4,a6,ffffffffc0203d7a <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0203d76:	22080463          	beqz	a6,ffffffffc0203f9e <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc0203d7a:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0203d7e:	24044463          	bltz	s0,ffffffffc0203fc6 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0203d82:	8622                	mv	a2,s0
ffffffffc0203d84:	8ace                	mv	s5,s3
ffffffffc0203d86:	46a9                	li	a3,10
ffffffffc0203d88:	a89d                	j	ffffffffc0203dfe <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc0203d8a:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203d8e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203d90:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0203d92:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203d96:	8fb5                	xor	a5,a5,a3
ffffffffc0203d98:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203d9c:	1ad74363          	blt	a4,a3,ffffffffc0203f42 <vprintfmt+0x2b4>
ffffffffc0203da0:	00369793          	slli	a5,a3,0x3
ffffffffc0203da4:	97e2                	add	a5,a5,s8
ffffffffc0203da6:	639c                	ld	a5,0(a5)
ffffffffc0203da8:	18078d63          	beqz	a5,ffffffffc0203f42 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203dac:	86be                	mv	a3,a5
ffffffffc0203dae:	00002617          	auipc	a2,0x2
ffffffffc0203db2:	0b260613          	addi	a2,a2,178 # ffffffffc0205e60 <error_string+0xe8>
ffffffffc0203db6:	85a6                	mv	a1,s1
ffffffffc0203db8:	854a                	mv	a0,s2
ffffffffc0203dba:	240000ef          	jal	ra,ffffffffc0203ffa <printfmt>
ffffffffc0203dbe:	b729                	j	ffffffffc0203cc8 <vprintfmt+0x3a>
            lflag ++;
ffffffffc0203dc0:	00144603          	lbu	a2,1(s0)
ffffffffc0203dc4:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203dc6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203dc8:	bf3d                	j	ffffffffc0203d06 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0203dca:	4705                	li	a4,1
ffffffffc0203dcc:	008a8593          	addi	a1,s5,8
ffffffffc0203dd0:	01074463          	blt	a4,a6,ffffffffc0203dd8 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0203dd4:	1e080263          	beqz	a6,ffffffffc0203fb8 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc0203dd8:	000ab603          	ld	a2,0(s5)
ffffffffc0203ddc:	46a1                	li	a3,8
ffffffffc0203dde:	8aae                	mv	s5,a1
ffffffffc0203de0:	a839                	j	ffffffffc0203dfe <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0203de2:	03000513          	li	a0,48
ffffffffc0203de6:	85a6                	mv	a1,s1
ffffffffc0203de8:	e03e                	sd	a5,0(sp)
ffffffffc0203dea:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203dec:	85a6                	mv	a1,s1
ffffffffc0203dee:	07800513          	li	a0,120
ffffffffc0203df2:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203df4:	0aa1                	addi	s5,s5,8
ffffffffc0203df6:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0203dfa:	6782                	ld	a5,0(sp)
ffffffffc0203dfc:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203dfe:	876e                	mv	a4,s11
ffffffffc0203e00:	85a6                	mv	a1,s1
ffffffffc0203e02:	854a                	mv	a0,s2
ffffffffc0203e04:	e1fff0ef          	jal	ra,ffffffffc0203c22 <printnum>
            break;
ffffffffc0203e08:	b5c1                	j	ffffffffc0203cc8 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203e0a:	000ab603          	ld	a2,0(s5)
ffffffffc0203e0e:	0aa1                	addi	s5,s5,8
ffffffffc0203e10:	1c060663          	beqz	a2,ffffffffc0203fdc <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0203e14:	00160413          	addi	s0,a2,1
ffffffffc0203e18:	17b05c63          	blez	s11,ffffffffc0203f90 <vprintfmt+0x302>
ffffffffc0203e1c:	02d00593          	li	a1,45
ffffffffc0203e20:	14b79263          	bne	a5,a1,ffffffffc0203f64 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203e24:	00064783          	lbu	a5,0(a2)
ffffffffc0203e28:	0007851b          	sext.w	a0,a5
ffffffffc0203e2c:	c905                	beqz	a0,ffffffffc0203e5c <vprintfmt+0x1ce>
ffffffffc0203e2e:	000cc563          	bltz	s9,ffffffffc0203e38 <vprintfmt+0x1aa>
ffffffffc0203e32:	3cfd                	addiw	s9,s9,-1
ffffffffc0203e34:	036c8263          	beq	s9,s6,ffffffffc0203e58 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0203e38:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203e3a:	18098463          	beqz	s3,ffffffffc0203fc2 <vprintfmt+0x334>
ffffffffc0203e3e:	3781                	addiw	a5,a5,-32
ffffffffc0203e40:	18fbf163          	bleu	a5,s7,ffffffffc0203fc2 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0203e44:	03f00513          	li	a0,63
ffffffffc0203e48:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203e4a:	0405                	addi	s0,s0,1
ffffffffc0203e4c:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203e50:	3dfd                	addiw	s11,s11,-1
ffffffffc0203e52:	0007851b          	sext.w	a0,a5
ffffffffc0203e56:	fd61                	bnez	a0,ffffffffc0203e2e <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc0203e58:	e7b058e3          	blez	s11,ffffffffc0203cc8 <vprintfmt+0x3a>
ffffffffc0203e5c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0203e5e:	85a6                	mv	a1,s1
ffffffffc0203e60:	02000513          	li	a0,32
ffffffffc0203e64:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203e66:	e60d81e3          	beqz	s11,ffffffffc0203cc8 <vprintfmt+0x3a>
ffffffffc0203e6a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0203e6c:	85a6                	mv	a1,s1
ffffffffc0203e6e:	02000513          	li	a0,32
ffffffffc0203e72:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203e74:	fe0d94e3          	bnez	s11,ffffffffc0203e5c <vprintfmt+0x1ce>
ffffffffc0203e78:	bd81                	j	ffffffffc0203cc8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203e7a:	4705                	li	a4,1
ffffffffc0203e7c:	008a8593          	addi	a1,s5,8
ffffffffc0203e80:	01074463          	blt	a4,a6,ffffffffc0203e88 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0203e84:	12080063          	beqz	a6,ffffffffc0203fa4 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0203e88:	000ab603          	ld	a2,0(s5)
ffffffffc0203e8c:	46a9                	li	a3,10
ffffffffc0203e8e:	8aae                	mv	s5,a1
ffffffffc0203e90:	b7bd                	j	ffffffffc0203dfe <vprintfmt+0x170>
ffffffffc0203e92:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc0203e96:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203e9a:	846a                	mv	s0,s10
ffffffffc0203e9c:	b5ad                	j	ffffffffc0203d06 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0203e9e:	85a6                	mv	a1,s1
ffffffffc0203ea0:	02500513          	li	a0,37
ffffffffc0203ea4:	9902                	jalr	s2
            break;
ffffffffc0203ea6:	b50d                	j	ffffffffc0203cc8 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc0203ea8:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0203eac:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203eb0:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203eb2:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0203eb4:	e40dd9e3          	bgez	s11,ffffffffc0203d06 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0203eb8:	8de6                	mv	s11,s9
ffffffffc0203eba:	5cfd                	li	s9,-1
ffffffffc0203ebc:	b5a9                	j	ffffffffc0203d06 <vprintfmt+0x78>
            goto reswitch;
ffffffffc0203ebe:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc0203ec2:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ec6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203ec8:	bd3d                	j	ffffffffc0203d06 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc0203eca:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0203ece:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ed2:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203ed4:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203ed8:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203edc:	fcd56ce3          	bltu	a0,a3,ffffffffc0203eb4 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc0203ee0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203ee2:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0203ee6:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203eea:	0196873b          	addw	a4,a3,s9
ffffffffc0203eee:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203ef2:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0203ef6:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0203efa:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0203efe:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203f02:	fcd57fe3          	bleu	a3,a0,ffffffffc0203ee0 <vprintfmt+0x252>
ffffffffc0203f06:	b77d                	j	ffffffffc0203eb4 <vprintfmt+0x226>
            if (width < 0)
ffffffffc0203f08:	fffdc693          	not	a3,s11
ffffffffc0203f0c:	96fd                	srai	a3,a3,0x3f
ffffffffc0203f0e:	00ddfdb3          	and	s11,s11,a3
ffffffffc0203f12:	00144603          	lbu	a2,1(s0)
ffffffffc0203f16:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f18:	846a                	mv	s0,s10
ffffffffc0203f1a:	b3f5                	j	ffffffffc0203d06 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0203f1c:	85a6                	mv	a1,s1
ffffffffc0203f1e:	02500513          	li	a0,37
ffffffffc0203f22:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203f24:	fff44703          	lbu	a4,-1(s0)
ffffffffc0203f28:	02500793          	li	a5,37
ffffffffc0203f2c:	8d22                	mv	s10,s0
ffffffffc0203f2e:	d8f70de3          	beq	a4,a5,ffffffffc0203cc8 <vprintfmt+0x3a>
ffffffffc0203f32:	02500713          	li	a4,37
ffffffffc0203f36:	1d7d                	addi	s10,s10,-1
ffffffffc0203f38:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0203f3c:	fee79de3          	bne	a5,a4,ffffffffc0203f36 <vprintfmt+0x2a8>
ffffffffc0203f40:	b361                	j	ffffffffc0203cc8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203f42:	00002617          	auipc	a2,0x2
ffffffffc0203f46:	f0e60613          	addi	a2,a2,-242 # ffffffffc0205e50 <error_string+0xd8>
ffffffffc0203f4a:	85a6                	mv	a1,s1
ffffffffc0203f4c:	854a                	mv	a0,s2
ffffffffc0203f4e:	0ac000ef          	jal	ra,ffffffffc0203ffa <printfmt>
ffffffffc0203f52:	bb9d                	j	ffffffffc0203cc8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0203f54:	00002617          	auipc	a2,0x2
ffffffffc0203f58:	ef460613          	addi	a2,a2,-268 # ffffffffc0205e48 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0203f5c:	00002417          	auipc	s0,0x2
ffffffffc0203f60:	eed40413          	addi	s0,s0,-275 # ffffffffc0205e49 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203f64:	8532                	mv	a0,a2
ffffffffc0203f66:	85e6                	mv	a1,s9
ffffffffc0203f68:	e032                	sd	a2,0(sp)
ffffffffc0203f6a:	e43e                	sd	a5,8(sp)
ffffffffc0203f6c:	c0dff0ef          	jal	ra,ffffffffc0203b78 <strnlen>
ffffffffc0203f70:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203f74:	6602                	ld	a2,0(sp)
ffffffffc0203f76:	01b05d63          	blez	s11,ffffffffc0203f90 <vprintfmt+0x302>
ffffffffc0203f7a:	67a2                	ld	a5,8(sp)
ffffffffc0203f7c:	2781                	sext.w	a5,a5
ffffffffc0203f7e:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0203f80:	6522                	ld	a0,8(sp)
ffffffffc0203f82:	85a6                	mv	a1,s1
ffffffffc0203f84:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203f86:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0203f88:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203f8a:	6602                	ld	a2,0(sp)
ffffffffc0203f8c:	fe0d9ae3          	bnez	s11,ffffffffc0203f80 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203f90:	00064783          	lbu	a5,0(a2)
ffffffffc0203f94:	0007851b          	sext.w	a0,a5
ffffffffc0203f98:	e8051be3          	bnez	a0,ffffffffc0203e2e <vprintfmt+0x1a0>
ffffffffc0203f9c:	b335                	j	ffffffffc0203cc8 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc0203f9e:	000aa403          	lw	s0,0(s5)
ffffffffc0203fa2:	bbf1                	j	ffffffffc0203d7e <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc0203fa4:	000ae603          	lwu	a2,0(s5)
ffffffffc0203fa8:	46a9                	li	a3,10
ffffffffc0203faa:	8aae                	mv	s5,a1
ffffffffc0203fac:	bd89                	j	ffffffffc0203dfe <vprintfmt+0x170>
ffffffffc0203fae:	000ae603          	lwu	a2,0(s5)
ffffffffc0203fb2:	46c1                	li	a3,16
ffffffffc0203fb4:	8aae                	mv	s5,a1
ffffffffc0203fb6:	b5a1                	j	ffffffffc0203dfe <vprintfmt+0x170>
ffffffffc0203fb8:	000ae603          	lwu	a2,0(s5)
ffffffffc0203fbc:	46a1                	li	a3,8
ffffffffc0203fbe:	8aae                	mv	s5,a1
ffffffffc0203fc0:	bd3d                	j	ffffffffc0203dfe <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0203fc2:	9902                	jalr	s2
ffffffffc0203fc4:	b559                	j	ffffffffc0203e4a <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc0203fc6:	85a6                	mv	a1,s1
ffffffffc0203fc8:	02d00513          	li	a0,45
ffffffffc0203fcc:	e03e                	sd	a5,0(sp)
ffffffffc0203fce:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203fd0:	8ace                	mv	s5,s3
ffffffffc0203fd2:	40800633          	neg	a2,s0
ffffffffc0203fd6:	46a9                	li	a3,10
ffffffffc0203fd8:	6782                	ld	a5,0(sp)
ffffffffc0203fda:	b515                	j	ffffffffc0203dfe <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc0203fdc:	01b05663          	blez	s11,ffffffffc0203fe8 <vprintfmt+0x35a>
ffffffffc0203fe0:	02d00693          	li	a3,45
ffffffffc0203fe4:	f6d798e3          	bne	a5,a3,ffffffffc0203f54 <vprintfmt+0x2c6>
ffffffffc0203fe8:	00002417          	auipc	s0,0x2
ffffffffc0203fec:	e6140413          	addi	s0,s0,-415 # ffffffffc0205e49 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203ff0:	02800513          	li	a0,40
ffffffffc0203ff4:	02800793          	li	a5,40
ffffffffc0203ff8:	bd1d                	j	ffffffffc0203e2e <vprintfmt+0x1a0>

ffffffffc0203ffa <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203ffa:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203ffc:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204000:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204002:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204004:	ec06                	sd	ra,24(sp)
ffffffffc0204006:	f83a                	sd	a4,48(sp)
ffffffffc0204008:	fc3e                	sd	a5,56(sp)
ffffffffc020400a:	e0c2                	sd	a6,64(sp)
ffffffffc020400c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020400e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204010:	c7fff0ef          	jal	ra,ffffffffc0203c8e <vprintfmt>
}
ffffffffc0204014:	60e2                	ld	ra,24(sp)
ffffffffc0204016:	6161                	addi	sp,sp,80
ffffffffc0204018:	8082                	ret

ffffffffc020401a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020401a:	715d                	addi	sp,sp,-80
ffffffffc020401c:	e486                	sd	ra,72(sp)
ffffffffc020401e:	e0a2                	sd	s0,64(sp)
ffffffffc0204020:	fc26                	sd	s1,56(sp)
ffffffffc0204022:	f84a                	sd	s2,48(sp)
ffffffffc0204024:	f44e                	sd	s3,40(sp)
ffffffffc0204026:	f052                	sd	s4,32(sp)
ffffffffc0204028:	ec56                	sd	s5,24(sp)
ffffffffc020402a:	e85a                	sd	s6,16(sp)
ffffffffc020402c:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc020402e:	c901                	beqz	a0,ffffffffc020403e <readline+0x24>
        cprintf("%s", prompt);
ffffffffc0204030:	85aa                	mv	a1,a0
ffffffffc0204032:	00002517          	auipc	a0,0x2
ffffffffc0204036:	e2e50513          	addi	a0,a0,-466 # ffffffffc0205e60 <error_string+0xe8>
ffffffffc020403a:	884fc0ef          	jal	ra,ffffffffc02000be <cprintf>
readline(const char *prompt) {
ffffffffc020403e:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204040:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0204042:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0204044:	4aa9                	li	s5,10
ffffffffc0204046:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0204048:	0000cb97          	auipc	s7,0xc
ffffffffc020404c:	ff8b8b93          	addi	s7,s7,-8 # ffffffffc0210040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204050:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0204054:	8a2fc0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc0204058:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc020405a:	00054b63          	bltz	a0,ffffffffc0204070 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020405e:	00a95b63          	ble	a0,s2,ffffffffc0204074 <readline+0x5a>
ffffffffc0204062:	029a5463          	ble	s1,s4,ffffffffc020408a <readline+0x70>
        c = getchar();
ffffffffc0204066:	890fc0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc020406a:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc020406c:	fe0559e3          	bgez	a0,ffffffffc020405e <readline+0x44>
            return NULL;
ffffffffc0204070:	4501                	li	a0,0
ffffffffc0204072:	a099                	j	ffffffffc02040b8 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0204074:	03341463          	bne	s0,s3,ffffffffc020409c <readline+0x82>
ffffffffc0204078:	e8b9                	bnez	s1,ffffffffc02040ce <readline+0xb4>
        c = getchar();
ffffffffc020407a:	87cfc0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc020407e:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0204080:	fe0548e3          	bltz	a0,ffffffffc0204070 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204084:	fea958e3          	ble	a0,s2,ffffffffc0204074 <readline+0x5a>
ffffffffc0204088:	4481                	li	s1,0
            cputchar(c);
ffffffffc020408a:	8522                	mv	a0,s0
ffffffffc020408c:	866fc0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i ++] = c;
ffffffffc0204090:	009b87b3          	add	a5,s7,s1
ffffffffc0204094:	00878023          	sb	s0,0(a5)
ffffffffc0204098:	2485                	addiw	s1,s1,1
ffffffffc020409a:	bf6d                	j	ffffffffc0204054 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc020409c:	01540463          	beq	s0,s5,ffffffffc02040a4 <readline+0x8a>
ffffffffc02040a0:	fb641ae3          	bne	s0,s6,ffffffffc0204054 <readline+0x3a>
            cputchar(c);
ffffffffc02040a4:	8522                	mv	a0,s0
ffffffffc02040a6:	84cfc0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i] = '\0';
ffffffffc02040aa:	0000c517          	auipc	a0,0xc
ffffffffc02040ae:	f9650513          	addi	a0,a0,-106 # ffffffffc0210040 <buf>
ffffffffc02040b2:	94aa                	add	s1,s1,a0
ffffffffc02040b4:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02040b8:	60a6                	ld	ra,72(sp)
ffffffffc02040ba:	6406                	ld	s0,64(sp)
ffffffffc02040bc:	74e2                	ld	s1,56(sp)
ffffffffc02040be:	7942                	ld	s2,48(sp)
ffffffffc02040c0:	79a2                	ld	s3,40(sp)
ffffffffc02040c2:	7a02                	ld	s4,32(sp)
ffffffffc02040c4:	6ae2                	ld	s5,24(sp)
ffffffffc02040c6:	6b42                	ld	s6,16(sp)
ffffffffc02040c8:	6ba2                	ld	s7,8(sp)
ffffffffc02040ca:	6161                	addi	sp,sp,80
ffffffffc02040cc:	8082                	ret
            cputchar(c);
ffffffffc02040ce:	4521                	li	a0,8
ffffffffc02040d0:	822fc0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            i --;
ffffffffc02040d4:	34fd                	addiw	s1,s1,-1
ffffffffc02040d6:	bfbd                	j	ffffffffc0204054 <readline+0x3a>
