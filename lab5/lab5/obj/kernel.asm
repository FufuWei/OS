
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020b2b7          	lui	t0,0xc020b
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
ffffffffc0200028:	c020b137          	lui	sp,0xc020b

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

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	000a1517          	auipc	a0,0xa1
ffffffffc020003a:	fb250513          	addi	a0,a0,-78 # ffffffffc02a0fe8 <edata>
ffffffffc020003e:	000ac617          	auipc	a2,0xac
ffffffffc0200042:	53a60613          	addi	a2,a2,1338 # ffffffffc02ac578 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	1b6060ef          	jal	ra,ffffffffc0206204 <memset>
    cons_init();                // init the console
ffffffffc0200052:	58e000ef          	jal	ra,ffffffffc02005e0 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200056:	00006597          	auipc	a1,0x6
ffffffffc020005a:	5ea58593          	addi	a1,a1,1514 # ffffffffc0206640 <etext+0x2>
ffffffffc020005e:	00006517          	auipc	a0,0x6
ffffffffc0200062:	60250513          	addi	a0,a0,1538 # ffffffffc0206660 <etext+0x22>
ffffffffc0200066:	06a000ef          	jal	ra,ffffffffc02000d0 <cprintf>

    print_kerninfo();
ffffffffc020006a:	25a000ef          	jal	ra,ffffffffc02002c4 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006e:	5e6010ef          	jal	ra,ffffffffc0201654 <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc0200072:	5e2000ef          	jal	ra,ffffffffc0200654 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200076:	5ec000ef          	jal	ra,ffffffffc0200662 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020007a:	2db020ef          	jal	ra,ffffffffc0202b54 <vmm_init>
    proc_init();                // init process table
ffffffffc020007e:	591050ef          	jal	ra,ffffffffc0205e0e <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc0200082:	4b0000ef          	jal	ra,ffffffffc0200532 <ide_init>
    swap_init();                // init swap
ffffffffc0200086:	620030ef          	jal	ra,ffffffffc02036a6 <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020008a:	500000ef          	jal	ra,ffffffffc020058a <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008e:	5c8000ef          	jal	ra,ffffffffc0200656 <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc0200092:	6c9050ef          	jal	ra,ffffffffc0205f5a <cpu_idle>

ffffffffc0200096 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200096:	1141                	addi	sp,sp,-16
ffffffffc0200098:	e022                	sd	s0,0(sp)
ffffffffc020009a:	e406                	sd	ra,8(sp)
ffffffffc020009c:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020009e:	544000ef          	jal	ra,ffffffffc02005e2 <cons_putc>
    (*cnt) ++;
ffffffffc02000a2:	401c                	lw	a5,0(s0)
}
ffffffffc02000a4:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000a6:	2785                	addiw	a5,a5,1
ffffffffc02000a8:	c01c                	sw	a5,0(s0)
}
ffffffffc02000aa:	6402                	ld	s0,0(sp)
ffffffffc02000ac:	0141                	addi	sp,sp,16
ffffffffc02000ae:	8082                	ret

ffffffffc02000b0 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b0:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	86ae                	mv	a3,a1
ffffffffc02000b4:	862a                	mv	a2,a0
ffffffffc02000b6:	006c                	addi	a1,sp,12
ffffffffc02000b8:	00000517          	auipc	a0,0x0
ffffffffc02000bc:	fde50513          	addi	a0,a0,-34 # ffffffffc0200096 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c0:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000c2:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c4:	1d6060ef          	jal	ra,ffffffffc020629a <vprintfmt>
    return cnt;
}
ffffffffc02000c8:	60e2                	ld	ra,24(sp)
ffffffffc02000ca:	4532                	lw	a0,12(sp)
ffffffffc02000cc:	6105                	addi	sp,sp,32
ffffffffc02000ce:	8082                	ret

ffffffffc02000d0 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d0:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000d2:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000d6:	f42e                	sd	a1,40(sp)
ffffffffc02000d8:	f832                	sd	a2,48(sp)
ffffffffc02000da:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000dc:	862a                	mv	a2,a0
ffffffffc02000de:	004c                	addi	a1,sp,4
ffffffffc02000e0:	00000517          	auipc	a0,0x0
ffffffffc02000e4:	fb650513          	addi	a0,a0,-74 # ffffffffc0200096 <cputch>
ffffffffc02000e8:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000ea:	ec06                	sd	ra,24(sp)
ffffffffc02000ec:	e0ba                	sd	a4,64(sp)
ffffffffc02000ee:	e4be                	sd	a5,72(sp)
ffffffffc02000f0:	e8c2                	sd	a6,80(sp)
ffffffffc02000f2:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000f4:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000f6:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f8:	1a2060ef          	jal	ra,ffffffffc020629a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000fc:	60e2                	ld	ra,24(sp)
ffffffffc02000fe:	4512                	lw	a0,4(sp)
ffffffffc0200100:	6125                	addi	sp,sp,96
ffffffffc0200102:	8082                	ret

ffffffffc0200104 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200104:	4de0006f          	j	ffffffffc02005e2 <cons_putc>

ffffffffc0200108 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200108:	1101                	addi	sp,sp,-32
ffffffffc020010a:	e822                	sd	s0,16(sp)
ffffffffc020010c:	ec06                	sd	ra,24(sp)
ffffffffc020010e:	e426                	sd	s1,8(sp)
ffffffffc0200110:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200112:	00054503          	lbu	a0,0(a0)
ffffffffc0200116:	c51d                	beqz	a0,ffffffffc0200144 <cputs+0x3c>
ffffffffc0200118:	0405                	addi	s0,s0,1
ffffffffc020011a:	4485                	li	s1,1
ffffffffc020011c:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020011e:	4c4000ef          	jal	ra,ffffffffc02005e2 <cons_putc>
    (*cnt) ++;
ffffffffc0200122:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc0200126:	0405                	addi	s0,s0,1
ffffffffc0200128:	fff44503          	lbu	a0,-1(s0)
ffffffffc020012c:	f96d                	bnez	a0,ffffffffc020011e <cputs+0x16>
ffffffffc020012e:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200132:	4529                	li	a0,10
ffffffffc0200134:	4ae000ef          	jal	ra,ffffffffc02005e2 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200138:	8522                	mv	a0,s0
ffffffffc020013a:	60e2                	ld	ra,24(sp)
ffffffffc020013c:	6442                	ld	s0,16(sp)
ffffffffc020013e:	64a2                	ld	s1,8(sp)
ffffffffc0200140:	6105                	addi	sp,sp,32
ffffffffc0200142:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200144:	4405                	li	s0,1
ffffffffc0200146:	b7f5                	j	ffffffffc0200132 <cputs+0x2a>

ffffffffc0200148 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200148:	1141                	addi	sp,sp,-16
ffffffffc020014a:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020014c:	4cc000ef          	jal	ra,ffffffffc0200618 <cons_getc>
ffffffffc0200150:	dd75                	beqz	a0,ffffffffc020014c <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200152:	60a2                	ld	ra,8(sp)
ffffffffc0200154:	0141                	addi	sp,sp,16
ffffffffc0200156:	8082                	ret

ffffffffc0200158 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200158:	715d                	addi	sp,sp,-80
ffffffffc020015a:	e486                	sd	ra,72(sp)
ffffffffc020015c:	e0a2                	sd	s0,64(sp)
ffffffffc020015e:	fc26                	sd	s1,56(sp)
ffffffffc0200160:	f84a                	sd	s2,48(sp)
ffffffffc0200162:	f44e                	sd	s3,40(sp)
ffffffffc0200164:	f052                	sd	s4,32(sp)
ffffffffc0200166:	ec56                	sd	s5,24(sp)
ffffffffc0200168:	e85a                	sd	s6,16(sp)
ffffffffc020016a:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc020016c:	c901                	beqz	a0,ffffffffc020017c <readline+0x24>
        cprintf("%s", prompt);
ffffffffc020016e:	85aa                	mv	a1,a0
ffffffffc0200170:	00006517          	auipc	a0,0x6
ffffffffc0200174:	4f850513          	addi	a0,a0,1272 # ffffffffc0206668 <etext+0x2a>
ffffffffc0200178:	f59ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
readline(const char *prompt) {
ffffffffc020017c:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020017e:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0200180:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0200182:	4aa9                	li	s5,10
ffffffffc0200184:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200186:	000a1b97          	auipc	s7,0xa1
ffffffffc020018a:	e62b8b93          	addi	s7,s7,-414 # ffffffffc02a0fe8 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020018e:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0200192:	fb7ff0ef          	jal	ra,ffffffffc0200148 <getchar>
ffffffffc0200196:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0200198:	00054b63          	bltz	a0,ffffffffc02001ae <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020019c:	00a95b63          	ble	a0,s2,ffffffffc02001b2 <readline+0x5a>
ffffffffc02001a0:	029a5463          	ble	s1,s4,ffffffffc02001c8 <readline+0x70>
        c = getchar();
ffffffffc02001a4:	fa5ff0ef          	jal	ra,ffffffffc0200148 <getchar>
ffffffffc02001a8:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02001aa:	fe0559e3          	bgez	a0,ffffffffc020019c <readline+0x44>
            return NULL;
ffffffffc02001ae:	4501                	li	a0,0
ffffffffc02001b0:	a099                	j	ffffffffc02001f6 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02001b2:	03341463          	bne	s0,s3,ffffffffc02001da <readline+0x82>
ffffffffc02001b6:	e8b9                	bnez	s1,ffffffffc020020c <readline+0xb4>
        c = getchar();
ffffffffc02001b8:	f91ff0ef          	jal	ra,ffffffffc0200148 <getchar>
ffffffffc02001bc:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02001be:	fe0548e3          	bltz	a0,ffffffffc02001ae <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02001c2:	fea958e3          	ble	a0,s2,ffffffffc02001b2 <readline+0x5a>
ffffffffc02001c6:	4481                	li	s1,0
            cputchar(c);
ffffffffc02001c8:	8522                	mv	a0,s0
ffffffffc02001ca:	f3bff0ef          	jal	ra,ffffffffc0200104 <cputchar>
            buf[i ++] = c;
ffffffffc02001ce:	009b87b3          	add	a5,s7,s1
ffffffffc02001d2:	00878023          	sb	s0,0(a5)
ffffffffc02001d6:	2485                	addiw	s1,s1,1
ffffffffc02001d8:	bf6d                	j	ffffffffc0200192 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc02001da:	01540463          	beq	s0,s5,ffffffffc02001e2 <readline+0x8a>
ffffffffc02001de:	fb641ae3          	bne	s0,s6,ffffffffc0200192 <readline+0x3a>
            cputchar(c);
ffffffffc02001e2:	8522                	mv	a0,s0
ffffffffc02001e4:	f21ff0ef          	jal	ra,ffffffffc0200104 <cputchar>
            buf[i] = '\0';
ffffffffc02001e8:	000a1517          	auipc	a0,0xa1
ffffffffc02001ec:	e0050513          	addi	a0,a0,-512 # ffffffffc02a0fe8 <edata>
ffffffffc02001f0:	94aa                	add	s1,s1,a0
ffffffffc02001f2:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02001f6:	60a6                	ld	ra,72(sp)
ffffffffc02001f8:	6406                	ld	s0,64(sp)
ffffffffc02001fa:	74e2                	ld	s1,56(sp)
ffffffffc02001fc:	7942                	ld	s2,48(sp)
ffffffffc02001fe:	79a2                	ld	s3,40(sp)
ffffffffc0200200:	7a02                	ld	s4,32(sp)
ffffffffc0200202:	6ae2                	ld	s5,24(sp)
ffffffffc0200204:	6b42                	ld	s6,16(sp)
ffffffffc0200206:	6ba2                	ld	s7,8(sp)
ffffffffc0200208:	6161                	addi	sp,sp,80
ffffffffc020020a:	8082                	ret
            cputchar(c);
ffffffffc020020c:	4521                	li	a0,8
ffffffffc020020e:	ef7ff0ef          	jal	ra,ffffffffc0200104 <cputchar>
            i --;
ffffffffc0200212:	34fd                	addiw	s1,s1,-1
ffffffffc0200214:	bfbd                	j	ffffffffc0200192 <readline+0x3a>

ffffffffc0200216 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200216:	000ac317          	auipc	t1,0xac
ffffffffc020021a:	1d230313          	addi	t1,t1,466 # ffffffffc02ac3e8 <is_panic>
ffffffffc020021e:	00033303          	ld	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200222:	715d                	addi	sp,sp,-80
ffffffffc0200224:	ec06                	sd	ra,24(sp)
ffffffffc0200226:	e822                	sd	s0,16(sp)
ffffffffc0200228:	f436                	sd	a3,40(sp)
ffffffffc020022a:	f83a                	sd	a4,48(sp)
ffffffffc020022c:	fc3e                	sd	a5,56(sp)
ffffffffc020022e:	e0c2                	sd	a6,64(sp)
ffffffffc0200230:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200232:	02031c63          	bnez	t1,ffffffffc020026a <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200236:	4785                	li	a5,1
ffffffffc0200238:	8432                	mv	s0,a2
ffffffffc020023a:	000ac717          	auipc	a4,0xac
ffffffffc020023e:	1af73723          	sd	a5,430(a4) # ffffffffc02ac3e8 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200242:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc0200244:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200246:	85aa                	mv	a1,a0
ffffffffc0200248:	00006517          	auipc	a0,0x6
ffffffffc020024c:	42850513          	addi	a0,a0,1064 # ffffffffc0206670 <etext+0x32>
    va_start(ap, fmt);
ffffffffc0200250:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200252:	e7fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200256:	65a2                	ld	a1,8(sp)
ffffffffc0200258:	8522                	mv	a0,s0
ffffffffc020025a:	e57ff0ef          	jal	ra,ffffffffc02000b0 <vcprintf>
    cprintf("\n");
ffffffffc020025e:	00007517          	auipc	a0,0x7
ffffffffc0200262:	1fa50513          	addi	a0,a0,506 # ffffffffc0207458 <commands+0xca8>
ffffffffc0200266:	e6bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc020026a:	4501                	li	a0,0
ffffffffc020026c:	4581                	li	a1,0
ffffffffc020026e:	4601                	li	a2,0
ffffffffc0200270:	48a1                	li	a7,8
ffffffffc0200272:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc0200276:	3e6000ef          	jal	ra,ffffffffc020065c <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020027a:	4501                	li	a0,0
ffffffffc020027c:	174000ef          	jal	ra,ffffffffc02003f0 <kmonitor>
ffffffffc0200280:	bfed                	j	ffffffffc020027a <__panic+0x64>

ffffffffc0200282 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200282:	715d                	addi	sp,sp,-80
ffffffffc0200284:	e822                	sd	s0,16(sp)
ffffffffc0200286:	fc3e                	sd	a5,56(sp)
ffffffffc0200288:	8432                	mv	s0,a2
    va_list ap;
    va_start(ap, fmt);
ffffffffc020028a:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020028c:	862e                	mv	a2,a1
ffffffffc020028e:	85aa                	mv	a1,a0
ffffffffc0200290:	00006517          	auipc	a0,0x6
ffffffffc0200294:	40050513          	addi	a0,a0,1024 # ffffffffc0206690 <etext+0x52>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200298:	ec06                	sd	ra,24(sp)
ffffffffc020029a:	f436                	sd	a3,40(sp)
ffffffffc020029c:	f83a                	sd	a4,48(sp)
ffffffffc020029e:	e0c2                	sd	a6,64(sp)
ffffffffc02002a0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02002a2:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02002a4:	e2dff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02002a8:	65a2                	ld	a1,8(sp)
ffffffffc02002aa:	8522                	mv	a0,s0
ffffffffc02002ac:	e05ff0ef          	jal	ra,ffffffffc02000b0 <vcprintf>
    cprintf("\n");
ffffffffc02002b0:	00007517          	auipc	a0,0x7
ffffffffc02002b4:	1a850513          	addi	a0,a0,424 # ffffffffc0207458 <commands+0xca8>
ffffffffc02002b8:	e19ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    va_end(ap);
}
ffffffffc02002bc:	60e2                	ld	ra,24(sp)
ffffffffc02002be:	6442                	ld	s0,16(sp)
ffffffffc02002c0:	6161                	addi	sp,sp,80
ffffffffc02002c2:	8082                	ret

ffffffffc02002c4 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02002c4:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02002c6:	00006517          	auipc	a0,0x6
ffffffffc02002ca:	41a50513          	addi	a0,a0,1050 # ffffffffc02066e0 <etext+0xa2>
void print_kerninfo(void) {
ffffffffc02002ce:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02002d0:	e01ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02002d4:	00000597          	auipc	a1,0x0
ffffffffc02002d8:	d6258593          	addi	a1,a1,-670 # ffffffffc0200036 <kern_init>
ffffffffc02002dc:	00006517          	auipc	a0,0x6
ffffffffc02002e0:	42450513          	addi	a0,a0,1060 # ffffffffc0206700 <etext+0xc2>
ffffffffc02002e4:	dedff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02002e8:	00006597          	auipc	a1,0x6
ffffffffc02002ec:	35658593          	addi	a1,a1,854 # ffffffffc020663e <etext>
ffffffffc02002f0:	00006517          	auipc	a0,0x6
ffffffffc02002f4:	43050513          	addi	a0,a0,1072 # ffffffffc0206720 <etext+0xe2>
ffffffffc02002f8:	dd9ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc02002fc:	000a1597          	auipc	a1,0xa1
ffffffffc0200300:	cec58593          	addi	a1,a1,-788 # ffffffffc02a0fe8 <edata>
ffffffffc0200304:	00006517          	auipc	a0,0x6
ffffffffc0200308:	43c50513          	addi	a0,a0,1084 # ffffffffc0206740 <etext+0x102>
ffffffffc020030c:	dc5ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200310:	000ac597          	auipc	a1,0xac
ffffffffc0200314:	26858593          	addi	a1,a1,616 # ffffffffc02ac578 <end>
ffffffffc0200318:	00006517          	auipc	a0,0x6
ffffffffc020031c:	44850513          	addi	a0,a0,1096 # ffffffffc0206760 <etext+0x122>
ffffffffc0200320:	db1ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200324:	000ac597          	auipc	a1,0xac
ffffffffc0200328:	65358593          	addi	a1,a1,1619 # ffffffffc02ac977 <end+0x3ff>
ffffffffc020032c:	00000797          	auipc	a5,0x0
ffffffffc0200330:	d0a78793          	addi	a5,a5,-758 # ffffffffc0200036 <kern_init>
ffffffffc0200334:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200338:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020033c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020033e:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200342:	95be                	add	a1,a1,a5
ffffffffc0200344:	85a9                	srai	a1,a1,0xa
ffffffffc0200346:	00006517          	auipc	a0,0x6
ffffffffc020034a:	43a50513          	addi	a0,a0,1082 # ffffffffc0206780 <etext+0x142>
}
ffffffffc020034e:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200350:	d81ff06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc0200354 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200354:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200356:	00006617          	auipc	a2,0x6
ffffffffc020035a:	35a60613          	addi	a2,a2,858 # ffffffffc02066b0 <etext+0x72>
ffffffffc020035e:	04d00593          	li	a1,77
ffffffffc0200362:	00006517          	auipc	a0,0x6
ffffffffc0200366:	36650513          	addi	a0,a0,870 # ffffffffc02066c8 <etext+0x8a>
void print_stackframe(void) {
ffffffffc020036a:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020036c:	eabff0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0200370 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200370:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200372:	00006617          	auipc	a2,0x6
ffffffffc0200376:	51e60613          	addi	a2,a2,1310 # ffffffffc0206890 <commands+0xe0>
ffffffffc020037a:	00006597          	auipc	a1,0x6
ffffffffc020037e:	53658593          	addi	a1,a1,1334 # ffffffffc02068b0 <commands+0x100>
ffffffffc0200382:	00006517          	auipc	a0,0x6
ffffffffc0200386:	53650513          	addi	a0,a0,1334 # ffffffffc02068b8 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020038a:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020038c:	d45ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0200390:	00006617          	auipc	a2,0x6
ffffffffc0200394:	53860613          	addi	a2,a2,1336 # ffffffffc02068c8 <commands+0x118>
ffffffffc0200398:	00006597          	auipc	a1,0x6
ffffffffc020039c:	55858593          	addi	a1,a1,1368 # ffffffffc02068f0 <commands+0x140>
ffffffffc02003a0:	00006517          	auipc	a0,0x6
ffffffffc02003a4:	51850513          	addi	a0,a0,1304 # ffffffffc02068b8 <commands+0x108>
ffffffffc02003a8:	d29ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc02003ac:	00006617          	auipc	a2,0x6
ffffffffc02003b0:	55460613          	addi	a2,a2,1364 # ffffffffc0206900 <commands+0x150>
ffffffffc02003b4:	00006597          	auipc	a1,0x6
ffffffffc02003b8:	56c58593          	addi	a1,a1,1388 # ffffffffc0206920 <commands+0x170>
ffffffffc02003bc:	00006517          	auipc	a0,0x6
ffffffffc02003c0:	4fc50513          	addi	a0,a0,1276 # ffffffffc02068b8 <commands+0x108>
ffffffffc02003c4:	d0dff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    }
    return 0;
}
ffffffffc02003c8:	60a2                	ld	ra,8(sp)
ffffffffc02003ca:	4501                	li	a0,0
ffffffffc02003cc:	0141                	addi	sp,sp,16
ffffffffc02003ce:	8082                	ret

ffffffffc02003d0 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02003d0:	1141                	addi	sp,sp,-16
ffffffffc02003d2:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02003d4:	ef1ff0ef          	jal	ra,ffffffffc02002c4 <print_kerninfo>
    return 0;
}
ffffffffc02003d8:	60a2                	ld	ra,8(sp)
ffffffffc02003da:	4501                	li	a0,0
ffffffffc02003dc:	0141                	addi	sp,sp,16
ffffffffc02003de:	8082                	ret

ffffffffc02003e0 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02003e0:	1141                	addi	sp,sp,-16
ffffffffc02003e2:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02003e4:	f71ff0ef          	jal	ra,ffffffffc0200354 <print_stackframe>
    return 0;
}
ffffffffc02003e8:	60a2                	ld	ra,8(sp)
ffffffffc02003ea:	4501                	li	a0,0
ffffffffc02003ec:	0141                	addi	sp,sp,16
ffffffffc02003ee:	8082                	ret

ffffffffc02003f0 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02003f0:	7115                	addi	sp,sp,-224
ffffffffc02003f2:	e962                	sd	s8,144(sp)
ffffffffc02003f4:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02003f6:	00006517          	auipc	a0,0x6
ffffffffc02003fa:	40250513          	addi	a0,a0,1026 # ffffffffc02067f8 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc02003fe:	ed86                	sd	ra,216(sp)
ffffffffc0200400:	e9a2                	sd	s0,208(sp)
ffffffffc0200402:	e5a6                	sd	s1,200(sp)
ffffffffc0200404:	e1ca                	sd	s2,192(sp)
ffffffffc0200406:	fd4e                	sd	s3,184(sp)
ffffffffc0200408:	f952                	sd	s4,176(sp)
ffffffffc020040a:	f556                	sd	s5,168(sp)
ffffffffc020040c:	f15a                	sd	s6,160(sp)
ffffffffc020040e:	ed5e                	sd	s7,152(sp)
ffffffffc0200410:	e566                	sd	s9,136(sp)
ffffffffc0200412:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200414:	cbdff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200418:	00006517          	auipc	a0,0x6
ffffffffc020041c:	40850513          	addi	a0,a0,1032 # ffffffffc0206820 <commands+0x70>
ffffffffc0200420:	cb1ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    if (tf != NULL) {
ffffffffc0200424:	000c0563          	beqz	s8,ffffffffc020042e <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200428:	8562                	mv	a0,s8
ffffffffc020042a:	420000ef          	jal	ra,ffffffffc020084a <print_trapframe>
ffffffffc020042e:	00006c97          	auipc	s9,0x6
ffffffffc0200432:	382c8c93          	addi	s9,s9,898 # ffffffffc02067b0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200436:	00006997          	auipc	s3,0x6
ffffffffc020043a:	41298993          	addi	s3,s3,1042 # ffffffffc0206848 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020043e:	00006917          	auipc	s2,0x6
ffffffffc0200442:	41290913          	addi	s2,s2,1042 # ffffffffc0206850 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc0200446:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200448:	00006b17          	auipc	s6,0x6
ffffffffc020044c:	410b0b13          	addi	s6,s6,1040 # ffffffffc0206858 <commands+0xa8>
    if (argc == 0) {
ffffffffc0200450:	00006a97          	auipc	s5,0x6
ffffffffc0200454:	460a8a93          	addi	s5,s5,1120 # ffffffffc02068b0 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200458:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020045a:	854e                	mv	a0,s3
ffffffffc020045c:	cfdff0ef          	jal	ra,ffffffffc0200158 <readline>
ffffffffc0200460:	842a                	mv	s0,a0
ffffffffc0200462:	dd65                	beqz	a0,ffffffffc020045a <kmonitor+0x6a>
ffffffffc0200464:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200468:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020046a:	c999                	beqz	a1,ffffffffc0200480 <kmonitor+0x90>
ffffffffc020046c:	854a                	mv	a0,s2
ffffffffc020046e:	579050ef          	jal	ra,ffffffffc02061e6 <strchr>
ffffffffc0200472:	c925                	beqz	a0,ffffffffc02004e2 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc0200474:	00144583          	lbu	a1,1(s0)
ffffffffc0200478:	00040023          	sb	zero,0(s0)
ffffffffc020047c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020047e:	f5fd                	bnez	a1,ffffffffc020046c <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc0200480:	dce9                	beqz	s1,ffffffffc020045a <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200482:	6582                	ld	a1,0(sp)
ffffffffc0200484:	00006d17          	auipc	s10,0x6
ffffffffc0200488:	32cd0d13          	addi	s10,s10,812 # ffffffffc02067b0 <commands>
    if (argc == 0) {
ffffffffc020048c:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020048e:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200490:	0d61                	addi	s10,s10,24
ffffffffc0200492:	52b050ef          	jal	ra,ffffffffc02061bc <strcmp>
ffffffffc0200496:	c919                	beqz	a0,ffffffffc02004ac <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200498:	2405                	addiw	s0,s0,1
ffffffffc020049a:	09740463          	beq	s0,s7,ffffffffc0200522 <kmonitor+0x132>
ffffffffc020049e:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02004a2:	6582                	ld	a1,0(sp)
ffffffffc02004a4:	0d61                	addi	s10,s10,24
ffffffffc02004a6:	517050ef          	jal	ra,ffffffffc02061bc <strcmp>
ffffffffc02004aa:	f57d                	bnez	a0,ffffffffc0200498 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02004ac:	00141793          	slli	a5,s0,0x1
ffffffffc02004b0:	97a2                	add	a5,a5,s0
ffffffffc02004b2:	078e                	slli	a5,a5,0x3
ffffffffc02004b4:	97e6                	add	a5,a5,s9
ffffffffc02004b6:	6b9c                	ld	a5,16(a5)
ffffffffc02004b8:	8662                	mv	a2,s8
ffffffffc02004ba:	002c                	addi	a1,sp,8
ffffffffc02004bc:	fff4851b          	addiw	a0,s1,-1
ffffffffc02004c0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02004c2:	f8055ce3          	bgez	a0,ffffffffc020045a <kmonitor+0x6a>
}
ffffffffc02004c6:	60ee                	ld	ra,216(sp)
ffffffffc02004c8:	644e                	ld	s0,208(sp)
ffffffffc02004ca:	64ae                	ld	s1,200(sp)
ffffffffc02004cc:	690e                	ld	s2,192(sp)
ffffffffc02004ce:	79ea                	ld	s3,184(sp)
ffffffffc02004d0:	7a4a                	ld	s4,176(sp)
ffffffffc02004d2:	7aaa                	ld	s5,168(sp)
ffffffffc02004d4:	7b0a                	ld	s6,160(sp)
ffffffffc02004d6:	6bea                	ld	s7,152(sp)
ffffffffc02004d8:	6c4a                	ld	s8,144(sp)
ffffffffc02004da:	6caa                	ld	s9,136(sp)
ffffffffc02004dc:	6d0a                	ld	s10,128(sp)
ffffffffc02004de:	612d                	addi	sp,sp,224
ffffffffc02004e0:	8082                	ret
        if (*buf == '\0') {
ffffffffc02004e2:	00044783          	lbu	a5,0(s0)
ffffffffc02004e6:	dfc9                	beqz	a5,ffffffffc0200480 <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc02004e8:	03448863          	beq	s1,s4,ffffffffc0200518 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc02004ec:	00349793          	slli	a5,s1,0x3
ffffffffc02004f0:	0118                	addi	a4,sp,128
ffffffffc02004f2:	97ba                	add	a5,a5,a4
ffffffffc02004f4:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004f8:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02004fc:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004fe:	e591                	bnez	a1,ffffffffc020050a <kmonitor+0x11a>
ffffffffc0200500:	b749                	j	ffffffffc0200482 <kmonitor+0x92>
            buf ++;
ffffffffc0200502:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200504:	00044583          	lbu	a1,0(s0)
ffffffffc0200508:	ddad                	beqz	a1,ffffffffc0200482 <kmonitor+0x92>
ffffffffc020050a:	854a                	mv	a0,s2
ffffffffc020050c:	4db050ef          	jal	ra,ffffffffc02061e6 <strchr>
ffffffffc0200510:	d96d                	beqz	a0,ffffffffc0200502 <kmonitor+0x112>
ffffffffc0200512:	00044583          	lbu	a1,0(s0)
ffffffffc0200516:	bf91                	j	ffffffffc020046a <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200518:	45c1                	li	a1,16
ffffffffc020051a:	855a                	mv	a0,s6
ffffffffc020051c:	bb5ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0200520:	b7f1                	j	ffffffffc02004ec <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200522:	6582                	ld	a1,0(sp)
ffffffffc0200524:	00006517          	auipc	a0,0x6
ffffffffc0200528:	35450513          	addi	a0,a0,852 # ffffffffc0206878 <commands+0xc8>
ffffffffc020052c:	ba5ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    return 0;
ffffffffc0200530:	b72d                	j	ffffffffc020045a <kmonitor+0x6a>

ffffffffc0200532 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc0200532:	8082                	ret

ffffffffc0200534 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc0200534:	00253513          	sltiu	a0,a0,2
ffffffffc0200538:	8082                	ret

ffffffffc020053a <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc020053a:	03800513          	li	a0,56
ffffffffc020053e:	8082                	ret

ffffffffc0200540 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200540:	000a1797          	auipc	a5,0xa1
ffffffffc0200544:	ea878793          	addi	a5,a5,-344 # ffffffffc02a13e8 <ide>
ffffffffc0200548:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc020054c:	1141                	addi	sp,sp,-16
ffffffffc020054e:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200550:	95be                	add	a1,a1,a5
ffffffffc0200552:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc0200556:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200558:	4bf050ef          	jal	ra,ffffffffc0206216 <memcpy>
    return 0;
}
ffffffffc020055c:	60a2                	ld	ra,8(sp)
ffffffffc020055e:	4501                	li	a0,0
ffffffffc0200560:	0141                	addi	sp,sp,16
ffffffffc0200562:	8082                	ret

ffffffffc0200564 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc0200564:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200566:	0095979b          	slliw	a5,a1,0x9
ffffffffc020056a:	000a1517          	auipc	a0,0xa1
ffffffffc020056e:	e7e50513          	addi	a0,a0,-386 # ffffffffc02a13e8 <ide>
                   size_t nsecs) {
ffffffffc0200572:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200574:	00969613          	slli	a2,a3,0x9
ffffffffc0200578:	85ba                	mv	a1,a4
ffffffffc020057a:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc020057c:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020057e:	499050ef          	jal	ra,ffffffffc0206216 <memcpy>
    return 0;
}
ffffffffc0200582:	60a2                	ld	ra,8(sp)
ffffffffc0200584:	4501                	li	a0,0
ffffffffc0200586:	0141                	addi	sp,sp,16
ffffffffc0200588:	8082                	ret

ffffffffc020058a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020058a:	67e1                	lui	a5,0x18
ffffffffc020058c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xdc28>
ffffffffc0200590:	000ac717          	auipc	a4,0xac
ffffffffc0200594:	e6f73023          	sd	a5,-416(a4) # ffffffffc02ac3f0 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200598:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020059c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020059e:	953e                	add	a0,a0,a5
ffffffffc02005a0:	4601                	li	a2,0
ffffffffc02005a2:	4881                	li	a7,0
ffffffffc02005a4:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02005a8:	02000793          	li	a5,32
ffffffffc02005ac:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02005b0:	00006517          	auipc	a0,0x6
ffffffffc02005b4:	38050513          	addi	a0,a0,896 # ffffffffc0206930 <commands+0x180>
    ticks = 0;
ffffffffc02005b8:	000ac797          	auipc	a5,0xac
ffffffffc02005bc:	e807b823          	sd	zero,-368(a5) # ffffffffc02ac448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02005c0:	b11ff06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc02005c4 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02005c4:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02005c8:	000ac797          	auipc	a5,0xac
ffffffffc02005cc:	e2878793          	addi	a5,a5,-472 # ffffffffc02ac3f0 <timebase>
ffffffffc02005d0:	639c                	ld	a5,0(a5)
ffffffffc02005d2:	4581                	li	a1,0
ffffffffc02005d4:	4601                	li	a2,0
ffffffffc02005d6:	953e                	add	a0,a0,a5
ffffffffc02005d8:	4881                	li	a7,0
ffffffffc02005da:	00000073          	ecall
ffffffffc02005de:	8082                	ret

ffffffffc02005e0 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02005e0:	8082                	ret

ffffffffc02005e2 <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005e2:	100027f3          	csrr	a5,sstatus
ffffffffc02005e6:	8b89                	andi	a5,a5,2
ffffffffc02005e8:	0ff57513          	andi	a0,a0,255
ffffffffc02005ec:	e799                	bnez	a5,ffffffffc02005fa <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02005ee:	4581                	li	a1,0
ffffffffc02005f0:	4601                	li	a2,0
ffffffffc02005f2:	4885                	li	a7,1
ffffffffc02005f4:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02005f8:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005fa:	1101                	addi	sp,sp,-32
ffffffffc02005fc:	ec06                	sd	ra,24(sp)
ffffffffc02005fe:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200600:	05c000ef          	jal	ra,ffffffffc020065c <intr_disable>
ffffffffc0200604:	6522                	ld	a0,8(sp)
ffffffffc0200606:	4581                	li	a1,0
ffffffffc0200608:	4601                	li	a2,0
ffffffffc020060a:	4885                	li	a7,1
ffffffffc020060c:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200610:	60e2                	ld	ra,24(sp)
ffffffffc0200612:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200614:	0420006f          	j	ffffffffc0200656 <intr_enable>

ffffffffc0200618 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200618:	100027f3          	csrr	a5,sstatus
ffffffffc020061c:	8b89                	andi	a5,a5,2
ffffffffc020061e:	eb89                	bnez	a5,ffffffffc0200630 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200620:	4501                	li	a0,0
ffffffffc0200622:	4581                	li	a1,0
ffffffffc0200624:	4601                	li	a2,0
ffffffffc0200626:	4889                	li	a7,2
ffffffffc0200628:	00000073          	ecall
ffffffffc020062c:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc020062e:	8082                	ret
int cons_getc(void) {
ffffffffc0200630:	1101                	addi	sp,sp,-32
ffffffffc0200632:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200634:	028000ef          	jal	ra,ffffffffc020065c <intr_disable>
ffffffffc0200638:	4501                	li	a0,0
ffffffffc020063a:	4581                	li	a1,0
ffffffffc020063c:	4601                	li	a2,0
ffffffffc020063e:	4889                	li	a7,2
ffffffffc0200640:	00000073          	ecall
ffffffffc0200644:	2501                	sext.w	a0,a0
ffffffffc0200646:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200648:	00e000ef          	jal	ra,ffffffffc0200656 <intr_enable>
}
ffffffffc020064c:	60e2                	ld	ra,24(sp)
ffffffffc020064e:	6522                	ld	a0,8(sp)
ffffffffc0200650:	6105                	addi	sp,sp,32
ffffffffc0200652:	8082                	ret

ffffffffc0200654 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200654:	8082                	ret

ffffffffc0200656 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200656:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020065a:	8082                	ret

ffffffffc020065c <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020065c:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200660:	8082                	ret

ffffffffc0200662 <idt_init>:
void
idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200662:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200666:	00000797          	auipc	a5,0x0
ffffffffc020066a:	67a78793          	addi	a5,a5,1658 # ffffffffc0200ce0 <__alltraps>
ffffffffc020066e:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200672:	000407b7          	lui	a5,0x40
ffffffffc0200676:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020067a:	8082                	ret

ffffffffc020067c <print_regs>:
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020067c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs* gpr) {
ffffffffc020067e:	1141                	addi	sp,sp,-16
ffffffffc0200680:	e022                	sd	s0,0(sp)
ffffffffc0200682:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200684:	00006517          	auipc	a0,0x6
ffffffffc0200688:	5f450513          	addi	a0,a0,1524 # ffffffffc0206c78 <commands+0x4c8>
void print_regs(struct pushregs* gpr) {
ffffffffc020068c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020068e:	a43ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200692:	640c                	ld	a1,8(s0)
ffffffffc0200694:	00006517          	auipc	a0,0x6
ffffffffc0200698:	5fc50513          	addi	a0,a0,1532 # ffffffffc0206c90 <commands+0x4e0>
ffffffffc020069c:	a35ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02006a0:	680c                	ld	a1,16(s0)
ffffffffc02006a2:	00006517          	auipc	a0,0x6
ffffffffc02006a6:	60650513          	addi	a0,a0,1542 # ffffffffc0206ca8 <commands+0x4f8>
ffffffffc02006aa:	a27ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02006ae:	6c0c                	ld	a1,24(s0)
ffffffffc02006b0:	00006517          	auipc	a0,0x6
ffffffffc02006b4:	61050513          	addi	a0,a0,1552 # ffffffffc0206cc0 <commands+0x510>
ffffffffc02006b8:	a19ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006bc:	700c                	ld	a1,32(s0)
ffffffffc02006be:	00006517          	auipc	a0,0x6
ffffffffc02006c2:	61a50513          	addi	a0,a0,1562 # ffffffffc0206cd8 <commands+0x528>
ffffffffc02006c6:	a0bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006ca:	740c                	ld	a1,40(s0)
ffffffffc02006cc:	00006517          	auipc	a0,0x6
ffffffffc02006d0:	62450513          	addi	a0,a0,1572 # ffffffffc0206cf0 <commands+0x540>
ffffffffc02006d4:	9fdff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006d8:	780c                	ld	a1,48(s0)
ffffffffc02006da:	00006517          	auipc	a0,0x6
ffffffffc02006de:	62e50513          	addi	a0,a0,1582 # ffffffffc0206d08 <commands+0x558>
ffffffffc02006e2:	9efff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006e6:	7c0c                	ld	a1,56(s0)
ffffffffc02006e8:	00006517          	auipc	a0,0x6
ffffffffc02006ec:	63850513          	addi	a0,a0,1592 # ffffffffc0206d20 <commands+0x570>
ffffffffc02006f0:	9e1ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006f4:	602c                	ld	a1,64(s0)
ffffffffc02006f6:	00006517          	auipc	a0,0x6
ffffffffc02006fa:	64250513          	addi	a0,a0,1602 # ffffffffc0206d38 <commands+0x588>
ffffffffc02006fe:	9d3ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200702:	642c                	ld	a1,72(s0)
ffffffffc0200704:	00006517          	auipc	a0,0x6
ffffffffc0200708:	64c50513          	addi	a0,a0,1612 # ffffffffc0206d50 <commands+0x5a0>
ffffffffc020070c:	9c5ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200710:	682c                	ld	a1,80(s0)
ffffffffc0200712:	00006517          	auipc	a0,0x6
ffffffffc0200716:	65650513          	addi	a0,a0,1622 # ffffffffc0206d68 <commands+0x5b8>
ffffffffc020071a:	9b7ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020071e:	6c2c                	ld	a1,88(s0)
ffffffffc0200720:	00006517          	auipc	a0,0x6
ffffffffc0200724:	66050513          	addi	a0,a0,1632 # ffffffffc0206d80 <commands+0x5d0>
ffffffffc0200728:	9a9ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020072c:	702c                	ld	a1,96(s0)
ffffffffc020072e:	00006517          	auipc	a0,0x6
ffffffffc0200732:	66a50513          	addi	a0,a0,1642 # ffffffffc0206d98 <commands+0x5e8>
ffffffffc0200736:	99bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020073a:	742c                	ld	a1,104(s0)
ffffffffc020073c:	00006517          	auipc	a0,0x6
ffffffffc0200740:	67450513          	addi	a0,a0,1652 # ffffffffc0206db0 <commands+0x600>
ffffffffc0200744:	98dff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200748:	782c                	ld	a1,112(s0)
ffffffffc020074a:	00006517          	auipc	a0,0x6
ffffffffc020074e:	67e50513          	addi	a0,a0,1662 # ffffffffc0206dc8 <commands+0x618>
ffffffffc0200752:	97fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200756:	7c2c                	ld	a1,120(s0)
ffffffffc0200758:	00006517          	auipc	a0,0x6
ffffffffc020075c:	68850513          	addi	a0,a0,1672 # ffffffffc0206de0 <commands+0x630>
ffffffffc0200760:	971ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200764:	604c                	ld	a1,128(s0)
ffffffffc0200766:	00006517          	auipc	a0,0x6
ffffffffc020076a:	69250513          	addi	a0,a0,1682 # ffffffffc0206df8 <commands+0x648>
ffffffffc020076e:	963ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200772:	644c                	ld	a1,136(s0)
ffffffffc0200774:	00006517          	auipc	a0,0x6
ffffffffc0200778:	69c50513          	addi	a0,a0,1692 # ffffffffc0206e10 <commands+0x660>
ffffffffc020077c:	955ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200780:	684c                	ld	a1,144(s0)
ffffffffc0200782:	00006517          	auipc	a0,0x6
ffffffffc0200786:	6a650513          	addi	a0,a0,1702 # ffffffffc0206e28 <commands+0x678>
ffffffffc020078a:	947ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020078e:	6c4c                	ld	a1,152(s0)
ffffffffc0200790:	00006517          	auipc	a0,0x6
ffffffffc0200794:	6b050513          	addi	a0,a0,1712 # ffffffffc0206e40 <commands+0x690>
ffffffffc0200798:	939ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020079c:	704c                	ld	a1,160(s0)
ffffffffc020079e:	00006517          	auipc	a0,0x6
ffffffffc02007a2:	6ba50513          	addi	a0,a0,1722 # ffffffffc0206e58 <commands+0x6a8>
ffffffffc02007a6:	92bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02007aa:	744c                	ld	a1,168(s0)
ffffffffc02007ac:	00006517          	auipc	a0,0x6
ffffffffc02007b0:	6c450513          	addi	a0,a0,1732 # ffffffffc0206e70 <commands+0x6c0>
ffffffffc02007b4:	91dff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007b8:	784c                	ld	a1,176(s0)
ffffffffc02007ba:	00006517          	auipc	a0,0x6
ffffffffc02007be:	6ce50513          	addi	a0,a0,1742 # ffffffffc0206e88 <commands+0x6d8>
ffffffffc02007c2:	90fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007c6:	7c4c                	ld	a1,184(s0)
ffffffffc02007c8:	00006517          	auipc	a0,0x6
ffffffffc02007cc:	6d850513          	addi	a0,a0,1752 # ffffffffc0206ea0 <commands+0x6f0>
ffffffffc02007d0:	901ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007d4:	606c                	ld	a1,192(s0)
ffffffffc02007d6:	00006517          	auipc	a0,0x6
ffffffffc02007da:	6e250513          	addi	a0,a0,1762 # ffffffffc0206eb8 <commands+0x708>
ffffffffc02007de:	8f3ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007e2:	646c                	ld	a1,200(s0)
ffffffffc02007e4:	00006517          	auipc	a0,0x6
ffffffffc02007e8:	6ec50513          	addi	a0,a0,1772 # ffffffffc0206ed0 <commands+0x720>
ffffffffc02007ec:	8e5ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007f0:	686c                	ld	a1,208(s0)
ffffffffc02007f2:	00006517          	auipc	a0,0x6
ffffffffc02007f6:	6f650513          	addi	a0,a0,1782 # ffffffffc0206ee8 <commands+0x738>
ffffffffc02007fa:	8d7ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200800:	00006517          	auipc	a0,0x6
ffffffffc0200804:	70050513          	addi	a0,a0,1792 # ffffffffc0206f00 <commands+0x750>
ffffffffc0200808:	8c9ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020080c:	706c                	ld	a1,224(s0)
ffffffffc020080e:	00006517          	auipc	a0,0x6
ffffffffc0200812:	70a50513          	addi	a0,a0,1802 # ffffffffc0206f18 <commands+0x768>
ffffffffc0200816:	8bbff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020081a:	746c                	ld	a1,232(s0)
ffffffffc020081c:	00006517          	auipc	a0,0x6
ffffffffc0200820:	71450513          	addi	a0,a0,1812 # ffffffffc0206f30 <commands+0x780>
ffffffffc0200824:	8adff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200828:	786c                	ld	a1,240(s0)
ffffffffc020082a:	00006517          	auipc	a0,0x6
ffffffffc020082e:	71e50513          	addi	a0,a0,1822 # ffffffffc0206f48 <commands+0x798>
ffffffffc0200832:	89fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200836:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200838:	6402                	ld	s0,0(sp)
ffffffffc020083a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020083c:	00006517          	auipc	a0,0x6
ffffffffc0200840:	72450513          	addi	a0,a0,1828 # ffffffffc0206f60 <commands+0x7b0>
}
ffffffffc0200844:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200846:	88bff06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc020084a <print_trapframe>:
print_trapframe(struct trapframe *tf) {
ffffffffc020084a:	1141                	addi	sp,sp,-16
ffffffffc020084c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020084e:	85aa                	mv	a1,a0
print_trapframe(struct trapframe *tf) {
ffffffffc0200850:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200852:	00006517          	auipc	a0,0x6
ffffffffc0200856:	72650513          	addi	a0,a0,1830 # ffffffffc0206f78 <commands+0x7c8>
print_trapframe(struct trapframe *tf) {
ffffffffc020085a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020085c:	875ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200860:	8522                	mv	a0,s0
ffffffffc0200862:	e1bff0ef          	jal	ra,ffffffffc020067c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200866:	10043583          	ld	a1,256(s0)
ffffffffc020086a:	00006517          	auipc	a0,0x6
ffffffffc020086e:	72650513          	addi	a0,a0,1830 # ffffffffc0206f90 <commands+0x7e0>
ffffffffc0200872:	85fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200876:	10843583          	ld	a1,264(s0)
ffffffffc020087a:	00006517          	auipc	a0,0x6
ffffffffc020087e:	72e50513          	addi	a0,a0,1838 # ffffffffc0206fa8 <commands+0x7f8>
ffffffffc0200882:	84fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200886:	11043583          	ld	a1,272(s0)
ffffffffc020088a:	00006517          	auipc	a0,0x6
ffffffffc020088e:	73650513          	addi	a0,a0,1846 # ffffffffc0206fc0 <commands+0x810>
ffffffffc0200892:	83fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200896:	11843583          	ld	a1,280(s0)
}
ffffffffc020089a:	6402                	ld	s0,0(sp)
ffffffffc020089c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020089e:	00006517          	auipc	a0,0x6
ffffffffc02008a2:	73250513          	addi	a0,a0,1842 # ffffffffc0206fd0 <commands+0x820>
}
ffffffffc02008a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02008a8:	829ff06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc02008ac <pgfault_handler>:
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf) {
ffffffffc02008ac:	1101                	addi	sp,sp,-32
ffffffffc02008ae:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008b0:	000ac497          	auipc	s1,0xac
ffffffffc02008b4:	bd048493          	addi	s1,s1,-1072 # ffffffffc02ac480 <check_mm_struct>
ffffffffc02008b8:	609c                	ld	a5,0(s1)
pgfault_handler(struct trapframe *tf) {
ffffffffc02008ba:	e822                	sd	s0,16(sp)
ffffffffc02008bc:	ec06                	sd	ra,24(sp)
ffffffffc02008be:	842a                	mv	s0,a0
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008c0:	cbbd                	beqz	a5,ffffffffc0200936 <pgfault_handler+0x8a>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008c2:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008c6:	11053583          	ld	a1,272(a0)
ffffffffc02008ca:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ce:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008d2:	cba1                	beqz	a5,ffffffffc0200922 <pgfault_handler+0x76>
ffffffffc02008d4:	11843703          	ld	a4,280(s0)
ffffffffc02008d8:	47bd                	li	a5,15
ffffffffc02008da:	05700693          	li	a3,87
ffffffffc02008de:	00f70463          	beq	a4,a5,ffffffffc02008e6 <pgfault_handler+0x3a>
ffffffffc02008e2:	05200693          	li	a3,82
ffffffffc02008e6:	00006517          	auipc	a0,0x6
ffffffffc02008ea:	31250513          	addi	a0,a0,786 # ffffffffc0206bf8 <commands+0x448>
ffffffffc02008ee:	fe2ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
ffffffffc02008f2:	6088                	ld	a0,0(s1)
ffffffffc02008f4:	c129                	beqz	a0,ffffffffc0200936 <pgfault_handler+0x8a>
        assert(current == idleproc);
ffffffffc02008f6:	000ac797          	auipc	a5,0xac
ffffffffc02008fa:	b3278793          	addi	a5,a5,-1230 # ffffffffc02ac428 <current>
ffffffffc02008fe:	6398                	ld	a4,0(a5)
ffffffffc0200900:	000ac797          	auipc	a5,0xac
ffffffffc0200904:	b3078793          	addi	a5,a5,-1232 # ffffffffc02ac430 <idleproc>
ffffffffc0200908:	639c                	ld	a5,0(a5)
ffffffffc020090a:	04f71763          	bne	a4,a5,ffffffffc0200958 <pgfault_handler+0xac>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020090e:	11043603          	ld	a2,272(s0)
ffffffffc0200912:	11843583          	ld	a1,280(s0)
}
ffffffffc0200916:	6442                	ld	s0,16(sp)
ffffffffc0200918:	60e2                	ld	ra,24(sp)
ffffffffc020091a:	64a2                	ld	s1,8(sp)
ffffffffc020091c:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020091e:	77c0206f          	j	ffffffffc020309a <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200922:	11843703          	ld	a4,280(s0)
ffffffffc0200926:	47bd                	li	a5,15
ffffffffc0200928:	05500613          	li	a2,85
ffffffffc020092c:	05700693          	li	a3,87
ffffffffc0200930:	faf719e3          	bne	a4,a5,ffffffffc02008e2 <pgfault_handler+0x36>
ffffffffc0200934:	bf4d                	j	ffffffffc02008e6 <pgfault_handler+0x3a>
        if (current == NULL) {
ffffffffc0200936:	000ac797          	auipc	a5,0xac
ffffffffc020093a:	af278793          	addi	a5,a5,-1294 # ffffffffc02ac428 <current>
ffffffffc020093e:	639c                	ld	a5,0(a5)
ffffffffc0200940:	cf85                	beqz	a5,ffffffffc0200978 <pgfault_handler+0xcc>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200942:	11043603          	ld	a2,272(s0)
ffffffffc0200946:	11843583          	ld	a1,280(s0)
}
ffffffffc020094a:	6442                	ld	s0,16(sp)
ffffffffc020094c:	60e2                	ld	ra,24(sp)
ffffffffc020094e:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc0200950:	7788                	ld	a0,40(a5)
}
ffffffffc0200952:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200954:	7460206f          	j	ffffffffc020309a <do_pgfault>
        assert(current == idleproc);
ffffffffc0200958:	00006697          	auipc	a3,0x6
ffffffffc020095c:	2c068693          	addi	a3,a3,704 # ffffffffc0206c18 <commands+0x468>
ffffffffc0200960:	00006617          	auipc	a2,0x6
ffffffffc0200964:	2d060613          	addi	a2,a2,720 # ffffffffc0206c30 <commands+0x480>
ffffffffc0200968:	06b00593          	li	a1,107
ffffffffc020096c:	00006517          	auipc	a0,0x6
ffffffffc0200970:	2dc50513          	addi	a0,a0,732 # ffffffffc0206c48 <commands+0x498>
ffffffffc0200974:	8a3ff0ef          	jal	ra,ffffffffc0200216 <__panic>
            print_trapframe(tf);
ffffffffc0200978:	8522                	mv	a0,s0
ffffffffc020097a:	ed1ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020097e:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200982:	11043583          	ld	a1,272(s0)
ffffffffc0200986:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020098a:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc020098e:	e399                	bnez	a5,ffffffffc0200994 <pgfault_handler+0xe8>
ffffffffc0200990:	05500613          	li	a2,85
ffffffffc0200994:	11843703          	ld	a4,280(s0)
ffffffffc0200998:	47bd                	li	a5,15
ffffffffc020099a:	02f70663          	beq	a4,a5,ffffffffc02009c6 <pgfault_handler+0x11a>
ffffffffc020099e:	05200693          	li	a3,82
ffffffffc02009a2:	00006517          	auipc	a0,0x6
ffffffffc02009a6:	25650513          	addi	a0,a0,598 # ffffffffc0206bf8 <commands+0x448>
ffffffffc02009aa:	f26ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            panic("unhandled page fault.\n");
ffffffffc02009ae:	00006617          	auipc	a2,0x6
ffffffffc02009b2:	2b260613          	addi	a2,a2,690 # ffffffffc0206c60 <commands+0x4b0>
ffffffffc02009b6:	07200593          	li	a1,114
ffffffffc02009ba:	00006517          	auipc	a0,0x6
ffffffffc02009be:	28e50513          	addi	a0,a0,654 # ffffffffc0206c48 <commands+0x498>
ffffffffc02009c2:	855ff0ef          	jal	ra,ffffffffc0200216 <__panic>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02009c6:	05700693          	li	a3,87
ffffffffc02009ca:	bfe1                	j	ffffffffc02009a2 <pgfault_handler+0xf6>

ffffffffc02009cc <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02009cc:	11853783          	ld	a5,280(a0)
ffffffffc02009d0:	577d                	li	a4,-1
ffffffffc02009d2:	8305                	srli	a4,a4,0x1
ffffffffc02009d4:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02009d6:	472d                	li	a4,11
ffffffffc02009d8:	08f76763          	bltu	a4,a5,ffffffffc0200a66 <interrupt_handler+0x9a>
ffffffffc02009dc:	00006717          	auipc	a4,0x6
ffffffffc02009e0:	f7070713          	addi	a4,a4,-144 # ffffffffc020694c <commands+0x19c>
ffffffffc02009e4:	078a                	slli	a5,a5,0x2
ffffffffc02009e6:	97ba                	add	a5,a5,a4
ffffffffc02009e8:	439c                	lw	a5,0(a5)
ffffffffc02009ea:	97ba                	add	a5,a5,a4
ffffffffc02009ec:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009ee:	00006517          	auipc	a0,0x6
ffffffffc02009f2:	1ca50513          	addi	a0,a0,458 # ffffffffc0206bb8 <commands+0x408>
ffffffffc02009f6:	edaff06f          	j	ffffffffc02000d0 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009fa:	00006517          	auipc	a0,0x6
ffffffffc02009fe:	19e50513          	addi	a0,a0,414 # ffffffffc0206b98 <commands+0x3e8>
ffffffffc0200a02:	eceff06f          	j	ffffffffc02000d0 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a06:	00006517          	auipc	a0,0x6
ffffffffc0200a0a:	15250513          	addi	a0,a0,338 # ffffffffc0206b58 <commands+0x3a8>
ffffffffc0200a0e:	ec2ff06f          	j	ffffffffc02000d0 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200a12:	00006517          	auipc	a0,0x6
ffffffffc0200a16:	16650513          	addi	a0,a0,358 # ffffffffc0206b78 <commands+0x3c8>
ffffffffc0200a1a:	eb6ff06f          	j	ffffffffc02000d0 <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a1e:	00006517          	auipc	a0,0x6
ffffffffc0200a22:	1ba50513          	addi	a0,a0,442 # ffffffffc0206bd8 <commands+0x428>
ffffffffc0200a26:	eaaff06f          	j	ffffffffc02000d0 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a2a:	1141                	addi	sp,sp,-16
ffffffffc0200a2c:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc0200a2e:	b97ff0ef          	jal	ra,ffffffffc02005c4 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0 && current) {
ffffffffc0200a32:	000ac797          	auipc	a5,0xac
ffffffffc0200a36:	a1678793          	addi	a5,a5,-1514 # ffffffffc02ac448 <ticks>
ffffffffc0200a3a:	639c                	ld	a5,0(a5)
ffffffffc0200a3c:	06400713          	li	a4,100
ffffffffc0200a40:	0785                	addi	a5,a5,1
ffffffffc0200a42:	02e7f733          	remu	a4,a5,a4
ffffffffc0200a46:	000ac697          	auipc	a3,0xac
ffffffffc0200a4a:	a0f6b123          	sd	a5,-1534(a3) # ffffffffc02ac448 <ticks>
ffffffffc0200a4e:	eb09                	bnez	a4,ffffffffc0200a60 <interrupt_handler+0x94>
ffffffffc0200a50:	000ac797          	auipc	a5,0xac
ffffffffc0200a54:	9d878793          	addi	a5,a5,-1576 # ffffffffc02ac428 <current>
ffffffffc0200a58:	639c                	ld	a5,0(a5)
ffffffffc0200a5a:	c399                	beqz	a5,ffffffffc0200a60 <interrupt_handler+0x94>
                current->need_resched = 1;
ffffffffc0200a5c:	4705                	li	a4,1
ffffffffc0200a5e:	ef98                	sd	a4,24(a5)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a60:	60a2                	ld	ra,8(sp)
ffffffffc0200a62:	0141                	addi	sp,sp,16
ffffffffc0200a64:	8082                	ret
            print_trapframe(tf);
ffffffffc0200a66:	de5ff06f          	j	ffffffffc020084a <print_trapframe>

ffffffffc0200a6a <exception_handler>:
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200a6a:	11853783          	ld	a5,280(a0)
ffffffffc0200a6e:	473d                	li	a4,15
ffffffffc0200a70:	1af76e63          	bltu	a4,a5,ffffffffc0200c2c <exception_handler+0x1c2>
ffffffffc0200a74:	00006717          	auipc	a4,0x6
ffffffffc0200a78:	f0870713          	addi	a4,a4,-248 # ffffffffc020697c <commands+0x1cc>
ffffffffc0200a7c:	078a                	slli	a5,a5,0x2
ffffffffc0200a7e:	97ba                	add	a5,a5,a4
ffffffffc0200a80:	439c                	lw	a5,0(a5)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a82:	1101                	addi	sp,sp,-32
ffffffffc0200a84:	e822                	sd	s0,16(sp)
ffffffffc0200a86:	ec06                	sd	ra,24(sp)
ffffffffc0200a88:	e426                	sd	s1,8(sp)
    switch (tf->cause) {
ffffffffc0200a8a:	97ba                	add	a5,a5,a4
ffffffffc0200a8c:	842a                	mv	s0,a0
ffffffffc0200a8e:	8782                	jr	a5
            // 从下一条指令开始执行，否则会无限循环系统调用
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
ffffffffc0200a90:	00006517          	auipc	a0,0x6
ffffffffc0200a94:	02050513          	addi	a0,a0,32 # ffffffffc0206ab0 <commands+0x300>
ffffffffc0200a98:	e38ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            tf->epc += 4;
ffffffffc0200a9c:	10843783          	ld	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200aa0:	60e2                	ld	ra,24(sp)
ffffffffc0200aa2:	64a2                	ld	s1,8(sp)
            tf->epc += 4;
ffffffffc0200aa4:	0791                	addi	a5,a5,4
ffffffffc0200aa6:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200aaa:	6442                	ld	s0,16(sp)
ffffffffc0200aac:	6105                	addi	sp,sp,32
            syscall();
ffffffffc0200aae:	6380506f          	j	ffffffffc02060e6 <syscall>
            cprintf("Environment call from H-mode\n");
ffffffffc0200ab2:	00006517          	auipc	a0,0x6
ffffffffc0200ab6:	01e50513          	addi	a0,a0,30 # ffffffffc0206ad0 <commands+0x320>
}
ffffffffc0200aba:	6442                	ld	s0,16(sp)
ffffffffc0200abc:	60e2                	ld	ra,24(sp)
ffffffffc0200abe:	64a2                	ld	s1,8(sp)
ffffffffc0200ac0:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200ac2:	e0eff06f          	j	ffffffffc02000d0 <cprintf>
            cprintf("Environment call from M-mode\n");
ffffffffc0200ac6:	00006517          	auipc	a0,0x6
ffffffffc0200aca:	02a50513          	addi	a0,a0,42 # ffffffffc0206af0 <commands+0x340>
ffffffffc0200ace:	b7f5                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200ad0:	00006517          	auipc	a0,0x6
ffffffffc0200ad4:	04050513          	addi	a0,a0,64 # ffffffffc0206b10 <commands+0x360>
ffffffffc0200ad8:	b7cd                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200ada:	00006517          	auipc	a0,0x6
ffffffffc0200ade:	04e50513          	addi	a0,a0,78 # ffffffffc0206b28 <commands+0x378>
ffffffffc0200ae2:	deeff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ae6:	8522                	mv	a0,s0
ffffffffc0200ae8:	dc5ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200aec:	84aa                	mv	s1,a0
ffffffffc0200aee:	14051163          	bnez	a0,ffffffffc0200c30 <exception_handler+0x1c6>
}
ffffffffc0200af2:	60e2                	ld	ra,24(sp)
ffffffffc0200af4:	6442                	ld	s0,16(sp)
ffffffffc0200af6:	64a2                	ld	s1,8(sp)
ffffffffc0200af8:	6105                	addi	sp,sp,32
ffffffffc0200afa:	8082                	ret
            cprintf("Store/AMO page fault\n");
ffffffffc0200afc:	00006517          	auipc	a0,0x6
ffffffffc0200b00:	04450513          	addi	a0,a0,68 # ffffffffc0206b40 <commands+0x390>
ffffffffc0200b04:	dccff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b08:	8522                	mv	a0,s0
ffffffffc0200b0a:	da3ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200b0e:	84aa                	mv	s1,a0
ffffffffc0200b10:	d16d                	beqz	a0,ffffffffc0200af2 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200b12:	8522                	mv	a0,s0
ffffffffc0200b14:	d37ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b18:	86a6                	mv	a3,s1
ffffffffc0200b1a:	00006617          	auipc	a2,0x6
ffffffffc0200b1e:	f4660613          	addi	a2,a2,-186 # ffffffffc0206a60 <commands+0x2b0>
ffffffffc0200b22:	0f900593          	li	a1,249
ffffffffc0200b26:	00006517          	auipc	a0,0x6
ffffffffc0200b2a:	12250513          	addi	a0,a0,290 # ffffffffc0206c48 <commands+0x498>
ffffffffc0200b2e:	ee8ff0ef          	jal	ra,ffffffffc0200216 <__panic>
            cprintf("Instruction address misaligned\n");
ffffffffc0200b32:	00006517          	auipc	a0,0x6
ffffffffc0200b36:	e8e50513          	addi	a0,a0,-370 # ffffffffc02069c0 <commands+0x210>
ffffffffc0200b3a:	b741                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Instruction access fault\n");
ffffffffc0200b3c:	00006517          	auipc	a0,0x6
ffffffffc0200b40:	ea450513          	addi	a0,a0,-348 # ffffffffc02069e0 <commands+0x230>
ffffffffc0200b44:	bf9d                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200b46:	00006517          	auipc	a0,0x6
ffffffffc0200b4a:	eba50513          	addi	a0,a0,-326 # ffffffffc0206a00 <commands+0x250>
ffffffffc0200b4e:	b7b5                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc0200b50:	00006517          	auipc	a0,0x6
ffffffffc0200b54:	ec850513          	addi	a0,a0,-312 # ffffffffc0206a18 <commands+0x268>
ffffffffc0200b58:	d78ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if(tf->gpr.a7 == 10){
ffffffffc0200b5c:	6458                	ld	a4,136(s0)
ffffffffc0200b5e:	47a9                	li	a5,10
ffffffffc0200b60:	f8f719e3          	bne	a4,a5,ffffffffc0200af2 <exception_handler+0x88>
                tf->epc += 4;
ffffffffc0200b64:	10843783          	ld	a5,264(s0)
ffffffffc0200b68:	0791                	addi	a5,a5,4
ffffffffc0200b6a:	10f43423          	sd	a5,264(s0)
                syscall();
ffffffffc0200b6e:	578050ef          	jal	ra,ffffffffc02060e6 <syscall>
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b72:	000ac797          	auipc	a5,0xac
ffffffffc0200b76:	8b678793          	addi	a5,a5,-1866 # ffffffffc02ac428 <current>
ffffffffc0200b7a:	639c                	ld	a5,0(a5)
ffffffffc0200b7c:	8522                	mv	a0,s0
}
ffffffffc0200b7e:	6442                	ld	s0,16(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b80:	6b9c                	ld	a5,16(a5)
}
ffffffffc0200b82:	60e2                	ld	ra,24(sp)
ffffffffc0200b84:	64a2                	ld	s1,8(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b86:	6589                	lui	a1,0x2
ffffffffc0200b88:	95be                	add	a1,a1,a5
}
ffffffffc0200b8a:	6105                	addi	sp,sp,32
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b8c:	2220006f          	j	ffffffffc0200dae <kernel_execve_ret>
            cprintf("Load address misaligned\n");
ffffffffc0200b90:	00006517          	auipc	a0,0x6
ffffffffc0200b94:	e9850513          	addi	a0,a0,-360 # ffffffffc0206a28 <commands+0x278>
ffffffffc0200b98:	b70d                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc0200b9a:	00006517          	auipc	a0,0x6
ffffffffc0200b9e:	eae50513          	addi	a0,a0,-338 # ffffffffc0206a48 <commands+0x298>
ffffffffc0200ba2:	d2eff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ba6:	8522                	mv	a0,s0
ffffffffc0200ba8:	d05ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200bac:	84aa                	mv	s1,a0
ffffffffc0200bae:	d131                	beqz	a0,ffffffffc0200af2 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200bb0:	8522                	mv	a0,s0
ffffffffc0200bb2:	c99ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bb6:	86a6                	mv	a3,s1
ffffffffc0200bb8:	00006617          	auipc	a2,0x6
ffffffffc0200bbc:	ea860613          	addi	a2,a2,-344 # ffffffffc0206a60 <commands+0x2b0>
ffffffffc0200bc0:	0cd00593          	li	a1,205
ffffffffc0200bc4:	00006517          	auipc	a0,0x6
ffffffffc0200bc8:	08450513          	addi	a0,a0,132 # ffffffffc0206c48 <commands+0x498>
ffffffffc0200bcc:	e4aff0ef          	jal	ra,ffffffffc0200216 <__panic>
            cprintf("Store/AMO access fault\n");
ffffffffc0200bd0:	00006517          	auipc	a0,0x6
ffffffffc0200bd4:	ec850513          	addi	a0,a0,-312 # ffffffffc0206a98 <commands+0x2e8>
ffffffffc0200bd8:	cf8ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200bdc:	8522                	mv	a0,s0
ffffffffc0200bde:	ccfff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200be2:	84aa                	mv	s1,a0
ffffffffc0200be4:	f00507e3          	beqz	a0,ffffffffc0200af2 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200be8:	8522                	mv	a0,s0
ffffffffc0200bea:	c61ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bee:	86a6                	mv	a3,s1
ffffffffc0200bf0:	00006617          	auipc	a2,0x6
ffffffffc0200bf4:	e7060613          	addi	a2,a2,-400 # ffffffffc0206a60 <commands+0x2b0>
ffffffffc0200bf8:	0d700593          	li	a1,215
ffffffffc0200bfc:	00006517          	auipc	a0,0x6
ffffffffc0200c00:	04c50513          	addi	a0,a0,76 # ffffffffc0206c48 <commands+0x498>
ffffffffc0200c04:	e12ff0ef          	jal	ra,ffffffffc0200216 <__panic>
}
ffffffffc0200c08:	6442                	ld	s0,16(sp)
ffffffffc0200c0a:	60e2                	ld	ra,24(sp)
ffffffffc0200c0c:	64a2                	ld	s1,8(sp)
ffffffffc0200c0e:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200c10:	c3bff06f          	j	ffffffffc020084a <print_trapframe>
            panic("AMO address misaligned\n");
ffffffffc0200c14:	00006617          	auipc	a2,0x6
ffffffffc0200c18:	e6c60613          	addi	a2,a2,-404 # ffffffffc0206a80 <commands+0x2d0>
ffffffffc0200c1c:	0d100593          	li	a1,209
ffffffffc0200c20:	00006517          	auipc	a0,0x6
ffffffffc0200c24:	02850513          	addi	a0,a0,40 # ffffffffc0206c48 <commands+0x498>
ffffffffc0200c28:	deeff0ef          	jal	ra,ffffffffc0200216 <__panic>
            print_trapframe(tf);
ffffffffc0200c2c:	c1fff06f          	j	ffffffffc020084a <print_trapframe>
                print_trapframe(tf);
ffffffffc0200c30:	8522                	mv	a0,s0
ffffffffc0200c32:	c19ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200c36:	86a6                	mv	a3,s1
ffffffffc0200c38:	00006617          	auipc	a2,0x6
ffffffffc0200c3c:	e2860613          	addi	a2,a2,-472 # ffffffffc0206a60 <commands+0x2b0>
ffffffffc0200c40:	0f200593          	li	a1,242
ffffffffc0200c44:	00006517          	auipc	a0,0x6
ffffffffc0200c48:	00450513          	addi	a0,a0,4 # ffffffffc0206c48 <commands+0x498>
ffffffffc0200c4c:	dcaff0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0200c50 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
ffffffffc0200c50:	1101                	addi	sp,sp,-32
ffffffffc0200c52:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
//    cputs("some trap");
    if (current == NULL) {
ffffffffc0200c54:	000ab417          	auipc	s0,0xab
ffffffffc0200c58:	7d440413          	addi	s0,s0,2004 # ffffffffc02ac428 <current>
ffffffffc0200c5c:	6018                	ld	a4,0(s0)
trap(struct trapframe *tf) {
ffffffffc0200c5e:	ec06                	sd	ra,24(sp)
ffffffffc0200c60:	e426                	sd	s1,8(sp)
ffffffffc0200c62:	e04a                	sd	s2,0(sp)
ffffffffc0200c64:	11853683          	ld	a3,280(a0)
    if (current == NULL) {
ffffffffc0200c68:	cf1d                	beqz	a4,ffffffffc0200ca6 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c6a:	10053483          	ld	s1,256(a0)
        trap_dispatch(tf);
    } else {
        struct trapframe *otf = current->tf;
ffffffffc0200c6e:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200c72:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c74:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c78:	0206c463          	bltz	a3,ffffffffc0200ca0 <trap+0x50>
        exception_handler(tf);
ffffffffc0200c7c:	defff0ef          	jal	ra,ffffffffc0200a6a <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200c80:	601c                	ld	a5,0(s0)
ffffffffc0200c82:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel) {
ffffffffc0200c86:	e499                	bnez	s1,ffffffffc0200c94 <trap+0x44>
            if (current->flags & PF_EXITING) {
ffffffffc0200c88:	0b07a703          	lw	a4,176(a5)
ffffffffc0200c8c:	8b05                	andi	a4,a4,1
ffffffffc0200c8e:	e339                	bnez	a4,ffffffffc0200cd4 <trap+0x84>
                do_exit(-E_KILLED);
            }
            if (current->need_resched) {
ffffffffc0200c90:	6f9c                	ld	a5,24(a5)
ffffffffc0200c92:	eb95                	bnez	a5,ffffffffc0200cc6 <trap+0x76>
                schedule();
            }
        }
    }
}
ffffffffc0200c94:	60e2                	ld	ra,24(sp)
ffffffffc0200c96:	6442                	ld	s0,16(sp)
ffffffffc0200c98:	64a2                	ld	s1,8(sp)
ffffffffc0200c9a:	6902                	ld	s2,0(sp)
ffffffffc0200c9c:	6105                	addi	sp,sp,32
ffffffffc0200c9e:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200ca0:	d2dff0ef          	jal	ra,ffffffffc02009cc <interrupt_handler>
ffffffffc0200ca4:	bff1                	j	ffffffffc0200c80 <trap+0x30>
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200ca6:	0006c963          	bltz	a3,ffffffffc0200cb8 <trap+0x68>
}
ffffffffc0200caa:	6442                	ld	s0,16(sp)
ffffffffc0200cac:	60e2                	ld	ra,24(sp)
ffffffffc0200cae:	64a2                	ld	s1,8(sp)
ffffffffc0200cb0:	6902                	ld	s2,0(sp)
ffffffffc0200cb2:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200cb4:	db7ff06f          	j	ffffffffc0200a6a <exception_handler>
}
ffffffffc0200cb8:	6442                	ld	s0,16(sp)
ffffffffc0200cba:	60e2                	ld	ra,24(sp)
ffffffffc0200cbc:	64a2                	ld	s1,8(sp)
ffffffffc0200cbe:	6902                	ld	s2,0(sp)
ffffffffc0200cc0:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200cc2:	d0bff06f          	j	ffffffffc02009cc <interrupt_handler>
}
ffffffffc0200cc6:	6442                	ld	s0,16(sp)
ffffffffc0200cc8:	60e2                	ld	ra,24(sp)
ffffffffc0200cca:	64a2                	ld	s1,8(sp)
ffffffffc0200ccc:	6902                	ld	s2,0(sp)
ffffffffc0200cce:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200cd0:	3200506f          	j	ffffffffc0205ff0 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200cd4:	555d                	li	a0,-9
ffffffffc0200cd6:	782040ef          	jal	ra,ffffffffc0205458 <do_exit>
ffffffffc0200cda:	601c                	ld	a5,0(s0)
ffffffffc0200cdc:	bf55                	j	ffffffffc0200c90 <trap+0x40>
	...

ffffffffc0200ce0 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ce0:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200ce4:	00011463          	bnez	sp,ffffffffc0200cec <__alltraps+0xc>
ffffffffc0200ce8:	14002173          	csrr	sp,sscratch
ffffffffc0200cec:	712d                	addi	sp,sp,-288
ffffffffc0200cee:	e002                	sd	zero,0(sp)
ffffffffc0200cf0:	e406                	sd	ra,8(sp)
ffffffffc0200cf2:	ec0e                	sd	gp,24(sp)
ffffffffc0200cf4:	f012                	sd	tp,32(sp)
ffffffffc0200cf6:	f416                	sd	t0,40(sp)
ffffffffc0200cf8:	f81a                	sd	t1,48(sp)
ffffffffc0200cfa:	fc1e                	sd	t2,56(sp)
ffffffffc0200cfc:	e0a2                	sd	s0,64(sp)
ffffffffc0200cfe:	e4a6                	sd	s1,72(sp)
ffffffffc0200d00:	e8aa                	sd	a0,80(sp)
ffffffffc0200d02:	ecae                	sd	a1,88(sp)
ffffffffc0200d04:	f0b2                	sd	a2,96(sp)
ffffffffc0200d06:	f4b6                	sd	a3,104(sp)
ffffffffc0200d08:	f8ba                	sd	a4,112(sp)
ffffffffc0200d0a:	fcbe                	sd	a5,120(sp)
ffffffffc0200d0c:	e142                	sd	a6,128(sp)
ffffffffc0200d0e:	e546                	sd	a7,136(sp)
ffffffffc0200d10:	e94a                	sd	s2,144(sp)
ffffffffc0200d12:	ed4e                	sd	s3,152(sp)
ffffffffc0200d14:	f152                	sd	s4,160(sp)
ffffffffc0200d16:	f556                	sd	s5,168(sp)
ffffffffc0200d18:	f95a                	sd	s6,176(sp)
ffffffffc0200d1a:	fd5e                	sd	s7,184(sp)
ffffffffc0200d1c:	e1e2                	sd	s8,192(sp)
ffffffffc0200d1e:	e5e6                	sd	s9,200(sp)
ffffffffc0200d20:	e9ea                	sd	s10,208(sp)
ffffffffc0200d22:	edee                	sd	s11,216(sp)
ffffffffc0200d24:	f1f2                	sd	t3,224(sp)
ffffffffc0200d26:	f5f6                	sd	t4,232(sp)
ffffffffc0200d28:	f9fa                	sd	t5,240(sp)
ffffffffc0200d2a:	fdfe                	sd	t6,248(sp)
ffffffffc0200d2c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200d30:	100024f3          	csrr	s1,sstatus
ffffffffc0200d34:	14102973          	csrr	s2,sepc
ffffffffc0200d38:	143029f3          	csrr	s3,stval
ffffffffc0200d3c:	14202a73          	csrr	s4,scause
ffffffffc0200d40:	e822                	sd	s0,16(sp)
ffffffffc0200d42:	e226                	sd	s1,256(sp)
ffffffffc0200d44:	e64a                	sd	s2,264(sp)
ffffffffc0200d46:	ea4e                	sd	s3,272(sp)
ffffffffc0200d48:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d4a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d4c:	f05ff0ef          	jal	ra,ffffffffc0200c50 <trap>

ffffffffc0200d50 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d50:	6492                	ld	s1,256(sp)
ffffffffc0200d52:	6932                	ld	s2,264(sp)
ffffffffc0200d54:	1004f413          	andi	s0,s1,256
ffffffffc0200d58:	e401                	bnez	s0,ffffffffc0200d60 <__trapret+0x10>
ffffffffc0200d5a:	1200                	addi	s0,sp,288
ffffffffc0200d5c:	14041073          	csrw	sscratch,s0
ffffffffc0200d60:	10049073          	csrw	sstatus,s1
ffffffffc0200d64:	14191073          	csrw	sepc,s2
ffffffffc0200d68:	60a2                	ld	ra,8(sp)
ffffffffc0200d6a:	61e2                	ld	gp,24(sp)
ffffffffc0200d6c:	7202                	ld	tp,32(sp)
ffffffffc0200d6e:	72a2                	ld	t0,40(sp)
ffffffffc0200d70:	7342                	ld	t1,48(sp)
ffffffffc0200d72:	73e2                	ld	t2,56(sp)
ffffffffc0200d74:	6406                	ld	s0,64(sp)
ffffffffc0200d76:	64a6                	ld	s1,72(sp)
ffffffffc0200d78:	6546                	ld	a0,80(sp)
ffffffffc0200d7a:	65e6                	ld	a1,88(sp)
ffffffffc0200d7c:	7606                	ld	a2,96(sp)
ffffffffc0200d7e:	76a6                	ld	a3,104(sp)
ffffffffc0200d80:	7746                	ld	a4,112(sp)
ffffffffc0200d82:	77e6                	ld	a5,120(sp)
ffffffffc0200d84:	680a                	ld	a6,128(sp)
ffffffffc0200d86:	68aa                	ld	a7,136(sp)
ffffffffc0200d88:	694a                	ld	s2,144(sp)
ffffffffc0200d8a:	69ea                	ld	s3,152(sp)
ffffffffc0200d8c:	7a0a                	ld	s4,160(sp)
ffffffffc0200d8e:	7aaa                	ld	s5,168(sp)
ffffffffc0200d90:	7b4a                	ld	s6,176(sp)
ffffffffc0200d92:	7bea                	ld	s7,184(sp)
ffffffffc0200d94:	6c0e                	ld	s8,192(sp)
ffffffffc0200d96:	6cae                	ld	s9,200(sp)
ffffffffc0200d98:	6d4e                	ld	s10,208(sp)
ffffffffc0200d9a:	6dee                	ld	s11,216(sp)
ffffffffc0200d9c:	7e0e                	ld	t3,224(sp)
ffffffffc0200d9e:	7eae                	ld	t4,232(sp)
ffffffffc0200da0:	7f4e                	ld	t5,240(sp)
ffffffffc0200da2:	7fee                	ld	t6,248(sp)
ffffffffc0200da4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200da6:	10200073          	sret

ffffffffc0200daa <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200daa:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200dac:	b755                	j	ffffffffc0200d50 <__trapret>

ffffffffc0200dae <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200dae:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7690>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200db2:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200db6:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200dba:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200dbe:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200dc2:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200dc6:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200dca:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200dce:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200dd2:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200dd4:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200dd6:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200dd8:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200dda:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200ddc:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200dde:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200de0:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200de2:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200de4:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200de6:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200de8:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200dea:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200dec:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200dee:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200df0:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200df2:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200df4:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200df6:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200df8:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200dfa:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200dfc:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200dfe:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200e00:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200e02:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200e04:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200e06:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200e08:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200e0a:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200e0c:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200e0e:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200e10:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200e12:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200e14:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200e16:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200e18:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200e1a:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200e1c:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200e1e:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200e20:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200e22:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200e24:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200e26:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200e28:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200e2a:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200e2c:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200e2e:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200e30:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200e32:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200e34:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200e36:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200e38:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200e3a:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200e3c:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200e3e:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200e40:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200e42:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200e44:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200e46:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200e48:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200e4a:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200e4c:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200e4e:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200e50:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200e52:	812e                	mv	sp,a1
ffffffffc0200e54:	bdf5                	j	ffffffffc0200d50 <__trapret>

ffffffffc0200e56 <pa2page.part.4>:
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *
pa2page(uintptr_t pa) {
ffffffffc0200e56:	1141                	addi	sp,sp,-16
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
ffffffffc0200e58:	00006617          	auipc	a2,0x6
ffffffffc0200e5c:	1f860613          	addi	a2,a2,504 # ffffffffc0207050 <commands+0x8a0>
ffffffffc0200e60:	06200593          	li	a1,98
ffffffffc0200e64:	00006517          	auipc	a0,0x6
ffffffffc0200e68:	20c50513          	addi	a0,a0,524 # ffffffffc0207070 <commands+0x8c0>
pa2page(uintptr_t pa) {
ffffffffc0200e6c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200e6e:	ba8ff0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0200e72 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0200e72:	715d                	addi	sp,sp,-80
ffffffffc0200e74:	e0a2                	sd	s0,64(sp)
ffffffffc0200e76:	fc26                	sd	s1,56(sp)
ffffffffc0200e78:	f84a                	sd	s2,48(sp)
ffffffffc0200e7a:	f44e                	sd	s3,40(sp)
ffffffffc0200e7c:	f052                	sd	s4,32(sp)
ffffffffc0200e7e:	ec56                	sd	s5,24(sp)
ffffffffc0200e80:	e486                	sd	ra,72(sp)
ffffffffc0200e82:	842a                	mv	s0,a0
ffffffffc0200e84:	000ab497          	auipc	s1,0xab
ffffffffc0200e88:	5cc48493          	addi	s1,s1,1484 # ffffffffc02ac450 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200e8c:	4985                	li	s3,1
ffffffffc0200e8e:	000aba17          	auipc	s4,0xab
ffffffffc0200e92:	592a0a13          	addi	s4,s4,1426 # ffffffffc02ac420 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0200e96:	0005091b          	sext.w	s2,a0
ffffffffc0200e9a:	000aba97          	auipc	s5,0xab
ffffffffc0200e9e:	5e6a8a93          	addi	s5,s5,1510 # ffffffffc02ac480 <check_mm_struct>
ffffffffc0200ea2:	a00d                	j	ffffffffc0200ec4 <alloc_pages+0x52>
            page = pmm_manager->alloc_pages(n);
ffffffffc0200ea4:	609c                	ld	a5,0(s1)
ffffffffc0200ea6:	6f9c                	ld	a5,24(a5)
ffffffffc0200ea8:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0);
ffffffffc0200eaa:	4601                	li	a2,0
ffffffffc0200eac:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200eae:	ed0d                	bnez	a0,ffffffffc0200ee8 <alloc_pages+0x76>
ffffffffc0200eb0:	0289ec63          	bltu	s3,s0,ffffffffc0200ee8 <alloc_pages+0x76>
ffffffffc0200eb4:	000a2783          	lw	a5,0(s4)
ffffffffc0200eb8:	2781                	sext.w	a5,a5
ffffffffc0200eba:	c79d                	beqz	a5,ffffffffc0200ee8 <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0);
ffffffffc0200ebc:	000ab503          	ld	a0,0(s5)
ffffffffc0200ec0:	787020ef          	jal	ra,ffffffffc0203e46 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200ec4:	100027f3          	csrr	a5,sstatus
ffffffffc0200ec8:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0200eca:	8522                	mv	a0,s0
ffffffffc0200ecc:	dfe1                	beqz	a5,ffffffffc0200ea4 <alloc_pages+0x32>
        intr_disable();
ffffffffc0200ece:	f8eff0ef          	jal	ra,ffffffffc020065c <intr_disable>
ffffffffc0200ed2:	609c                	ld	a5,0(s1)
ffffffffc0200ed4:	8522                	mv	a0,s0
ffffffffc0200ed6:	6f9c                	ld	a5,24(a5)
ffffffffc0200ed8:	9782                	jalr	a5
ffffffffc0200eda:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200edc:	f7aff0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc0200ee0:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0);
ffffffffc0200ee2:	4601                	li	a2,0
ffffffffc0200ee4:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200ee6:	d569                	beqz	a0,ffffffffc0200eb0 <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0200ee8:	60a6                	ld	ra,72(sp)
ffffffffc0200eea:	6406                	ld	s0,64(sp)
ffffffffc0200eec:	74e2                	ld	s1,56(sp)
ffffffffc0200eee:	7942                	ld	s2,48(sp)
ffffffffc0200ef0:	79a2                	ld	s3,40(sp)
ffffffffc0200ef2:	7a02                	ld	s4,32(sp)
ffffffffc0200ef4:	6ae2                	ld	s5,24(sp)
ffffffffc0200ef6:	6161                	addi	sp,sp,80
ffffffffc0200ef8:	8082                	ret

ffffffffc0200efa <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200efa:	100027f3          	csrr	a5,sstatus
ffffffffc0200efe:	8b89                	andi	a5,a5,2
ffffffffc0200f00:	eb89                	bnez	a5,ffffffffc0200f12 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200f02:	000ab797          	auipc	a5,0xab
ffffffffc0200f06:	54e78793          	addi	a5,a5,1358 # ffffffffc02ac450 <pmm_manager>
ffffffffc0200f0a:	639c                	ld	a5,0(a5)
ffffffffc0200f0c:	0207b303          	ld	t1,32(a5)
ffffffffc0200f10:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0200f12:	1101                	addi	sp,sp,-32
ffffffffc0200f14:	ec06                	sd	ra,24(sp)
ffffffffc0200f16:	e822                	sd	s0,16(sp)
ffffffffc0200f18:	e426                	sd	s1,8(sp)
ffffffffc0200f1a:	842a                	mv	s0,a0
ffffffffc0200f1c:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200f1e:	f3eff0ef          	jal	ra,ffffffffc020065c <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200f22:	000ab797          	auipc	a5,0xab
ffffffffc0200f26:	52e78793          	addi	a5,a5,1326 # ffffffffc02ac450 <pmm_manager>
ffffffffc0200f2a:	639c                	ld	a5,0(a5)
ffffffffc0200f2c:	85a6                	mv	a1,s1
ffffffffc0200f2e:	8522                	mv	a0,s0
ffffffffc0200f30:	739c                	ld	a5,32(a5)
ffffffffc0200f32:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200f34:	6442                	ld	s0,16(sp)
ffffffffc0200f36:	60e2                	ld	ra,24(sp)
ffffffffc0200f38:	64a2                	ld	s1,8(sp)
ffffffffc0200f3a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200f3c:	f1aff06f          	j	ffffffffc0200656 <intr_enable>

ffffffffc0200f40 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f40:	100027f3          	csrr	a5,sstatus
ffffffffc0200f44:	8b89                	andi	a5,a5,2
ffffffffc0200f46:	eb89                	bnez	a5,ffffffffc0200f58 <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200f48:	000ab797          	auipc	a5,0xab
ffffffffc0200f4c:	50878793          	addi	a5,a5,1288 # ffffffffc02ac450 <pmm_manager>
ffffffffc0200f50:	639c                	ld	a5,0(a5)
ffffffffc0200f52:	0287b303          	ld	t1,40(a5)
ffffffffc0200f56:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc0200f58:	1141                	addi	sp,sp,-16
ffffffffc0200f5a:	e406                	sd	ra,8(sp)
ffffffffc0200f5c:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200f5e:	efeff0ef          	jal	ra,ffffffffc020065c <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200f62:	000ab797          	auipc	a5,0xab
ffffffffc0200f66:	4ee78793          	addi	a5,a5,1262 # ffffffffc02ac450 <pmm_manager>
ffffffffc0200f6a:	639c                	ld	a5,0(a5)
ffffffffc0200f6c:	779c                	ld	a5,40(a5)
ffffffffc0200f6e:	9782                	jalr	a5
ffffffffc0200f70:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200f72:	ee4ff0ef          	jal	ra,ffffffffc0200656 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200f76:	8522                	mv	a0,s0
ffffffffc0200f78:	60a2                	ld	ra,8(sp)
ffffffffc0200f7a:	6402                	ld	s0,0(sp)
ffffffffc0200f7c:	0141                	addi	sp,sp,16
ffffffffc0200f7e:	8082                	ret

ffffffffc0200f80 <get_pte>:
// parameter:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200f80:	7139                	addi	sp,sp,-64
ffffffffc0200f82:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200f84:	01e5d493          	srli	s1,a1,0x1e
ffffffffc0200f88:	1ff4f493          	andi	s1,s1,511
ffffffffc0200f8c:	048e                	slli	s1,s1,0x3
ffffffffc0200f8e:	94aa                	add	s1,s1,a0
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200f90:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200f92:	f04a                	sd	s2,32(sp)
ffffffffc0200f94:	ec4e                	sd	s3,24(sp)
ffffffffc0200f96:	e852                	sd	s4,16(sp)
ffffffffc0200f98:	fc06                	sd	ra,56(sp)
ffffffffc0200f9a:	f822                	sd	s0,48(sp)
ffffffffc0200f9c:	e456                	sd	s5,8(sp)
ffffffffc0200f9e:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200fa0:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200fa4:	892e                	mv	s2,a1
ffffffffc0200fa6:	8a32                	mv	s4,a2
ffffffffc0200fa8:	000ab997          	auipc	s3,0xab
ffffffffc0200fac:	45898993          	addi	s3,s3,1112 # ffffffffc02ac400 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200fb0:	e7bd                	bnez	a5,ffffffffc020101e <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0200fb2:	12060c63          	beqz	a2,ffffffffc02010ea <get_pte+0x16a>
ffffffffc0200fb6:	4505                	li	a0,1
ffffffffc0200fb8:	ebbff0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0200fbc:	842a                	mv	s0,a0
ffffffffc0200fbe:	12050663          	beqz	a0,ffffffffc02010ea <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0200fc2:	000abb17          	auipc	s6,0xab
ffffffffc0200fc6:	4a6b0b13          	addi	s6,s6,1190 # ffffffffc02ac468 <pages>
ffffffffc0200fca:	000b3503          	ld	a0,0(s6)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc0200fce:	4785                	li	a5,1
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200fd0:	000ab997          	auipc	s3,0xab
ffffffffc0200fd4:	43098993          	addi	s3,s3,1072 # ffffffffc02ac400 <npage>
    return page - pages + nbase;
ffffffffc0200fd8:	40a40533          	sub	a0,s0,a0
ffffffffc0200fdc:	00080ab7          	lui	s5,0x80
ffffffffc0200fe0:	8519                	srai	a0,a0,0x6
ffffffffc0200fe2:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc0200fe6:	c01c                	sw	a5,0(s0)
ffffffffc0200fe8:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0200fea:	9556                	add	a0,a0,s5
ffffffffc0200fec:	83b1                	srli	a5,a5,0xc
ffffffffc0200fee:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ff0:	0532                	slli	a0,a0,0xc
ffffffffc0200ff2:	14e7f363          	bleu	a4,a5,ffffffffc0201138 <get_pte+0x1b8>
ffffffffc0200ff6:	000ab797          	auipc	a5,0xab
ffffffffc0200ffa:	46278793          	addi	a5,a5,1122 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0200ffe:	639c                	ld	a5,0(a5)
ffffffffc0201000:	6605                	lui	a2,0x1
ffffffffc0201002:	4581                	li	a1,0
ffffffffc0201004:	953e                	add	a0,a0,a5
ffffffffc0201006:	1fe050ef          	jal	ra,ffffffffc0206204 <memset>
    return page - pages + nbase;
ffffffffc020100a:	000b3683          	ld	a3,0(s6)
ffffffffc020100e:	40d406b3          	sub	a3,s0,a3
ffffffffc0201012:	8699                	srai	a3,a3,0x6
ffffffffc0201014:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201016:	06aa                	slli	a3,a3,0xa
ffffffffc0201018:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020101c:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020101e:	77fd                	lui	a5,0xfffff
ffffffffc0201020:	068a                	slli	a3,a3,0x2
ffffffffc0201022:	0009b703          	ld	a4,0(s3)
ffffffffc0201026:	8efd                	and	a3,a3,a5
ffffffffc0201028:	00c6d793          	srli	a5,a3,0xc
ffffffffc020102c:	0ce7f163          	bleu	a4,a5,ffffffffc02010ee <get_pte+0x16e>
ffffffffc0201030:	000aba97          	auipc	s5,0xab
ffffffffc0201034:	428a8a93          	addi	s5,s5,1064 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0201038:	000ab403          	ld	s0,0(s5)
ffffffffc020103c:	01595793          	srli	a5,s2,0x15
ffffffffc0201040:	1ff7f793          	andi	a5,a5,511
ffffffffc0201044:	96a2                	add	a3,a3,s0
ffffffffc0201046:	00379413          	slli	s0,a5,0x3
ffffffffc020104a:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc020104c:	6014                	ld	a3,0(s0)
ffffffffc020104e:	0016f793          	andi	a5,a3,1
ffffffffc0201052:	e3ad                	bnez	a5,ffffffffc02010b4 <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201054:	080a0b63          	beqz	s4,ffffffffc02010ea <get_pte+0x16a>
ffffffffc0201058:	4505                	li	a0,1
ffffffffc020105a:	e19ff0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc020105e:	84aa                	mv	s1,a0
ffffffffc0201060:	c549                	beqz	a0,ffffffffc02010ea <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201062:	000abb17          	auipc	s6,0xab
ffffffffc0201066:	406b0b13          	addi	s6,s6,1030 # ffffffffc02ac468 <pages>
ffffffffc020106a:	000b3503          	ld	a0,0(s6)
    page->ref = val;
ffffffffc020106e:	4785                	li	a5,1
    return page - pages + nbase;
ffffffffc0201070:	00080a37          	lui	s4,0x80
ffffffffc0201074:	40a48533          	sub	a0,s1,a0
ffffffffc0201078:	8519                	srai	a0,a0,0x6
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020107a:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc020107e:	c09c                	sw	a5,0(s1)
ffffffffc0201080:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0201082:	9552                	add	a0,a0,s4
ffffffffc0201084:	83b1                	srli	a5,a5,0xc
ffffffffc0201086:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201088:	0532                	slli	a0,a0,0xc
ffffffffc020108a:	08e7fa63          	bleu	a4,a5,ffffffffc020111e <get_pte+0x19e>
ffffffffc020108e:	000ab783          	ld	a5,0(s5)
ffffffffc0201092:	6605                	lui	a2,0x1
ffffffffc0201094:	4581                	li	a1,0
ffffffffc0201096:	953e                	add	a0,a0,a5
ffffffffc0201098:	16c050ef          	jal	ra,ffffffffc0206204 <memset>
    return page - pages + nbase;
ffffffffc020109c:	000b3683          	ld	a3,0(s6)
ffffffffc02010a0:	40d486b3          	sub	a3,s1,a3
ffffffffc02010a4:	8699                	srai	a3,a3,0x6
ffffffffc02010a6:	96d2                	add	a3,a3,s4
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02010a8:	06aa                	slli	a3,a3,0xa
ffffffffc02010aa:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02010ae:	e014                	sd	a3,0(s0)
ffffffffc02010b0:	0009b703          	ld	a4,0(s3)
        }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02010b4:	068a                	slli	a3,a3,0x2
ffffffffc02010b6:	757d                	lui	a0,0xfffff
ffffffffc02010b8:	8ee9                	and	a3,a3,a0
ffffffffc02010ba:	00c6d793          	srli	a5,a3,0xc
ffffffffc02010be:	04e7f463          	bleu	a4,a5,ffffffffc0201106 <get_pte+0x186>
ffffffffc02010c2:	000ab503          	ld	a0,0(s5)
ffffffffc02010c6:	00c95793          	srli	a5,s2,0xc
ffffffffc02010ca:	1ff7f793          	andi	a5,a5,511
ffffffffc02010ce:	96aa                	add	a3,a3,a0
ffffffffc02010d0:	00379513          	slli	a0,a5,0x3
ffffffffc02010d4:	9536                	add	a0,a0,a3
}
ffffffffc02010d6:	70e2                	ld	ra,56(sp)
ffffffffc02010d8:	7442                	ld	s0,48(sp)
ffffffffc02010da:	74a2                	ld	s1,40(sp)
ffffffffc02010dc:	7902                	ld	s2,32(sp)
ffffffffc02010de:	69e2                	ld	s3,24(sp)
ffffffffc02010e0:	6a42                	ld	s4,16(sp)
ffffffffc02010e2:	6aa2                	ld	s5,8(sp)
ffffffffc02010e4:	6b02                	ld	s6,0(sp)
ffffffffc02010e6:	6121                	addi	sp,sp,64
ffffffffc02010e8:	8082                	ret
            return NULL;
ffffffffc02010ea:	4501                	li	a0,0
ffffffffc02010ec:	b7ed                	j	ffffffffc02010d6 <get_pte+0x156>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02010ee:	00006617          	auipc	a2,0x6
ffffffffc02010f2:	f2a60613          	addi	a2,a2,-214 # ffffffffc0207018 <commands+0x868>
ffffffffc02010f6:	0e300593          	li	a1,227
ffffffffc02010fa:	00006517          	auipc	a0,0x6
ffffffffc02010fe:	f4650513          	addi	a0,a0,-186 # ffffffffc0207040 <commands+0x890>
ffffffffc0201102:	914ff0ef          	jal	ra,ffffffffc0200216 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201106:	00006617          	auipc	a2,0x6
ffffffffc020110a:	f1260613          	addi	a2,a2,-238 # ffffffffc0207018 <commands+0x868>
ffffffffc020110e:	0ee00593          	li	a1,238
ffffffffc0201112:	00006517          	auipc	a0,0x6
ffffffffc0201116:	f2e50513          	addi	a0,a0,-210 # ffffffffc0207040 <commands+0x890>
ffffffffc020111a:	8fcff0ef          	jal	ra,ffffffffc0200216 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020111e:	86aa                	mv	a3,a0
ffffffffc0201120:	00006617          	auipc	a2,0x6
ffffffffc0201124:	ef860613          	addi	a2,a2,-264 # ffffffffc0207018 <commands+0x868>
ffffffffc0201128:	0eb00593          	li	a1,235
ffffffffc020112c:	00006517          	auipc	a0,0x6
ffffffffc0201130:	f1450513          	addi	a0,a0,-236 # ffffffffc0207040 <commands+0x890>
ffffffffc0201134:	8e2ff0ef          	jal	ra,ffffffffc0200216 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201138:	86aa                	mv	a3,a0
ffffffffc020113a:	00006617          	auipc	a2,0x6
ffffffffc020113e:	ede60613          	addi	a2,a2,-290 # ffffffffc0207018 <commands+0x868>
ffffffffc0201142:	0df00593          	li	a1,223
ffffffffc0201146:	00006517          	auipc	a0,0x6
ffffffffc020114a:	efa50513          	addi	a0,a0,-262 # ffffffffc0207040 <commands+0x890>
ffffffffc020114e:	8c8ff0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0201152 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201152:	1141                	addi	sp,sp,-16
ffffffffc0201154:	e022                	sd	s0,0(sp)
ffffffffc0201156:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201158:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc020115a:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020115c:	e25ff0ef          	jal	ra,ffffffffc0200f80 <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201160:	c011                	beqz	s0,ffffffffc0201164 <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0201162:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201164:	c129                	beqz	a0,ffffffffc02011a6 <get_page+0x54>
ffffffffc0201166:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201168:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc020116a:	0017f713          	andi	a4,a5,1
ffffffffc020116e:	e709                	bnez	a4,ffffffffc0201178 <get_page+0x26>
}
ffffffffc0201170:	60a2                	ld	ra,8(sp)
ffffffffc0201172:	6402                	ld	s0,0(sp)
ffffffffc0201174:	0141                	addi	sp,sp,16
ffffffffc0201176:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0201178:	000ab717          	auipc	a4,0xab
ffffffffc020117c:	28870713          	addi	a4,a4,648 # ffffffffc02ac400 <npage>
ffffffffc0201180:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201182:	078a                	slli	a5,a5,0x2
ffffffffc0201184:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201186:	02e7f563          	bleu	a4,a5,ffffffffc02011b0 <get_page+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc020118a:	000ab717          	auipc	a4,0xab
ffffffffc020118e:	2de70713          	addi	a4,a4,734 # ffffffffc02ac468 <pages>
ffffffffc0201192:	6308                	ld	a0,0(a4)
ffffffffc0201194:	60a2                	ld	ra,8(sp)
ffffffffc0201196:	6402                	ld	s0,0(sp)
ffffffffc0201198:	fff80737          	lui	a4,0xfff80
ffffffffc020119c:	97ba                	add	a5,a5,a4
ffffffffc020119e:	079a                	slli	a5,a5,0x6
ffffffffc02011a0:	953e                	add	a0,a0,a5
ffffffffc02011a2:	0141                	addi	sp,sp,16
ffffffffc02011a4:	8082                	ret
ffffffffc02011a6:	60a2                	ld	ra,8(sp)
ffffffffc02011a8:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc02011aa:	4501                	li	a0,0
}
ffffffffc02011ac:	0141                	addi	sp,sp,16
ffffffffc02011ae:	8082                	ret
ffffffffc02011b0:	ca7ff0ef          	jal	ra,ffffffffc0200e56 <pa2page.part.4>

ffffffffc02011b4 <unmap_range>:
        *ptep = 0;                  //(5) clear second page table entry
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02011b4:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02011b6:	00c5e7b3          	or	a5,a1,a2
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02011ba:	ec86                	sd	ra,88(sp)
ffffffffc02011bc:	e8a2                	sd	s0,80(sp)
ffffffffc02011be:	e4a6                	sd	s1,72(sp)
ffffffffc02011c0:	e0ca                	sd	s2,64(sp)
ffffffffc02011c2:	fc4e                	sd	s3,56(sp)
ffffffffc02011c4:	f852                	sd	s4,48(sp)
ffffffffc02011c6:	f456                	sd	s5,40(sp)
ffffffffc02011c8:	f05a                	sd	s6,32(sp)
ffffffffc02011ca:	ec5e                	sd	s7,24(sp)
ffffffffc02011cc:	e862                	sd	s8,16(sp)
ffffffffc02011ce:	e466                	sd	s9,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02011d0:	03479713          	slli	a4,a5,0x34
ffffffffc02011d4:	eb71                	bnez	a4,ffffffffc02012a8 <unmap_range+0xf4>
    assert(USER_ACCESS(start, end));
ffffffffc02011d6:	002007b7          	lui	a5,0x200
ffffffffc02011da:	842e                	mv	s0,a1
ffffffffc02011dc:	0af5e663          	bltu	a1,a5,ffffffffc0201288 <unmap_range+0xd4>
ffffffffc02011e0:	8932                	mv	s2,a2
ffffffffc02011e2:	0ac5f363          	bleu	a2,a1,ffffffffc0201288 <unmap_range+0xd4>
ffffffffc02011e6:	4785                	li	a5,1
ffffffffc02011e8:	07fe                	slli	a5,a5,0x1f
ffffffffc02011ea:	08c7ef63          	bltu	a5,a2,ffffffffc0201288 <unmap_range+0xd4>
ffffffffc02011ee:	89aa                	mv	s3,a0
            continue;
        }
        if (*ptep != 0) {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02011f0:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc02011f2:	000abc97          	auipc	s9,0xab
ffffffffc02011f6:	20ec8c93          	addi	s9,s9,526 # ffffffffc02ac400 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02011fa:	000abc17          	auipc	s8,0xab
ffffffffc02011fe:	26ec0c13          	addi	s8,s8,622 # ffffffffc02ac468 <pages>
ffffffffc0201202:	fff80bb7          	lui	s7,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0201206:	00200b37          	lui	s6,0x200
ffffffffc020120a:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc020120e:	4601                	li	a2,0
ffffffffc0201210:	85a2                	mv	a1,s0
ffffffffc0201212:	854e                	mv	a0,s3
ffffffffc0201214:	d6dff0ef          	jal	ra,ffffffffc0200f80 <get_pte>
ffffffffc0201218:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc020121a:	cd21                	beqz	a0,ffffffffc0201272 <unmap_range+0xbe>
        if (*ptep != 0) {
ffffffffc020121c:	611c                	ld	a5,0(a0)
ffffffffc020121e:	e38d                	bnez	a5,ffffffffc0201240 <unmap_range+0x8c>
        start += PGSIZE;
ffffffffc0201220:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0201222:	ff2466e3          	bltu	s0,s2,ffffffffc020120e <unmap_range+0x5a>
}
ffffffffc0201226:	60e6                	ld	ra,88(sp)
ffffffffc0201228:	6446                	ld	s0,80(sp)
ffffffffc020122a:	64a6                	ld	s1,72(sp)
ffffffffc020122c:	6906                	ld	s2,64(sp)
ffffffffc020122e:	79e2                	ld	s3,56(sp)
ffffffffc0201230:	7a42                	ld	s4,48(sp)
ffffffffc0201232:	7aa2                	ld	s5,40(sp)
ffffffffc0201234:	7b02                	ld	s6,32(sp)
ffffffffc0201236:	6be2                	ld	s7,24(sp)
ffffffffc0201238:	6c42                	ld	s8,16(sp)
ffffffffc020123a:	6ca2                	ld	s9,8(sp)
ffffffffc020123c:	6125                	addi	sp,sp,96
ffffffffc020123e:	8082                	ret
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0201240:	0017f713          	andi	a4,a5,1
ffffffffc0201244:	df71                	beqz	a4,ffffffffc0201220 <unmap_range+0x6c>
    if (PPN(pa) >= npage) {
ffffffffc0201246:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020124a:	078a                	slli	a5,a5,0x2
ffffffffc020124c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020124e:	06e7fd63          	bleu	a4,a5,ffffffffc02012c8 <unmap_range+0x114>
    return &pages[PPN(pa) - nbase];
ffffffffc0201252:	000c3503          	ld	a0,0(s8)
ffffffffc0201256:	97de                	add	a5,a5,s7
ffffffffc0201258:	079a                	slli	a5,a5,0x6
ffffffffc020125a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020125c:	411c                	lw	a5,0(a0)
ffffffffc020125e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201262:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201264:	cf11                	beqz	a4,ffffffffc0201280 <unmap_range+0xcc>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0201266:	0004b023          	sd	zero,0(s1)
}

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020126a:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc020126e:	9452                	add	s0,s0,s4
ffffffffc0201270:	bf4d                	j	ffffffffc0201222 <unmap_range+0x6e>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0201272:	945a                	add	s0,s0,s6
ffffffffc0201274:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0201278:	d45d                	beqz	s0,ffffffffc0201226 <unmap_range+0x72>
ffffffffc020127a:	f9246ae3          	bltu	s0,s2,ffffffffc020120e <unmap_range+0x5a>
ffffffffc020127e:	b765                	j	ffffffffc0201226 <unmap_range+0x72>
            free_page(page);
ffffffffc0201280:	4585                	li	a1,1
ffffffffc0201282:	c79ff0ef          	jal	ra,ffffffffc0200efa <free_pages>
ffffffffc0201286:	b7c5                	j	ffffffffc0201266 <unmap_range+0xb2>
    assert(USER_ACCESS(start, end));
ffffffffc0201288:	00006697          	auipc	a3,0x6
ffffffffc020128c:	3b868693          	addi	a3,a3,952 # ffffffffc0207640 <commands+0xe90>
ffffffffc0201290:	00006617          	auipc	a2,0x6
ffffffffc0201294:	9a060613          	addi	a2,a2,-1632 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201298:	11000593          	li	a1,272
ffffffffc020129c:	00006517          	auipc	a0,0x6
ffffffffc02012a0:	da450513          	addi	a0,a0,-604 # ffffffffc0207040 <commands+0x890>
ffffffffc02012a4:	f73fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02012a8:	00006697          	auipc	a3,0x6
ffffffffc02012ac:	36868693          	addi	a3,a3,872 # ffffffffc0207610 <commands+0xe60>
ffffffffc02012b0:	00006617          	auipc	a2,0x6
ffffffffc02012b4:	98060613          	addi	a2,a2,-1664 # ffffffffc0206c30 <commands+0x480>
ffffffffc02012b8:	10f00593          	li	a1,271
ffffffffc02012bc:	00006517          	auipc	a0,0x6
ffffffffc02012c0:	d8450513          	addi	a0,a0,-636 # ffffffffc0207040 <commands+0x890>
ffffffffc02012c4:	f53fe0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc02012c8:	b8fff0ef          	jal	ra,ffffffffc0200e56 <pa2page.part.4>

ffffffffc02012cc <exit_range>:
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02012cc:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02012ce:	00c5e7b3          	or	a5,a1,a2
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02012d2:	fc86                	sd	ra,120(sp)
ffffffffc02012d4:	f8a2                	sd	s0,112(sp)
ffffffffc02012d6:	f4a6                	sd	s1,104(sp)
ffffffffc02012d8:	f0ca                	sd	s2,96(sp)
ffffffffc02012da:	ecce                	sd	s3,88(sp)
ffffffffc02012dc:	e8d2                	sd	s4,80(sp)
ffffffffc02012de:	e4d6                	sd	s5,72(sp)
ffffffffc02012e0:	e0da                	sd	s6,64(sp)
ffffffffc02012e2:	fc5e                	sd	s7,56(sp)
ffffffffc02012e4:	f862                	sd	s8,48(sp)
ffffffffc02012e6:	f466                	sd	s9,40(sp)
ffffffffc02012e8:	f06a                	sd	s10,32(sp)
ffffffffc02012ea:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02012ec:	03479713          	slli	a4,a5,0x34
ffffffffc02012f0:	1c071163          	bnez	a4,ffffffffc02014b2 <exit_range+0x1e6>
    assert(USER_ACCESS(start, end));
ffffffffc02012f4:	002007b7          	lui	a5,0x200
ffffffffc02012f8:	20f5e563          	bltu	a1,a5,ffffffffc0201502 <exit_range+0x236>
ffffffffc02012fc:	8b32                	mv	s6,a2
ffffffffc02012fe:	20c5f263          	bleu	a2,a1,ffffffffc0201502 <exit_range+0x236>
ffffffffc0201302:	4785                	li	a5,1
ffffffffc0201304:	07fe                	slli	a5,a5,0x1f
ffffffffc0201306:	1ec7ee63          	bltu	a5,a2,ffffffffc0201502 <exit_range+0x236>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020130a:	c00009b7          	lui	s3,0xc0000
ffffffffc020130e:	400007b7          	lui	a5,0x40000
ffffffffc0201312:	0135f9b3          	and	s3,a1,s3
ffffffffc0201316:	99be                	add	s3,s3,a5
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0201318:	c0000337          	lui	t1,0xc0000
ffffffffc020131c:	00698933          	add	s2,s3,t1
ffffffffc0201320:	01e95913          	srli	s2,s2,0x1e
ffffffffc0201324:	1ff97913          	andi	s2,s2,511
ffffffffc0201328:	8e2a                	mv	t3,a0
ffffffffc020132a:	090e                	slli	s2,s2,0x3
ffffffffc020132c:	9972                	add	s2,s2,t3
ffffffffc020132e:	00093b83          	ld	s7,0(s2)
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0201332:	ffe004b7          	lui	s1,0xffe00
    return KADDR(page2pa(page));
ffffffffc0201336:	5dfd                	li	s11,-1
        if (pde1&PTE_V){
ffffffffc0201338:	001bf793          	andi	a5,s7,1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020133c:	8ced                	and	s1,s1,a1
    if (PPN(pa) >= npage) {
ffffffffc020133e:	000abd17          	auipc	s10,0xab
ffffffffc0201342:	0c2d0d13          	addi	s10,s10,194 # ffffffffc02ac400 <npage>
    return KADDR(page2pa(page));
ffffffffc0201346:	00cddd93          	srli	s11,s11,0xc
ffffffffc020134a:	000ab717          	auipc	a4,0xab
ffffffffc020134e:	10e70713          	addi	a4,a4,270 # ffffffffc02ac458 <va_pa_offset>
    return &pages[PPN(pa) - nbase];
ffffffffc0201352:	000abe97          	auipc	t4,0xab
ffffffffc0201356:	116e8e93          	addi	t4,t4,278 # ffffffffc02ac468 <pages>
        if (pde1&PTE_V){
ffffffffc020135a:	e79d                	bnez	a5,ffffffffc0201388 <exit_range+0xbc>
    } while (d1start != 0 && d1start < end);
ffffffffc020135c:	12098963          	beqz	s3,ffffffffc020148e <exit_range+0x1c2>
ffffffffc0201360:	400007b7          	lui	a5,0x40000
ffffffffc0201364:	84ce                	mv	s1,s3
ffffffffc0201366:	97ce                	add	a5,a5,s3
ffffffffc0201368:	1369f363          	bleu	s6,s3,ffffffffc020148e <exit_range+0x1c2>
ffffffffc020136c:	89be                	mv	s3,a5
        pde1 = pgdir[PDX1(d1start)];
ffffffffc020136e:	00698933          	add	s2,s3,t1
ffffffffc0201372:	01e95913          	srli	s2,s2,0x1e
ffffffffc0201376:	1ff97913          	andi	s2,s2,511
ffffffffc020137a:	090e                	slli	s2,s2,0x3
ffffffffc020137c:	9972                	add	s2,s2,t3
ffffffffc020137e:	00093b83          	ld	s7,0(s2)
        if (pde1&PTE_V){
ffffffffc0201382:	001bf793          	andi	a5,s7,1
ffffffffc0201386:	dbf9                	beqz	a5,ffffffffc020135c <exit_range+0x90>
    if (PPN(pa) >= npage) {
ffffffffc0201388:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020138c:	0b8a                	slli	s7,s7,0x2
ffffffffc020138e:	00cbdb93          	srli	s7,s7,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201392:	14fbfc63          	bleu	a5,s7,ffffffffc02014ea <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc0201396:	fff80ab7          	lui	s5,0xfff80
ffffffffc020139a:	9ade                	add	s5,s5,s7
    return page - pages + nbase;
ffffffffc020139c:	000806b7          	lui	a3,0x80
ffffffffc02013a0:	96d6                	add	a3,a3,s5
ffffffffc02013a2:	006a9593          	slli	a1,s5,0x6
    return KADDR(page2pa(page));
ffffffffc02013a6:	01b6f633          	and	a2,a3,s11
    return page - pages + nbase;
ffffffffc02013aa:	e42e                	sd	a1,8(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc02013ac:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02013ae:	12f67263          	bleu	a5,a2,ffffffffc02014d2 <exit_range+0x206>
ffffffffc02013b2:	00073a03          	ld	s4,0(a4)
            free_pd0 = 1;
ffffffffc02013b6:	4c85                	li	s9,1
    return &pages[PPN(pa) - nbase];
ffffffffc02013b8:	fff808b7          	lui	a7,0xfff80
    return KADDR(page2pa(page));
ffffffffc02013bc:	9a36                	add	s4,s4,a3
    return page - pages + nbase;
ffffffffc02013be:	00080837          	lui	a6,0x80
ffffffffc02013c2:	6a85                	lui	s5,0x1
                d0start += PTSIZE;
ffffffffc02013c4:	00200c37          	lui	s8,0x200
ffffffffc02013c8:	a801                	j	ffffffffc02013d8 <exit_range+0x10c>
                    free_pd0 = 0;
ffffffffc02013ca:	4c81                	li	s9,0
                d0start += PTSIZE;
ffffffffc02013cc:	94e2                	add	s1,s1,s8
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc02013ce:	c0d9                	beqz	s1,ffffffffc0201454 <exit_range+0x188>
ffffffffc02013d0:	0934f263          	bleu	s3,s1,ffffffffc0201454 <exit_range+0x188>
ffffffffc02013d4:	0d64fc63          	bleu	s6,s1,ffffffffc02014ac <exit_range+0x1e0>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02013d8:	0154d413          	srli	s0,s1,0x15
ffffffffc02013dc:	1ff47413          	andi	s0,s0,511
ffffffffc02013e0:	040e                	slli	s0,s0,0x3
ffffffffc02013e2:	9452                	add	s0,s0,s4
ffffffffc02013e4:	601c                	ld	a5,0(s0)
                if (pde0&PTE_V) {
ffffffffc02013e6:	0017f693          	andi	a3,a5,1
ffffffffc02013ea:	d2e5                	beqz	a3,ffffffffc02013ca <exit_range+0xfe>
    if (PPN(pa) >= npage) {
ffffffffc02013ec:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02013f0:	00279513          	slli	a0,a5,0x2
ffffffffc02013f4:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc02013f6:	0eb57a63          	bleu	a1,a0,ffffffffc02014ea <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc02013fa:	9546                	add	a0,a0,a7
    return page - pages + nbase;
ffffffffc02013fc:	010506b3          	add	a3,a0,a6
    return KADDR(page2pa(page));
ffffffffc0201400:	01b6f7b3          	and	a5,a3,s11
    return page - pages + nbase;
ffffffffc0201404:	051a                	slli	a0,a0,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0201406:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201408:	0cb7f563          	bleu	a1,a5,ffffffffc02014d2 <exit_range+0x206>
ffffffffc020140c:	631c                	ld	a5,0(a4)
ffffffffc020140e:	96be                	add	a3,a3,a5
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc0201410:	015685b3          	add	a1,a3,s5
                        if (pt[i]&PTE_V){
ffffffffc0201414:	629c                	ld	a5,0(a3)
ffffffffc0201416:	8b85                	andi	a5,a5,1
ffffffffc0201418:	fbd5                	bnez	a5,ffffffffc02013cc <exit_range+0x100>
ffffffffc020141a:	06a1                	addi	a3,a3,8
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc020141c:	fed59ce3          	bne	a1,a3,ffffffffc0201414 <exit_range+0x148>
    return &pages[PPN(pa) - nbase];
ffffffffc0201420:	000eb783          	ld	a5,0(t4)
                        free_page(pde2page(pde0));
ffffffffc0201424:	4585                	li	a1,1
ffffffffc0201426:	e072                	sd	t3,0(sp)
ffffffffc0201428:	953e                	add	a0,a0,a5
ffffffffc020142a:	ad1ff0ef          	jal	ra,ffffffffc0200efa <free_pages>
                d0start += PTSIZE;
ffffffffc020142e:	94e2                	add	s1,s1,s8
                        pd0[PDX0(d0start)] = 0;
ffffffffc0201430:	00043023          	sd	zero,0(s0)
ffffffffc0201434:	000abe97          	auipc	t4,0xab
ffffffffc0201438:	034e8e93          	addi	t4,t4,52 # ffffffffc02ac468 <pages>
ffffffffc020143c:	6e02                	ld	t3,0(sp)
ffffffffc020143e:	c0000337          	lui	t1,0xc0000
ffffffffc0201442:	fff808b7          	lui	a7,0xfff80
ffffffffc0201446:	00080837          	lui	a6,0x80
ffffffffc020144a:	000ab717          	auipc	a4,0xab
ffffffffc020144e:	00e70713          	addi	a4,a4,14 # ffffffffc02ac458 <va_pa_offset>
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc0201452:	fcbd                	bnez	s1,ffffffffc02013d0 <exit_range+0x104>
            if (free_pd0) {
ffffffffc0201454:	f00c84e3          	beqz	s9,ffffffffc020135c <exit_range+0x90>
    if (PPN(pa) >= npage) {
ffffffffc0201458:	000d3783          	ld	a5,0(s10)
ffffffffc020145c:	e072                	sd	t3,0(sp)
ffffffffc020145e:	08fbf663          	bleu	a5,s7,ffffffffc02014ea <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc0201462:	000eb503          	ld	a0,0(t4)
                free_page(pde2page(pde1));
ffffffffc0201466:	67a2                	ld	a5,8(sp)
ffffffffc0201468:	4585                	li	a1,1
ffffffffc020146a:	953e                	add	a0,a0,a5
ffffffffc020146c:	a8fff0ef          	jal	ra,ffffffffc0200efa <free_pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0201470:	00093023          	sd	zero,0(s2)
ffffffffc0201474:	000ab717          	auipc	a4,0xab
ffffffffc0201478:	fe470713          	addi	a4,a4,-28 # ffffffffc02ac458 <va_pa_offset>
ffffffffc020147c:	c0000337          	lui	t1,0xc0000
ffffffffc0201480:	6e02                	ld	t3,0(sp)
ffffffffc0201482:	000abe97          	auipc	t4,0xab
ffffffffc0201486:	fe6e8e93          	addi	t4,t4,-26 # ffffffffc02ac468 <pages>
    } while (d1start != 0 && d1start < end);
ffffffffc020148a:	ec099be3          	bnez	s3,ffffffffc0201360 <exit_range+0x94>
}
ffffffffc020148e:	70e6                	ld	ra,120(sp)
ffffffffc0201490:	7446                	ld	s0,112(sp)
ffffffffc0201492:	74a6                	ld	s1,104(sp)
ffffffffc0201494:	7906                	ld	s2,96(sp)
ffffffffc0201496:	69e6                	ld	s3,88(sp)
ffffffffc0201498:	6a46                	ld	s4,80(sp)
ffffffffc020149a:	6aa6                	ld	s5,72(sp)
ffffffffc020149c:	6b06                	ld	s6,64(sp)
ffffffffc020149e:	7be2                	ld	s7,56(sp)
ffffffffc02014a0:	7c42                	ld	s8,48(sp)
ffffffffc02014a2:	7ca2                	ld	s9,40(sp)
ffffffffc02014a4:	7d02                	ld	s10,32(sp)
ffffffffc02014a6:	6de2                	ld	s11,24(sp)
ffffffffc02014a8:	6109                	addi	sp,sp,128
ffffffffc02014aa:	8082                	ret
            if (free_pd0) {
ffffffffc02014ac:	ea0c8ae3          	beqz	s9,ffffffffc0201360 <exit_range+0x94>
ffffffffc02014b0:	b765                	j	ffffffffc0201458 <exit_range+0x18c>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02014b2:	00006697          	auipc	a3,0x6
ffffffffc02014b6:	15e68693          	addi	a3,a3,350 # ffffffffc0207610 <commands+0xe60>
ffffffffc02014ba:	00005617          	auipc	a2,0x5
ffffffffc02014be:	77660613          	addi	a2,a2,1910 # ffffffffc0206c30 <commands+0x480>
ffffffffc02014c2:	12000593          	li	a1,288
ffffffffc02014c6:	00006517          	auipc	a0,0x6
ffffffffc02014ca:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0207040 <commands+0x890>
ffffffffc02014ce:	d49fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    return KADDR(page2pa(page));
ffffffffc02014d2:	00006617          	auipc	a2,0x6
ffffffffc02014d6:	b4660613          	addi	a2,a2,-1210 # ffffffffc0207018 <commands+0x868>
ffffffffc02014da:	06900593          	li	a1,105
ffffffffc02014de:	00006517          	auipc	a0,0x6
ffffffffc02014e2:	b9250513          	addi	a0,a0,-1134 # ffffffffc0207070 <commands+0x8c0>
ffffffffc02014e6:	d31fe0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02014ea:	00006617          	auipc	a2,0x6
ffffffffc02014ee:	b6660613          	addi	a2,a2,-1178 # ffffffffc0207050 <commands+0x8a0>
ffffffffc02014f2:	06200593          	li	a1,98
ffffffffc02014f6:	00006517          	auipc	a0,0x6
ffffffffc02014fa:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0207070 <commands+0x8c0>
ffffffffc02014fe:	d19fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0201502:	00006697          	auipc	a3,0x6
ffffffffc0201506:	13e68693          	addi	a3,a3,318 # ffffffffc0207640 <commands+0xe90>
ffffffffc020150a:	00005617          	auipc	a2,0x5
ffffffffc020150e:	72660613          	addi	a2,a2,1830 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201512:	12100593          	li	a1,289
ffffffffc0201516:	00006517          	auipc	a0,0x6
ffffffffc020151a:	b2a50513          	addi	a0,a0,-1238 # ffffffffc0207040 <commands+0x890>
ffffffffc020151e:	cf9fe0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0201522 <page_remove>:
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201522:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201524:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201526:	e426                	sd	s1,8(sp)
ffffffffc0201528:	ec06                	sd	ra,24(sp)
ffffffffc020152a:	e822                	sd	s0,16(sp)
ffffffffc020152c:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020152e:	a53ff0ef          	jal	ra,ffffffffc0200f80 <get_pte>
    if (ptep != NULL) {
ffffffffc0201532:	c511                	beqz	a0,ffffffffc020153e <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0201534:	611c                	ld	a5,0(a0)
ffffffffc0201536:	842a                	mv	s0,a0
ffffffffc0201538:	0017f713          	andi	a4,a5,1
ffffffffc020153c:	e711                	bnez	a4,ffffffffc0201548 <page_remove+0x26>
}
ffffffffc020153e:	60e2                	ld	ra,24(sp)
ffffffffc0201540:	6442                	ld	s0,16(sp)
ffffffffc0201542:	64a2                	ld	s1,8(sp)
ffffffffc0201544:	6105                	addi	sp,sp,32
ffffffffc0201546:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0201548:	000ab717          	auipc	a4,0xab
ffffffffc020154c:	eb870713          	addi	a4,a4,-328 # ffffffffc02ac400 <npage>
ffffffffc0201550:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201552:	078a                	slli	a5,a5,0x2
ffffffffc0201554:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201556:	02e7fe63          	bleu	a4,a5,ffffffffc0201592 <page_remove+0x70>
    return &pages[PPN(pa) - nbase];
ffffffffc020155a:	000ab717          	auipc	a4,0xab
ffffffffc020155e:	f0e70713          	addi	a4,a4,-242 # ffffffffc02ac468 <pages>
ffffffffc0201562:	6308                	ld	a0,0(a4)
ffffffffc0201564:	fff80737          	lui	a4,0xfff80
ffffffffc0201568:	97ba                	add	a5,a5,a4
ffffffffc020156a:	079a                	slli	a5,a5,0x6
ffffffffc020156c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020156e:	411c                	lw	a5,0(a0)
ffffffffc0201570:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201574:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201576:	cb11                	beqz	a4,ffffffffc020158a <page_remove+0x68>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0201578:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020157c:	12048073          	sfence.vma	s1
}
ffffffffc0201580:	60e2                	ld	ra,24(sp)
ffffffffc0201582:	6442                	ld	s0,16(sp)
ffffffffc0201584:	64a2                	ld	s1,8(sp)
ffffffffc0201586:	6105                	addi	sp,sp,32
ffffffffc0201588:	8082                	ret
            free_page(page);
ffffffffc020158a:	4585                	li	a1,1
ffffffffc020158c:	96fff0ef          	jal	ra,ffffffffc0200efa <free_pages>
ffffffffc0201590:	b7e5                	j	ffffffffc0201578 <page_remove+0x56>
ffffffffc0201592:	8c5ff0ef          	jal	ra,ffffffffc0200e56 <pa2page.part.4>

ffffffffc0201596 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201596:	7179                	addi	sp,sp,-48
ffffffffc0201598:	e44e                	sd	s3,8(sp)
ffffffffc020159a:	89b2                	mv	s3,a2
ffffffffc020159c:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020159e:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02015a0:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02015a2:	85ce                	mv	a1,s3
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02015a4:	ec26                	sd	s1,24(sp)
ffffffffc02015a6:	f406                	sd	ra,40(sp)
ffffffffc02015a8:	e84a                	sd	s2,16(sp)
ffffffffc02015aa:	e052                	sd	s4,0(sp)
ffffffffc02015ac:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02015ae:	9d3ff0ef          	jal	ra,ffffffffc0200f80 <get_pte>
    if (ptep == NULL) {
ffffffffc02015b2:	cd49                	beqz	a0,ffffffffc020164c <page_insert+0xb6>
    page->ref += 1;
ffffffffc02015b4:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc02015b6:	611c                	ld	a5,0(a0)
ffffffffc02015b8:	892a                	mv	s2,a0
ffffffffc02015ba:	0016871b          	addiw	a4,a3,1
ffffffffc02015be:	c018                	sw	a4,0(s0)
ffffffffc02015c0:	0017f713          	andi	a4,a5,1
ffffffffc02015c4:	ef05                	bnez	a4,ffffffffc02015fc <page_insert+0x66>
ffffffffc02015c6:	000ab797          	auipc	a5,0xab
ffffffffc02015ca:	ea278793          	addi	a5,a5,-350 # ffffffffc02ac468 <pages>
ffffffffc02015ce:	6398                	ld	a4,0(a5)
    return page - pages + nbase;
ffffffffc02015d0:	8c19                	sub	s0,s0,a4
ffffffffc02015d2:	000806b7          	lui	a3,0x80
ffffffffc02015d6:	8419                	srai	s0,s0,0x6
ffffffffc02015d8:	9436                	add	s0,s0,a3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02015da:	042a                	slli	s0,s0,0xa
ffffffffc02015dc:	8c45                	or	s0,s0,s1
ffffffffc02015de:	00146413          	ori	s0,s0,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02015e2:	00893023          	sd	s0,0(s2)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02015e6:	12098073          	sfence.vma	s3
    return 0;
ffffffffc02015ea:	4501                	li	a0,0
}
ffffffffc02015ec:	70a2                	ld	ra,40(sp)
ffffffffc02015ee:	7402                	ld	s0,32(sp)
ffffffffc02015f0:	64e2                	ld	s1,24(sp)
ffffffffc02015f2:	6942                	ld	s2,16(sp)
ffffffffc02015f4:	69a2                	ld	s3,8(sp)
ffffffffc02015f6:	6a02                	ld	s4,0(sp)
ffffffffc02015f8:	6145                	addi	sp,sp,48
ffffffffc02015fa:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc02015fc:	000ab717          	auipc	a4,0xab
ffffffffc0201600:	e0470713          	addi	a4,a4,-508 # ffffffffc02ac400 <npage>
ffffffffc0201604:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201606:	078a                	slli	a5,a5,0x2
ffffffffc0201608:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020160a:	04e7f363          	bleu	a4,a5,ffffffffc0201650 <page_insert+0xba>
    return &pages[PPN(pa) - nbase];
ffffffffc020160e:	000aba17          	auipc	s4,0xab
ffffffffc0201612:	e5aa0a13          	addi	s4,s4,-422 # ffffffffc02ac468 <pages>
ffffffffc0201616:	000a3703          	ld	a4,0(s4)
ffffffffc020161a:	fff80537          	lui	a0,0xfff80
ffffffffc020161e:	953e                	add	a0,a0,a5
ffffffffc0201620:	051a                	slli	a0,a0,0x6
ffffffffc0201622:	953a                	add	a0,a0,a4
        if (p == page) {
ffffffffc0201624:	00a40a63          	beq	s0,a0,ffffffffc0201638 <page_insert+0xa2>
    page->ref -= 1;
ffffffffc0201628:	411c                	lw	a5,0(a0)
ffffffffc020162a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020162e:	c114                	sw	a3,0(a0)
        if (page_ref(page) ==
ffffffffc0201630:	c691                	beqz	a3,ffffffffc020163c <page_insert+0xa6>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201632:	12098073          	sfence.vma	s3
ffffffffc0201636:	bf69                	j	ffffffffc02015d0 <page_insert+0x3a>
ffffffffc0201638:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020163a:	bf59                	j	ffffffffc02015d0 <page_insert+0x3a>
            free_page(page);
ffffffffc020163c:	4585                	li	a1,1
ffffffffc020163e:	8bdff0ef          	jal	ra,ffffffffc0200efa <free_pages>
ffffffffc0201642:	000a3703          	ld	a4,0(s4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201646:	12098073          	sfence.vma	s3
ffffffffc020164a:	b759                	j	ffffffffc02015d0 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020164c:	5571                	li	a0,-4
ffffffffc020164e:	bf79                	j	ffffffffc02015ec <page_insert+0x56>
ffffffffc0201650:	807ff0ef          	jal	ra,ffffffffc0200e56 <pa2page.part.4>

ffffffffc0201654 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201654:	00007797          	auipc	a5,0x7
ffffffffc0201658:	cfc78793          	addi	a5,a5,-772 # ffffffffc0208350 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020165c:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc020165e:	715d                	addi	sp,sp,-80
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201660:	00006517          	auipc	a0,0x6
ffffffffc0201664:	a3850513          	addi	a0,a0,-1480 # ffffffffc0207098 <commands+0x8e8>
void pmm_init(void) {
ffffffffc0201668:	e486                	sd	ra,72(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020166a:	000ab717          	auipc	a4,0xab
ffffffffc020166e:	def73323          	sd	a5,-538(a4) # ffffffffc02ac450 <pmm_manager>
void pmm_init(void) {
ffffffffc0201672:	e0a2                	sd	s0,64(sp)
ffffffffc0201674:	fc26                	sd	s1,56(sp)
ffffffffc0201676:	f84a                	sd	s2,48(sp)
ffffffffc0201678:	f44e                	sd	s3,40(sp)
ffffffffc020167a:	f052                	sd	s4,32(sp)
ffffffffc020167c:	ec56                	sd	s5,24(sp)
ffffffffc020167e:	e85a                	sd	s6,16(sp)
ffffffffc0201680:	e45e                	sd	s7,8(sp)
ffffffffc0201682:	e062                	sd	s8,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201684:	000ab417          	auipc	s0,0xab
ffffffffc0201688:	dcc40413          	addi	s0,s0,-564 # ffffffffc02ac450 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020168c:	a45fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    pmm_manager->init();
ffffffffc0201690:	601c                	ld	a5,0(s0)
ffffffffc0201692:	000ab497          	auipc	s1,0xab
ffffffffc0201696:	d6e48493          	addi	s1,s1,-658 # ffffffffc02ac400 <npage>
ffffffffc020169a:	000ab917          	auipc	s2,0xab
ffffffffc020169e:	dce90913          	addi	s2,s2,-562 # ffffffffc02ac468 <pages>
ffffffffc02016a2:	679c                	ld	a5,8(a5)
ffffffffc02016a4:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02016a6:	57f5                	li	a5,-3
ffffffffc02016a8:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02016aa:	00006517          	auipc	a0,0x6
ffffffffc02016ae:	a0650513          	addi	a0,a0,-1530 # ffffffffc02070b0 <commands+0x900>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02016b2:	000ab717          	auipc	a4,0xab
ffffffffc02016b6:	daf73323          	sd	a5,-602(a4) # ffffffffc02ac458 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc02016ba:	a17fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02016be:	46c5                	li	a3,17
ffffffffc02016c0:	06ee                	slli	a3,a3,0x1b
ffffffffc02016c2:	40100613          	li	a2,1025
ffffffffc02016c6:	16fd                	addi	a3,a3,-1
ffffffffc02016c8:	0656                	slli	a2,a2,0x15
ffffffffc02016ca:	07e005b7          	lui	a1,0x7e00
ffffffffc02016ce:	00006517          	auipc	a0,0x6
ffffffffc02016d2:	9fa50513          	addi	a0,a0,-1542 # ffffffffc02070c8 <commands+0x918>
ffffffffc02016d6:	9fbfe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02016da:	777d                	lui	a4,0xfffff
ffffffffc02016dc:	000ac797          	auipc	a5,0xac
ffffffffc02016e0:	e9b78793          	addi	a5,a5,-357 # ffffffffc02ad577 <end+0xfff>
ffffffffc02016e4:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02016e6:	00088737          	lui	a4,0x88
ffffffffc02016ea:	000ab697          	auipc	a3,0xab
ffffffffc02016ee:	d0e6bb23          	sd	a4,-746(a3) # ffffffffc02ac400 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02016f2:	000ab717          	auipc	a4,0xab
ffffffffc02016f6:	d6f73b23          	sd	a5,-650(a4) # ffffffffc02ac468 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02016fa:	4701                	li	a4,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016fc:	4685                	li	a3,1
ffffffffc02016fe:	fff80837          	lui	a6,0xfff80
ffffffffc0201702:	a019                	j	ffffffffc0201708 <pmm_init+0xb4>
ffffffffc0201704:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc0201708:	00671613          	slli	a2,a4,0x6
ffffffffc020170c:	97b2                	add	a5,a5,a2
ffffffffc020170e:	07a1                	addi	a5,a5,8
ffffffffc0201710:	40d7b02f          	amoor.d	zero,a3,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201714:	6090                	ld	a2,0(s1)
ffffffffc0201716:	0705                	addi	a4,a4,1
ffffffffc0201718:	010607b3          	add	a5,a2,a6
ffffffffc020171c:	fef764e3          	bltu	a4,a5,ffffffffc0201704 <pmm_init+0xb0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201720:	00093503          	ld	a0,0(s2)
ffffffffc0201724:	fe0007b7          	lui	a5,0xfe000
ffffffffc0201728:	00661693          	slli	a3,a2,0x6
ffffffffc020172c:	97aa                	add	a5,a5,a0
ffffffffc020172e:	96be                	add	a3,a3,a5
ffffffffc0201730:	c02007b7          	lui	a5,0xc0200
ffffffffc0201734:	7af6ed63          	bltu	a3,a5,ffffffffc0201eee <pmm_init+0x89a>
ffffffffc0201738:	000ab997          	auipc	s3,0xab
ffffffffc020173c:	d2098993          	addi	s3,s3,-736 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0201740:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0201744:	47c5                	li	a5,17
ffffffffc0201746:	07ee                	slli	a5,a5,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201748:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc020174a:	02f6f763          	bleu	a5,a3,ffffffffc0201778 <pmm_init+0x124>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020174e:	6585                	lui	a1,0x1
ffffffffc0201750:	15fd                	addi	a1,a1,-1
ffffffffc0201752:	96ae                	add	a3,a3,a1
    if (PPN(pa) >= npage) {
ffffffffc0201754:	00c6d713          	srli	a4,a3,0xc
ffffffffc0201758:	48c77a63          	bleu	a2,a4,ffffffffc0201bec <pmm_init+0x598>
    pmm_manager->init_memmap(base, n);
ffffffffc020175c:	6010                	ld	a2,0(s0)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020175e:	75fd                	lui	a1,0xfffff
ffffffffc0201760:	8eed                	and	a3,a3,a1
    return &pages[PPN(pa) - nbase];
ffffffffc0201762:	9742                	add	a4,a4,a6
    pmm_manager->init_memmap(base, n);
ffffffffc0201764:	6a10                	ld	a2,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201766:	40d786b3          	sub	a3,a5,a3
ffffffffc020176a:	071a                	slli	a4,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc020176c:	00c6d593          	srli	a1,a3,0xc
ffffffffc0201770:	953a                	add	a0,a0,a4
ffffffffc0201772:	9602                	jalr	a2
ffffffffc0201774:	0009b583          	ld	a1,0(s3)
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0201778:	00006517          	auipc	a0,0x6
ffffffffc020177c:	9a050513          	addi	a0,a0,-1632 # ffffffffc0207118 <commands+0x968>
ffffffffc0201780:	951fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201784:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201786:	000ab417          	auipc	s0,0xab
ffffffffc020178a:	c7240413          	addi	s0,s0,-910 # ffffffffc02ac3f8 <boot_pgdir>
    pmm_manager->check();
ffffffffc020178e:	7b9c                	ld	a5,48(a5)
ffffffffc0201790:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201792:	00006517          	auipc	a0,0x6
ffffffffc0201796:	99e50513          	addi	a0,a0,-1634 # ffffffffc0207130 <commands+0x980>
ffffffffc020179a:	937fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc020179e:	0000a697          	auipc	a3,0xa
ffffffffc02017a2:	86268693          	addi	a3,a3,-1950 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc02017a6:	000ab797          	auipc	a5,0xab
ffffffffc02017aa:	c4d7b923          	sd	a3,-942(a5) # ffffffffc02ac3f8 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02017ae:	c02007b7          	lui	a5,0xc0200
ffffffffc02017b2:	10f6eae3          	bltu	a3,a5,ffffffffc02020c6 <pmm_init+0xa72>
ffffffffc02017b6:	0009b783          	ld	a5,0(s3)
ffffffffc02017ba:	8e9d                	sub	a3,a3,a5
ffffffffc02017bc:	000ab797          	auipc	a5,0xab
ffffffffc02017c0:	cad7b223          	sd	a3,-860(a5) # ffffffffc02ac460 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();
ffffffffc02017c4:	f7cff0ef          	jal	ra,ffffffffc0200f40 <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02017c8:	6098                	ld	a4,0(s1)
ffffffffc02017ca:	c80007b7          	lui	a5,0xc8000
ffffffffc02017ce:	83b1                	srli	a5,a5,0xc
    nr_free_store=nr_free_pages();
ffffffffc02017d0:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02017d2:	0ce7eae3          	bltu	a5,a4,ffffffffc02020a6 <pmm_init+0xa52>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02017d6:	6008                	ld	a0,0(s0)
ffffffffc02017d8:	44050463          	beqz	a0,ffffffffc0201c20 <pmm_init+0x5cc>
ffffffffc02017dc:	6785                	lui	a5,0x1
ffffffffc02017de:	17fd                	addi	a5,a5,-1
ffffffffc02017e0:	8fe9                	and	a5,a5,a0
ffffffffc02017e2:	2781                	sext.w	a5,a5
ffffffffc02017e4:	42079e63          	bnez	a5,ffffffffc0201c20 <pmm_init+0x5cc>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02017e8:	4601                	li	a2,0
ffffffffc02017ea:	4581                	li	a1,0
ffffffffc02017ec:	967ff0ef          	jal	ra,ffffffffc0201152 <get_page>
ffffffffc02017f0:	78051b63          	bnez	a0,ffffffffc0201f86 <pmm_init+0x932>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc02017f4:	4505                	li	a0,1
ffffffffc02017f6:	e7cff0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc02017fa:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02017fc:	6008                	ld	a0,0(s0)
ffffffffc02017fe:	4681                	li	a3,0
ffffffffc0201800:	4601                	li	a2,0
ffffffffc0201802:	85d6                	mv	a1,s5
ffffffffc0201804:	d93ff0ef          	jal	ra,ffffffffc0201596 <page_insert>
ffffffffc0201808:	7a051f63          	bnez	a0,ffffffffc0201fc6 <pmm_init+0x972>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc020180c:	6008                	ld	a0,0(s0)
ffffffffc020180e:	4601                	li	a2,0
ffffffffc0201810:	4581                	li	a1,0
ffffffffc0201812:	f6eff0ef          	jal	ra,ffffffffc0200f80 <get_pte>
ffffffffc0201816:	78050863          	beqz	a0,ffffffffc0201fa6 <pmm_init+0x952>
    assert(pte2page(*ptep) == p1);
ffffffffc020181a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020181c:	0017f713          	andi	a4,a5,1
ffffffffc0201820:	3e070463          	beqz	a4,ffffffffc0201c08 <pmm_init+0x5b4>
    if (PPN(pa) >= npage) {
ffffffffc0201824:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201826:	078a                	slli	a5,a5,0x2
ffffffffc0201828:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020182a:	3ce7f163          	bleu	a4,a5,ffffffffc0201bec <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc020182e:	00093683          	ld	a3,0(s2)
ffffffffc0201832:	fff80637          	lui	a2,0xfff80
ffffffffc0201836:	97b2                	add	a5,a5,a2
ffffffffc0201838:	079a                	slli	a5,a5,0x6
ffffffffc020183a:	97b6                	add	a5,a5,a3
ffffffffc020183c:	72fa9563          	bne	s5,a5,ffffffffc0201f66 <pmm_init+0x912>
    assert(page_ref(p1) == 1);
ffffffffc0201840:	000aab83          	lw	s7,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
ffffffffc0201844:	4785                	li	a5,1
ffffffffc0201846:	70fb9063          	bne	s7,a5,ffffffffc0201f46 <pmm_init+0x8f2>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020184a:	6008                	ld	a0,0(s0)
ffffffffc020184c:	76fd                	lui	a3,0xfffff
ffffffffc020184e:	611c                	ld	a5,0(a0)
ffffffffc0201850:	078a                	slli	a5,a5,0x2
ffffffffc0201852:	8ff5                	and	a5,a5,a3
ffffffffc0201854:	00c7d613          	srli	a2,a5,0xc
ffffffffc0201858:	66e67e63          	bleu	a4,a2,ffffffffc0201ed4 <pmm_init+0x880>
ffffffffc020185c:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201860:	97e2                	add	a5,a5,s8
ffffffffc0201862:	0007bb03          	ld	s6,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
ffffffffc0201866:	0b0a                	slli	s6,s6,0x2
ffffffffc0201868:	00db7b33          	and	s6,s6,a3
ffffffffc020186c:	00cb5793          	srli	a5,s6,0xc
ffffffffc0201870:	56e7f863          	bleu	a4,a5,ffffffffc0201de0 <pmm_init+0x78c>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201874:	4601                	li	a2,0
ffffffffc0201876:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201878:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020187a:	f06ff0ef          	jal	ra,ffffffffc0200f80 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020187e:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201880:	55651063          	bne	a0,s6,ffffffffc0201dc0 <pmm_init+0x76c>

    p2 = alloc_page();
ffffffffc0201884:	4505                	li	a0,1
ffffffffc0201886:	decff0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc020188a:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020188c:	6008                	ld	a0,0(s0)
ffffffffc020188e:	46d1                	li	a3,20
ffffffffc0201890:	6605                	lui	a2,0x1
ffffffffc0201892:	85da                	mv	a1,s6
ffffffffc0201894:	d03ff0ef          	jal	ra,ffffffffc0201596 <page_insert>
ffffffffc0201898:	50051463          	bnez	a0,ffffffffc0201da0 <pmm_init+0x74c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020189c:	6008                	ld	a0,0(s0)
ffffffffc020189e:	4601                	li	a2,0
ffffffffc02018a0:	6585                	lui	a1,0x1
ffffffffc02018a2:	edeff0ef          	jal	ra,ffffffffc0200f80 <get_pte>
ffffffffc02018a6:	4c050d63          	beqz	a0,ffffffffc0201d80 <pmm_init+0x72c>
    assert(*ptep & PTE_U);
ffffffffc02018aa:	611c                	ld	a5,0(a0)
ffffffffc02018ac:	0107f713          	andi	a4,a5,16
ffffffffc02018b0:	4a070863          	beqz	a4,ffffffffc0201d60 <pmm_init+0x70c>
    assert(*ptep & PTE_W);
ffffffffc02018b4:	8b91                	andi	a5,a5,4
ffffffffc02018b6:	48078563          	beqz	a5,ffffffffc0201d40 <pmm_init+0x6ec>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02018ba:	6008                	ld	a0,0(s0)
ffffffffc02018bc:	611c                	ld	a5,0(a0)
ffffffffc02018be:	8bc1                	andi	a5,a5,16
ffffffffc02018c0:	46078063          	beqz	a5,ffffffffc0201d20 <pmm_init+0x6cc>
    assert(page_ref(p2) == 1);
ffffffffc02018c4:	000b2783          	lw	a5,0(s6) # 200000 <_binary_obj___user_exit_out_size+0x1f5588>
ffffffffc02018c8:	43779c63          	bne	a5,s7,ffffffffc0201d00 <pmm_init+0x6ac>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02018cc:	4681                	li	a3,0
ffffffffc02018ce:	6605                	lui	a2,0x1
ffffffffc02018d0:	85d6                	mv	a1,s5
ffffffffc02018d2:	cc5ff0ef          	jal	ra,ffffffffc0201596 <page_insert>
ffffffffc02018d6:	40051563          	bnez	a0,ffffffffc0201ce0 <pmm_init+0x68c>
    assert(page_ref(p1) == 2);
ffffffffc02018da:	000aa703          	lw	a4,0(s5)
ffffffffc02018de:	4789                	li	a5,2
ffffffffc02018e0:	3ef71063          	bne	a4,a5,ffffffffc0201cc0 <pmm_init+0x66c>
    assert(page_ref(p2) == 0);
ffffffffc02018e4:	000b2783          	lw	a5,0(s6)
ffffffffc02018e8:	3a079c63          	bnez	a5,ffffffffc0201ca0 <pmm_init+0x64c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02018ec:	6008                	ld	a0,0(s0)
ffffffffc02018ee:	4601                	li	a2,0
ffffffffc02018f0:	6585                	lui	a1,0x1
ffffffffc02018f2:	e8eff0ef          	jal	ra,ffffffffc0200f80 <get_pte>
ffffffffc02018f6:	38050563          	beqz	a0,ffffffffc0201c80 <pmm_init+0x62c>
    assert(pte2page(*ptep) == p1);
ffffffffc02018fa:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02018fc:	00177793          	andi	a5,a4,1
ffffffffc0201900:	30078463          	beqz	a5,ffffffffc0201c08 <pmm_init+0x5b4>
    if (PPN(pa) >= npage) {
ffffffffc0201904:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201906:	00271793          	slli	a5,a4,0x2
ffffffffc020190a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020190c:	2ed7f063          	bleu	a3,a5,ffffffffc0201bec <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0201910:	00093683          	ld	a3,0(s2)
ffffffffc0201914:	fff80637          	lui	a2,0xfff80
ffffffffc0201918:	97b2                	add	a5,a5,a2
ffffffffc020191a:	079a                	slli	a5,a5,0x6
ffffffffc020191c:	97b6                	add	a5,a5,a3
ffffffffc020191e:	32fa9163          	bne	s5,a5,ffffffffc0201c40 <pmm_init+0x5ec>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201922:	8b41                	andi	a4,a4,16
ffffffffc0201924:	70071163          	bnez	a4,ffffffffc0202026 <pmm_init+0x9d2>

    page_remove(boot_pgdir, 0x0);
ffffffffc0201928:	6008                	ld	a0,0(s0)
ffffffffc020192a:	4581                	li	a1,0
ffffffffc020192c:	bf7ff0ef          	jal	ra,ffffffffc0201522 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201930:	000aa703          	lw	a4,0(s5)
ffffffffc0201934:	4785                	li	a5,1
ffffffffc0201936:	6cf71863          	bne	a4,a5,ffffffffc0202006 <pmm_init+0x9b2>
    assert(page_ref(p2) == 0);
ffffffffc020193a:	000b2783          	lw	a5,0(s6)
ffffffffc020193e:	6a079463          	bnez	a5,ffffffffc0201fe6 <pmm_init+0x992>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0201942:	6008                	ld	a0,0(s0)
ffffffffc0201944:	6585                	lui	a1,0x1
ffffffffc0201946:	bddff0ef          	jal	ra,ffffffffc0201522 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc020194a:	000aa783          	lw	a5,0(s5)
ffffffffc020194e:	50079363          	bnez	a5,ffffffffc0201e54 <pmm_init+0x800>
    assert(page_ref(p2) == 0);
ffffffffc0201952:	000b2783          	lw	a5,0(s6)
ffffffffc0201956:	4c079f63          	bnez	a5,ffffffffc0201e34 <pmm_init+0x7e0>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020195a:	00043a83          	ld	s5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc020195e:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201960:	000ab783          	ld	a5,0(s5)
ffffffffc0201964:	078a                	slli	a5,a5,0x2
ffffffffc0201966:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201968:	28c7f263          	bleu	a2,a5,ffffffffc0201bec <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc020196c:	fff80737          	lui	a4,0xfff80
ffffffffc0201970:	00093503          	ld	a0,0(s2)
ffffffffc0201974:	97ba                	add	a5,a5,a4
ffffffffc0201976:	079a                	slli	a5,a5,0x6
ffffffffc0201978:	00f50733          	add	a4,a0,a5
ffffffffc020197c:	4314                	lw	a3,0(a4)
ffffffffc020197e:	4705                	li	a4,1
ffffffffc0201980:	48e69a63          	bne	a3,a4,ffffffffc0201e14 <pmm_init+0x7c0>
    return page - pages + nbase;
ffffffffc0201984:	8799                	srai	a5,a5,0x6
ffffffffc0201986:	00080b37          	lui	s6,0x80
    return KADDR(page2pa(page));
ffffffffc020198a:	577d                	li	a4,-1
    return page - pages + nbase;
ffffffffc020198c:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc020198e:	8331                	srli	a4,a4,0xc
ffffffffc0201990:	8f7d                	and	a4,a4,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201992:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0201994:	46c77363          	bleu	a2,a4,ffffffffc0201dfa <pmm_init+0x7a6>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201998:	0009b683          	ld	a3,0(s3)
ffffffffc020199c:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc020199e:	639c                	ld	a5,0(a5)
ffffffffc02019a0:	078a                	slli	a5,a5,0x2
ffffffffc02019a2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02019a4:	24c7f463          	bleu	a2,a5,ffffffffc0201bec <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc02019a8:	416787b3          	sub	a5,a5,s6
ffffffffc02019ac:	079a                	slli	a5,a5,0x6
ffffffffc02019ae:	953e                	add	a0,a0,a5
ffffffffc02019b0:	4585                	li	a1,1
ffffffffc02019b2:	d48ff0ef          	jal	ra,ffffffffc0200efa <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02019b6:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage) {
ffffffffc02019ba:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02019bc:	078a                	slli	a5,a5,0x2
ffffffffc02019be:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02019c0:	22e7f663          	bleu	a4,a5,ffffffffc0201bec <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc02019c4:	00093503          	ld	a0,0(s2)
ffffffffc02019c8:	416787b3          	sub	a5,a5,s6
ffffffffc02019cc:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc02019ce:	953e                	add	a0,a0,a5
ffffffffc02019d0:	4585                	li	a1,1
ffffffffc02019d2:	d28ff0ef          	jal	ra,ffffffffc0200efa <free_pages>
    boot_pgdir[0] = 0;
ffffffffc02019d6:	601c                	ld	a5,0(s0)
ffffffffc02019d8:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc02019dc:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc02019e0:	d60ff0ef          	jal	ra,ffffffffc0200f40 <nr_free_pages>
ffffffffc02019e4:	68aa1163          	bne	s4,a0,ffffffffc0202066 <pmm_init+0xa12>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02019e8:	00006517          	auipc	a0,0x6
ffffffffc02019ec:	a5850513          	addi	a0,a0,-1448 # ffffffffc0207440 <commands+0xc90>
ffffffffc02019f0:	ee0fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();
ffffffffc02019f4:	d4cff0ef          	jal	ra,ffffffffc0200f40 <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02019f8:	6098                	ld	a4,0(s1)
ffffffffc02019fa:	c02007b7          	lui	a5,0xc0200
    nr_free_store=nr_free_pages();
ffffffffc02019fe:	8a2a                	mv	s4,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201a00:	00c71693          	slli	a3,a4,0xc
ffffffffc0201a04:	18d7f563          	bleu	a3,a5,ffffffffc0201b8e <pmm_init+0x53a>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201a08:	83b1                	srli	a5,a5,0xc
ffffffffc0201a0a:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201a0c:	c0200ab7          	lui	s5,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201a10:	1ae7f163          	bleu	a4,a5,ffffffffc0201bb2 <pmm_init+0x55e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201a14:	7bfd                	lui	s7,0xfffff
ffffffffc0201a16:	6b05                	lui	s6,0x1
ffffffffc0201a18:	a029                	j	ffffffffc0201a22 <pmm_init+0x3ce>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201a1a:	00cad713          	srli	a4,s5,0xc
ffffffffc0201a1e:	18f77a63          	bleu	a5,a4,ffffffffc0201bb2 <pmm_init+0x55e>
ffffffffc0201a22:	0009b583          	ld	a1,0(s3)
ffffffffc0201a26:	4601                	li	a2,0
ffffffffc0201a28:	95d6                	add	a1,a1,s5
ffffffffc0201a2a:	d56ff0ef          	jal	ra,ffffffffc0200f80 <get_pte>
ffffffffc0201a2e:	16050263          	beqz	a0,ffffffffc0201b92 <pmm_init+0x53e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201a32:	611c                	ld	a5,0(a0)
ffffffffc0201a34:	078a                	slli	a5,a5,0x2
ffffffffc0201a36:	0177f7b3          	and	a5,a5,s7
ffffffffc0201a3a:	19579963          	bne	a5,s5,ffffffffc0201bcc <pmm_init+0x578>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201a3e:	609c                	ld	a5,0(s1)
ffffffffc0201a40:	9ada                	add	s5,s5,s6
ffffffffc0201a42:	6008                	ld	a0,0(s0)
ffffffffc0201a44:	00c79713          	slli	a4,a5,0xc
ffffffffc0201a48:	fceae9e3          	bltu	s5,a4,ffffffffc0201a1a <pmm_init+0x3c6>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc0201a4c:	611c                	ld	a5,0(a0)
ffffffffc0201a4e:	62079c63          	bnez	a5,ffffffffc0202086 <pmm_init+0xa32>

    struct Page *p;
    p = alloc_page();
ffffffffc0201a52:	4505                	li	a0,1
ffffffffc0201a54:	c1eff0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0201a58:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201a5a:	6008                	ld	a0,0(s0)
ffffffffc0201a5c:	4699                	li	a3,6
ffffffffc0201a5e:	10000613          	li	a2,256
ffffffffc0201a62:	85d6                	mv	a1,s5
ffffffffc0201a64:	b33ff0ef          	jal	ra,ffffffffc0201596 <page_insert>
ffffffffc0201a68:	1e051c63          	bnez	a0,ffffffffc0201c60 <pmm_init+0x60c>
    assert(page_ref(p) == 1);
ffffffffc0201a6c:	000aa703          	lw	a4,0(s5) # ffffffffc0200000 <kern_entry>
ffffffffc0201a70:	4785                	li	a5,1
ffffffffc0201a72:	44f71163          	bne	a4,a5,ffffffffc0201eb4 <pmm_init+0x860>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201a76:	6008                	ld	a0,0(s0)
ffffffffc0201a78:	6b05                	lui	s6,0x1
ffffffffc0201a7a:	4699                	li	a3,6
ffffffffc0201a7c:	100b0613          	addi	a2,s6,256 # 1100 <_binary_obj___user_faultread_out_size-0x8470>
ffffffffc0201a80:	85d6                	mv	a1,s5
ffffffffc0201a82:	b15ff0ef          	jal	ra,ffffffffc0201596 <page_insert>
ffffffffc0201a86:	40051763          	bnez	a0,ffffffffc0201e94 <pmm_init+0x840>
    assert(page_ref(p) == 2);
ffffffffc0201a8a:	000aa703          	lw	a4,0(s5)
ffffffffc0201a8e:	4789                	li	a5,2
ffffffffc0201a90:	3ef71263          	bne	a4,a5,ffffffffc0201e74 <pmm_init+0x820>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0201a94:	00006597          	auipc	a1,0x6
ffffffffc0201a98:	ae458593          	addi	a1,a1,-1308 # ffffffffc0207578 <commands+0xdc8>
ffffffffc0201a9c:	10000513          	li	a0,256
ffffffffc0201aa0:	70a040ef          	jal	ra,ffffffffc02061aa <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201aa4:	100b0593          	addi	a1,s6,256
ffffffffc0201aa8:	10000513          	li	a0,256
ffffffffc0201aac:	710040ef          	jal	ra,ffffffffc02061bc <strcmp>
ffffffffc0201ab0:	44051b63          	bnez	a0,ffffffffc0201f06 <pmm_init+0x8b2>
    return page - pages + nbase;
ffffffffc0201ab4:	00093683          	ld	a3,0(s2)
ffffffffc0201ab8:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0201abc:	5b7d                	li	s6,-1
    return page - pages + nbase;
ffffffffc0201abe:	40da86b3          	sub	a3,s5,a3
ffffffffc0201ac2:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0201ac4:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0201ac6:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0201ac8:	00cb5b13          	srli	s6,s6,0xc
ffffffffc0201acc:	0166f733          	and	a4,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ad0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201ad2:	10f77f63          	bleu	a5,a4,ffffffffc0201bf0 <pmm_init+0x59c>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201ad6:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201ada:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201ade:	96be                	add	a3,a3,a5
ffffffffc0201ae0:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fd52b88>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201ae4:	682040ef          	jal	ra,ffffffffc0206166 <strlen>
ffffffffc0201ae8:	54051f63          	bnez	a0,ffffffffc0202046 <pmm_init+0x9f2>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0201aec:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0201af0:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201af2:	000bb683          	ld	a3,0(s7) # fffffffffffff000 <end+0x3fd52a88>
ffffffffc0201af6:	068a                	slli	a3,a3,0x2
ffffffffc0201af8:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201afa:	0ef6f963          	bleu	a5,a3,ffffffffc0201bec <pmm_init+0x598>
    return KADDR(page2pa(page));
ffffffffc0201afe:	0166fb33          	and	s6,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b02:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201b04:	0efb7663          	bleu	a5,s6,ffffffffc0201bf0 <pmm_init+0x59c>
ffffffffc0201b08:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc0201b0c:	4585                	li	a1,1
ffffffffc0201b0e:	8556                	mv	a0,s5
ffffffffc0201b10:	99b6                	add	s3,s3,a3
ffffffffc0201b12:	be8ff0ef          	jal	ra,ffffffffc0200efa <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b16:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0201b1a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b1c:	078a                	slli	a5,a5,0x2
ffffffffc0201b1e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201b20:	0ce7f663          	bleu	a4,a5,ffffffffc0201bec <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b24:	00093503          	ld	a0,0(s2)
ffffffffc0201b28:	fff809b7          	lui	s3,0xfff80
ffffffffc0201b2c:	97ce                	add	a5,a5,s3
ffffffffc0201b2e:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0201b30:	953e                	add	a0,a0,a5
ffffffffc0201b32:	4585                	li	a1,1
ffffffffc0201b34:	bc6ff0ef          	jal	ra,ffffffffc0200efa <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b38:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc0201b3c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b3e:	078a                	slli	a5,a5,0x2
ffffffffc0201b40:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201b42:	0ae7f563          	bleu	a4,a5,ffffffffc0201bec <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b46:	00093503          	ld	a0,0(s2)
ffffffffc0201b4a:	97ce                	add	a5,a5,s3
ffffffffc0201b4c:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0201b4e:	953e                	add	a0,a0,a5
ffffffffc0201b50:	4585                	li	a1,1
ffffffffc0201b52:	ba8ff0ef          	jal	ra,ffffffffc0200efa <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0201b56:	601c                	ld	a5,0(s0)
ffffffffc0201b58:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>
  asm volatile("sfence.vma");
ffffffffc0201b5c:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0201b60:	be0ff0ef          	jal	ra,ffffffffc0200f40 <nr_free_pages>
ffffffffc0201b64:	3caa1163          	bne	s4,a0,ffffffffc0201f26 <pmm_init+0x8d2>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0201b68:	00006517          	auipc	a0,0x6
ffffffffc0201b6c:	a8850513          	addi	a0,a0,-1400 # ffffffffc02075f0 <commands+0xe40>
ffffffffc0201b70:	d60fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
}
ffffffffc0201b74:	6406                	ld	s0,64(sp)
ffffffffc0201b76:	60a6                	ld	ra,72(sp)
ffffffffc0201b78:	74e2                	ld	s1,56(sp)
ffffffffc0201b7a:	7942                	ld	s2,48(sp)
ffffffffc0201b7c:	79a2                	ld	s3,40(sp)
ffffffffc0201b7e:	7a02                	ld	s4,32(sp)
ffffffffc0201b80:	6ae2                	ld	s5,24(sp)
ffffffffc0201b82:	6b42                	ld	s6,16(sp)
ffffffffc0201b84:	6ba2                	ld	s7,8(sp)
ffffffffc0201b86:	6c02                	ld	s8,0(sp)
ffffffffc0201b88:	6161                	addi	sp,sp,80
    kmalloc_init();
ffffffffc0201b8a:	1190106f          	j	ffffffffc02034a2 <kmalloc_init>
ffffffffc0201b8e:	6008                	ld	a0,0(s0)
ffffffffc0201b90:	bd75                	j	ffffffffc0201a4c <pmm_init+0x3f8>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201b92:	00006697          	auipc	a3,0x6
ffffffffc0201b96:	8ce68693          	addi	a3,a3,-1842 # ffffffffc0207460 <commands+0xcb0>
ffffffffc0201b9a:	00005617          	auipc	a2,0x5
ffffffffc0201b9e:	09660613          	addi	a2,a2,150 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201ba2:	24b00593          	li	a1,587
ffffffffc0201ba6:	00005517          	auipc	a0,0x5
ffffffffc0201baa:	49a50513          	addi	a0,a0,1178 # ffffffffc0207040 <commands+0x890>
ffffffffc0201bae:	e68fe0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0201bb2:	86d6                	mv	a3,s5
ffffffffc0201bb4:	00005617          	auipc	a2,0x5
ffffffffc0201bb8:	46460613          	addi	a2,a2,1124 # ffffffffc0207018 <commands+0x868>
ffffffffc0201bbc:	24b00593          	li	a1,587
ffffffffc0201bc0:	00005517          	auipc	a0,0x5
ffffffffc0201bc4:	48050513          	addi	a0,a0,1152 # ffffffffc0207040 <commands+0x890>
ffffffffc0201bc8:	e4efe0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201bcc:	00006697          	auipc	a3,0x6
ffffffffc0201bd0:	8d468693          	addi	a3,a3,-1836 # ffffffffc02074a0 <commands+0xcf0>
ffffffffc0201bd4:	00005617          	auipc	a2,0x5
ffffffffc0201bd8:	05c60613          	addi	a2,a2,92 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201bdc:	24c00593          	li	a1,588
ffffffffc0201be0:	00005517          	auipc	a0,0x5
ffffffffc0201be4:	46050513          	addi	a0,a0,1120 # ffffffffc0207040 <commands+0x890>
ffffffffc0201be8:	e2efe0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0201bec:	a6aff0ef          	jal	ra,ffffffffc0200e56 <pa2page.part.4>
    return KADDR(page2pa(page));
ffffffffc0201bf0:	00005617          	auipc	a2,0x5
ffffffffc0201bf4:	42860613          	addi	a2,a2,1064 # ffffffffc0207018 <commands+0x868>
ffffffffc0201bf8:	06900593          	li	a1,105
ffffffffc0201bfc:	00005517          	auipc	a0,0x5
ffffffffc0201c00:	47450513          	addi	a0,a0,1140 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0201c04:	e12fe0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0201c08:	00005617          	auipc	a2,0x5
ffffffffc0201c0c:	62860613          	addi	a2,a2,1576 # ffffffffc0207230 <commands+0xa80>
ffffffffc0201c10:	07400593          	li	a1,116
ffffffffc0201c14:	00005517          	auipc	a0,0x5
ffffffffc0201c18:	45c50513          	addi	a0,a0,1116 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0201c1c:	dfafe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201c20:	00005697          	auipc	a3,0x5
ffffffffc0201c24:	55068693          	addi	a3,a3,1360 # ffffffffc0207170 <commands+0x9c0>
ffffffffc0201c28:	00005617          	auipc	a2,0x5
ffffffffc0201c2c:	00860613          	addi	a2,a2,8 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201c30:	20f00593          	li	a1,527
ffffffffc0201c34:	00005517          	auipc	a0,0x5
ffffffffc0201c38:	40c50513          	addi	a0,a0,1036 # ffffffffc0207040 <commands+0x890>
ffffffffc0201c3c:	ddafe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201c40:	00005697          	auipc	a3,0x5
ffffffffc0201c44:	61868693          	addi	a3,a3,1560 # ffffffffc0207258 <commands+0xaa8>
ffffffffc0201c48:	00005617          	auipc	a2,0x5
ffffffffc0201c4c:	fe860613          	addi	a2,a2,-24 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201c50:	22b00593          	li	a1,555
ffffffffc0201c54:	00005517          	auipc	a0,0x5
ffffffffc0201c58:	3ec50513          	addi	a0,a0,1004 # ffffffffc0207040 <commands+0x890>
ffffffffc0201c5c:	dbafe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201c60:	00006697          	auipc	a3,0x6
ffffffffc0201c64:	87068693          	addi	a3,a3,-1936 # ffffffffc02074d0 <commands+0xd20>
ffffffffc0201c68:	00005617          	auipc	a2,0x5
ffffffffc0201c6c:	fc860613          	addi	a2,a2,-56 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201c70:	25400593          	li	a1,596
ffffffffc0201c74:	00005517          	auipc	a0,0x5
ffffffffc0201c78:	3cc50513          	addi	a0,a0,972 # ffffffffc0207040 <commands+0x890>
ffffffffc0201c7c:	d9afe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201c80:	00005697          	auipc	a3,0x5
ffffffffc0201c84:	66868693          	addi	a3,a3,1640 # ffffffffc02072e8 <commands+0xb38>
ffffffffc0201c88:	00005617          	auipc	a2,0x5
ffffffffc0201c8c:	fa860613          	addi	a2,a2,-88 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201c90:	22a00593          	li	a1,554
ffffffffc0201c94:	00005517          	auipc	a0,0x5
ffffffffc0201c98:	3ac50513          	addi	a0,a0,940 # ffffffffc0207040 <commands+0x890>
ffffffffc0201c9c:	d7afe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201ca0:	00005697          	auipc	a3,0x5
ffffffffc0201ca4:	71068693          	addi	a3,a3,1808 # ffffffffc02073b0 <commands+0xc00>
ffffffffc0201ca8:	00005617          	auipc	a2,0x5
ffffffffc0201cac:	f8860613          	addi	a2,a2,-120 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201cb0:	22900593          	li	a1,553
ffffffffc0201cb4:	00005517          	auipc	a0,0x5
ffffffffc0201cb8:	38c50513          	addi	a0,a0,908 # ffffffffc0207040 <commands+0x890>
ffffffffc0201cbc:	d5afe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0201cc0:	00005697          	auipc	a3,0x5
ffffffffc0201cc4:	6d868693          	addi	a3,a3,1752 # ffffffffc0207398 <commands+0xbe8>
ffffffffc0201cc8:	00005617          	auipc	a2,0x5
ffffffffc0201ccc:	f6860613          	addi	a2,a2,-152 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201cd0:	22800593          	li	a1,552
ffffffffc0201cd4:	00005517          	auipc	a0,0x5
ffffffffc0201cd8:	36c50513          	addi	a0,a0,876 # ffffffffc0207040 <commands+0x890>
ffffffffc0201cdc:	d3afe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201ce0:	00005697          	auipc	a3,0x5
ffffffffc0201ce4:	68868693          	addi	a3,a3,1672 # ffffffffc0207368 <commands+0xbb8>
ffffffffc0201ce8:	00005617          	auipc	a2,0x5
ffffffffc0201cec:	f4860613          	addi	a2,a2,-184 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201cf0:	22700593          	li	a1,551
ffffffffc0201cf4:	00005517          	auipc	a0,0x5
ffffffffc0201cf8:	34c50513          	addi	a0,a0,844 # ffffffffc0207040 <commands+0x890>
ffffffffc0201cfc:	d1afe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0201d00:	00005697          	auipc	a3,0x5
ffffffffc0201d04:	65068693          	addi	a3,a3,1616 # ffffffffc0207350 <commands+0xba0>
ffffffffc0201d08:	00005617          	auipc	a2,0x5
ffffffffc0201d0c:	f2860613          	addi	a2,a2,-216 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201d10:	22500593          	li	a1,549
ffffffffc0201d14:	00005517          	auipc	a0,0x5
ffffffffc0201d18:	32c50513          	addi	a0,a0,812 # ffffffffc0207040 <commands+0x890>
ffffffffc0201d1c:	cfafe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201d20:	00005697          	auipc	a3,0x5
ffffffffc0201d24:	61868693          	addi	a3,a3,1560 # ffffffffc0207338 <commands+0xb88>
ffffffffc0201d28:	00005617          	auipc	a2,0x5
ffffffffc0201d2c:	f0860613          	addi	a2,a2,-248 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201d30:	22400593          	li	a1,548
ffffffffc0201d34:	00005517          	auipc	a0,0x5
ffffffffc0201d38:	30c50513          	addi	a0,a0,780 # ffffffffc0207040 <commands+0x890>
ffffffffc0201d3c:	cdafe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0201d40:	00005697          	auipc	a3,0x5
ffffffffc0201d44:	5e868693          	addi	a3,a3,1512 # ffffffffc0207328 <commands+0xb78>
ffffffffc0201d48:	00005617          	auipc	a2,0x5
ffffffffc0201d4c:	ee860613          	addi	a2,a2,-280 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201d50:	22300593          	li	a1,547
ffffffffc0201d54:	00005517          	auipc	a0,0x5
ffffffffc0201d58:	2ec50513          	addi	a0,a0,748 # ffffffffc0207040 <commands+0x890>
ffffffffc0201d5c:	cbafe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0201d60:	00005697          	auipc	a3,0x5
ffffffffc0201d64:	5b868693          	addi	a3,a3,1464 # ffffffffc0207318 <commands+0xb68>
ffffffffc0201d68:	00005617          	auipc	a2,0x5
ffffffffc0201d6c:	ec860613          	addi	a2,a2,-312 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201d70:	22200593          	li	a1,546
ffffffffc0201d74:	00005517          	auipc	a0,0x5
ffffffffc0201d78:	2cc50513          	addi	a0,a0,716 # ffffffffc0207040 <commands+0x890>
ffffffffc0201d7c:	c9afe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201d80:	00005697          	auipc	a3,0x5
ffffffffc0201d84:	56868693          	addi	a3,a3,1384 # ffffffffc02072e8 <commands+0xb38>
ffffffffc0201d88:	00005617          	auipc	a2,0x5
ffffffffc0201d8c:	ea860613          	addi	a2,a2,-344 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201d90:	22100593          	li	a1,545
ffffffffc0201d94:	00005517          	auipc	a0,0x5
ffffffffc0201d98:	2ac50513          	addi	a0,a0,684 # ffffffffc0207040 <commands+0x890>
ffffffffc0201d9c:	c7afe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201da0:	00005697          	auipc	a3,0x5
ffffffffc0201da4:	51068693          	addi	a3,a3,1296 # ffffffffc02072b0 <commands+0xb00>
ffffffffc0201da8:	00005617          	auipc	a2,0x5
ffffffffc0201dac:	e8860613          	addi	a2,a2,-376 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201db0:	22000593          	li	a1,544
ffffffffc0201db4:	00005517          	auipc	a0,0x5
ffffffffc0201db8:	28c50513          	addi	a0,a0,652 # ffffffffc0207040 <commands+0x890>
ffffffffc0201dbc:	c5afe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201dc0:	00005697          	auipc	a3,0x5
ffffffffc0201dc4:	4c868693          	addi	a3,a3,1224 # ffffffffc0207288 <commands+0xad8>
ffffffffc0201dc8:	00005617          	auipc	a2,0x5
ffffffffc0201dcc:	e6860613          	addi	a2,a2,-408 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201dd0:	21d00593          	li	a1,541
ffffffffc0201dd4:	00005517          	auipc	a0,0x5
ffffffffc0201dd8:	26c50513          	addi	a0,a0,620 # ffffffffc0207040 <commands+0x890>
ffffffffc0201ddc:	c3afe0ef          	jal	ra,ffffffffc0200216 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201de0:	86da                	mv	a3,s6
ffffffffc0201de2:	00005617          	auipc	a2,0x5
ffffffffc0201de6:	23660613          	addi	a2,a2,566 # ffffffffc0207018 <commands+0x868>
ffffffffc0201dea:	21c00593          	li	a1,540
ffffffffc0201dee:	00005517          	auipc	a0,0x5
ffffffffc0201df2:	25250513          	addi	a0,a0,594 # ffffffffc0207040 <commands+0x890>
ffffffffc0201df6:	c20fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    return KADDR(page2pa(page));
ffffffffc0201dfa:	86be                	mv	a3,a5
ffffffffc0201dfc:	00005617          	auipc	a2,0x5
ffffffffc0201e00:	21c60613          	addi	a2,a2,540 # ffffffffc0207018 <commands+0x868>
ffffffffc0201e04:	06900593          	li	a1,105
ffffffffc0201e08:	00005517          	auipc	a0,0x5
ffffffffc0201e0c:	26850513          	addi	a0,a0,616 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0201e10:	c06fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201e14:	00005697          	auipc	a3,0x5
ffffffffc0201e18:	5e468693          	addi	a3,a3,1508 # ffffffffc02073f8 <commands+0xc48>
ffffffffc0201e1c:	00005617          	auipc	a2,0x5
ffffffffc0201e20:	e1460613          	addi	a2,a2,-492 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201e24:	23600593          	li	a1,566
ffffffffc0201e28:	00005517          	auipc	a0,0x5
ffffffffc0201e2c:	21850513          	addi	a0,a0,536 # ffffffffc0207040 <commands+0x890>
ffffffffc0201e30:	be6fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201e34:	00005697          	auipc	a3,0x5
ffffffffc0201e38:	57c68693          	addi	a3,a3,1404 # ffffffffc02073b0 <commands+0xc00>
ffffffffc0201e3c:	00005617          	auipc	a2,0x5
ffffffffc0201e40:	df460613          	addi	a2,a2,-524 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201e44:	23400593          	li	a1,564
ffffffffc0201e48:	00005517          	auipc	a0,0x5
ffffffffc0201e4c:	1f850513          	addi	a0,a0,504 # ffffffffc0207040 <commands+0x890>
ffffffffc0201e50:	bc6fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0201e54:	00005697          	auipc	a3,0x5
ffffffffc0201e58:	58c68693          	addi	a3,a3,1420 # ffffffffc02073e0 <commands+0xc30>
ffffffffc0201e5c:	00005617          	auipc	a2,0x5
ffffffffc0201e60:	dd460613          	addi	a2,a2,-556 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201e64:	23300593          	li	a1,563
ffffffffc0201e68:	00005517          	auipc	a0,0x5
ffffffffc0201e6c:	1d850513          	addi	a0,a0,472 # ffffffffc0207040 <commands+0x890>
ffffffffc0201e70:	ba6fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0201e74:	00005697          	auipc	a3,0x5
ffffffffc0201e78:	6ec68693          	addi	a3,a3,1772 # ffffffffc0207560 <commands+0xdb0>
ffffffffc0201e7c:	00005617          	auipc	a2,0x5
ffffffffc0201e80:	db460613          	addi	a2,a2,-588 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201e84:	25700593          	li	a1,599
ffffffffc0201e88:	00005517          	auipc	a0,0x5
ffffffffc0201e8c:	1b850513          	addi	a0,a0,440 # ffffffffc0207040 <commands+0x890>
ffffffffc0201e90:	b86fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201e94:	00005697          	auipc	a3,0x5
ffffffffc0201e98:	68c68693          	addi	a3,a3,1676 # ffffffffc0207520 <commands+0xd70>
ffffffffc0201e9c:	00005617          	auipc	a2,0x5
ffffffffc0201ea0:	d9460613          	addi	a2,a2,-620 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201ea4:	25600593          	li	a1,598
ffffffffc0201ea8:	00005517          	auipc	a0,0x5
ffffffffc0201eac:	19850513          	addi	a0,a0,408 # ffffffffc0207040 <commands+0x890>
ffffffffc0201eb0:	b66fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0201eb4:	00005697          	auipc	a3,0x5
ffffffffc0201eb8:	65468693          	addi	a3,a3,1620 # ffffffffc0207508 <commands+0xd58>
ffffffffc0201ebc:	00005617          	auipc	a2,0x5
ffffffffc0201ec0:	d7460613          	addi	a2,a2,-652 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201ec4:	25500593          	li	a1,597
ffffffffc0201ec8:	00005517          	auipc	a0,0x5
ffffffffc0201ecc:	17850513          	addi	a0,a0,376 # ffffffffc0207040 <commands+0x890>
ffffffffc0201ed0:	b46fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201ed4:	86be                	mv	a3,a5
ffffffffc0201ed6:	00005617          	auipc	a2,0x5
ffffffffc0201eda:	14260613          	addi	a2,a2,322 # ffffffffc0207018 <commands+0x868>
ffffffffc0201ede:	21b00593          	li	a1,539
ffffffffc0201ee2:	00005517          	auipc	a0,0x5
ffffffffc0201ee6:	15e50513          	addi	a0,a0,350 # ffffffffc0207040 <commands+0x890>
ffffffffc0201eea:	b2cfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201eee:	00005617          	auipc	a2,0x5
ffffffffc0201ef2:	20260613          	addi	a2,a2,514 # ffffffffc02070f0 <commands+0x940>
ffffffffc0201ef6:	07f00593          	li	a1,127
ffffffffc0201efa:	00005517          	auipc	a0,0x5
ffffffffc0201efe:	14650513          	addi	a0,a0,326 # ffffffffc0207040 <commands+0x890>
ffffffffc0201f02:	b14fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201f06:	00005697          	auipc	a3,0x5
ffffffffc0201f0a:	68a68693          	addi	a3,a3,1674 # ffffffffc0207590 <commands+0xde0>
ffffffffc0201f0e:	00005617          	auipc	a2,0x5
ffffffffc0201f12:	d2260613          	addi	a2,a2,-734 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201f16:	25b00593          	li	a1,603
ffffffffc0201f1a:	00005517          	auipc	a0,0x5
ffffffffc0201f1e:	12650513          	addi	a0,a0,294 # ffffffffc0207040 <commands+0x890>
ffffffffc0201f22:	af4fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0201f26:	00005697          	auipc	a3,0x5
ffffffffc0201f2a:	4fa68693          	addi	a3,a3,1274 # ffffffffc0207420 <commands+0xc70>
ffffffffc0201f2e:	00005617          	auipc	a2,0x5
ffffffffc0201f32:	d0260613          	addi	a2,a2,-766 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201f36:	26700593          	li	a1,615
ffffffffc0201f3a:	00005517          	auipc	a0,0x5
ffffffffc0201f3e:	10650513          	addi	a0,a0,262 # ffffffffc0207040 <commands+0x890>
ffffffffc0201f42:	ad4fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201f46:	00005697          	auipc	a3,0x5
ffffffffc0201f4a:	32a68693          	addi	a3,a3,810 # ffffffffc0207270 <commands+0xac0>
ffffffffc0201f4e:	00005617          	auipc	a2,0x5
ffffffffc0201f52:	ce260613          	addi	a2,a2,-798 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201f56:	21900593          	li	a1,537
ffffffffc0201f5a:	00005517          	auipc	a0,0x5
ffffffffc0201f5e:	0e650513          	addi	a0,a0,230 # ffffffffc0207040 <commands+0x890>
ffffffffc0201f62:	ab4fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201f66:	00005697          	auipc	a3,0x5
ffffffffc0201f6a:	2f268693          	addi	a3,a3,754 # ffffffffc0207258 <commands+0xaa8>
ffffffffc0201f6e:	00005617          	auipc	a2,0x5
ffffffffc0201f72:	cc260613          	addi	a2,a2,-830 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201f76:	21800593          	li	a1,536
ffffffffc0201f7a:	00005517          	auipc	a0,0x5
ffffffffc0201f7e:	0c650513          	addi	a0,a0,198 # ffffffffc0207040 <commands+0x890>
ffffffffc0201f82:	a94fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201f86:	00005697          	auipc	a3,0x5
ffffffffc0201f8a:	22268693          	addi	a3,a3,546 # ffffffffc02071a8 <commands+0x9f8>
ffffffffc0201f8e:	00005617          	auipc	a2,0x5
ffffffffc0201f92:	ca260613          	addi	a2,a2,-862 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201f96:	21000593          	li	a1,528
ffffffffc0201f9a:	00005517          	auipc	a0,0x5
ffffffffc0201f9e:	0a650513          	addi	a0,a0,166 # ffffffffc0207040 <commands+0x890>
ffffffffc0201fa2:	a74fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201fa6:	00005697          	auipc	a3,0x5
ffffffffc0201faa:	25a68693          	addi	a3,a3,602 # ffffffffc0207200 <commands+0xa50>
ffffffffc0201fae:	00005617          	auipc	a2,0x5
ffffffffc0201fb2:	c8260613          	addi	a2,a2,-894 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201fb6:	21700593          	li	a1,535
ffffffffc0201fba:	00005517          	auipc	a0,0x5
ffffffffc0201fbe:	08650513          	addi	a0,a0,134 # ffffffffc0207040 <commands+0x890>
ffffffffc0201fc2:	a54fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201fc6:	00005697          	auipc	a3,0x5
ffffffffc0201fca:	20a68693          	addi	a3,a3,522 # ffffffffc02071d0 <commands+0xa20>
ffffffffc0201fce:	00005617          	auipc	a2,0x5
ffffffffc0201fd2:	c6260613          	addi	a2,a2,-926 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201fd6:	21400593          	li	a1,532
ffffffffc0201fda:	00005517          	auipc	a0,0x5
ffffffffc0201fde:	06650513          	addi	a0,a0,102 # ffffffffc0207040 <commands+0x890>
ffffffffc0201fe2:	a34fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201fe6:	00005697          	auipc	a3,0x5
ffffffffc0201fea:	3ca68693          	addi	a3,a3,970 # ffffffffc02073b0 <commands+0xc00>
ffffffffc0201fee:	00005617          	auipc	a2,0x5
ffffffffc0201ff2:	c4260613          	addi	a2,a2,-958 # ffffffffc0206c30 <commands+0x480>
ffffffffc0201ff6:	23000593          	li	a1,560
ffffffffc0201ffa:	00005517          	auipc	a0,0x5
ffffffffc0201ffe:	04650513          	addi	a0,a0,70 # ffffffffc0207040 <commands+0x890>
ffffffffc0202002:	a14fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202006:	00005697          	auipc	a3,0x5
ffffffffc020200a:	26a68693          	addi	a3,a3,618 # ffffffffc0207270 <commands+0xac0>
ffffffffc020200e:	00005617          	auipc	a2,0x5
ffffffffc0202012:	c2260613          	addi	a2,a2,-990 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202016:	22f00593          	li	a1,559
ffffffffc020201a:	00005517          	auipc	a0,0x5
ffffffffc020201e:	02650513          	addi	a0,a0,38 # ffffffffc0207040 <commands+0x890>
ffffffffc0202022:	9f4fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202026:	00005697          	auipc	a3,0x5
ffffffffc020202a:	3a268693          	addi	a3,a3,930 # ffffffffc02073c8 <commands+0xc18>
ffffffffc020202e:	00005617          	auipc	a2,0x5
ffffffffc0202032:	c0260613          	addi	a2,a2,-1022 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202036:	22c00593          	li	a1,556
ffffffffc020203a:	00005517          	auipc	a0,0x5
ffffffffc020203e:	00650513          	addi	a0,a0,6 # ffffffffc0207040 <commands+0x890>
ffffffffc0202042:	9d4fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202046:	00005697          	auipc	a3,0x5
ffffffffc020204a:	58268693          	addi	a3,a3,1410 # ffffffffc02075c8 <commands+0xe18>
ffffffffc020204e:	00005617          	auipc	a2,0x5
ffffffffc0202052:	be260613          	addi	a2,a2,-1054 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202056:	25e00593          	li	a1,606
ffffffffc020205a:	00005517          	auipc	a0,0x5
ffffffffc020205e:	fe650513          	addi	a0,a0,-26 # ffffffffc0207040 <commands+0x890>
ffffffffc0202062:	9b4fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202066:	00005697          	auipc	a3,0x5
ffffffffc020206a:	3ba68693          	addi	a3,a3,954 # ffffffffc0207420 <commands+0xc70>
ffffffffc020206e:	00005617          	auipc	a2,0x5
ffffffffc0202072:	bc260613          	addi	a2,a2,-1086 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202076:	23e00593          	li	a1,574
ffffffffc020207a:	00005517          	auipc	a0,0x5
ffffffffc020207e:	fc650513          	addi	a0,a0,-58 # ffffffffc0207040 <commands+0x890>
ffffffffc0202082:	994fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0202086:	00005697          	auipc	a3,0x5
ffffffffc020208a:	43268693          	addi	a3,a3,1074 # ffffffffc02074b8 <commands+0xd08>
ffffffffc020208e:	00005617          	auipc	a2,0x5
ffffffffc0202092:	ba260613          	addi	a2,a2,-1118 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202096:	25000593          	li	a1,592
ffffffffc020209a:	00005517          	auipc	a0,0x5
ffffffffc020209e:	fa650513          	addi	a0,a0,-90 # ffffffffc0207040 <commands+0x890>
ffffffffc02020a2:	974fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02020a6:	00005697          	auipc	a3,0x5
ffffffffc02020aa:	0aa68693          	addi	a3,a3,170 # ffffffffc0207150 <commands+0x9a0>
ffffffffc02020ae:	00005617          	auipc	a2,0x5
ffffffffc02020b2:	b8260613          	addi	a2,a2,-1150 # ffffffffc0206c30 <commands+0x480>
ffffffffc02020b6:	20e00593          	li	a1,526
ffffffffc02020ba:	00005517          	auipc	a0,0x5
ffffffffc02020be:	f8650513          	addi	a0,a0,-122 # ffffffffc0207040 <commands+0x890>
ffffffffc02020c2:	954fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02020c6:	00005617          	auipc	a2,0x5
ffffffffc02020ca:	02a60613          	addi	a2,a2,42 # ffffffffc02070f0 <commands+0x940>
ffffffffc02020ce:	0c100593          	li	a1,193
ffffffffc02020d2:	00005517          	auipc	a0,0x5
ffffffffc02020d6:	f6e50513          	addi	a0,a0,-146 # ffffffffc0207040 <commands+0x890>
ffffffffc02020da:	93cfe0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02020de <copy_range>:
               bool share) {
ffffffffc02020de:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020e0:	00d667b3          	or	a5,a2,a3
               bool share) {
ffffffffc02020e4:	f486                	sd	ra,104(sp)
ffffffffc02020e6:	f0a2                	sd	s0,96(sp)
ffffffffc02020e8:	eca6                	sd	s1,88(sp)
ffffffffc02020ea:	e8ca                	sd	s2,80(sp)
ffffffffc02020ec:	e4ce                	sd	s3,72(sp)
ffffffffc02020ee:	e0d2                	sd	s4,64(sp)
ffffffffc02020f0:	fc56                	sd	s5,56(sp)
ffffffffc02020f2:	f85a                	sd	s6,48(sp)
ffffffffc02020f4:	f45e                	sd	s7,40(sp)
ffffffffc02020f6:	f062                	sd	s8,32(sp)
ffffffffc02020f8:	ec66                	sd	s9,24(sp)
ffffffffc02020fa:	e86a                	sd	s10,16(sp)
ffffffffc02020fc:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020fe:	03479713          	slli	a4,a5,0x34
ffffffffc0202102:	1e071863          	bnez	a4,ffffffffc02022f2 <copy_range+0x214>
    assert(USER_ACCESS(start, end));
ffffffffc0202106:	002007b7          	lui	a5,0x200
ffffffffc020210a:	8432                	mv	s0,a2
ffffffffc020210c:	16f66b63          	bltu	a2,a5,ffffffffc0202282 <copy_range+0x1a4>
ffffffffc0202110:	84b6                	mv	s1,a3
ffffffffc0202112:	16d67863          	bleu	a3,a2,ffffffffc0202282 <copy_range+0x1a4>
ffffffffc0202116:	4785                	li	a5,1
ffffffffc0202118:	07fe                	slli	a5,a5,0x1f
ffffffffc020211a:	16d7e463          	bltu	a5,a3,ffffffffc0202282 <copy_range+0x1a4>
ffffffffc020211e:	5a7d                	li	s4,-1
ffffffffc0202120:	8aaa                	mv	s5,a0
ffffffffc0202122:	892e                	mv	s2,a1
        start += PGSIZE;
ffffffffc0202124:	6985                	lui	s3,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202126:	000aac17          	auipc	s8,0xaa
ffffffffc020212a:	2dac0c13          	addi	s8,s8,730 # ffffffffc02ac400 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020212e:	000aab97          	auipc	s7,0xaa
ffffffffc0202132:	33ab8b93          	addi	s7,s7,826 # ffffffffc02ac468 <pages>
    return page - pages + nbase;
ffffffffc0202136:	00080b37          	lui	s6,0x80
    return KADDR(page2pa(page));
ffffffffc020213a:	00ca5a13          	srli	s4,s4,0xc
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020213e:	4601                	li	a2,0
ffffffffc0202140:	85a2                	mv	a1,s0
ffffffffc0202142:	854a                	mv	a0,s2
ffffffffc0202144:	e3dfe0ef          	jal	ra,ffffffffc0200f80 <get_pte>
ffffffffc0202148:	8caa                	mv	s9,a0
        if (ptep == NULL) {
ffffffffc020214a:	c17d                	beqz	a0,ffffffffc0202230 <copy_range+0x152>
        if (*ptep & PTE_V) {
ffffffffc020214c:	611c                	ld	a5,0(a0)
ffffffffc020214e:	8b85                	andi	a5,a5,1
ffffffffc0202150:	e785                	bnez	a5,ffffffffc0202178 <copy_range+0x9a>
        start += PGSIZE;
ffffffffc0202152:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0202154:	fe9465e3          	bltu	s0,s1,ffffffffc020213e <copy_range+0x60>
    return 0;
ffffffffc0202158:	4501                	li	a0,0
}
ffffffffc020215a:	70a6                	ld	ra,104(sp)
ffffffffc020215c:	7406                	ld	s0,96(sp)
ffffffffc020215e:	64e6                	ld	s1,88(sp)
ffffffffc0202160:	6946                	ld	s2,80(sp)
ffffffffc0202162:	69a6                	ld	s3,72(sp)
ffffffffc0202164:	6a06                	ld	s4,64(sp)
ffffffffc0202166:	7ae2                	ld	s5,56(sp)
ffffffffc0202168:	7b42                	ld	s6,48(sp)
ffffffffc020216a:	7ba2                	ld	s7,40(sp)
ffffffffc020216c:	7c02                	ld	s8,32(sp)
ffffffffc020216e:	6ce2                	ld	s9,24(sp)
ffffffffc0202170:	6d42                	ld	s10,16(sp)
ffffffffc0202172:	6da2                	ld	s11,8(sp)
ffffffffc0202174:	6165                	addi	sp,sp,112
ffffffffc0202176:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc0202178:	4605                	li	a2,1
ffffffffc020217a:	85a2                	mv	a1,s0
ffffffffc020217c:	8556                	mv	a0,s5
ffffffffc020217e:	e03fe0ef          	jal	ra,ffffffffc0200f80 <get_pte>
ffffffffc0202182:	c169                	beqz	a0,ffffffffc0202244 <copy_range+0x166>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0202184:	000cb783          	ld	a5,0(s9)
    if (!(pte & PTE_V)) {
ffffffffc0202188:	0017f713          	andi	a4,a5,1
ffffffffc020218c:	01f7fc93          	andi	s9,a5,31
ffffffffc0202190:	14070563          	beqz	a4,ffffffffc02022da <copy_range+0x1fc>
    if (PPN(pa) >= npage) {
ffffffffc0202194:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202198:	078a                	slli	a5,a5,0x2
ffffffffc020219a:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020219e:	12d77263          	bleu	a3,a4,ffffffffc02022c2 <copy_range+0x1e4>
    return &pages[PPN(pa) - nbase];
ffffffffc02021a2:	000bb783          	ld	a5,0(s7)
ffffffffc02021a6:	fff806b7          	lui	a3,0xfff80
ffffffffc02021aa:	9736                	add	a4,a4,a3
ffffffffc02021ac:	071a                	slli	a4,a4,0x6
            struct Page *npage = alloc_page();
ffffffffc02021ae:	4505                	li	a0,1
ffffffffc02021b0:	00e78db3          	add	s11,a5,a4
ffffffffc02021b4:	cbffe0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc02021b8:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc02021ba:	0a0d8463          	beqz	s11,ffffffffc0202262 <copy_range+0x184>
            assert(npage != NULL);
ffffffffc02021be:	c175                	beqz	a0,ffffffffc02022a2 <copy_range+0x1c4>
    return page - pages + nbase;
ffffffffc02021c0:	000bb703          	ld	a4,0(s7)
    return KADDR(page2pa(page));
ffffffffc02021c4:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02021c8:	40ed86b3          	sub	a3,s11,a4
ffffffffc02021cc:	8699                	srai	a3,a3,0x6
ffffffffc02021ce:	96da                	add	a3,a3,s6
    return KADDR(page2pa(page));
ffffffffc02021d0:	0146f7b3          	and	a5,a3,s4
    return page2ppn(page) << PGSHIFT;
ffffffffc02021d4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02021d6:	06c7fa63          	bleu	a2,a5,ffffffffc020224a <copy_range+0x16c>
    return page - pages + nbase;
ffffffffc02021da:	40e507b3          	sub	a5,a0,a4
    return KADDR(page2pa(page));
ffffffffc02021de:	000aa717          	auipc	a4,0xaa
ffffffffc02021e2:	27a70713          	addi	a4,a4,634 # ffffffffc02ac458 <va_pa_offset>
ffffffffc02021e6:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc02021e8:	8799                	srai	a5,a5,0x6
ffffffffc02021ea:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc02021ec:	0147f733          	and	a4,a5,s4
ffffffffc02021f0:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02021f4:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02021f6:	04c77963          	bleu	a2,a4,ffffffffc0202248 <copy_range+0x16a>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02021fa:	6605                	lui	a2,0x1
ffffffffc02021fc:	953e                	add	a0,a0,a5
ffffffffc02021fe:	018040ef          	jal	ra,ffffffffc0206216 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc0202202:	86e6                	mv	a3,s9
ffffffffc0202204:	8622                	mv	a2,s0
ffffffffc0202206:	85ea                	mv	a1,s10
ffffffffc0202208:	8556                	mv	a0,s5
ffffffffc020220a:	b8cff0ef          	jal	ra,ffffffffc0201596 <page_insert>
            assert(ret == 0);
ffffffffc020220e:	d131                	beqz	a0,ffffffffc0202152 <copy_range+0x74>
ffffffffc0202210:	00005697          	auipc	a3,0x5
ffffffffc0202214:	df868693          	addi	a3,a3,-520 # ffffffffc0207008 <commands+0x858>
ffffffffc0202218:	00005617          	auipc	a2,0x5
ffffffffc020221c:	a1860613          	addi	a2,a2,-1512 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202220:	1af00593          	li	a1,431
ffffffffc0202224:	00005517          	auipc	a0,0x5
ffffffffc0202228:	e1c50513          	addi	a0,a0,-484 # ffffffffc0207040 <commands+0x890>
ffffffffc020222c:	febfd0ef          	jal	ra,ffffffffc0200216 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202230:	002007b7          	lui	a5,0x200
ffffffffc0202234:	943e                	add	s0,s0,a5
ffffffffc0202236:	ffe007b7          	lui	a5,0xffe00
ffffffffc020223a:	8c7d                	and	s0,s0,a5
    } while (start != 0 && start < end);
ffffffffc020223c:	dc11                	beqz	s0,ffffffffc0202158 <copy_range+0x7a>
ffffffffc020223e:	f09460e3          	bltu	s0,s1,ffffffffc020213e <copy_range+0x60>
ffffffffc0202242:	bf19                	j	ffffffffc0202158 <copy_range+0x7a>
                return -E_NO_MEM;
ffffffffc0202244:	5571                	li	a0,-4
ffffffffc0202246:	bf11                	j	ffffffffc020215a <copy_range+0x7c>
ffffffffc0202248:	86be                	mv	a3,a5
ffffffffc020224a:	00005617          	auipc	a2,0x5
ffffffffc020224e:	dce60613          	addi	a2,a2,-562 # ffffffffc0207018 <commands+0x868>
ffffffffc0202252:	06900593          	li	a1,105
ffffffffc0202256:	00005517          	auipc	a0,0x5
ffffffffc020225a:	e1a50513          	addi	a0,a0,-486 # ffffffffc0207070 <commands+0x8c0>
ffffffffc020225e:	fb9fd0ef          	jal	ra,ffffffffc0200216 <__panic>
            assert(page != NULL);
ffffffffc0202262:	00005697          	auipc	a3,0x5
ffffffffc0202266:	d8668693          	addi	a3,a3,-634 # ffffffffc0206fe8 <commands+0x838>
ffffffffc020226a:	00005617          	auipc	a2,0x5
ffffffffc020226e:	9c660613          	addi	a2,a2,-1594 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202272:	18700593          	li	a1,391
ffffffffc0202276:	00005517          	auipc	a0,0x5
ffffffffc020227a:	dca50513          	addi	a0,a0,-566 # ffffffffc0207040 <commands+0x890>
ffffffffc020227e:	f99fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202282:	00005697          	auipc	a3,0x5
ffffffffc0202286:	3be68693          	addi	a3,a3,958 # ffffffffc0207640 <commands+0xe90>
ffffffffc020228a:	00005617          	auipc	a2,0x5
ffffffffc020228e:	9a660613          	addi	a2,a2,-1626 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202292:	16900593          	li	a1,361
ffffffffc0202296:	00005517          	auipc	a0,0x5
ffffffffc020229a:	daa50513          	addi	a0,a0,-598 # ffffffffc0207040 <commands+0x890>
ffffffffc020229e:	f79fd0ef          	jal	ra,ffffffffc0200216 <__panic>
            assert(npage != NULL);
ffffffffc02022a2:	00005697          	auipc	a3,0x5
ffffffffc02022a6:	d5668693          	addi	a3,a3,-682 # ffffffffc0206ff8 <commands+0x848>
ffffffffc02022aa:	00005617          	auipc	a2,0x5
ffffffffc02022ae:	98660613          	addi	a2,a2,-1658 # ffffffffc0206c30 <commands+0x480>
ffffffffc02022b2:	18800593          	li	a1,392
ffffffffc02022b6:	00005517          	auipc	a0,0x5
ffffffffc02022ba:	d8a50513          	addi	a0,a0,-630 # ffffffffc0207040 <commands+0x890>
ffffffffc02022be:	f59fd0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02022c2:	00005617          	auipc	a2,0x5
ffffffffc02022c6:	d8e60613          	addi	a2,a2,-626 # ffffffffc0207050 <commands+0x8a0>
ffffffffc02022ca:	06200593          	li	a1,98
ffffffffc02022ce:	00005517          	auipc	a0,0x5
ffffffffc02022d2:	da250513          	addi	a0,a0,-606 # ffffffffc0207070 <commands+0x8c0>
ffffffffc02022d6:	f41fd0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02022da:	00005617          	auipc	a2,0x5
ffffffffc02022de:	f5660613          	addi	a2,a2,-170 # ffffffffc0207230 <commands+0xa80>
ffffffffc02022e2:	07400593          	li	a1,116
ffffffffc02022e6:	00005517          	auipc	a0,0x5
ffffffffc02022ea:	d8a50513          	addi	a0,a0,-630 # ffffffffc0207070 <commands+0x8c0>
ffffffffc02022ee:	f29fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022f2:	00005697          	auipc	a3,0x5
ffffffffc02022f6:	31e68693          	addi	a3,a3,798 # ffffffffc0207610 <commands+0xe60>
ffffffffc02022fa:	00005617          	auipc	a2,0x5
ffffffffc02022fe:	93660613          	addi	a2,a2,-1738 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202302:	16700593          	li	a1,359
ffffffffc0202306:	00005517          	auipc	a0,0x5
ffffffffc020230a:	d3a50513          	addi	a0,a0,-710 # ffffffffc0207040 <commands+0x890>
ffffffffc020230e:	f09fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202312 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202312:	12058073          	sfence.vma	a1
}
ffffffffc0202316:	8082                	ret

ffffffffc0202318 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202318:	7179                	addi	sp,sp,-48
ffffffffc020231a:	e84a                	sd	s2,16(sp)
ffffffffc020231c:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc020231e:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202320:	f022                	sd	s0,32(sp)
ffffffffc0202322:	ec26                	sd	s1,24(sp)
ffffffffc0202324:	e44e                	sd	s3,8(sp)
ffffffffc0202326:	f406                	sd	ra,40(sp)
ffffffffc0202328:	84ae                	mv	s1,a1
ffffffffc020232a:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc020232c:	b47fe0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0202330:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0202332:	cd1d                	beqz	a0,ffffffffc0202370 <pgdir_alloc_page+0x58>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0202334:	85aa                	mv	a1,a0
ffffffffc0202336:	86ce                	mv	a3,s3
ffffffffc0202338:	8626                	mv	a2,s1
ffffffffc020233a:	854a                	mv	a0,s2
ffffffffc020233c:	a5aff0ef          	jal	ra,ffffffffc0201596 <page_insert>
ffffffffc0202340:	e121                	bnez	a0,ffffffffc0202380 <pgdir_alloc_page+0x68>
        if (swap_init_ok) {
ffffffffc0202342:	000aa797          	auipc	a5,0xaa
ffffffffc0202346:	0de78793          	addi	a5,a5,222 # ffffffffc02ac420 <swap_init_ok>
ffffffffc020234a:	439c                	lw	a5,0(a5)
ffffffffc020234c:	2781                	sext.w	a5,a5
ffffffffc020234e:	c38d                	beqz	a5,ffffffffc0202370 <pgdir_alloc_page+0x58>
            if (check_mm_struct != NULL) {
ffffffffc0202350:	000aa797          	auipc	a5,0xaa
ffffffffc0202354:	13078793          	addi	a5,a5,304 # ffffffffc02ac480 <check_mm_struct>
ffffffffc0202358:	6388                	ld	a0,0(a5)
ffffffffc020235a:	c919                	beqz	a0,ffffffffc0202370 <pgdir_alloc_page+0x58>
                swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc020235c:	4681                	li	a3,0
ffffffffc020235e:	8622                	mv	a2,s0
ffffffffc0202360:	85a6                	mv	a1,s1
ffffffffc0202362:	2d5010ef          	jal	ra,ffffffffc0203e36 <swap_map_swappable>
                assert(page_ref(page) == 1);
ffffffffc0202366:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la;
ffffffffc0202368:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1);
ffffffffc020236a:	4785                	li	a5,1
ffffffffc020236c:	02f71063          	bne	a4,a5,ffffffffc020238c <pgdir_alloc_page+0x74>
}
ffffffffc0202370:	8522                	mv	a0,s0
ffffffffc0202372:	70a2                	ld	ra,40(sp)
ffffffffc0202374:	7402                	ld	s0,32(sp)
ffffffffc0202376:	64e2                	ld	s1,24(sp)
ffffffffc0202378:	6942                	ld	s2,16(sp)
ffffffffc020237a:	69a2                	ld	s3,8(sp)
ffffffffc020237c:	6145                	addi	sp,sp,48
ffffffffc020237e:	8082                	ret
            free_page(page);
ffffffffc0202380:	8522                	mv	a0,s0
ffffffffc0202382:	4585                	li	a1,1
ffffffffc0202384:	b77fe0ef          	jal	ra,ffffffffc0200efa <free_pages>
            return NULL;
ffffffffc0202388:	4401                	li	s0,0
ffffffffc020238a:	b7dd                	j	ffffffffc0202370 <pgdir_alloc_page+0x58>
                assert(page_ref(page) == 1);
ffffffffc020238c:	00005697          	auipc	a3,0x5
ffffffffc0202390:	cf468693          	addi	a3,a3,-780 # ffffffffc0207080 <commands+0x8d0>
ffffffffc0202394:	00005617          	auipc	a2,0x5
ffffffffc0202398:	89c60613          	addi	a2,a2,-1892 # ffffffffc0206c30 <commands+0x480>
ffffffffc020239c:	1ef00593          	li	a1,495
ffffffffc02023a0:	00005517          	auipc	a0,0x5
ffffffffc02023a4:	ca050513          	addi	a0,a0,-864 # ffffffffc0207040 <commands+0x890>
ffffffffc02023a8:	e6ffd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02023ac <_fifo_init_mm>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02023ac:	000aa797          	auipc	a5,0xaa
ffffffffc02023b0:	0c478793          	addi	a5,a5,196 # ffffffffc02ac470 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc02023b4:	f51c                	sd	a5,40(a0)
ffffffffc02023b6:	e79c                	sd	a5,8(a5)
ffffffffc02023b8:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc02023ba:	4501                	li	a0,0
ffffffffc02023bc:	8082                	ret

ffffffffc02023be <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc02023be:	4501                	li	a0,0
ffffffffc02023c0:	8082                	ret

ffffffffc02023c2 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc02023c2:	4501                	li	a0,0
ffffffffc02023c4:	8082                	ret

ffffffffc02023c6 <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc02023c6:	4501                	li	a0,0
ffffffffc02023c8:	8082                	ret

ffffffffc02023ca <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc02023ca:	711d                	addi	sp,sp,-96
ffffffffc02023cc:	fc4e                	sd	s3,56(sp)
ffffffffc02023ce:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc02023d0:	00005517          	auipc	a0,0x5
ffffffffc02023d4:	28850513          	addi	a0,a0,648 # ffffffffc0207658 <commands+0xea8>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02023d8:	698d                	lui	s3,0x3
ffffffffc02023da:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc02023dc:	e8a2                	sd	s0,80(sp)
ffffffffc02023de:	e4a6                	sd	s1,72(sp)
ffffffffc02023e0:	ec86                	sd	ra,88(sp)
ffffffffc02023e2:	e0ca                	sd	s2,64(sp)
ffffffffc02023e4:	f456                	sd	s5,40(sp)
ffffffffc02023e6:	f05a                	sd	s6,32(sp)
ffffffffc02023e8:	ec5e                	sd	s7,24(sp)
ffffffffc02023ea:	e862                	sd	s8,16(sp)
ffffffffc02023ec:	e466                	sd	s9,8(sp)
    assert(pgfault_num==4);
ffffffffc02023ee:	000aa417          	auipc	s0,0xaa
ffffffffc02023f2:	01a40413          	addi	s0,s0,26 # ffffffffc02ac408 <pgfault_num>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc02023f6:	cdbfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02023fa:	01498023          	sb	s4,0(s3) # 3000 <_binary_obj___user_faultread_out_size-0x6570>
    assert(pgfault_num==4);
ffffffffc02023fe:	4004                	lw	s1,0(s0)
ffffffffc0202400:	4791                	li	a5,4
ffffffffc0202402:	2481                	sext.w	s1,s1
ffffffffc0202404:	14f49963          	bne	s1,a5,ffffffffc0202556 <_fifo_check_swap+0x18c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0202408:	00005517          	auipc	a0,0x5
ffffffffc020240c:	2a050513          	addi	a0,a0,672 # ffffffffc02076a8 <commands+0xef8>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202410:	6a85                	lui	s5,0x1
ffffffffc0202412:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0202414:	cbdfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202418:	016a8023          	sb	s6,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
    assert(pgfault_num==4);
ffffffffc020241c:	00042903          	lw	s2,0(s0)
ffffffffc0202420:	2901                	sext.w	s2,s2
ffffffffc0202422:	2a991a63          	bne	s2,s1,ffffffffc02026d6 <_fifo_check_swap+0x30c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0202426:	00005517          	auipc	a0,0x5
ffffffffc020242a:	2aa50513          	addi	a0,a0,682 # ffffffffc02076d0 <commands+0xf20>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc020242e:	6b91                	lui	s7,0x4
ffffffffc0202430:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0202432:	c9ffd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202436:	018b8023          	sb	s8,0(s7) # 4000 <_binary_obj___user_faultread_out_size-0x5570>
    assert(pgfault_num==4);
ffffffffc020243a:	4004                	lw	s1,0(s0)
ffffffffc020243c:	2481                	sext.w	s1,s1
ffffffffc020243e:	27249c63          	bne	s1,s2,ffffffffc02026b6 <_fifo_check_swap+0x2ec>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0202442:	00005517          	auipc	a0,0x5
ffffffffc0202446:	2b650513          	addi	a0,a0,694 # ffffffffc02076f8 <commands+0xf48>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020244a:	6909                	lui	s2,0x2
ffffffffc020244c:	4cad                	li	s9,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc020244e:	c83fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202452:	01990023          	sb	s9,0(s2) # 2000 <_binary_obj___user_faultread_out_size-0x7570>
    assert(pgfault_num==4);
ffffffffc0202456:	401c                	lw	a5,0(s0)
ffffffffc0202458:	2781                	sext.w	a5,a5
ffffffffc020245a:	22979e63          	bne	a5,s1,ffffffffc0202696 <_fifo_check_swap+0x2cc>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc020245e:	00005517          	auipc	a0,0x5
ffffffffc0202462:	2c250513          	addi	a0,a0,706 # ffffffffc0207720 <commands+0xf70>
ffffffffc0202466:	c6bfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc020246a:	6795                	lui	a5,0x5
ffffffffc020246c:	4739                	li	a4,14
ffffffffc020246e:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4570>
    assert(pgfault_num==5);
ffffffffc0202472:	4004                	lw	s1,0(s0)
ffffffffc0202474:	4795                	li	a5,5
ffffffffc0202476:	2481                	sext.w	s1,s1
ffffffffc0202478:	1ef49f63          	bne	s1,a5,ffffffffc0202676 <_fifo_check_swap+0x2ac>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc020247c:	00005517          	auipc	a0,0x5
ffffffffc0202480:	27c50513          	addi	a0,a0,636 # ffffffffc02076f8 <commands+0xf48>
ffffffffc0202484:	c4dfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202488:	01990023          	sb	s9,0(s2)
    assert(pgfault_num==5);
ffffffffc020248c:	401c                	lw	a5,0(s0)
ffffffffc020248e:	2781                	sext.w	a5,a5
ffffffffc0202490:	1c979363          	bne	a5,s1,ffffffffc0202656 <_fifo_check_swap+0x28c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0202494:	00005517          	auipc	a0,0x5
ffffffffc0202498:	21450513          	addi	a0,a0,532 # ffffffffc02076a8 <commands+0xef8>
ffffffffc020249c:	c35fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02024a0:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc02024a4:	401c                	lw	a5,0(s0)
ffffffffc02024a6:	4719                	li	a4,6
ffffffffc02024a8:	2781                	sext.w	a5,a5
ffffffffc02024aa:	18e79663          	bne	a5,a4,ffffffffc0202636 <_fifo_check_swap+0x26c>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02024ae:	00005517          	auipc	a0,0x5
ffffffffc02024b2:	24a50513          	addi	a0,a0,586 # ffffffffc02076f8 <commands+0xf48>
ffffffffc02024b6:	c1bfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02024ba:	01990023          	sb	s9,0(s2)
    assert(pgfault_num==7);
ffffffffc02024be:	401c                	lw	a5,0(s0)
ffffffffc02024c0:	471d                	li	a4,7
ffffffffc02024c2:	2781                	sext.w	a5,a5
ffffffffc02024c4:	14e79963          	bne	a5,a4,ffffffffc0202616 <_fifo_check_swap+0x24c>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc02024c8:	00005517          	auipc	a0,0x5
ffffffffc02024cc:	19050513          	addi	a0,a0,400 # ffffffffc0207658 <commands+0xea8>
ffffffffc02024d0:	c01fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02024d4:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc02024d8:	401c                	lw	a5,0(s0)
ffffffffc02024da:	4721                	li	a4,8
ffffffffc02024dc:	2781                	sext.w	a5,a5
ffffffffc02024de:	10e79c63          	bne	a5,a4,ffffffffc02025f6 <_fifo_check_swap+0x22c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02024e2:	00005517          	auipc	a0,0x5
ffffffffc02024e6:	1ee50513          	addi	a0,a0,494 # ffffffffc02076d0 <commands+0xf20>
ffffffffc02024ea:	be7fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02024ee:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc02024f2:	401c                	lw	a5,0(s0)
ffffffffc02024f4:	4725                	li	a4,9
ffffffffc02024f6:	2781                	sext.w	a5,a5
ffffffffc02024f8:	0ce79f63          	bne	a5,a4,ffffffffc02025d6 <_fifo_check_swap+0x20c>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc02024fc:	00005517          	auipc	a0,0x5
ffffffffc0202500:	22450513          	addi	a0,a0,548 # ffffffffc0207720 <commands+0xf70>
ffffffffc0202504:	bcdfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0202508:	6795                	lui	a5,0x5
ffffffffc020250a:	4739                	li	a4,14
ffffffffc020250c:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4570>
    assert(pgfault_num==10);
ffffffffc0202510:	4004                	lw	s1,0(s0)
ffffffffc0202512:	47a9                	li	a5,10
ffffffffc0202514:	2481                	sext.w	s1,s1
ffffffffc0202516:	0af49063          	bne	s1,a5,ffffffffc02025b6 <_fifo_check_swap+0x1ec>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc020251a:	00005517          	auipc	a0,0x5
ffffffffc020251e:	18e50513          	addi	a0,a0,398 # ffffffffc02076a8 <commands+0xef8>
ffffffffc0202522:	baffd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0202526:	6785                	lui	a5,0x1
ffffffffc0202528:	0007c783          	lbu	a5,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
ffffffffc020252c:	06979563          	bne	a5,s1,ffffffffc0202596 <_fifo_check_swap+0x1cc>
    assert(pgfault_num==11);
ffffffffc0202530:	401c                	lw	a5,0(s0)
ffffffffc0202532:	472d                	li	a4,11
ffffffffc0202534:	2781                	sext.w	a5,a5
ffffffffc0202536:	04e79063          	bne	a5,a4,ffffffffc0202576 <_fifo_check_swap+0x1ac>
}
ffffffffc020253a:	60e6                	ld	ra,88(sp)
ffffffffc020253c:	6446                	ld	s0,80(sp)
ffffffffc020253e:	64a6                	ld	s1,72(sp)
ffffffffc0202540:	6906                	ld	s2,64(sp)
ffffffffc0202542:	79e2                	ld	s3,56(sp)
ffffffffc0202544:	7a42                	ld	s4,48(sp)
ffffffffc0202546:	7aa2                	ld	s5,40(sp)
ffffffffc0202548:	7b02                	ld	s6,32(sp)
ffffffffc020254a:	6be2                	ld	s7,24(sp)
ffffffffc020254c:	6c42                	ld	s8,16(sp)
ffffffffc020254e:	6ca2                	ld	s9,8(sp)
ffffffffc0202550:	4501                	li	a0,0
ffffffffc0202552:	6125                	addi	sp,sp,96
ffffffffc0202554:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0202556:	00005697          	auipc	a3,0x5
ffffffffc020255a:	12a68693          	addi	a3,a3,298 # ffffffffc0207680 <commands+0xed0>
ffffffffc020255e:	00004617          	auipc	a2,0x4
ffffffffc0202562:	6d260613          	addi	a2,a2,1746 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202566:	05100593          	li	a1,81
ffffffffc020256a:	00005517          	auipc	a0,0x5
ffffffffc020256e:	12650513          	addi	a0,a0,294 # ffffffffc0207690 <commands+0xee0>
ffffffffc0202572:	ca5fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==11);
ffffffffc0202576:	00005697          	auipc	a3,0x5
ffffffffc020257a:	25a68693          	addi	a3,a3,602 # ffffffffc02077d0 <commands+0x1020>
ffffffffc020257e:	00004617          	auipc	a2,0x4
ffffffffc0202582:	6b260613          	addi	a2,a2,1714 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202586:	07300593          	li	a1,115
ffffffffc020258a:	00005517          	auipc	a0,0x5
ffffffffc020258e:	10650513          	addi	a0,a0,262 # ffffffffc0207690 <commands+0xee0>
ffffffffc0202592:	c85fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0202596:	00005697          	auipc	a3,0x5
ffffffffc020259a:	21268693          	addi	a3,a3,530 # ffffffffc02077a8 <commands+0xff8>
ffffffffc020259e:	00004617          	auipc	a2,0x4
ffffffffc02025a2:	69260613          	addi	a2,a2,1682 # ffffffffc0206c30 <commands+0x480>
ffffffffc02025a6:	07100593          	li	a1,113
ffffffffc02025aa:	00005517          	auipc	a0,0x5
ffffffffc02025ae:	0e650513          	addi	a0,a0,230 # ffffffffc0207690 <commands+0xee0>
ffffffffc02025b2:	c65fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==10);
ffffffffc02025b6:	00005697          	auipc	a3,0x5
ffffffffc02025ba:	1e268693          	addi	a3,a3,482 # ffffffffc0207798 <commands+0xfe8>
ffffffffc02025be:	00004617          	auipc	a2,0x4
ffffffffc02025c2:	67260613          	addi	a2,a2,1650 # ffffffffc0206c30 <commands+0x480>
ffffffffc02025c6:	06f00593          	li	a1,111
ffffffffc02025ca:	00005517          	auipc	a0,0x5
ffffffffc02025ce:	0c650513          	addi	a0,a0,198 # ffffffffc0207690 <commands+0xee0>
ffffffffc02025d2:	c45fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==9);
ffffffffc02025d6:	00005697          	auipc	a3,0x5
ffffffffc02025da:	1b268693          	addi	a3,a3,434 # ffffffffc0207788 <commands+0xfd8>
ffffffffc02025de:	00004617          	auipc	a2,0x4
ffffffffc02025e2:	65260613          	addi	a2,a2,1618 # ffffffffc0206c30 <commands+0x480>
ffffffffc02025e6:	06c00593          	li	a1,108
ffffffffc02025ea:	00005517          	auipc	a0,0x5
ffffffffc02025ee:	0a650513          	addi	a0,a0,166 # ffffffffc0207690 <commands+0xee0>
ffffffffc02025f2:	c25fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==8);
ffffffffc02025f6:	00005697          	auipc	a3,0x5
ffffffffc02025fa:	18268693          	addi	a3,a3,386 # ffffffffc0207778 <commands+0xfc8>
ffffffffc02025fe:	00004617          	auipc	a2,0x4
ffffffffc0202602:	63260613          	addi	a2,a2,1586 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202606:	06900593          	li	a1,105
ffffffffc020260a:	00005517          	auipc	a0,0x5
ffffffffc020260e:	08650513          	addi	a0,a0,134 # ffffffffc0207690 <commands+0xee0>
ffffffffc0202612:	c05fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==7);
ffffffffc0202616:	00005697          	auipc	a3,0x5
ffffffffc020261a:	15268693          	addi	a3,a3,338 # ffffffffc0207768 <commands+0xfb8>
ffffffffc020261e:	00004617          	auipc	a2,0x4
ffffffffc0202622:	61260613          	addi	a2,a2,1554 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202626:	06600593          	li	a1,102
ffffffffc020262a:	00005517          	auipc	a0,0x5
ffffffffc020262e:	06650513          	addi	a0,a0,102 # ffffffffc0207690 <commands+0xee0>
ffffffffc0202632:	be5fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==6);
ffffffffc0202636:	00005697          	auipc	a3,0x5
ffffffffc020263a:	12268693          	addi	a3,a3,290 # ffffffffc0207758 <commands+0xfa8>
ffffffffc020263e:	00004617          	auipc	a2,0x4
ffffffffc0202642:	5f260613          	addi	a2,a2,1522 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202646:	06300593          	li	a1,99
ffffffffc020264a:	00005517          	auipc	a0,0x5
ffffffffc020264e:	04650513          	addi	a0,a0,70 # ffffffffc0207690 <commands+0xee0>
ffffffffc0202652:	bc5fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==5);
ffffffffc0202656:	00005697          	auipc	a3,0x5
ffffffffc020265a:	0f268693          	addi	a3,a3,242 # ffffffffc0207748 <commands+0xf98>
ffffffffc020265e:	00004617          	auipc	a2,0x4
ffffffffc0202662:	5d260613          	addi	a2,a2,1490 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202666:	06000593          	li	a1,96
ffffffffc020266a:	00005517          	auipc	a0,0x5
ffffffffc020266e:	02650513          	addi	a0,a0,38 # ffffffffc0207690 <commands+0xee0>
ffffffffc0202672:	ba5fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==5);
ffffffffc0202676:	00005697          	auipc	a3,0x5
ffffffffc020267a:	0d268693          	addi	a3,a3,210 # ffffffffc0207748 <commands+0xf98>
ffffffffc020267e:	00004617          	auipc	a2,0x4
ffffffffc0202682:	5b260613          	addi	a2,a2,1458 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202686:	05d00593          	li	a1,93
ffffffffc020268a:	00005517          	auipc	a0,0x5
ffffffffc020268e:	00650513          	addi	a0,a0,6 # ffffffffc0207690 <commands+0xee0>
ffffffffc0202692:	b85fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==4);
ffffffffc0202696:	00005697          	auipc	a3,0x5
ffffffffc020269a:	fea68693          	addi	a3,a3,-22 # ffffffffc0207680 <commands+0xed0>
ffffffffc020269e:	00004617          	auipc	a2,0x4
ffffffffc02026a2:	59260613          	addi	a2,a2,1426 # ffffffffc0206c30 <commands+0x480>
ffffffffc02026a6:	05a00593          	li	a1,90
ffffffffc02026aa:	00005517          	auipc	a0,0x5
ffffffffc02026ae:	fe650513          	addi	a0,a0,-26 # ffffffffc0207690 <commands+0xee0>
ffffffffc02026b2:	b65fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==4);
ffffffffc02026b6:	00005697          	auipc	a3,0x5
ffffffffc02026ba:	fca68693          	addi	a3,a3,-54 # ffffffffc0207680 <commands+0xed0>
ffffffffc02026be:	00004617          	auipc	a2,0x4
ffffffffc02026c2:	57260613          	addi	a2,a2,1394 # ffffffffc0206c30 <commands+0x480>
ffffffffc02026c6:	05700593          	li	a1,87
ffffffffc02026ca:	00005517          	auipc	a0,0x5
ffffffffc02026ce:	fc650513          	addi	a0,a0,-58 # ffffffffc0207690 <commands+0xee0>
ffffffffc02026d2:	b45fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==4);
ffffffffc02026d6:	00005697          	auipc	a3,0x5
ffffffffc02026da:	faa68693          	addi	a3,a3,-86 # ffffffffc0207680 <commands+0xed0>
ffffffffc02026de:	00004617          	auipc	a2,0x4
ffffffffc02026e2:	55260613          	addi	a2,a2,1362 # ffffffffc0206c30 <commands+0x480>
ffffffffc02026e6:	05400593          	li	a1,84
ffffffffc02026ea:	00005517          	auipc	a0,0x5
ffffffffc02026ee:	fa650513          	addi	a0,a0,-90 # ffffffffc0207690 <commands+0xee0>
ffffffffc02026f2:	b25fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02026f6 <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02026f6:	751c                	ld	a5,40(a0)
{
ffffffffc02026f8:	1141                	addi	sp,sp,-16
ffffffffc02026fa:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc02026fc:	cf91                	beqz	a5,ffffffffc0202718 <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc02026fe:	ee0d                	bnez	a2,ffffffffc0202738 <_fifo_swap_out_victim+0x42>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0202700:	679c                	ld	a5,8(a5)
}
ffffffffc0202702:	60a2                	ld	ra,8(sp)
ffffffffc0202704:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc0202706:	6394                	ld	a3,0(a5)
ffffffffc0202708:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc020270a:	fd878793          	addi	a5,a5,-40
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020270e:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0202710:	e314                	sd	a3,0(a4)
ffffffffc0202712:	e19c                	sd	a5,0(a1)
}
ffffffffc0202714:	0141                	addi	sp,sp,16
ffffffffc0202716:	8082                	ret
         assert(head != NULL);
ffffffffc0202718:	00005697          	auipc	a3,0x5
ffffffffc020271c:	0e868693          	addi	a3,a3,232 # ffffffffc0207800 <commands+0x1050>
ffffffffc0202720:	00004617          	auipc	a2,0x4
ffffffffc0202724:	51060613          	addi	a2,a2,1296 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202728:	04100593          	li	a1,65
ffffffffc020272c:	00005517          	auipc	a0,0x5
ffffffffc0202730:	f6450513          	addi	a0,a0,-156 # ffffffffc0207690 <commands+0xee0>
ffffffffc0202734:	ae3fd0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(in_tick==0);
ffffffffc0202738:	00005697          	auipc	a3,0x5
ffffffffc020273c:	0d868693          	addi	a3,a3,216 # ffffffffc0207810 <commands+0x1060>
ffffffffc0202740:	00004617          	auipc	a2,0x4
ffffffffc0202744:	4f060613          	addi	a2,a2,1264 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202748:	04200593          	li	a1,66
ffffffffc020274c:	00005517          	auipc	a0,0x5
ffffffffc0202750:	f4450513          	addi	a0,a0,-188 # ffffffffc0207690 <commands+0xee0>
ffffffffc0202754:	ac3fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202758 <_fifo_map_swappable>:
    list_entry_t *entry=&(page->pra_page_link);
ffffffffc0202758:	02860713          	addi	a4,a2,40
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc020275c:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc020275e:	cb09                	beqz	a4,ffffffffc0202770 <_fifo_map_swappable+0x18>
ffffffffc0202760:	cb81                	beqz	a5,ffffffffc0202770 <_fifo_map_swappable+0x18>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0202762:	6394                	ld	a3,0(a5)
    prev->next = next->prev = elm;
ffffffffc0202764:	e398                	sd	a4,0(a5)
}
ffffffffc0202766:	4501                	li	a0,0
ffffffffc0202768:	e698                	sd	a4,8(a3)
    elm->next = next;
ffffffffc020276a:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc020276c:	f614                	sd	a3,40(a2)
ffffffffc020276e:	8082                	ret
{
ffffffffc0202770:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0202772:	00005697          	auipc	a3,0x5
ffffffffc0202776:	06e68693          	addi	a3,a3,110 # ffffffffc02077e0 <commands+0x1030>
ffffffffc020277a:	00004617          	auipc	a2,0x4
ffffffffc020277e:	4b660613          	addi	a2,a2,1206 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202782:	03200593          	li	a1,50
ffffffffc0202786:	00005517          	auipc	a0,0x5
ffffffffc020278a:	f0a50513          	addi	a0,a0,-246 # ffffffffc0207690 <commands+0xee0>
{
ffffffffc020278e:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0202790:	a87fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202794 <check_vma_overlap.isra.0.part.1>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0202794:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202796:	00005697          	auipc	a3,0x5
ffffffffc020279a:	0a268693          	addi	a3,a3,162 # ffffffffc0207838 <commands+0x1088>
ffffffffc020279e:	00004617          	auipc	a2,0x4
ffffffffc02027a2:	49260613          	addi	a2,a2,1170 # ffffffffc0206c30 <commands+0x480>
ffffffffc02027a6:	06d00593          	li	a1,109
ffffffffc02027aa:	00005517          	auipc	a0,0x5
ffffffffc02027ae:	0ae50513          	addi	a0,a0,174 # ffffffffc0207858 <commands+0x10a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02027b2:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02027b4:	a63fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02027b8 <mm_create>:
mm_create(void) {
ffffffffc02027b8:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02027ba:	04000513          	li	a0,64
mm_create(void) {
ffffffffc02027be:	e022                	sd	s0,0(sp)
ffffffffc02027c0:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02027c2:	505000ef          	jal	ra,ffffffffc02034c6 <kmalloc>
ffffffffc02027c6:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc02027c8:	c515                	beqz	a0,ffffffffc02027f4 <mm_create+0x3c>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02027ca:	000aa797          	auipc	a5,0xaa
ffffffffc02027ce:	c5678793          	addi	a5,a5,-938 # ffffffffc02ac420 <swap_init_ok>
ffffffffc02027d2:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc02027d4:	e408                	sd	a0,8(s0)
ffffffffc02027d6:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc02027d8:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02027dc:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02027e0:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02027e4:	2781                	sext.w	a5,a5
ffffffffc02027e6:	ef81                	bnez	a5,ffffffffc02027fe <mm_create+0x46>
        else mm->sm_priv = NULL;
ffffffffc02027e8:	02053423          	sd	zero,40(a0)
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
ffffffffc02027ec:	02042823          	sw	zero,48(s0)

typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock) {
    *lock = 0;
ffffffffc02027f0:	02043c23          	sd	zero,56(s0)
}
ffffffffc02027f4:	8522                	mv	a0,s0
ffffffffc02027f6:	60a2                	ld	ra,8(sp)
ffffffffc02027f8:	6402                	ld	s0,0(sp)
ffffffffc02027fa:	0141                	addi	sp,sp,16
ffffffffc02027fc:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02027fe:	628010ef          	jal	ra,ffffffffc0203e26 <swap_init_mm>
ffffffffc0202802:	b7ed                	j	ffffffffc02027ec <mm_create+0x34>

ffffffffc0202804 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0202804:	1101                	addi	sp,sp,-32
ffffffffc0202806:	e04a                	sd	s2,0(sp)
ffffffffc0202808:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020280a:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc020280e:	e822                	sd	s0,16(sp)
ffffffffc0202810:	e426                	sd	s1,8(sp)
ffffffffc0202812:	ec06                	sd	ra,24(sp)
ffffffffc0202814:	84ae                	mv	s1,a1
ffffffffc0202816:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202818:	4af000ef          	jal	ra,ffffffffc02034c6 <kmalloc>
    if (vma != NULL) {
ffffffffc020281c:	c509                	beqz	a0,ffffffffc0202826 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc020281e:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202822:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202824:	cd00                	sw	s0,24(a0)
}
ffffffffc0202826:	60e2                	ld	ra,24(sp)
ffffffffc0202828:	6442                	ld	s0,16(sp)
ffffffffc020282a:	64a2                	ld	s1,8(sp)
ffffffffc020282c:	6902                	ld	s2,0(sp)
ffffffffc020282e:	6105                	addi	sp,sp,32
ffffffffc0202830:	8082                	ret

ffffffffc0202832 <find_vma>:
    if (mm != NULL) {
ffffffffc0202832:	c51d                	beqz	a0,ffffffffc0202860 <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc0202834:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0202836:	c781                	beqz	a5,ffffffffc020283e <find_vma+0xc>
ffffffffc0202838:	6798                	ld	a4,8(a5)
ffffffffc020283a:	02e5f663          	bleu	a4,a1,ffffffffc0202866 <find_vma+0x34>
                list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc020283e:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc0202840:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0202842:	00f50f63          	beq	a0,a5,ffffffffc0202860 <find_vma+0x2e>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0202846:	fe87b703          	ld	a4,-24(a5)
ffffffffc020284a:	fee5ebe3          	bltu	a1,a4,ffffffffc0202840 <find_vma+0xe>
ffffffffc020284e:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202852:	fee5f7e3          	bleu	a4,a1,ffffffffc0202840 <find_vma+0xe>
                    vma = le2vma(le, list_link);
ffffffffc0202856:	1781                	addi	a5,a5,-32
        if (vma != NULL) {
ffffffffc0202858:	c781                	beqz	a5,ffffffffc0202860 <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc020285a:	e91c                	sd	a5,16(a0)
}
ffffffffc020285c:	853e                	mv	a0,a5
ffffffffc020285e:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc0202860:	4781                	li	a5,0
}
ffffffffc0202862:	853e                	mv	a0,a5
ffffffffc0202864:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0202866:	6b98                	ld	a4,16(a5)
ffffffffc0202868:	fce5fbe3          	bleu	a4,a1,ffffffffc020283e <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc020286c:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc020286e:	b7fd                	j	ffffffffc020285c <find_vma+0x2a>

ffffffffc0202870 <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202870:	6590                	ld	a2,8(a1)
ffffffffc0202872:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0202876:	1141                	addi	sp,sp,-16
ffffffffc0202878:	e406                	sd	ra,8(sp)
ffffffffc020287a:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020287c:	01066863          	bltu	a2,a6,ffffffffc020288c <insert_vma_struct+0x1c>
ffffffffc0202880:	a8b9                	j	ffffffffc02028de <insert_vma_struct+0x6e>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0202882:	fe87b683          	ld	a3,-24(a5)
ffffffffc0202886:	04d66763          	bltu	a2,a3,ffffffffc02028d4 <insert_vma_struct+0x64>
ffffffffc020288a:	873e                	mv	a4,a5
ffffffffc020288c:	671c                	ld	a5,8(a4)
        while ((le = list_next(le)) != list) {
ffffffffc020288e:	fef51ae3          	bne	a0,a5,ffffffffc0202882 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0202892:	02a70463          	beq	a4,a0,ffffffffc02028ba <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202896:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020289a:	fe873883          	ld	a7,-24(a4)
ffffffffc020289e:	08d8f063          	bleu	a3,a7,ffffffffc020291e <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02028a2:	04d66e63          	bltu	a2,a3,ffffffffc02028fe <insert_vma_struct+0x8e>
    }
    if (le_next != list) {
ffffffffc02028a6:	00f50a63          	beq	a0,a5,ffffffffc02028ba <insert_vma_struct+0x4a>
ffffffffc02028aa:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02028ae:	0506e863          	bltu	a3,a6,ffffffffc02028fe <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02028b2:	ff07b603          	ld	a2,-16(a5)
ffffffffc02028b6:	02c6f263          	bleu	a2,a3,ffffffffc02028da <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc02028ba:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc02028bc:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02028be:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02028c2:	e390                	sd	a2,0(a5)
ffffffffc02028c4:	e710                	sd	a2,8(a4)
}
ffffffffc02028c6:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02028c8:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02028ca:	f198                	sd	a4,32(a1)
    mm->map_count ++;
ffffffffc02028cc:	2685                	addiw	a3,a3,1
ffffffffc02028ce:	d114                	sw	a3,32(a0)
}
ffffffffc02028d0:	0141                	addi	sp,sp,16
ffffffffc02028d2:	8082                	ret
    if (le_prev != list) {
ffffffffc02028d4:	fca711e3          	bne	a4,a0,ffffffffc0202896 <insert_vma_struct+0x26>
ffffffffc02028d8:	bfd9                	j	ffffffffc02028ae <insert_vma_struct+0x3e>
ffffffffc02028da:	ebbff0ef          	jal	ra,ffffffffc0202794 <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02028de:	00005697          	auipc	a3,0x5
ffffffffc02028e2:	06a68693          	addi	a3,a3,106 # ffffffffc0207948 <commands+0x1198>
ffffffffc02028e6:	00004617          	auipc	a2,0x4
ffffffffc02028ea:	34a60613          	addi	a2,a2,842 # ffffffffc0206c30 <commands+0x480>
ffffffffc02028ee:	07400593          	li	a1,116
ffffffffc02028f2:	00005517          	auipc	a0,0x5
ffffffffc02028f6:	f6650513          	addi	a0,a0,-154 # ffffffffc0207858 <commands+0x10a8>
ffffffffc02028fa:	91dfd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02028fe:	00005697          	auipc	a3,0x5
ffffffffc0202902:	08a68693          	addi	a3,a3,138 # ffffffffc0207988 <commands+0x11d8>
ffffffffc0202906:	00004617          	auipc	a2,0x4
ffffffffc020290a:	32a60613          	addi	a2,a2,810 # ffffffffc0206c30 <commands+0x480>
ffffffffc020290e:	06c00593          	li	a1,108
ffffffffc0202912:	00005517          	auipc	a0,0x5
ffffffffc0202916:	f4650513          	addi	a0,a0,-186 # ffffffffc0207858 <commands+0x10a8>
ffffffffc020291a:	8fdfd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020291e:	00005697          	auipc	a3,0x5
ffffffffc0202922:	04a68693          	addi	a3,a3,74 # ffffffffc0207968 <commands+0x11b8>
ffffffffc0202926:	00004617          	auipc	a2,0x4
ffffffffc020292a:	30a60613          	addi	a2,a2,778 # ffffffffc0206c30 <commands+0x480>
ffffffffc020292e:	06b00593          	li	a1,107
ffffffffc0202932:	00005517          	auipc	a0,0x5
ffffffffc0202936:	f2650513          	addi	a0,a0,-218 # ffffffffc0207858 <commands+0x10a8>
ffffffffc020293a:	8ddfd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020293e <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);
ffffffffc020293e:	591c                	lw	a5,48(a0)
mm_destroy(struct mm_struct *mm) {
ffffffffc0202940:	1141                	addi	sp,sp,-16
ffffffffc0202942:	e406                	sd	ra,8(sp)
ffffffffc0202944:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0202946:	e78d                	bnez	a5,ffffffffc0202970 <mm_destroy+0x32>
ffffffffc0202948:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc020294a:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc020294c:	00a40c63          	beq	s0,a0,ffffffffc0202964 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0202950:	6118                	ld	a4,0(a0)
ffffffffc0202952:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0202954:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0202956:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202958:	e398                	sd	a4,0(a5)
ffffffffc020295a:	429000ef          	jal	ra,ffffffffc0203582 <kfree>
    return listelm->next;
ffffffffc020295e:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0202960:	fea418e3          	bne	s0,a0,ffffffffc0202950 <mm_destroy+0x12>
    }
    kfree(mm); //kfree mm
ffffffffc0202964:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0202966:	6402                	ld	s0,0(sp)
ffffffffc0202968:	60a2                	ld	ra,8(sp)
ffffffffc020296a:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc020296c:	4170006f          	j	ffffffffc0203582 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0202970:	00005697          	auipc	a3,0x5
ffffffffc0202974:	03868693          	addi	a3,a3,56 # ffffffffc02079a8 <commands+0x11f8>
ffffffffc0202978:	00004617          	auipc	a2,0x4
ffffffffc020297c:	2b860613          	addi	a2,a2,696 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202980:	09400593          	li	a1,148
ffffffffc0202984:	00005517          	auipc	a0,0x5
ffffffffc0202988:	ed450513          	addi	a0,a0,-300 # ffffffffc0207858 <commands+0x10a8>
ffffffffc020298c:	88bfd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202990 <mm_map>:

int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
       struct vma_struct **vma_store) {
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0202990:	6785                	lui	a5,0x1
       struct vma_struct **vma_store) {
ffffffffc0202992:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0202994:	17fd                	addi	a5,a5,-1
ffffffffc0202996:	787d                	lui	a6,0xfffff
       struct vma_struct **vma_store) {
ffffffffc0202998:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020299a:	00f60433          	add	s0,a2,a5
       struct vma_struct **vma_store) {
ffffffffc020299e:	f426                	sd	s1,40(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02029a0:	942e                	add	s0,s0,a1
       struct vma_struct **vma_store) {
ffffffffc02029a2:	fc06                	sd	ra,56(sp)
ffffffffc02029a4:	f04a                	sd	s2,32(sp)
ffffffffc02029a6:	ec4e                	sd	s3,24(sp)
ffffffffc02029a8:	e852                	sd	s4,16(sp)
ffffffffc02029aa:	e456                	sd	s5,8(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02029ac:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end)) {
ffffffffc02029b0:	002007b7          	lui	a5,0x200
ffffffffc02029b4:	01047433          	and	s0,s0,a6
ffffffffc02029b8:	06f4e363          	bltu	s1,a5,ffffffffc0202a1e <mm_map+0x8e>
ffffffffc02029bc:	0684f163          	bleu	s0,s1,ffffffffc0202a1e <mm_map+0x8e>
ffffffffc02029c0:	4785                	li	a5,1
ffffffffc02029c2:	07fe                	slli	a5,a5,0x1f
ffffffffc02029c4:	0487ed63          	bltu	a5,s0,ffffffffc0202a1e <mm_map+0x8e>
ffffffffc02029c8:	89aa                	mv	s3,a0
ffffffffc02029ca:	8a3a                	mv	s4,a4
ffffffffc02029cc:	8ab6                	mv	s5,a3
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc02029ce:	c931                	beqz	a0,ffffffffc0202a22 <mm_map+0x92>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
ffffffffc02029d0:	85a6                	mv	a1,s1
ffffffffc02029d2:	e61ff0ef          	jal	ra,ffffffffc0202832 <find_vma>
ffffffffc02029d6:	c501                	beqz	a0,ffffffffc02029de <mm_map+0x4e>
ffffffffc02029d8:	651c                	ld	a5,8(a0)
ffffffffc02029da:	0487e263          	bltu	a5,s0,ffffffffc0202a1e <mm_map+0x8e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02029de:	03000513          	li	a0,48
ffffffffc02029e2:	2e5000ef          	jal	ra,ffffffffc02034c6 <kmalloc>
ffffffffc02029e6:	892a                	mv	s2,a0
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02029e8:	5571                	li	a0,-4
    if (vma != NULL) {
ffffffffc02029ea:	02090163          	beqz	s2,ffffffffc0202a0c <mm_map+0x7c>

    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02029ee:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02029f0:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02029f4:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02029f8:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02029fc:	85ca                	mv	a1,s2
ffffffffc02029fe:	e73ff0ef          	jal	ra,ffffffffc0202870 <insert_vma_struct>
    if (vma_store != NULL) {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0202a02:	4501                	li	a0,0
    if (vma_store != NULL) {
ffffffffc0202a04:	000a0463          	beqz	s4,ffffffffc0202a0c <mm_map+0x7c>
        *vma_store = vma;
ffffffffc0202a08:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc0202a0c:	70e2                	ld	ra,56(sp)
ffffffffc0202a0e:	7442                	ld	s0,48(sp)
ffffffffc0202a10:	74a2                	ld	s1,40(sp)
ffffffffc0202a12:	7902                	ld	s2,32(sp)
ffffffffc0202a14:	69e2                	ld	s3,24(sp)
ffffffffc0202a16:	6a42                	ld	s4,16(sp)
ffffffffc0202a18:	6aa2                	ld	s5,8(sp)
ffffffffc0202a1a:	6121                	addi	sp,sp,64
ffffffffc0202a1c:	8082                	ret
        return -E_INVAL;
ffffffffc0202a1e:	5575                	li	a0,-3
ffffffffc0202a20:	b7f5                	j	ffffffffc0202a0c <mm_map+0x7c>
    assert(mm != NULL);
ffffffffc0202a22:	00005697          	auipc	a3,0x5
ffffffffc0202a26:	f9e68693          	addi	a3,a3,-98 # ffffffffc02079c0 <commands+0x1210>
ffffffffc0202a2a:	00004617          	auipc	a2,0x4
ffffffffc0202a2e:	20660613          	addi	a2,a2,518 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202a32:	0a700593          	li	a1,167
ffffffffc0202a36:	00005517          	auipc	a0,0x5
ffffffffc0202a3a:	e2250513          	addi	a0,a0,-478 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202a3e:	fd8fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202a42 <dup_mmap>:

//接下来，它会调用copy_range函数，将源进程中对应内存映射区域的内容复制到目标进程中。如果复制过程中出现内存不足的情况，将返回-E_NO_MEM错误。

//最后，dup_mmap函数将遍历完成后返回0，表示复制内存映射区域的操作成功完成。
int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
ffffffffc0202a42:	7139                	addi	sp,sp,-64
ffffffffc0202a44:	fc06                	sd	ra,56(sp)
ffffffffc0202a46:	f822                	sd	s0,48(sp)
ffffffffc0202a48:	f426                	sd	s1,40(sp)
ffffffffc0202a4a:	f04a                	sd	s2,32(sp)
ffffffffc0202a4c:	ec4e                	sd	s3,24(sp)
ffffffffc0202a4e:	e852                	sd	s4,16(sp)
ffffffffc0202a50:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0202a52:	c535                	beqz	a0,ffffffffc0202abe <dup_mmap+0x7c>
ffffffffc0202a54:	892a                	mv	s2,a0
ffffffffc0202a56:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0202a58:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0202a5a:	e59d                	bnez	a1,ffffffffc0202a88 <dup_mmap+0x46>
ffffffffc0202a5c:	a08d                	j	ffffffffc0202abe <dup_mmap+0x7c>
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0202a5e:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0202a60:	0157b423          	sd	s5,8(a5) # 200008 <_binary_obj___user_exit_out_size+0x1f5590>
        insert_vma_struct(to, nvma);
ffffffffc0202a64:	854a                	mv	a0,s2
        vma->vm_end = vm_end;
ffffffffc0202a66:	0147b823          	sd	s4,16(a5)
        vma->vm_flags = vm_flags;
ffffffffc0202a6a:	0137ac23          	sw	s3,24(a5)
        insert_vma_struct(to, nvma);
ffffffffc0202a6e:	e03ff0ef          	jal	ra,ffffffffc0202870 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
ffffffffc0202a72:	ff043683          	ld	a3,-16(s0)
ffffffffc0202a76:	fe843603          	ld	a2,-24(s0)
ffffffffc0202a7a:	6c8c                	ld	a1,24(s1)
ffffffffc0202a7c:	01893503          	ld	a0,24(s2)
ffffffffc0202a80:	4701                	li	a4,0
ffffffffc0202a82:	e5cff0ef          	jal	ra,ffffffffc02020de <copy_range>
ffffffffc0202a86:	e105                	bnez	a0,ffffffffc0202aa6 <dup_mmap+0x64>
    return listelm->prev;
ffffffffc0202a88:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list) {
ffffffffc0202a8a:	02848863          	beq	s1,s0,ffffffffc0202aba <dup_mmap+0x78>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202a8e:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0202a92:	fe843a83          	ld	s5,-24(s0)
ffffffffc0202a96:	ff043a03          	ld	s4,-16(s0)
ffffffffc0202a9a:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202a9e:	229000ef          	jal	ra,ffffffffc02034c6 <kmalloc>
ffffffffc0202aa2:	87aa                	mv	a5,a0
    if (vma != NULL) {
ffffffffc0202aa4:	fd4d                	bnez	a0,ffffffffc0202a5e <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0202aa6:	5571                	li	a0,-4
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0202aa8:	70e2                	ld	ra,56(sp)
ffffffffc0202aaa:	7442                	ld	s0,48(sp)
ffffffffc0202aac:	74a2                	ld	s1,40(sp)
ffffffffc0202aae:	7902                	ld	s2,32(sp)
ffffffffc0202ab0:	69e2                	ld	s3,24(sp)
ffffffffc0202ab2:	6a42                	ld	s4,16(sp)
ffffffffc0202ab4:	6aa2                	ld	s5,8(sp)
ffffffffc0202ab6:	6121                	addi	sp,sp,64
ffffffffc0202ab8:	8082                	ret
    return 0;
ffffffffc0202aba:	4501                	li	a0,0
ffffffffc0202abc:	b7f5                	j	ffffffffc0202aa8 <dup_mmap+0x66>
    assert(to != NULL && from != NULL);
ffffffffc0202abe:	00005697          	auipc	a3,0x5
ffffffffc0202ac2:	e4a68693          	addi	a3,a3,-438 # ffffffffc0207908 <commands+0x1158>
ffffffffc0202ac6:	00004617          	auipc	a2,0x4
ffffffffc0202aca:	16a60613          	addi	a2,a2,362 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202ace:	0c700593          	li	a1,199
ffffffffc0202ad2:	00005517          	auipc	a0,0x5
ffffffffc0202ad6:	d8650513          	addi	a0,a0,-634 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202ada:	f3cfd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202ade <exit_mmap>:

void
exit_mmap(struct mm_struct *mm) {
ffffffffc0202ade:	1101                	addi	sp,sp,-32
ffffffffc0202ae0:	ec06                	sd	ra,24(sp)
ffffffffc0202ae2:	e822                	sd	s0,16(sp)
ffffffffc0202ae4:	e426                	sd	s1,8(sp)
ffffffffc0202ae6:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0202ae8:	c531                	beqz	a0,ffffffffc0202b34 <exit_mmap+0x56>
ffffffffc0202aea:	591c                	lw	a5,48(a0)
ffffffffc0202aec:	84aa                	mv	s1,a0
ffffffffc0202aee:	e3b9                	bnez	a5,ffffffffc0202b34 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0202af0:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0202af2:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list) {
ffffffffc0202af6:	02850663          	beq	a0,s0,ffffffffc0202b22 <exit_mmap+0x44>
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0202afa:	ff043603          	ld	a2,-16(s0)
ffffffffc0202afe:	fe843583          	ld	a1,-24(s0)
ffffffffc0202b02:	854a                	mv	a0,s2
ffffffffc0202b04:	eb0fe0ef          	jal	ra,ffffffffc02011b4 <unmap_range>
ffffffffc0202b08:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0202b0a:	fe8498e3          	bne	s1,s0,ffffffffc0202afa <exit_mmap+0x1c>
ffffffffc0202b0e:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list) {
ffffffffc0202b10:	00848c63          	beq	s1,s0,ffffffffc0202b28 <exit_mmap+0x4a>
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0202b14:	ff043603          	ld	a2,-16(s0)
ffffffffc0202b18:	fe843583          	ld	a1,-24(s0)
ffffffffc0202b1c:	854a                	mv	a0,s2
ffffffffc0202b1e:	faefe0ef          	jal	ra,ffffffffc02012cc <exit_range>
ffffffffc0202b22:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0202b24:	fe8498e3          	bne	s1,s0,ffffffffc0202b14 <exit_mmap+0x36>
    }
}
ffffffffc0202b28:	60e2                	ld	ra,24(sp)
ffffffffc0202b2a:	6442                	ld	s0,16(sp)
ffffffffc0202b2c:	64a2                	ld	s1,8(sp)
ffffffffc0202b2e:	6902                	ld	s2,0(sp)
ffffffffc0202b30:	6105                	addi	sp,sp,32
ffffffffc0202b32:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0202b34:	00005697          	auipc	a3,0x5
ffffffffc0202b38:	df468693          	addi	a3,a3,-524 # ffffffffc0207928 <commands+0x1178>
ffffffffc0202b3c:	00004617          	auipc	a2,0x4
ffffffffc0202b40:	0f460613          	addi	a2,a2,244 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202b44:	0dd00593          	li	a1,221
ffffffffc0202b48:	00005517          	auipc	a0,0x5
ffffffffc0202b4c:	d1050513          	addi	a0,a0,-752 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202b50:	ec6fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202b54 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0202b54:	7139                	addi	sp,sp,-64
ffffffffc0202b56:	f822                	sd	s0,48(sp)
ffffffffc0202b58:	f426                	sd	s1,40(sp)
ffffffffc0202b5a:	fc06                	sd	ra,56(sp)
ffffffffc0202b5c:	f04a                	sd	s2,32(sp)
ffffffffc0202b5e:	ec4e                	sd	s3,24(sp)
ffffffffc0202b60:	e852                	sd	s4,16(sp)
ffffffffc0202b62:	e456                	sd	s5,8(sp)

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc0202b64:	c55ff0ef          	jal	ra,ffffffffc02027b8 <mm_create>
    assert(mm != NULL);
ffffffffc0202b68:	842a                	mv	s0,a0
ffffffffc0202b6a:	03200493          	li	s1,50
ffffffffc0202b6e:	e919                	bnez	a0,ffffffffc0202b84 <vmm_init+0x30>
ffffffffc0202b70:	a989                	j	ffffffffc0202fc2 <vmm_init+0x46e>
        vma->vm_start = vm_start;
ffffffffc0202b72:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202b74:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202b76:	00052c23          	sw	zero,24(a0)

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202b7a:	14ed                	addi	s1,s1,-5
ffffffffc0202b7c:	8522                	mv	a0,s0
ffffffffc0202b7e:	cf3ff0ef          	jal	ra,ffffffffc0202870 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0202b82:	c88d                	beqz	s1,ffffffffc0202bb4 <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202b84:	03000513          	li	a0,48
ffffffffc0202b88:	13f000ef          	jal	ra,ffffffffc02034c6 <kmalloc>
ffffffffc0202b8c:	85aa                	mv	a1,a0
ffffffffc0202b8e:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0202b92:	f165                	bnez	a0,ffffffffc0202b72 <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc0202b94:	00005697          	auipc	a3,0x5
ffffffffc0202b98:	05468693          	addi	a3,a3,84 # ffffffffc0207be8 <commands+0x1438>
ffffffffc0202b9c:	00004617          	auipc	a2,0x4
ffffffffc0202ba0:	09460613          	addi	a2,a2,148 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202ba4:	11a00593          	li	a1,282
ffffffffc0202ba8:	00005517          	auipc	a0,0x5
ffffffffc0202bac:	cb050513          	addi	a0,a0,-848 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202bb0:	e66fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    for (i = step1; i >= 1; i --) {
ffffffffc0202bb4:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0202bb8:	1f900913          	li	s2,505
ffffffffc0202bbc:	a819                	j	ffffffffc0202bd2 <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc0202bbe:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202bc0:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202bc2:	00052c23          	sw	zero,24(a0)
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202bc6:	0495                	addi	s1,s1,5
ffffffffc0202bc8:	8522                	mv	a0,s0
ffffffffc0202bca:	ca7ff0ef          	jal	ra,ffffffffc0202870 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0202bce:	03248a63          	beq	s1,s2,ffffffffc0202c02 <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202bd2:	03000513          	li	a0,48
ffffffffc0202bd6:	0f1000ef          	jal	ra,ffffffffc02034c6 <kmalloc>
ffffffffc0202bda:	85aa                	mv	a1,a0
ffffffffc0202bdc:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0202be0:	fd79                	bnez	a0,ffffffffc0202bbe <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc0202be2:	00005697          	auipc	a3,0x5
ffffffffc0202be6:	00668693          	addi	a3,a3,6 # ffffffffc0207be8 <commands+0x1438>
ffffffffc0202bea:	00004617          	auipc	a2,0x4
ffffffffc0202bee:	04660613          	addi	a2,a2,70 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202bf2:	12000593          	li	a1,288
ffffffffc0202bf6:	00005517          	auipc	a0,0x5
ffffffffc0202bfa:	c6250513          	addi	a0,a0,-926 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202bfe:	e18fd0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0202c02:	6418                	ld	a4,8(s0)
ffffffffc0202c04:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc0202c06:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0202c0a:	2ee40063          	beq	s0,a4,ffffffffc0202eea <vmm_init+0x396>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202c0e:	fe873603          	ld	a2,-24(a4)
ffffffffc0202c12:	ffe78693          	addi	a3,a5,-2
ffffffffc0202c16:	24d61a63          	bne	a2,a3,ffffffffc0202e6a <vmm_init+0x316>
ffffffffc0202c1a:	ff073683          	ld	a3,-16(a4)
ffffffffc0202c1e:	24f69663          	bne	a3,a5,ffffffffc0202e6a <vmm_init+0x316>
ffffffffc0202c22:	0795                	addi	a5,a5,5
ffffffffc0202c24:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i ++) {
ffffffffc0202c26:	feb792e3          	bne	a5,a1,ffffffffc0202c0a <vmm_init+0xb6>
ffffffffc0202c2a:	491d                	li	s2,7
ffffffffc0202c2c:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0202c2e:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202c32:	85a6                	mv	a1,s1
ffffffffc0202c34:	8522                	mv	a0,s0
ffffffffc0202c36:	bfdff0ef          	jal	ra,ffffffffc0202832 <find_vma>
ffffffffc0202c3a:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0202c3c:	30050763          	beqz	a0,ffffffffc0202f4a <vmm_init+0x3f6>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0202c40:	00148593          	addi	a1,s1,1
ffffffffc0202c44:	8522                	mv	a0,s0
ffffffffc0202c46:	bedff0ef          	jal	ra,ffffffffc0202832 <find_vma>
ffffffffc0202c4a:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202c4c:	2c050f63          	beqz	a0,ffffffffc0202f2a <vmm_init+0x3d6>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0202c50:	85ca                	mv	a1,s2
ffffffffc0202c52:	8522                	mv	a0,s0
ffffffffc0202c54:	bdfff0ef          	jal	ra,ffffffffc0202832 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202c58:	2a051963          	bnez	a0,ffffffffc0202f0a <vmm_init+0x3b6>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0202c5c:	00348593          	addi	a1,s1,3
ffffffffc0202c60:	8522                	mv	a0,s0
ffffffffc0202c62:	bd1ff0ef          	jal	ra,ffffffffc0202832 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202c66:	32051263          	bnez	a0,ffffffffc0202f8a <vmm_init+0x436>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0202c6a:	00448593          	addi	a1,s1,4
ffffffffc0202c6e:	8522                	mv	a0,s0
ffffffffc0202c70:	bc3ff0ef          	jal	ra,ffffffffc0202832 <find_vma>
        assert(vma5 == NULL);
ffffffffc0202c74:	2e051b63          	bnez	a0,ffffffffc0202f6a <vmm_init+0x416>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0202c78:	008a3783          	ld	a5,8(s4)
ffffffffc0202c7c:	20979763          	bne	a5,s1,ffffffffc0202e8a <vmm_init+0x336>
ffffffffc0202c80:	010a3783          	ld	a5,16(s4)
ffffffffc0202c84:	21279363          	bne	a5,s2,ffffffffc0202e8a <vmm_init+0x336>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0202c88:	0089b783          	ld	a5,8(s3)
ffffffffc0202c8c:	20979f63          	bne	a5,s1,ffffffffc0202eaa <vmm_init+0x356>
ffffffffc0202c90:	0109b783          	ld	a5,16(s3)
ffffffffc0202c94:	21279b63          	bne	a5,s2,ffffffffc0202eaa <vmm_init+0x356>
ffffffffc0202c98:	0495                	addi	s1,s1,5
ffffffffc0202c9a:	0915                	addi	s2,s2,5
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0202c9c:	f9549be3          	bne	s1,s5,ffffffffc0202c32 <vmm_init+0xde>
ffffffffc0202ca0:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0202ca2:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0202ca4:	85a6                	mv	a1,s1
ffffffffc0202ca6:	8522                	mv	a0,s0
ffffffffc0202ca8:	b8bff0ef          	jal	ra,ffffffffc0202832 <find_vma>
ffffffffc0202cac:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL ) {
ffffffffc0202cb0:	c90d                	beqz	a0,ffffffffc0202ce2 <vmm_init+0x18e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0202cb2:	6914                	ld	a3,16(a0)
ffffffffc0202cb4:	6510                	ld	a2,8(a0)
ffffffffc0202cb6:	00005517          	auipc	a0,0x5
ffffffffc0202cba:	e1a50513          	addi	a0,a0,-486 # ffffffffc0207ad0 <commands+0x1320>
ffffffffc0202cbe:	c12fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0202cc2:	00005697          	auipc	a3,0x5
ffffffffc0202cc6:	e3668693          	addi	a3,a3,-458 # ffffffffc0207af8 <commands+0x1348>
ffffffffc0202cca:	00004617          	auipc	a2,0x4
ffffffffc0202cce:	f6660613          	addi	a2,a2,-154 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202cd2:	14200593          	li	a1,322
ffffffffc0202cd6:	00005517          	auipc	a0,0x5
ffffffffc0202cda:	b8250513          	addi	a0,a0,-1150 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202cde:	d38fd0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0202ce2:	14fd                	addi	s1,s1,-1
    for (i =4; i>=0; i--) {
ffffffffc0202ce4:	fd2490e3          	bne	s1,s2,ffffffffc0202ca4 <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc0202ce8:	8522                	mv	a0,s0
ffffffffc0202cea:	c55ff0ef          	jal	ra,ffffffffc020293e <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0202cee:	00005517          	auipc	a0,0x5
ffffffffc0202cf2:	e2250513          	addi	a0,a0,-478 # ffffffffc0207b10 <commands+0x1360>
ffffffffc0202cf6:	bdafd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0202cfa:	a46fe0ef          	jal	ra,ffffffffc0200f40 <nr_free_pages>
ffffffffc0202cfe:	89aa                	mv	s3,a0

    check_mm_struct = mm_create();
ffffffffc0202d00:	ab9ff0ef          	jal	ra,ffffffffc02027b8 <mm_create>
ffffffffc0202d04:	000a9797          	auipc	a5,0xa9
ffffffffc0202d08:	76a7be23          	sd	a0,1916(a5) # ffffffffc02ac480 <check_mm_struct>
ffffffffc0202d0c:	84aa                	mv	s1,a0
    assert(check_mm_struct != NULL);
ffffffffc0202d0e:	36050663          	beqz	a0,ffffffffc020307a <vmm_init+0x526>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202d12:	000a9797          	auipc	a5,0xa9
ffffffffc0202d16:	6e678793          	addi	a5,a5,1766 # ffffffffc02ac3f8 <boot_pgdir>
ffffffffc0202d1a:	0007b903          	ld	s2,0(a5)
    assert(pgdir[0] == 0);
ffffffffc0202d1e:	00093783          	ld	a5,0(s2)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202d22:	01253c23          	sd	s2,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0202d26:	2c079e63          	bnez	a5,ffffffffc0203002 <vmm_init+0x4ae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202d2a:	03000513          	li	a0,48
ffffffffc0202d2e:	798000ef          	jal	ra,ffffffffc02034c6 <kmalloc>
ffffffffc0202d32:	842a                	mv	s0,a0
    if (vma != NULL) {
ffffffffc0202d34:	18050b63          	beqz	a0,ffffffffc0202eca <vmm_init+0x376>
        vma->vm_end = vm_end;
ffffffffc0202d38:	002007b7          	lui	a5,0x200
ffffffffc0202d3c:	e81c                	sd	a5,16(s0)
        vma->vm_flags = vm_flags;
ffffffffc0202d3e:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0202d40:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0202d42:	cc1c                	sw	a5,24(s0)
    insert_vma_struct(mm, vma);
ffffffffc0202d44:	8526                	mv	a0,s1
        vma->vm_start = vm_start;
ffffffffc0202d46:	00043423          	sd	zero,8(s0)
    insert_vma_struct(mm, vma);
ffffffffc0202d4a:	b27ff0ef          	jal	ra,ffffffffc0202870 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0202d4e:	10000593          	li	a1,256
ffffffffc0202d52:	8526                	mv	a0,s1
ffffffffc0202d54:	adfff0ef          	jal	ra,ffffffffc0202832 <find_vma>
ffffffffc0202d58:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
ffffffffc0202d5c:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0202d60:	2ca41163          	bne	s0,a0,ffffffffc0203022 <vmm_init+0x4ce>
        *(char *)(addr + i) = i;
ffffffffc0202d64:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f5588>
        sum += i;
ffffffffc0202d68:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i ++) {
ffffffffc0202d6a:	fee79de3          	bne	a5,a4,ffffffffc0202d64 <vmm_init+0x210>
        sum += i;
ffffffffc0202d6e:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i ++) {
ffffffffc0202d70:	10000793          	li	a5,256
        sum += i;
ffffffffc0202d74:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_faultread_out_size-0x821a>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0202d78:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0202d7c:	0007c683          	lbu	a3,0(a5)
ffffffffc0202d80:	0785                	addi	a5,a5,1
ffffffffc0202d82:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0202d84:	fec79ce3          	bne	a5,a2,ffffffffc0202d7c <vmm_init+0x228>
    }

    assert(sum == 0);
ffffffffc0202d88:	2c071963          	bnez	a4,ffffffffc020305a <vmm_init+0x506>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d8c:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202d90:	000a9a97          	auipc	s5,0xa9
ffffffffc0202d94:	670a8a93          	addi	s5,s5,1648 # ffffffffc02ac400 <npage>
ffffffffc0202d98:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d9c:	078a                	slli	a5,a5,0x2
ffffffffc0202d9e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202da0:	20e7f563          	bleu	a4,a5,ffffffffc0202faa <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc0202da4:	00006697          	auipc	a3,0x6
ffffffffc0202da8:	fc468693          	addi	a3,a3,-60 # ffffffffc0208d68 <nbase>
ffffffffc0202dac:	0006ba03          	ld	s4,0(a3)
ffffffffc0202db0:	414786b3          	sub	a3,a5,s4
ffffffffc0202db4:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0202db6:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202db8:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0202dba:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc0202dbc:	83b1                	srli	a5,a5,0xc
ffffffffc0202dbe:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202dc0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202dc2:	28e7f063          	bleu	a4,a5,ffffffffc0203042 <vmm_init+0x4ee>
ffffffffc0202dc6:	000a9797          	auipc	a5,0xa9
ffffffffc0202dca:	69278793          	addi	a5,a5,1682 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0202dce:	6380                	ld	s0,0(a5)

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0202dd0:	4581                	li	a1,0
ffffffffc0202dd2:	854a                	mv	a0,s2
ffffffffc0202dd4:	9436                	add	s0,s0,a3
ffffffffc0202dd6:	f4cfe0ef          	jal	ra,ffffffffc0201522 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202dda:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202ddc:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202de0:	078a                	slli	a5,a5,0x2
ffffffffc0202de2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202de4:	1ce7f363          	bleu	a4,a5,ffffffffc0202faa <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc0202de8:	000a9417          	auipc	s0,0xa9
ffffffffc0202dec:	68040413          	addi	s0,s0,1664 # ffffffffc02ac468 <pages>
ffffffffc0202df0:	6008                	ld	a0,0(s0)
ffffffffc0202df2:	414787b3          	sub	a5,a5,s4
ffffffffc0202df6:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0202df8:	953e                	add	a0,a0,a5
ffffffffc0202dfa:	4585                	li	a1,1
ffffffffc0202dfc:	8fefe0ef          	jal	ra,ffffffffc0200efa <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e00:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202e04:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e08:	078a                	slli	a5,a5,0x2
ffffffffc0202e0a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202e0c:	18e7ff63          	bleu	a4,a5,ffffffffc0202faa <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e10:	6008                	ld	a0,0(s0)
ffffffffc0202e12:	414787b3          	sub	a5,a5,s4
ffffffffc0202e16:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0202e18:	4585                	li	a1,1
ffffffffc0202e1a:	953e                	add	a0,a0,a5
ffffffffc0202e1c:	8defe0ef          	jal	ra,ffffffffc0200efa <free_pages>
    pgdir[0] = 0;
ffffffffc0202e20:	00093023          	sd	zero,0(s2)
  asm volatile("sfence.vma");
ffffffffc0202e24:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc0202e28:	0004bc23          	sd	zero,24(s1)
    mm_destroy(mm);
ffffffffc0202e2c:	8526                	mv	a0,s1
ffffffffc0202e2e:	b11ff0ef          	jal	ra,ffffffffc020293e <mm_destroy>
    check_mm_struct = NULL;
ffffffffc0202e32:	000a9797          	auipc	a5,0xa9
ffffffffc0202e36:	6407b723          	sd	zero,1614(a5) # ffffffffc02ac480 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202e3a:	906fe0ef          	jal	ra,ffffffffc0200f40 <nr_free_pages>
ffffffffc0202e3e:	1aa99263          	bne	s3,a0,ffffffffc0202fe2 <vmm_init+0x48e>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0202e42:	00005517          	auipc	a0,0x5
ffffffffc0202e46:	d6e50513          	addi	a0,a0,-658 # ffffffffc0207bb0 <commands+0x1400>
ffffffffc0202e4a:	a86fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
}
ffffffffc0202e4e:	7442                	ld	s0,48(sp)
ffffffffc0202e50:	70e2                	ld	ra,56(sp)
ffffffffc0202e52:	74a2                	ld	s1,40(sp)
ffffffffc0202e54:	7902                	ld	s2,32(sp)
ffffffffc0202e56:	69e2                	ld	s3,24(sp)
ffffffffc0202e58:	6a42                	ld	s4,16(sp)
ffffffffc0202e5a:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202e5c:	00005517          	auipc	a0,0x5
ffffffffc0202e60:	d7450513          	addi	a0,a0,-652 # ffffffffc0207bd0 <commands+0x1420>
}
ffffffffc0202e64:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202e66:	a6afd06f          	j	ffffffffc02000d0 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202e6a:	00005697          	auipc	a3,0x5
ffffffffc0202e6e:	b7e68693          	addi	a3,a3,-1154 # ffffffffc02079e8 <commands+0x1238>
ffffffffc0202e72:	00004617          	auipc	a2,0x4
ffffffffc0202e76:	dbe60613          	addi	a2,a2,-578 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202e7a:	12900593          	li	a1,297
ffffffffc0202e7e:	00005517          	auipc	a0,0x5
ffffffffc0202e82:	9da50513          	addi	a0,a0,-1574 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202e86:	b90fd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0202e8a:	00005697          	auipc	a3,0x5
ffffffffc0202e8e:	be668693          	addi	a3,a3,-1050 # ffffffffc0207a70 <commands+0x12c0>
ffffffffc0202e92:	00004617          	auipc	a2,0x4
ffffffffc0202e96:	d9e60613          	addi	a2,a2,-610 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202e9a:	13900593          	li	a1,313
ffffffffc0202e9e:	00005517          	auipc	a0,0x5
ffffffffc0202ea2:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202ea6:	b70fd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0202eaa:	00005697          	auipc	a3,0x5
ffffffffc0202eae:	bf668693          	addi	a3,a3,-1034 # ffffffffc0207aa0 <commands+0x12f0>
ffffffffc0202eb2:	00004617          	auipc	a2,0x4
ffffffffc0202eb6:	d7e60613          	addi	a2,a2,-642 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202eba:	13a00593          	li	a1,314
ffffffffc0202ebe:	00005517          	auipc	a0,0x5
ffffffffc0202ec2:	99a50513          	addi	a0,a0,-1638 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202ec6:	b50fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(vma != NULL);
ffffffffc0202eca:	00005697          	auipc	a3,0x5
ffffffffc0202ece:	d1e68693          	addi	a3,a3,-738 # ffffffffc0207be8 <commands+0x1438>
ffffffffc0202ed2:	00004617          	auipc	a2,0x4
ffffffffc0202ed6:	d5e60613          	addi	a2,a2,-674 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202eda:	15900593          	li	a1,345
ffffffffc0202ede:	00005517          	auipc	a0,0x5
ffffffffc0202ee2:	97a50513          	addi	a0,a0,-1670 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202ee6:	b30fd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0202eea:	00005697          	auipc	a3,0x5
ffffffffc0202eee:	ae668693          	addi	a3,a3,-1306 # ffffffffc02079d0 <commands+0x1220>
ffffffffc0202ef2:	00004617          	auipc	a2,0x4
ffffffffc0202ef6:	d3e60613          	addi	a2,a2,-706 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202efa:	12700593          	li	a1,295
ffffffffc0202efe:	00005517          	auipc	a0,0x5
ffffffffc0202f02:	95a50513          	addi	a0,a0,-1702 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202f06:	b10fd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma3 == NULL);
ffffffffc0202f0a:	00005697          	auipc	a3,0x5
ffffffffc0202f0e:	b3668693          	addi	a3,a3,-1226 # ffffffffc0207a40 <commands+0x1290>
ffffffffc0202f12:	00004617          	auipc	a2,0x4
ffffffffc0202f16:	d1e60613          	addi	a2,a2,-738 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202f1a:	13300593          	li	a1,307
ffffffffc0202f1e:	00005517          	auipc	a0,0x5
ffffffffc0202f22:	93a50513          	addi	a0,a0,-1734 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202f26:	af0fd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma2 != NULL);
ffffffffc0202f2a:	00005697          	auipc	a3,0x5
ffffffffc0202f2e:	b0668693          	addi	a3,a3,-1274 # ffffffffc0207a30 <commands+0x1280>
ffffffffc0202f32:	00004617          	auipc	a2,0x4
ffffffffc0202f36:	cfe60613          	addi	a2,a2,-770 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202f3a:	13100593          	li	a1,305
ffffffffc0202f3e:	00005517          	auipc	a0,0x5
ffffffffc0202f42:	91a50513          	addi	a0,a0,-1766 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202f46:	ad0fd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma1 != NULL);
ffffffffc0202f4a:	00005697          	auipc	a3,0x5
ffffffffc0202f4e:	ad668693          	addi	a3,a3,-1322 # ffffffffc0207a20 <commands+0x1270>
ffffffffc0202f52:	00004617          	auipc	a2,0x4
ffffffffc0202f56:	cde60613          	addi	a2,a2,-802 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202f5a:	12f00593          	li	a1,303
ffffffffc0202f5e:	00005517          	auipc	a0,0x5
ffffffffc0202f62:	8fa50513          	addi	a0,a0,-1798 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202f66:	ab0fd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma5 == NULL);
ffffffffc0202f6a:	00005697          	auipc	a3,0x5
ffffffffc0202f6e:	af668693          	addi	a3,a3,-1290 # ffffffffc0207a60 <commands+0x12b0>
ffffffffc0202f72:	00004617          	auipc	a2,0x4
ffffffffc0202f76:	cbe60613          	addi	a2,a2,-834 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202f7a:	13700593          	li	a1,311
ffffffffc0202f7e:	00005517          	auipc	a0,0x5
ffffffffc0202f82:	8da50513          	addi	a0,a0,-1830 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202f86:	a90fd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma4 == NULL);
ffffffffc0202f8a:	00005697          	auipc	a3,0x5
ffffffffc0202f8e:	ac668693          	addi	a3,a3,-1338 # ffffffffc0207a50 <commands+0x12a0>
ffffffffc0202f92:	00004617          	auipc	a2,0x4
ffffffffc0202f96:	c9e60613          	addi	a2,a2,-866 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202f9a:	13500593          	li	a1,309
ffffffffc0202f9e:	00005517          	auipc	a0,0x5
ffffffffc0202fa2:	8ba50513          	addi	a0,a0,-1862 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202fa6:	a70fd0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202faa:	00004617          	auipc	a2,0x4
ffffffffc0202fae:	0a660613          	addi	a2,a2,166 # ffffffffc0207050 <commands+0x8a0>
ffffffffc0202fb2:	06200593          	li	a1,98
ffffffffc0202fb6:	00004517          	auipc	a0,0x4
ffffffffc0202fba:	0ba50513          	addi	a0,a0,186 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0202fbe:	a58fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(mm != NULL);
ffffffffc0202fc2:	00005697          	auipc	a3,0x5
ffffffffc0202fc6:	9fe68693          	addi	a3,a3,-1538 # ffffffffc02079c0 <commands+0x1210>
ffffffffc0202fca:	00004617          	auipc	a2,0x4
ffffffffc0202fce:	c6660613          	addi	a2,a2,-922 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202fd2:	11300593          	li	a1,275
ffffffffc0202fd6:	00005517          	auipc	a0,0x5
ffffffffc0202fda:	88250513          	addi	a0,a0,-1918 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202fde:	a38fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202fe2:	00005697          	auipc	a3,0x5
ffffffffc0202fe6:	ba668693          	addi	a3,a3,-1114 # ffffffffc0207b88 <commands+0x13d8>
ffffffffc0202fea:	00004617          	auipc	a2,0x4
ffffffffc0202fee:	c4660613          	addi	a2,a2,-954 # ffffffffc0206c30 <commands+0x480>
ffffffffc0202ff2:	17700593          	li	a1,375
ffffffffc0202ff6:	00005517          	auipc	a0,0x5
ffffffffc0202ffa:	86250513          	addi	a0,a0,-1950 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0202ffe:	a18fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0203002:	00005697          	auipc	a3,0x5
ffffffffc0203006:	b4668693          	addi	a3,a3,-1210 # ffffffffc0207b48 <commands+0x1398>
ffffffffc020300a:	00004617          	auipc	a2,0x4
ffffffffc020300e:	c2660613          	addi	a2,a2,-986 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203012:	15600593          	li	a1,342
ffffffffc0203016:	00005517          	auipc	a0,0x5
ffffffffc020301a:	84250513          	addi	a0,a0,-1982 # ffffffffc0207858 <commands+0x10a8>
ffffffffc020301e:	9f8fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0203022:	00005697          	auipc	a3,0x5
ffffffffc0203026:	b3668693          	addi	a3,a3,-1226 # ffffffffc0207b58 <commands+0x13a8>
ffffffffc020302a:	00004617          	auipc	a2,0x4
ffffffffc020302e:	c0660613          	addi	a2,a2,-1018 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203032:	15e00593          	li	a1,350
ffffffffc0203036:	00005517          	auipc	a0,0x5
ffffffffc020303a:	82250513          	addi	a0,a0,-2014 # ffffffffc0207858 <commands+0x10a8>
ffffffffc020303e:	9d8fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203042:	00004617          	auipc	a2,0x4
ffffffffc0203046:	fd660613          	addi	a2,a2,-42 # ffffffffc0207018 <commands+0x868>
ffffffffc020304a:	06900593          	li	a1,105
ffffffffc020304e:	00004517          	auipc	a0,0x4
ffffffffc0203052:	02250513          	addi	a0,a0,34 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0203056:	9c0fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(sum == 0);
ffffffffc020305a:	00005697          	auipc	a3,0x5
ffffffffc020305e:	b1e68693          	addi	a3,a3,-1250 # ffffffffc0207b78 <commands+0x13c8>
ffffffffc0203062:	00004617          	auipc	a2,0x4
ffffffffc0203066:	bce60613          	addi	a2,a2,-1074 # ffffffffc0206c30 <commands+0x480>
ffffffffc020306a:	16a00593          	li	a1,362
ffffffffc020306e:	00004517          	auipc	a0,0x4
ffffffffc0203072:	7ea50513          	addi	a0,a0,2026 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0203076:	9a0fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc020307a:	00005697          	auipc	a3,0x5
ffffffffc020307e:	ab668693          	addi	a3,a3,-1354 # ffffffffc0207b30 <commands+0x1380>
ffffffffc0203082:	00004617          	auipc	a2,0x4
ffffffffc0203086:	bae60613          	addi	a2,a2,-1106 # ffffffffc0206c30 <commands+0x480>
ffffffffc020308a:	15200593          	li	a1,338
ffffffffc020308e:	00004517          	auipc	a0,0x4
ffffffffc0203092:	7ca50513          	addi	a0,a0,1994 # ffffffffc0207858 <commands+0x10a8>
ffffffffc0203096:	980fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020309a <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc020309a:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc020309c:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc020309e:	f022                	sd	s0,32(sp)
ffffffffc02030a0:	ec26                	sd	s1,24(sp)
ffffffffc02030a2:	f406                	sd	ra,40(sp)
ffffffffc02030a4:	e84a                	sd	s2,16(sp)
ffffffffc02030a6:	8432                	mv	s0,a2
ffffffffc02030a8:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02030aa:	f88ff0ef          	jal	ra,ffffffffc0202832 <find_vma>

    pgfault_num++;
ffffffffc02030ae:	000a9797          	auipc	a5,0xa9
ffffffffc02030b2:	35a78793          	addi	a5,a5,858 # ffffffffc02ac408 <pgfault_num>
ffffffffc02030b6:	439c                	lw	a5,0(a5)
ffffffffc02030b8:	2785                	addiw	a5,a5,1
ffffffffc02030ba:	000a9717          	auipc	a4,0xa9
ffffffffc02030be:	34f72723          	sw	a5,846(a4) # ffffffffc02ac408 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc02030c2:	c551                	beqz	a0,ffffffffc020314e <do_pgfault+0xb4>
ffffffffc02030c4:	651c                	ld	a5,8(a0)
ffffffffc02030c6:	08f46463          	bltu	s0,a5,ffffffffc020314e <do_pgfault+0xb4>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc02030ca:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc02030cc:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc02030ce:	8b89                	andi	a5,a5,2
ffffffffc02030d0:	efb1                	bnez	a5,ffffffffc020312c <do_pgfault+0x92>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02030d2:	767d                	lui	a2,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc02030d4:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02030d6:	8c71                	and	s0,s0,a2
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc02030d8:	85a2                	mv	a1,s0
ffffffffc02030da:	4605                	li	a2,1
ffffffffc02030dc:	ea5fd0ef          	jal	ra,ffffffffc0200f80 <get_pte>
ffffffffc02030e0:	c941                	beqz	a0,ffffffffc0203170 <do_pgfault+0xd6>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc02030e2:	610c                	ld	a1,0(a0)
ffffffffc02030e4:	c5b1                	beqz	a1,ffffffffc0203130 <do_pgfault+0x96>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc02030e6:	000a9797          	auipc	a5,0xa9
ffffffffc02030ea:	33a78793          	addi	a5,a5,826 # ffffffffc02ac420 <swap_init_ok>
ffffffffc02030ee:	439c                	lw	a5,0(a5)
ffffffffc02030f0:	2781                	sext.w	a5,a5
ffffffffc02030f2:	c7bd                	beqz	a5,ffffffffc0203160 <do_pgfault+0xc6>
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            swap_in(mm, addr, &page);
ffffffffc02030f4:	85a2                	mv	a1,s0
ffffffffc02030f6:	0030                	addi	a2,sp,8
ffffffffc02030f8:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc02030fa:	e402                	sd	zero,8(sp)
            swap_in(mm, addr, &page);
ffffffffc02030fc:	65f000ef          	jal	ra,ffffffffc0203f5a <swap_in>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            page_insert(mm->pgdir, page, addr, perm);
ffffffffc0203100:	65a2                	ld	a1,8(sp)
ffffffffc0203102:	6c88                	ld	a0,24(s1)
ffffffffc0203104:	86ca                	mv	a3,s2
ffffffffc0203106:	8622                	mv	a2,s0
ffffffffc0203108:	c8efe0ef          	jal	ra,ffffffffc0201596 <page_insert>
            //(3) make the page swappable.
            swap_map_swappable(mm, addr, page, 1);
ffffffffc020310c:	6622                	ld	a2,8(sp)
ffffffffc020310e:	4685                	li	a3,1
ffffffffc0203110:	85a2                	mv	a1,s0
ffffffffc0203112:	8526                	mv	a0,s1
ffffffffc0203114:	523000ef          	jal	ra,ffffffffc0203e36 <swap_map_swappable>
            
            page->pra_vaddr = addr;
ffffffffc0203118:	6722                	ld	a4,8(sp)
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }
   ret = 0;
ffffffffc020311a:	4781                	li	a5,0
            page->pra_vaddr = addr;
ffffffffc020311c:	ff00                	sd	s0,56(a4)
failed:
    return ret;
}
ffffffffc020311e:	70a2                	ld	ra,40(sp)
ffffffffc0203120:	7402                	ld	s0,32(sp)
ffffffffc0203122:	64e2                	ld	s1,24(sp)
ffffffffc0203124:	6942                	ld	s2,16(sp)
ffffffffc0203126:	853e                	mv	a0,a5
ffffffffc0203128:	6145                	addi	sp,sp,48
ffffffffc020312a:	8082                	ret
        perm |= READ_WRITE;
ffffffffc020312c:	495d                	li	s2,23
ffffffffc020312e:	b755                	j	ffffffffc02030d2 <do_pgfault+0x38>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0203130:	6c88                	ld	a0,24(s1)
ffffffffc0203132:	864a                	mv	a2,s2
ffffffffc0203134:	85a2                	mv	a1,s0
ffffffffc0203136:	9e2ff0ef          	jal	ra,ffffffffc0202318 <pgdir_alloc_page>
   ret = 0;
ffffffffc020313a:	4781                	li	a5,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc020313c:	f16d                	bnez	a0,ffffffffc020311e <do_pgfault+0x84>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc020313e:	00004517          	auipc	a0,0x4
ffffffffc0203142:	77a50513          	addi	a0,a0,1914 # ffffffffc02078b8 <commands+0x1108>
ffffffffc0203146:	f8bfc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    ret = -E_NO_MEM;
ffffffffc020314a:	57f1                	li	a5,-4
            goto failed;
ffffffffc020314c:	bfc9                	j	ffffffffc020311e <do_pgfault+0x84>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc020314e:	85a2                	mv	a1,s0
ffffffffc0203150:	00004517          	auipc	a0,0x4
ffffffffc0203154:	71850513          	addi	a0,a0,1816 # ffffffffc0207868 <commands+0x10b8>
ffffffffc0203158:	f79fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    int ret = -E_INVAL;
ffffffffc020315c:	57f5                	li	a5,-3
        goto failed;
ffffffffc020315e:	b7c1                	j	ffffffffc020311e <do_pgfault+0x84>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0203160:	00004517          	auipc	a0,0x4
ffffffffc0203164:	78050513          	addi	a0,a0,1920 # ffffffffc02078e0 <commands+0x1130>
ffffffffc0203168:	f69fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    ret = -E_NO_MEM;
ffffffffc020316c:	57f1                	li	a5,-4
            goto failed;
ffffffffc020316e:	bf45                	j	ffffffffc020311e <do_pgfault+0x84>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0203170:	00004517          	auipc	a0,0x4
ffffffffc0203174:	72850513          	addi	a0,a0,1832 # ffffffffc0207898 <commands+0x10e8>
ffffffffc0203178:	f59fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    ret = -E_NO_MEM;
ffffffffc020317c:	57f1                	li	a5,-4
        goto failed;
ffffffffc020317e:	b745                	j	ffffffffc020311e <do_pgfault+0x84>

ffffffffc0203180 <user_mem_check>:

bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
ffffffffc0203180:	7179                	addi	sp,sp,-48
ffffffffc0203182:	f022                	sd	s0,32(sp)
ffffffffc0203184:	f406                	sd	ra,40(sp)
ffffffffc0203186:	ec26                	sd	s1,24(sp)
ffffffffc0203188:	e84a                	sd	s2,16(sp)
ffffffffc020318a:	e44e                	sd	s3,8(sp)
ffffffffc020318c:	e052                	sd	s4,0(sp)
ffffffffc020318e:	842e                	mv	s0,a1
    if (mm != NULL) {
ffffffffc0203190:	c135                	beqz	a0,ffffffffc02031f4 <user_mem_check+0x74>
        if (!USER_ACCESS(addr, addr + len)) {
ffffffffc0203192:	002007b7          	lui	a5,0x200
ffffffffc0203196:	04f5e663          	bltu	a1,a5,ffffffffc02031e2 <user_mem_check+0x62>
ffffffffc020319a:	00c584b3          	add	s1,a1,a2
ffffffffc020319e:	0495f263          	bleu	s1,a1,ffffffffc02031e2 <user_mem_check+0x62>
ffffffffc02031a2:	4785                	li	a5,1
ffffffffc02031a4:	07fe                	slli	a5,a5,0x1f
ffffffffc02031a6:	0297ee63          	bltu	a5,s1,ffffffffc02031e2 <user_mem_check+0x62>
ffffffffc02031aa:	892a                	mv	s2,a0
ffffffffc02031ac:	89b6                	mv	s3,a3
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc02031ae:	6a05                	lui	s4,0x1
ffffffffc02031b0:	a821                	j	ffffffffc02031c8 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc02031b2:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc02031b6:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc02031b8:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc02031ba:	c685                	beqz	a3,ffffffffc02031e2 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc02031bc:	c399                	beqz	a5,ffffffffc02031c2 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc02031be:	02e46263          	bltu	s0,a4,ffffffffc02031e2 <user_mem_check+0x62>
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc02031c2:	6900                	ld	s0,16(a0)
        while (start < end) {
ffffffffc02031c4:	04947663          	bleu	s1,s0,ffffffffc0203210 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
ffffffffc02031c8:	85a2                	mv	a1,s0
ffffffffc02031ca:	854a                	mv	a0,s2
ffffffffc02031cc:	e66ff0ef          	jal	ra,ffffffffc0202832 <find_vma>
ffffffffc02031d0:	c909                	beqz	a0,ffffffffc02031e2 <user_mem_check+0x62>
ffffffffc02031d2:	6518                	ld	a4,8(a0)
ffffffffc02031d4:	00e46763          	bltu	s0,a4,ffffffffc02031e2 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc02031d8:	4d1c                	lw	a5,24(a0)
ffffffffc02031da:	fc099ce3          	bnez	s3,ffffffffc02031b2 <user_mem_check+0x32>
ffffffffc02031de:	8b85                	andi	a5,a5,1
ffffffffc02031e0:	f3ed                	bnez	a5,ffffffffc02031c2 <user_mem_check+0x42>
            return 0;
ffffffffc02031e2:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc02031e4:	70a2                	ld	ra,40(sp)
ffffffffc02031e6:	7402                	ld	s0,32(sp)
ffffffffc02031e8:	64e2                	ld	s1,24(sp)
ffffffffc02031ea:	6942                	ld	s2,16(sp)
ffffffffc02031ec:	69a2                	ld	s3,8(sp)
ffffffffc02031ee:	6a02                	ld	s4,0(sp)
ffffffffc02031f0:	6145                	addi	sp,sp,48
ffffffffc02031f2:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc02031f4:	c02007b7          	lui	a5,0xc0200
ffffffffc02031f8:	4501                	li	a0,0
ffffffffc02031fa:	fef5e5e3          	bltu	a1,a5,ffffffffc02031e4 <user_mem_check+0x64>
ffffffffc02031fe:	962e                	add	a2,a2,a1
ffffffffc0203200:	fec5f2e3          	bleu	a2,a1,ffffffffc02031e4 <user_mem_check+0x64>
ffffffffc0203204:	c8000537          	lui	a0,0xc8000
ffffffffc0203208:	0505                	addi	a0,a0,1
ffffffffc020320a:	00a63533          	sltu	a0,a2,a0
ffffffffc020320e:	bfd9                	j	ffffffffc02031e4 <user_mem_check+0x64>
        return 1;
ffffffffc0203210:	4505                	li	a0,1
ffffffffc0203212:	bfc9                	j	ffffffffc02031e4 <user_mem_check+0x64>

ffffffffc0203214 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0203214:	c125                	beqz	a0,ffffffffc0203274 <slob_free+0x60>
		return;

	if (size)
ffffffffc0203216:	e1a5                	bnez	a1,ffffffffc0203276 <slob_free+0x62>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203218:	100027f3          	csrr	a5,sstatus
ffffffffc020321c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020321e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203220:	e3bd                	bnez	a5,ffffffffc0203286 <slob_free+0x72>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0203222:	0009e797          	auipc	a5,0x9e
ffffffffc0203226:	db678793          	addi	a5,a5,-586 # ffffffffc02a0fd8 <slobfree>
ffffffffc020322a:	639c                	ld	a5,0(a5)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020322c:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020322e:	00a7fa63          	bleu	a0,a5,ffffffffc0203242 <slob_free+0x2e>
ffffffffc0203232:	00e56c63          	bltu	a0,a4,ffffffffc020324a <slob_free+0x36>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0203236:	00e7fa63          	bleu	a4,a5,ffffffffc020324a <slob_free+0x36>
    return 0;
ffffffffc020323a:	87ba                	mv	a5,a4
ffffffffc020323c:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020323e:	fea7eae3          	bltu	a5,a0,ffffffffc0203232 <slob_free+0x1e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0203242:	fee7ece3          	bltu	a5,a4,ffffffffc020323a <slob_free+0x26>
ffffffffc0203246:	fee57ae3          	bleu	a4,a0,ffffffffc020323a <slob_free+0x26>
			break;

	if (b + b->units == cur->next) {
ffffffffc020324a:	4110                	lw	a2,0(a0)
ffffffffc020324c:	00461693          	slli	a3,a2,0x4
ffffffffc0203250:	96aa                	add	a3,a3,a0
ffffffffc0203252:	08d70b63          	beq	a4,a3,ffffffffc02032e8 <slob_free+0xd4>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc0203256:	4394                	lw	a3,0(a5)
		b->next = cur->next;
ffffffffc0203258:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc020325a:	00469713          	slli	a4,a3,0x4
ffffffffc020325e:	973e                	add	a4,a4,a5
ffffffffc0203260:	08e50f63          	beq	a0,a4,ffffffffc02032fe <slob_free+0xea>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc0203264:	e788                	sd	a0,8(a5)

	slobfree = cur;
ffffffffc0203266:	0009e717          	auipc	a4,0x9e
ffffffffc020326a:	d6f73923          	sd	a5,-654(a4) # ffffffffc02a0fd8 <slobfree>
    if (flag) {
ffffffffc020326e:	c199                	beqz	a1,ffffffffc0203274 <slob_free+0x60>
        intr_enable();
ffffffffc0203270:	be6fd06f          	j	ffffffffc0200656 <intr_enable>
ffffffffc0203274:	8082                	ret
		b->units = SLOB_UNITS(size);
ffffffffc0203276:	05bd                	addi	a1,a1,15
ffffffffc0203278:	8191                	srli	a1,a1,0x4
ffffffffc020327a:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020327c:	100027f3          	csrr	a5,sstatus
ffffffffc0203280:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203282:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203284:	dfd9                	beqz	a5,ffffffffc0203222 <slob_free+0xe>
{
ffffffffc0203286:	1101                	addi	sp,sp,-32
ffffffffc0203288:	e42a                	sd	a0,8(sp)
ffffffffc020328a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020328c:	bd0fd0ef          	jal	ra,ffffffffc020065c <intr_disable>
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0203290:	0009e797          	auipc	a5,0x9e
ffffffffc0203294:	d4878793          	addi	a5,a5,-696 # ffffffffc02a0fd8 <slobfree>
ffffffffc0203298:	639c                	ld	a5,0(a5)
        return 1;
ffffffffc020329a:	6522                	ld	a0,8(sp)
ffffffffc020329c:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020329e:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02032a0:	00a7fa63          	bleu	a0,a5,ffffffffc02032b4 <slob_free+0xa0>
ffffffffc02032a4:	00e56c63          	bltu	a0,a4,ffffffffc02032bc <slob_free+0xa8>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02032a8:	00e7fa63          	bleu	a4,a5,ffffffffc02032bc <slob_free+0xa8>
    return 0;
ffffffffc02032ac:	87ba                	mv	a5,a4
ffffffffc02032ae:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02032b0:	fea7eae3          	bltu	a5,a0,ffffffffc02032a4 <slob_free+0x90>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02032b4:	fee7ece3          	bltu	a5,a4,ffffffffc02032ac <slob_free+0x98>
ffffffffc02032b8:	fee57ae3          	bleu	a4,a0,ffffffffc02032ac <slob_free+0x98>
	if (b + b->units == cur->next) {
ffffffffc02032bc:	4110                	lw	a2,0(a0)
ffffffffc02032be:	00461693          	slli	a3,a2,0x4
ffffffffc02032c2:	96aa                	add	a3,a3,a0
ffffffffc02032c4:	04d70763          	beq	a4,a3,ffffffffc0203312 <slob_free+0xfe>
		b->next = cur->next;
ffffffffc02032c8:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc02032ca:	4394                	lw	a3,0(a5)
ffffffffc02032cc:	00469713          	slli	a4,a3,0x4
ffffffffc02032d0:	973e                	add	a4,a4,a5
ffffffffc02032d2:	04e50663          	beq	a0,a4,ffffffffc020331e <slob_free+0x10a>
		cur->next = b;
ffffffffc02032d6:	e788                	sd	a0,8(a5)
	slobfree = cur;
ffffffffc02032d8:	0009e717          	auipc	a4,0x9e
ffffffffc02032dc:	d0f73023          	sd	a5,-768(a4) # ffffffffc02a0fd8 <slobfree>
    if (flag) {
ffffffffc02032e0:	e58d                	bnez	a1,ffffffffc020330a <slob_free+0xf6>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02032e2:	60e2                	ld	ra,24(sp)
ffffffffc02032e4:	6105                	addi	sp,sp,32
ffffffffc02032e6:	8082                	ret
		b->units += cur->next->units;
ffffffffc02032e8:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02032ea:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc02032ec:	9e35                	addw	a2,a2,a3
ffffffffc02032ee:	c110                	sw	a2,0(a0)
	if (cur + cur->units == b) {
ffffffffc02032f0:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02032f2:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc02032f4:	00469713          	slli	a4,a3,0x4
ffffffffc02032f8:	973e                	add	a4,a4,a5
ffffffffc02032fa:	f6e515e3          	bne	a0,a4,ffffffffc0203264 <slob_free+0x50>
		cur->units += b->units;
ffffffffc02032fe:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0203300:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0203302:	9eb9                	addw	a3,a3,a4
ffffffffc0203304:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc0203306:	e790                	sd	a2,8(a5)
ffffffffc0203308:	bfb9                	j	ffffffffc0203266 <slob_free+0x52>
}
ffffffffc020330a:	60e2                	ld	ra,24(sp)
ffffffffc020330c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020330e:	b48fd06f          	j	ffffffffc0200656 <intr_enable>
		b->units += cur->next->units;
ffffffffc0203312:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0203314:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc0203316:	9e35                	addw	a2,a2,a3
ffffffffc0203318:	c110                	sw	a2,0(a0)
		b->next = cur->next->next;
ffffffffc020331a:	e518                	sd	a4,8(a0)
ffffffffc020331c:	b77d                	j	ffffffffc02032ca <slob_free+0xb6>
		cur->units += b->units;
ffffffffc020331e:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0203320:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0203322:	9eb9                	addw	a3,a3,a4
ffffffffc0203324:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc0203326:	e790                	sd	a2,8(a5)
ffffffffc0203328:	bf45                	j	ffffffffc02032d8 <slob_free+0xc4>

ffffffffc020332a <__slob_get_free_pages.isra.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc020332a:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020332c:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc020332e:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0203332:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc0203334:	b3ffd0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
  if(!page)
ffffffffc0203338:	c139                	beqz	a0,ffffffffc020337e <__slob_get_free_pages.isra.0+0x54>
    return page - pages + nbase;
ffffffffc020333a:	000a9797          	auipc	a5,0xa9
ffffffffc020333e:	12e78793          	addi	a5,a5,302 # ffffffffc02ac468 <pages>
ffffffffc0203342:	6394                	ld	a3,0(a5)
ffffffffc0203344:	00006797          	auipc	a5,0x6
ffffffffc0203348:	a2478793          	addi	a5,a5,-1500 # ffffffffc0208d68 <nbase>
    return KADDR(page2pa(page));
ffffffffc020334c:	000a9717          	auipc	a4,0xa9
ffffffffc0203350:	0b470713          	addi	a4,a4,180 # ffffffffc02ac400 <npage>
    return page - pages + nbase;
ffffffffc0203354:	40d506b3          	sub	a3,a0,a3
ffffffffc0203358:	6388                	ld	a0,0(a5)
ffffffffc020335a:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020335c:	57fd                	li	a5,-1
ffffffffc020335e:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0203360:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0203362:	83b1                	srli	a5,a5,0xc
ffffffffc0203364:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0203366:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203368:	00e7ff63          	bleu	a4,a5,ffffffffc0203386 <__slob_get_free_pages.isra.0+0x5c>
ffffffffc020336c:	000a9797          	auipc	a5,0xa9
ffffffffc0203370:	0ec78793          	addi	a5,a5,236 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0203374:	6388                	ld	a0,0(a5)
}
ffffffffc0203376:	60a2                	ld	ra,8(sp)
ffffffffc0203378:	9536                	add	a0,a0,a3
ffffffffc020337a:	0141                	addi	sp,sp,16
ffffffffc020337c:	8082                	ret
ffffffffc020337e:	60a2                	ld	ra,8(sp)
    return NULL;
ffffffffc0203380:	4501                	li	a0,0
}
ffffffffc0203382:	0141                	addi	sp,sp,16
ffffffffc0203384:	8082                	ret
ffffffffc0203386:	00004617          	auipc	a2,0x4
ffffffffc020338a:	c9260613          	addi	a2,a2,-878 # ffffffffc0207018 <commands+0x868>
ffffffffc020338e:	06900593          	li	a1,105
ffffffffc0203392:	00004517          	auipc	a0,0x4
ffffffffc0203396:	cde50513          	addi	a0,a0,-802 # ffffffffc0207070 <commands+0x8c0>
ffffffffc020339a:	e7dfc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020339e <slob_alloc.isra.1.constprop.3>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc020339e:	7179                	addi	sp,sp,-48
ffffffffc02033a0:	f406                	sd	ra,40(sp)
ffffffffc02033a2:	f022                	sd	s0,32(sp)
ffffffffc02033a4:	ec26                	sd	s1,24(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc02033a6:	01050713          	addi	a4,a0,16
ffffffffc02033aa:	6785                	lui	a5,0x1
ffffffffc02033ac:	0cf77b63          	bleu	a5,a4,ffffffffc0203482 <slob_alloc.isra.1.constprop.3+0xe4>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02033b0:	00f50413          	addi	s0,a0,15
ffffffffc02033b4:	8011                	srli	s0,s0,0x4
ffffffffc02033b6:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02033b8:	10002673          	csrr	a2,sstatus
ffffffffc02033bc:	8a09                	andi	a2,a2,2
ffffffffc02033be:	ea5d                	bnez	a2,ffffffffc0203474 <slob_alloc.isra.1.constprop.3+0xd6>
	prev = slobfree;
ffffffffc02033c0:	0009e497          	auipc	s1,0x9e
ffffffffc02033c4:	c1848493          	addi	s1,s1,-1000 # ffffffffc02a0fd8 <slobfree>
ffffffffc02033c8:	6094                	ld	a3,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02033ca:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02033cc:	4398                	lw	a4,0(a5)
ffffffffc02033ce:	0a875763          	ble	s0,a4,ffffffffc020347c <slob_alloc.isra.1.constprop.3+0xde>
		if (cur == slobfree) {
ffffffffc02033d2:	00f68a63          	beq	a3,a5,ffffffffc02033e6 <slob_alloc.isra.1.constprop.3+0x48>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02033d6:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02033d8:	4118                	lw	a4,0(a0)
ffffffffc02033da:	02875763          	ble	s0,a4,ffffffffc0203408 <slob_alloc.isra.1.constprop.3+0x6a>
ffffffffc02033de:	6094                	ld	a3,0(s1)
ffffffffc02033e0:	87aa                	mv	a5,a0
		if (cur == slobfree) {
ffffffffc02033e2:	fef69ae3          	bne	a3,a5,ffffffffc02033d6 <slob_alloc.isra.1.constprop.3+0x38>
    if (flag) {
ffffffffc02033e6:	ea39                	bnez	a2,ffffffffc020343c <slob_alloc.isra.1.constprop.3+0x9e>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02033e8:	4501                	li	a0,0
ffffffffc02033ea:	f41ff0ef          	jal	ra,ffffffffc020332a <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc02033ee:	cd29                	beqz	a0,ffffffffc0203448 <slob_alloc.isra.1.constprop.3+0xaa>
			slob_free(cur, PAGE_SIZE);
ffffffffc02033f0:	6585                	lui	a1,0x1
ffffffffc02033f2:	e23ff0ef          	jal	ra,ffffffffc0203214 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02033f6:	10002673          	csrr	a2,sstatus
ffffffffc02033fa:	8a09                	andi	a2,a2,2
ffffffffc02033fc:	ea1d                	bnez	a2,ffffffffc0203432 <slob_alloc.isra.1.constprop.3+0x94>
			cur = slobfree;
ffffffffc02033fe:	609c                	ld	a5,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0203400:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0203402:	4118                	lw	a4,0(a0)
ffffffffc0203404:	fc874de3          	blt	a4,s0,ffffffffc02033de <slob_alloc.isra.1.constprop.3+0x40>
			if (cur->units == units) /* exact fit? */
ffffffffc0203408:	04e40663          	beq	s0,a4,ffffffffc0203454 <slob_alloc.isra.1.constprop.3+0xb6>
				prev->next = cur + units;
ffffffffc020340c:	00441693          	slli	a3,s0,0x4
ffffffffc0203410:	96aa                	add	a3,a3,a0
ffffffffc0203412:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0203414:	650c                	ld	a1,8(a0)
				prev->next->units = cur->units - units;
ffffffffc0203416:	9f01                	subw	a4,a4,s0
ffffffffc0203418:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc020341a:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc020341c:	c100                	sw	s0,0(a0)
			slobfree = prev;
ffffffffc020341e:	0009e717          	auipc	a4,0x9e
ffffffffc0203422:	baf73d23          	sd	a5,-1094(a4) # ffffffffc02a0fd8 <slobfree>
    if (flag) {
ffffffffc0203426:	ee15                	bnez	a2,ffffffffc0203462 <slob_alloc.isra.1.constprop.3+0xc4>
}
ffffffffc0203428:	70a2                	ld	ra,40(sp)
ffffffffc020342a:	7402                	ld	s0,32(sp)
ffffffffc020342c:	64e2                	ld	s1,24(sp)
ffffffffc020342e:	6145                	addi	sp,sp,48
ffffffffc0203430:	8082                	ret
        intr_disable();
ffffffffc0203432:	a2afd0ef          	jal	ra,ffffffffc020065c <intr_disable>
ffffffffc0203436:	4605                	li	a2,1
			cur = slobfree;
ffffffffc0203438:	609c                	ld	a5,0(s1)
ffffffffc020343a:	b7d9                	j	ffffffffc0203400 <slob_alloc.isra.1.constprop.3+0x62>
        intr_enable();
ffffffffc020343c:	a1afd0ef          	jal	ra,ffffffffc0200656 <intr_enable>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0203440:	4501                	li	a0,0
ffffffffc0203442:	ee9ff0ef          	jal	ra,ffffffffc020332a <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc0203446:	f54d                	bnez	a0,ffffffffc02033f0 <slob_alloc.isra.1.constprop.3+0x52>
}
ffffffffc0203448:	70a2                	ld	ra,40(sp)
ffffffffc020344a:	7402                	ld	s0,32(sp)
ffffffffc020344c:	64e2                	ld	s1,24(sp)
				return 0;
ffffffffc020344e:	4501                	li	a0,0
}
ffffffffc0203450:	6145                	addi	sp,sp,48
ffffffffc0203452:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0203454:	6518                	ld	a4,8(a0)
ffffffffc0203456:	e798                	sd	a4,8(a5)
			slobfree = prev;
ffffffffc0203458:	0009e717          	auipc	a4,0x9e
ffffffffc020345c:	b8f73023          	sd	a5,-1152(a4) # ffffffffc02a0fd8 <slobfree>
    if (flag) {
ffffffffc0203460:	d661                	beqz	a2,ffffffffc0203428 <slob_alloc.isra.1.constprop.3+0x8a>
ffffffffc0203462:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0203464:	9f2fd0ef          	jal	ra,ffffffffc0200656 <intr_enable>
}
ffffffffc0203468:	70a2                	ld	ra,40(sp)
ffffffffc020346a:	7402                	ld	s0,32(sp)
ffffffffc020346c:	6522                	ld	a0,8(sp)
ffffffffc020346e:	64e2                	ld	s1,24(sp)
ffffffffc0203470:	6145                	addi	sp,sp,48
ffffffffc0203472:	8082                	ret
        intr_disable();
ffffffffc0203474:	9e8fd0ef          	jal	ra,ffffffffc020065c <intr_disable>
ffffffffc0203478:	4605                	li	a2,1
ffffffffc020347a:	b799                	j	ffffffffc02033c0 <slob_alloc.isra.1.constprop.3+0x22>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc020347c:	853e                	mv	a0,a5
ffffffffc020347e:	87b6                	mv	a5,a3
ffffffffc0203480:	b761                	j	ffffffffc0203408 <slob_alloc.isra.1.constprop.3+0x6a>
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0203482:	00004697          	auipc	a3,0x4
ffffffffc0203486:	79668693          	addi	a3,a3,1942 # ffffffffc0207c18 <commands+0x1468>
ffffffffc020348a:	00003617          	auipc	a2,0x3
ffffffffc020348e:	7a660613          	addi	a2,a2,1958 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203492:	06400593          	li	a1,100
ffffffffc0203496:	00004517          	auipc	a0,0x4
ffffffffc020349a:	7a250513          	addi	a0,a0,1954 # ffffffffc0207c38 <commands+0x1488>
ffffffffc020349e:	d79fc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02034a2 <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc02034a2:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc02034a4:	00004517          	auipc	a0,0x4
ffffffffc02034a8:	7ac50513          	addi	a0,a0,1964 # ffffffffc0207c50 <commands+0x14a0>
kmalloc_init(void) {
ffffffffc02034ac:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc02034ae:	c23fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc02034b2:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc02034b4:	00004517          	auipc	a0,0x4
ffffffffc02034b8:	74450513          	addi	a0,a0,1860 # ffffffffc0207bf8 <commands+0x1448>
}
ffffffffc02034bc:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc02034be:	c13fc06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc02034c2 <kallocated>:
}

size_t
kallocated(void) {
   return slob_allocated();
}
ffffffffc02034c2:	4501                	li	a0,0
ffffffffc02034c4:	8082                	ret

ffffffffc02034c6 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc02034c6:	1101                	addi	sp,sp,-32
ffffffffc02034c8:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc02034ca:	6905                	lui	s2,0x1
{
ffffffffc02034cc:	e822                	sd	s0,16(sp)
ffffffffc02034ce:	ec06                	sd	ra,24(sp)
ffffffffc02034d0:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc02034d2:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8581>
{
ffffffffc02034d6:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc02034d8:	04a7fc63          	bleu	a0,a5,ffffffffc0203530 <kmalloc+0x6a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc02034dc:	4561                	li	a0,24
ffffffffc02034de:	ec1ff0ef          	jal	ra,ffffffffc020339e <slob_alloc.isra.1.constprop.3>
ffffffffc02034e2:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc02034e4:	cd21                	beqz	a0,ffffffffc020353c <kmalloc+0x76>
	bb->order = find_order(size);
ffffffffc02034e6:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc02034ea:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc02034ec:	00f95763          	ble	a5,s2,ffffffffc02034fa <kmalloc+0x34>
ffffffffc02034f0:	6705                	lui	a4,0x1
ffffffffc02034f2:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc02034f4:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc02034f6:	fef74ee3          	blt	a4,a5,ffffffffc02034f2 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc02034fa:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc02034fc:	e2fff0ef          	jal	ra,ffffffffc020332a <__slob_get_free_pages.isra.0>
ffffffffc0203500:	e488                	sd	a0,8(s1)
ffffffffc0203502:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0203504:	c935                	beqz	a0,ffffffffc0203578 <kmalloc+0xb2>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203506:	100027f3          	csrr	a5,sstatus
ffffffffc020350a:	8b89                	andi	a5,a5,2
ffffffffc020350c:	e3a1                	bnez	a5,ffffffffc020354c <kmalloc+0x86>
		bb->next = bigblocks;
ffffffffc020350e:	000a9797          	auipc	a5,0xa9
ffffffffc0203512:	f0278793          	addi	a5,a5,-254 # ffffffffc02ac410 <bigblocks>
ffffffffc0203516:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0203518:	000a9717          	auipc	a4,0xa9
ffffffffc020351c:	ee973c23          	sd	s1,-264(a4) # ffffffffc02ac410 <bigblocks>
		bb->next = bigblocks;
ffffffffc0203520:	e89c                	sd	a5,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0203522:	8522                	mv	a0,s0
ffffffffc0203524:	60e2                	ld	ra,24(sp)
ffffffffc0203526:	6442                	ld	s0,16(sp)
ffffffffc0203528:	64a2                	ld	s1,8(sp)
ffffffffc020352a:	6902                	ld	s2,0(sp)
ffffffffc020352c:	6105                	addi	sp,sp,32
ffffffffc020352e:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0203530:	0541                	addi	a0,a0,16
ffffffffc0203532:	e6dff0ef          	jal	ra,ffffffffc020339e <slob_alloc.isra.1.constprop.3>
		return m ? (void *)(m + 1) : 0;
ffffffffc0203536:	01050413          	addi	s0,a0,16
ffffffffc020353a:	f565                	bnez	a0,ffffffffc0203522 <kmalloc+0x5c>
ffffffffc020353c:	4401                	li	s0,0
}
ffffffffc020353e:	8522                	mv	a0,s0
ffffffffc0203540:	60e2                	ld	ra,24(sp)
ffffffffc0203542:	6442                	ld	s0,16(sp)
ffffffffc0203544:	64a2                	ld	s1,8(sp)
ffffffffc0203546:	6902                	ld	s2,0(sp)
ffffffffc0203548:	6105                	addi	sp,sp,32
ffffffffc020354a:	8082                	ret
        intr_disable();
ffffffffc020354c:	910fd0ef          	jal	ra,ffffffffc020065c <intr_disable>
		bb->next = bigblocks;
ffffffffc0203550:	000a9797          	auipc	a5,0xa9
ffffffffc0203554:	ec078793          	addi	a5,a5,-320 # ffffffffc02ac410 <bigblocks>
ffffffffc0203558:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc020355a:	000a9717          	auipc	a4,0xa9
ffffffffc020355e:	ea973b23          	sd	s1,-330(a4) # ffffffffc02ac410 <bigblocks>
		bb->next = bigblocks;
ffffffffc0203562:	e89c                	sd	a5,16(s1)
        intr_enable();
ffffffffc0203564:	8f2fd0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc0203568:	6480                	ld	s0,8(s1)
}
ffffffffc020356a:	60e2                	ld	ra,24(sp)
ffffffffc020356c:	64a2                	ld	s1,8(sp)
ffffffffc020356e:	8522                	mv	a0,s0
ffffffffc0203570:	6442                	ld	s0,16(sp)
ffffffffc0203572:	6902                	ld	s2,0(sp)
ffffffffc0203574:	6105                	addi	sp,sp,32
ffffffffc0203576:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0203578:	45e1                	li	a1,24
ffffffffc020357a:	8526                	mv	a0,s1
ffffffffc020357c:	c99ff0ef          	jal	ra,ffffffffc0203214 <slob_free>
  return __kmalloc(size, 0);
ffffffffc0203580:	b74d                	j	ffffffffc0203522 <kmalloc+0x5c>

ffffffffc0203582 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0203582:	c175                	beqz	a0,ffffffffc0203666 <kfree+0xe4>
{
ffffffffc0203584:	1101                	addi	sp,sp,-32
ffffffffc0203586:	e426                	sd	s1,8(sp)
ffffffffc0203588:	ec06                	sd	ra,24(sp)
ffffffffc020358a:	e822                	sd	s0,16(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc020358c:	03451793          	slli	a5,a0,0x34
ffffffffc0203590:	84aa                	mv	s1,a0
ffffffffc0203592:	eb8d                	bnez	a5,ffffffffc02035c4 <kfree+0x42>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203594:	100027f3          	csrr	a5,sstatus
ffffffffc0203598:	8b89                	andi	a5,a5,2
ffffffffc020359a:	efc9                	bnez	a5,ffffffffc0203634 <kfree+0xb2>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc020359c:	000a9797          	auipc	a5,0xa9
ffffffffc02035a0:	e7478793          	addi	a5,a5,-396 # ffffffffc02ac410 <bigblocks>
ffffffffc02035a4:	6394                	ld	a3,0(a5)
ffffffffc02035a6:	ce99                	beqz	a3,ffffffffc02035c4 <kfree+0x42>
			if (bb->pages == block) {
ffffffffc02035a8:	669c                	ld	a5,8(a3)
ffffffffc02035aa:	6a80                	ld	s0,16(a3)
ffffffffc02035ac:	0af50e63          	beq	a0,a5,ffffffffc0203668 <kfree+0xe6>
    return 0;
ffffffffc02035b0:	4601                	li	a2,0
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc02035b2:	c801                	beqz	s0,ffffffffc02035c2 <kfree+0x40>
			if (bb->pages == block) {
ffffffffc02035b4:	6418                	ld	a4,8(s0)
ffffffffc02035b6:	681c                	ld	a5,16(s0)
ffffffffc02035b8:	00970f63          	beq	a4,s1,ffffffffc02035d6 <kfree+0x54>
ffffffffc02035bc:	86a2                	mv	a3,s0
ffffffffc02035be:	843e                	mv	s0,a5
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc02035c0:	f875                	bnez	s0,ffffffffc02035b4 <kfree+0x32>
    if (flag) {
ffffffffc02035c2:	e659                	bnez	a2,ffffffffc0203650 <kfree+0xce>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc02035c4:	6442                	ld	s0,16(sp)
ffffffffc02035c6:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc02035c8:	ff048513          	addi	a0,s1,-16
}
ffffffffc02035cc:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc02035ce:	4581                	li	a1,0
}
ffffffffc02035d0:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc02035d2:	c43ff06f          	j	ffffffffc0203214 <slob_free>
				*last = bb->next;
ffffffffc02035d6:	ea9c                	sd	a5,16(a3)
ffffffffc02035d8:	e641                	bnez	a2,ffffffffc0203660 <kfree+0xde>
    return pa2page(PADDR(kva));
ffffffffc02035da:	c02007b7          	lui	a5,0xc0200
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc02035de:	4018                	lw	a4,0(s0)
ffffffffc02035e0:	08f4ea63          	bltu	s1,a5,ffffffffc0203674 <kfree+0xf2>
ffffffffc02035e4:	000a9797          	auipc	a5,0xa9
ffffffffc02035e8:	e7478793          	addi	a5,a5,-396 # ffffffffc02ac458 <va_pa_offset>
ffffffffc02035ec:	6394                	ld	a3,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc02035ee:	000a9797          	auipc	a5,0xa9
ffffffffc02035f2:	e1278793          	addi	a5,a5,-494 # ffffffffc02ac400 <npage>
ffffffffc02035f6:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc02035f8:	8c95                	sub	s1,s1,a3
    if (PPN(pa) >= npage) {
ffffffffc02035fa:	80b1                	srli	s1,s1,0xc
ffffffffc02035fc:	08f4f963          	bleu	a5,s1,ffffffffc020368e <kfree+0x10c>
    return &pages[PPN(pa) - nbase];
ffffffffc0203600:	00005797          	auipc	a5,0x5
ffffffffc0203604:	76878793          	addi	a5,a5,1896 # ffffffffc0208d68 <nbase>
ffffffffc0203608:	639c                	ld	a5,0(a5)
ffffffffc020360a:	000a9697          	auipc	a3,0xa9
ffffffffc020360e:	e5e68693          	addi	a3,a3,-418 # ffffffffc02ac468 <pages>
ffffffffc0203612:	6288                	ld	a0,0(a3)
ffffffffc0203614:	8c9d                	sub	s1,s1,a5
ffffffffc0203616:	049a                	slli	s1,s1,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0203618:	4585                	li	a1,1
ffffffffc020361a:	9526                	add	a0,a0,s1
ffffffffc020361c:	00e595bb          	sllw	a1,a1,a4
ffffffffc0203620:	8dbfd0ef          	jal	ra,ffffffffc0200efa <free_pages>
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0203624:	8522                	mv	a0,s0
}
ffffffffc0203626:	6442                	ld	s0,16(sp)
ffffffffc0203628:	60e2                	ld	ra,24(sp)
ffffffffc020362a:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc020362c:	45e1                	li	a1,24
}
ffffffffc020362e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0203630:	be5ff06f          	j	ffffffffc0203214 <slob_free>
        intr_disable();
ffffffffc0203634:	828fd0ef          	jal	ra,ffffffffc020065c <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0203638:	000a9797          	auipc	a5,0xa9
ffffffffc020363c:	dd878793          	addi	a5,a5,-552 # ffffffffc02ac410 <bigblocks>
ffffffffc0203640:	6394                	ld	a3,0(a5)
ffffffffc0203642:	c699                	beqz	a3,ffffffffc0203650 <kfree+0xce>
			if (bb->pages == block) {
ffffffffc0203644:	669c                	ld	a5,8(a3)
ffffffffc0203646:	6a80                	ld	s0,16(a3)
ffffffffc0203648:	00f48763          	beq	s1,a5,ffffffffc0203656 <kfree+0xd4>
        return 1;
ffffffffc020364c:	4605                	li	a2,1
ffffffffc020364e:	b795                	j	ffffffffc02035b2 <kfree+0x30>
        intr_enable();
ffffffffc0203650:	806fd0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc0203654:	bf85                	j	ffffffffc02035c4 <kfree+0x42>
				*last = bb->next;
ffffffffc0203656:	000a9797          	auipc	a5,0xa9
ffffffffc020365a:	da87bd23          	sd	s0,-582(a5) # ffffffffc02ac410 <bigblocks>
ffffffffc020365e:	8436                	mv	s0,a3
ffffffffc0203660:	ff7fc0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc0203664:	bf9d                	j	ffffffffc02035da <kfree+0x58>
ffffffffc0203666:	8082                	ret
ffffffffc0203668:	000a9797          	auipc	a5,0xa9
ffffffffc020366c:	da87b423          	sd	s0,-600(a5) # ffffffffc02ac410 <bigblocks>
ffffffffc0203670:	8436                	mv	s0,a3
ffffffffc0203672:	b7a5                	j	ffffffffc02035da <kfree+0x58>
    return pa2page(PADDR(kva));
ffffffffc0203674:	86a6                	mv	a3,s1
ffffffffc0203676:	00004617          	auipc	a2,0x4
ffffffffc020367a:	a7a60613          	addi	a2,a2,-1414 # ffffffffc02070f0 <commands+0x940>
ffffffffc020367e:	06e00593          	li	a1,110
ffffffffc0203682:	00004517          	auipc	a0,0x4
ffffffffc0203686:	9ee50513          	addi	a0,a0,-1554 # ffffffffc0207070 <commands+0x8c0>
ffffffffc020368a:	b8dfc0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020368e:	00004617          	auipc	a2,0x4
ffffffffc0203692:	9c260613          	addi	a2,a2,-1598 # ffffffffc0207050 <commands+0x8a0>
ffffffffc0203696:	06200593          	li	a1,98
ffffffffc020369a:	00004517          	auipc	a0,0x4
ffffffffc020369e:	9d650513          	addi	a0,a0,-1578 # ffffffffc0207070 <commands+0x8c0>
ffffffffc02036a2:	b75fc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02036a6 <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc02036a6:	7135                	addi	sp,sp,-160
ffffffffc02036a8:	ed06                	sd	ra,152(sp)
ffffffffc02036aa:	e922                	sd	s0,144(sp)
ffffffffc02036ac:	e526                	sd	s1,136(sp)
ffffffffc02036ae:	e14a                	sd	s2,128(sp)
ffffffffc02036b0:	fcce                	sd	s3,120(sp)
ffffffffc02036b2:	f8d2                	sd	s4,112(sp)
ffffffffc02036b4:	f4d6                	sd	s5,104(sp)
ffffffffc02036b6:	f0da                	sd	s6,96(sp)
ffffffffc02036b8:	ecde                	sd	s7,88(sp)
ffffffffc02036ba:	e8e2                	sd	s8,80(sp)
ffffffffc02036bc:	e4e6                	sd	s9,72(sp)
ffffffffc02036be:	e0ea                	sd	s10,64(sp)
ffffffffc02036c0:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc02036c2:	460010ef          	jal	ra,ffffffffc0204b22 <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc02036c6:	000a9797          	auipc	a5,0xa9
ffffffffc02036ca:	e4a78793          	addi	a5,a5,-438 # ffffffffc02ac510 <max_swap_offset>
ffffffffc02036ce:	6394                	ld	a3,0(a5)
ffffffffc02036d0:	010007b7          	lui	a5,0x1000
ffffffffc02036d4:	17e1                	addi	a5,a5,-8
ffffffffc02036d6:	ff968713          	addi	a4,a3,-7
ffffffffc02036da:	4ae7ee63          	bltu	a5,a4,ffffffffc0203b96 <swap_init+0x4f0>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;
ffffffffc02036de:	0009e797          	auipc	a5,0x9e
ffffffffc02036e2:	8aa78793          	addi	a5,a5,-1878 # ffffffffc02a0f88 <swap_manager_fifo>
     int r = sm->init();
ffffffffc02036e6:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc02036e8:	000a9697          	auipc	a3,0xa9
ffffffffc02036ec:	d2f6b823          	sd	a5,-720(a3) # ffffffffc02ac418 <sm>
     int r = sm->init();
ffffffffc02036f0:	9702                	jalr	a4
ffffffffc02036f2:	8aaa                	mv	s5,a0
     
     if (r == 0)
ffffffffc02036f4:	c10d                	beqz	a0,ffffffffc0203716 <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02036f6:	60ea                	ld	ra,152(sp)
ffffffffc02036f8:	644a                	ld	s0,144(sp)
ffffffffc02036fa:	8556                	mv	a0,s5
ffffffffc02036fc:	64aa                	ld	s1,136(sp)
ffffffffc02036fe:	690a                	ld	s2,128(sp)
ffffffffc0203700:	79e6                	ld	s3,120(sp)
ffffffffc0203702:	7a46                	ld	s4,112(sp)
ffffffffc0203704:	7aa6                	ld	s5,104(sp)
ffffffffc0203706:	7b06                	ld	s6,96(sp)
ffffffffc0203708:	6be6                	ld	s7,88(sp)
ffffffffc020370a:	6c46                	ld	s8,80(sp)
ffffffffc020370c:	6ca6                	ld	s9,72(sp)
ffffffffc020370e:	6d06                	ld	s10,64(sp)
ffffffffc0203710:	7de2                	ld	s11,56(sp)
ffffffffc0203712:	610d                	addi	sp,sp,160
ffffffffc0203714:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203716:	000a9797          	auipc	a5,0xa9
ffffffffc020371a:	d0278793          	addi	a5,a5,-766 # ffffffffc02ac418 <sm>
ffffffffc020371e:	639c                	ld	a5,0(a5)
ffffffffc0203720:	00004517          	auipc	a0,0x4
ffffffffc0203724:	5c850513          	addi	a0,a0,1480 # ffffffffc0207ce8 <commands+0x1538>
ffffffffc0203728:	000a9417          	auipc	s0,0xa9
ffffffffc020372c:	e2840413          	addi	s0,s0,-472 # ffffffffc02ac550 <free_area>
ffffffffc0203730:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0203732:	4785                	li	a5,1
ffffffffc0203734:	000a9717          	auipc	a4,0xa9
ffffffffc0203738:	cef72623          	sw	a5,-788(a4) # ffffffffc02ac420 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc020373c:	995fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0203740:	641c                	ld	a5,8(s0)
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203742:	36878e63          	beq	a5,s0,ffffffffc0203abe <swap_init+0x418>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203746:	ff07b703          	ld	a4,-16(a5)
ffffffffc020374a:	8305                	srli	a4,a4,0x1
ffffffffc020374c:	8b05                	andi	a4,a4,1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020374e:	36070c63          	beqz	a4,ffffffffc0203ac6 <swap_init+0x420>
     int ret, count = 0, total = 0, i;
ffffffffc0203752:	4481                	li	s1,0
ffffffffc0203754:	4901                	li	s2,0
ffffffffc0203756:	a031                	j	ffffffffc0203762 <swap_init+0xbc>
ffffffffc0203758:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc020375c:	8b09                	andi	a4,a4,2
ffffffffc020375e:	36070463          	beqz	a4,ffffffffc0203ac6 <swap_init+0x420>
        count ++, total += p->property;
ffffffffc0203762:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203766:	679c                	ld	a5,8(a5)
ffffffffc0203768:	2905                	addiw	s2,s2,1
ffffffffc020376a:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc020376c:	fe8796e3          	bne	a5,s0,ffffffffc0203758 <swap_init+0xb2>
ffffffffc0203770:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc0203772:	fcefd0ef          	jal	ra,ffffffffc0200f40 <nr_free_pages>
ffffffffc0203776:	69351863          	bne	a0,s3,ffffffffc0203e06 <swap_init+0x760>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc020377a:	8626                	mv	a2,s1
ffffffffc020377c:	85ca                	mv	a1,s2
ffffffffc020377e:	00004517          	auipc	a0,0x4
ffffffffc0203782:	5b250513          	addi	a0,a0,1458 # ffffffffc0207d30 <commands+0x1580>
ffffffffc0203786:	94bfc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc020378a:	82eff0ef          	jal	ra,ffffffffc02027b8 <mm_create>
ffffffffc020378e:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc0203790:	60050b63          	beqz	a0,ffffffffc0203da6 <swap_init+0x700>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0203794:	000a9797          	auipc	a5,0xa9
ffffffffc0203798:	cec78793          	addi	a5,a5,-788 # ffffffffc02ac480 <check_mm_struct>
ffffffffc020379c:	639c                	ld	a5,0(a5)
ffffffffc020379e:	62079463          	bnez	a5,ffffffffc0203dc6 <swap_init+0x720>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02037a2:	000a9797          	auipc	a5,0xa9
ffffffffc02037a6:	c5678793          	addi	a5,a5,-938 # ffffffffc02ac3f8 <boot_pgdir>
ffffffffc02037aa:	0007bb03          	ld	s6,0(a5)
     check_mm_struct = mm;
ffffffffc02037ae:	000a9797          	auipc	a5,0xa9
ffffffffc02037b2:	cca7b923          	sd	a0,-814(a5) # ffffffffc02ac480 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc02037b6:	000b3783          	ld	a5,0(s6) # 80000 <_binary_obj___user_exit_out_size+0x75588>
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02037ba:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc02037be:	4e079863          	bnez	a5,ffffffffc0203cae <swap_init+0x608>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc02037c2:	6599                	lui	a1,0x6
ffffffffc02037c4:	460d                	li	a2,3
ffffffffc02037c6:	6505                	lui	a0,0x1
ffffffffc02037c8:	83cff0ef          	jal	ra,ffffffffc0202804 <vma_create>
ffffffffc02037cc:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc02037ce:	50050063          	beqz	a0,ffffffffc0203cce <swap_init+0x628>

     insert_vma_struct(mm, vma);
ffffffffc02037d2:	855e                	mv	a0,s7
ffffffffc02037d4:	89cff0ef          	jal	ra,ffffffffc0202870 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc02037d8:	00004517          	auipc	a0,0x4
ffffffffc02037dc:	59850513          	addi	a0,a0,1432 # ffffffffc0207d70 <commands+0x15c0>
ffffffffc02037e0:	8f1fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc02037e4:	018bb503          	ld	a0,24(s7)
ffffffffc02037e8:	4605                	li	a2,1
ffffffffc02037ea:	6585                	lui	a1,0x1
ffffffffc02037ec:	f94fd0ef          	jal	ra,ffffffffc0200f80 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc02037f0:	4e050f63          	beqz	a0,ffffffffc0203cee <swap_init+0x648>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02037f4:	00004517          	auipc	a0,0x4
ffffffffc02037f8:	5cc50513          	addi	a0,a0,1484 # ffffffffc0207dc0 <commands+0x1610>
ffffffffc02037fc:	000a9997          	auipc	s3,0xa9
ffffffffc0203800:	c8c98993          	addi	s3,s3,-884 # ffffffffc02ac488 <check_rp>
ffffffffc0203804:	8cdfc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203808:	000a9a17          	auipc	s4,0xa9
ffffffffc020380c:	ca0a0a13          	addi	s4,s4,-864 # ffffffffc02ac4a8 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0203810:	8c4e                	mv	s8,s3
          check_rp[i] = alloc_page();
ffffffffc0203812:	4505                	li	a0,1
ffffffffc0203814:	e5efd0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0203818:	00ac3023          	sd	a0,0(s8)
          assert(check_rp[i] != NULL );
ffffffffc020381c:	32050d63          	beqz	a0,ffffffffc0203b56 <swap_init+0x4b0>
ffffffffc0203820:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0203822:	8b89                	andi	a5,a5,2
ffffffffc0203824:	30079963          	bnez	a5,ffffffffc0203b36 <swap_init+0x490>
ffffffffc0203828:	0c21                	addi	s8,s8,8
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020382a:	ff4c14e3          	bne	s8,s4,ffffffffc0203812 <swap_init+0x16c>
     }
     list_entry_t free_list_store = free_list;
ffffffffc020382e:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0203830:	000a9c17          	auipc	s8,0xa9
ffffffffc0203834:	c58c0c13          	addi	s8,s8,-936 # ffffffffc02ac488 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc0203838:	ec3e                	sd	a5,24(sp)
ffffffffc020383a:	641c                	ld	a5,8(s0)
ffffffffc020383c:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc020383e:	481c                	lw	a5,16(s0)
ffffffffc0203840:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc0203842:	000a9797          	auipc	a5,0xa9
ffffffffc0203846:	d087bb23          	sd	s0,-746(a5) # ffffffffc02ac558 <free_area+0x8>
ffffffffc020384a:	000a9797          	auipc	a5,0xa9
ffffffffc020384e:	d087b323          	sd	s0,-762(a5) # ffffffffc02ac550 <free_area>
     nr_free = 0;
ffffffffc0203852:	000a9797          	auipc	a5,0xa9
ffffffffc0203856:	d007a723          	sw	zero,-754(a5) # ffffffffc02ac560 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc020385a:	000c3503          	ld	a0,0(s8)
ffffffffc020385e:	4585                	li	a1,1
ffffffffc0203860:	0c21                	addi	s8,s8,8
ffffffffc0203862:	e98fd0ef          	jal	ra,ffffffffc0200efa <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203866:	ff4c1ae3          	bne	s8,s4,ffffffffc020385a <swap_init+0x1b4>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc020386a:	01042c03          	lw	s8,16(s0)
ffffffffc020386e:	4791                	li	a5,4
ffffffffc0203870:	50fc1b63          	bne	s8,a5,ffffffffc0203d86 <swap_init+0x6e0>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0203874:	00004517          	auipc	a0,0x4
ffffffffc0203878:	5d450513          	addi	a0,a0,1492 # ffffffffc0207e48 <commands+0x1698>
ffffffffc020387c:	855fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203880:	6685                	lui	a3,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0203882:	000a9797          	auipc	a5,0xa9
ffffffffc0203886:	b807a323          	sw	zero,-1146(a5) # ffffffffc02ac408 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc020388a:	4629                	li	a2,10
     pgfault_num=0;
ffffffffc020388c:	000a9797          	auipc	a5,0xa9
ffffffffc0203890:	b7c78793          	addi	a5,a5,-1156 # ffffffffc02ac408 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203894:	00c68023          	sb	a2,0(a3) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
     assert(pgfault_num==1);
ffffffffc0203898:	4398                	lw	a4,0(a5)
ffffffffc020389a:	4585                	li	a1,1
ffffffffc020389c:	2701                	sext.w	a4,a4
ffffffffc020389e:	38b71863          	bne	a4,a1,ffffffffc0203c2e <swap_init+0x588>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc02038a2:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==1);
ffffffffc02038a6:	4394                	lw	a3,0(a5)
ffffffffc02038a8:	2681                	sext.w	a3,a3
ffffffffc02038aa:	3ae69263          	bne	a3,a4,ffffffffc0203c4e <swap_init+0x5a8>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc02038ae:	6689                	lui	a3,0x2
ffffffffc02038b0:	462d                	li	a2,11
ffffffffc02038b2:	00c68023          	sb	a2,0(a3) # 2000 <_binary_obj___user_faultread_out_size-0x7570>
     assert(pgfault_num==2);
ffffffffc02038b6:	4398                	lw	a4,0(a5)
ffffffffc02038b8:	4589                	li	a1,2
ffffffffc02038ba:	2701                	sext.w	a4,a4
ffffffffc02038bc:	2eb71963          	bne	a4,a1,ffffffffc0203bae <swap_init+0x508>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc02038c0:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc02038c4:	4394                	lw	a3,0(a5)
ffffffffc02038c6:	2681                	sext.w	a3,a3
ffffffffc02038c8:	30e69363          	bne	a3,a4,ffffffffc0203bce <swap_init+0x528>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc02038cc:	668d                	lui	a3,0x3
ffffffffc02038ce:	4631                	li	a2,12
ffffffffc02038d0:	00c68023          	sb	a2,0(a3) # 3000 <_binary_obj___user_faultread_out_size-0x6570>
     assert(pgfault_num==3);
ffffffffc02038d4:	4398                	lw	a4,0(a5)
ffffffffc02038d6:	458d                	li	a1,3
ffffffffc02038d8:	2701                	sext.w	a4,a4
ffffffffc02038da:	30b71a63          	bne	a4,a1,ffffffffc0203bee <swap_init+0x548>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc02038de:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc02038e2:	4394                	lw	a3,0(a5)
ffffffffc02038e4:	2681                	sext.w	a3,a3
ffffffffc02038e6:	32e69463          	bne	a3,a4,ffffffffc0203c0e <swap_init+0x568>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc02038ea:	6691                	lui	a3,0x4
ffffffffc02038ec:	4635                	li	a2,13
ffffffffc02038ee:	00c68023          	sb	a2,0(a3) # 4000 <_binary_obj___user_faultread_out_size-0x5570>
     assert(pgfault_num==4);
ffffffffc02038f2:	4398                	lw	a4,0(a5)
ffffffffc02038f4:	2701                	sext.w	a4,a4
ffffffffc02038f6:	37871c63          	bne	a4,s8,ffffffffc0203c6e <swap_init+0x5c8>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc02038fa:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc02038fe:	439c                	lw	a5,0(a5)
ffffffffc0203900:	2781                	sext.w	a5,a5
ffffffffc0203902:	38e79663          	bne	a5,a4,ffffffffc0203c8e <swap_init+0x5e8>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0203906:	481c                	lw	a5,16(s0)
ffffffffc0203908:	40079363          	bnez	a5,ffffffffc0203d0e <swap_init+0x668>
ffffffffc020390c:	000a9797          	auipc	a5,0xa9
ffffffffc0203910:	b9c78793          	addi	a5,a5,-1124 # ffffffffc02ac4a8 <swap_in_seq_no>
ffffffffc0203914:	000a9717          	auipc	a4,0xa9
ffffffffc0203918:	bbc70713          	addi	a4,a4,-1092 # ffffffffc02ac4d0 <swap_out_seq_no>
ffffffffc020391c:	000a9617          	auipc	a2,0xa9
ffffffffc0203920:	bb460613          	addi	a2,a2,-1100 # ffffffffc02ac4d0 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0203924:	56fd                	li	a3,-1
ffffffffc0203926:	c394                	sw	a3,0(a5)
ffffffffc0203928:	c314                	sw	a3,0(a4)
ffffffffc020392a:	0791                	addi	a5,a5,4
ffffffffc020392c:	0711                	addi	a4,a4,4
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc020392e:	fef61ce3          	bne	a2,a5,ffffffffc0203926 <swap_init+0x280>
ffffffffc0203932:	000a9697          	auipc	a3,0xa9
ffffffffc0203936:	bfe68693          	addi	a3,a3,-1026 # ffffffffc02ac530 <check_ptep>
ffffffffc020393a:	000a9817          	auipc	a6,0xa9
ffffffffc020393e:	b4e80813          	addi	a6,a6,-1202 # ffffffffc02ac488 <check_rp>
ffffffffc0203942:	6d05                	lui	s10,0x1
    if (PPN(pa) >= npage) {
ffffffffc0203944:	000a9c97          	auipc	s9,0xa9
ffffffffc0203948:	abcc8c93          	addi	s9,s9,-1348 # ffffffffc02ac400 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020394c:	00005d97          	auipc	s11,0x5
ffffffffc0203950:	41cd8d93          	addi	s11,s11,1052 # ffffffffc0208d68 <nbase>
ffffffffc0203954:	000a9c17          	auipc	s8,0xa9
ffffffffc0203958:	b14c0c13          	addi	s8,s8,-1260 # ffffffffc02ac468 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc020395c:	0006b023          	sd	zero,0(a3)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203960:	4601                	li	a2,0
ffffffffc0203962:	85ea                	mv	a1,s10
ffffffffc0203964:	855a                	mv	a0,s6
ffffffffc0203966:	e842                	sd	a6,16(sp)
         check_ptep[i]=0;
ffffffffc0203968:	e436                	sd	a3,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc020396a:	e16fd0ef          	jal	ra,ffffffffc0200f80 <get_pte>
ffffffffc020396e:	66a2                	ld	a3,8(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0203970:	6842                	ld	a6,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203972:	e288                	sd	a0,0(a3)
         assert(check_ptep[i] != NULL);
ffffffffc0203974:	20050163          	beqz	a0,ffffffffc0203b76 <swap_init+0x4d0>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0203978:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020397a:	0017f613          	andi	a2,a5,1
ffffffffc020397e:	1a060063          	beqz	a2,ffffffffc0203b1e <swap_init+0x478>
    if (PPN(pa) >= npage) {
ffffffffc0203982:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203986:	078a                	slli	a5,a5,0x2
ffffffffc0203988:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020398a:	14c7fe63          	bleu	a2,a5,ffffffffc0203ae6 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc020398e:	000db703          	ld	a4,0(s11)
ffffffffc0203992:	000c3603          	ld	a2,0(s8)
ffffffffc0203996:	00083583          	ld	a1,0(a6)
ffffffffc020399a:	8f99                	sub	a5,a5,a4
ffffffffc020399c:	079a                	slli	a5,a5,0x6
ffffffffc020399e:	e43a                	sd	a4,8(sp)
ffffffffc02039a0:	97b2                	add	a5,a5,a2
ffffffffc02039a2:	14f59e63          	bne	a1,a5,ffffffffc0203afe <swap_init+0x458>
ffffffffc02039a6:	6785                	lui	a5,0x1
ffffffffc02039a8:	9d3e                	add	s10,s10,a5
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02039aa:	6795                	lui	a5,0x5
ffffffffc02039ac:	06a1                	addi	a3,a3,8
ffffffffc02039ae:	0821                	addi	a6,a6,8
ffffffffc02039b0:	fafd16e3          	bne	s10,a5,ffffffffc020395c <swap_init+0x2b6>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc02039b4:	00004517          	auipc	a0,0x4
ffffffffc02039b8:	53c50513          	addi	a0,a0,1340 # ffffffffc0207ef0 <commands+0x1740>
ffffffffc02039bc:	f14fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    int ret = sm->check_swap();
ffffffffc02039c0:	000a9797          	auipc	a5,0xa9
ffffffffc02039c4:	a5878793          	addi	a5,a5,-1448 # ffffffffc02ac418 <sm>
ffffffffc02039c8:	639c                	ld	a5,0(a5)
ffffffffc02039ca:	7f9c                	ld	a5,56(a5)
ffffffffc02039cc:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc02039ce:	40051c63          	bnez	a0,ffffffffc0203de6 <swap_init+0x740>

     nr_free = nr_free_store;
ffffffffc02039d2:	77a2                	ld	a5,40(sp)
ffffffffc02039d4:	000a9717          	auipc	a4,0xa9
ffffffffc02039d8:	b8f72623          	sw	a5,-1140(a4) # ffffffffc02ac560 <free_area+0x10>
     free_list = free_list_store;
ffffffffc02039dc:	67e2                	ld	a5,24(sp)
ffffffffc02039de:	000a9717          	auipc	a4,0xa9
ffffffffc02039e2:	b6f73923          	sd	a5,-1166(a4) # ffffffffc02ac550 <free_area>
ffffffffc02039e6:	7782                	ld	a5,32(sp)
ffffffffc02039e8:	000a9717          	auipc	a4,0xa9
ffffffffc02039ec:	b6f73823          	sd	a5,-1168(a4) # ffffffffc02ac558 <free_area+0x8>

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc02039f0:	0009b503          	ld	a0,0(s3)
ffffffffc02039f4:	4585                	li	a1,1
ffffffffc02039f6:	09a1                	addi	s3,s3,8
ffffffffc02039f8:	d02fd0ef          	jal	ra,ffffffffc0200efa <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02039fc:	ff499ae3          	bne	s3,s4,ffffffffc02039f0 <swap_init+0x34a>
     } 

     //free_page(pte2page(*temp_ptep));

     mm->pgdir = NULL;
ffffffffc0203a00:	000bbc23          	sd	zero,24(s7)
     mm_destroy(mm);
ffffffffc0203a04:	855e                	mv	a0,s7
ffffffffc0203a06:	f39fe0ef          	jal	ra,ffffffffc020293e <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0203a0a:	000a9797          	auipc	a5,0xa9
ffffffffc0203a0e:	9ee78793          	addi	a5,a5,-1554 # ffffffffc02ac3f8 <boot_pgdir>
ffffffffc0203a12:	639c                	ld	a5,0(a5)
     check_mm_struct = NULL;
ffffffffc0203a14:	000a9697          	auipc	a3,0xa9
ffffffffc0203a18:	a606b623          	sd	zero,-1428(a3) # ffffffffc02ac480 <check_mm_struct>
    if (PPN(pa) >= npage) {
ffffffffc0203a1c:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203a20:	6394                	ld	a3,0(a5)
ffffffffc0203a22:	068a                	slli	a3,a3,0x2
ffffffffc0203a24:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203a26:	0ce6f063          	bleu	a4,a3,ffffffffc0203ae6 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203a2a:	67a2                	ld	a5,8(sp)
ffffffffc0203a2c:	000c3503          	ld	a0,0(s8)
ffffffffc0203a30:	8e9d                	sub	a3,a3,a5
ffffffffc0203a32:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0203a34:	8699                	srai	a3,a3,0x6
ffffffffc0203a36:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203a38:	57fd                	li	a5,-1
ffffffffc0203a3a:	83b1                	srli	a5,a5,0xc
ffffffffc0203a3c:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0203a3e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203a40:	2ee7f763          	bleu	a4,a5,ffffffffc0203d2e <swap_init+0x688>
     free_page(pde2page(pd0[0]));
ffffffffc0203a44:	000a9797          	auipc	a5,0xa9
ffffffffc0203a48:	a1478793          	addi	a5,a5,-1516 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0203a4c:	639c                	ld	a5,0(a5)
ffffffffc0203a4e:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0203a50:	629c                	ld	a5,0(a3)
ffffffffc0203a52:	078a                	slli	a5,a5,0x2
ffffffffc0203a54:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203a56:	08e7f863          	bleu	a4,a5,ffffffffc0203ae6 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203a5a:	69a2                	ld	s3,8(sp)
ffffffffc0203a5c:	4585                	li	a1,1
ffffffffc0203a5e:	413787b3          	sub	a5,a5,s3
ffffffffc0203a62:	079a                	slli	a5,a5,0x6
ffffffffc0203a64:	953e                	add	a0,a0,a5
ffffffffc0203a66:	c94fd0ef          	jal	ra,ffffffffc0200efa <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203a6a:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0203a6e:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203a72:	078a                	slli	a5,a5,0x2
ffffffffc0203a74:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203a76:	06e7f863          	bleu	a4,a5,ffffffffc0203ae6 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203a7a:	000c3503          	ld	a0,0(s8)
ffffffffc0203a7e:	413787b3          	sub	a5,a5,s3
ffffffffc0203a82:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc0203a84:	4585                	li	a1,1
ffffffffc0203a86:	953e                	add	a0,a0,a5
ffffffffc0203a88:	c72fd0ef          	jal	ra,ffffffffc0200efa <free_pages>
     pgdir[0] = 0;
ffffffffc0203a8c:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc0203a90:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0203a94:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203a96:	00878963          	beq	a5,s0,ffffffffc0203aa8 <swap_init+0x402>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0203a9a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203a9e:	679c                	ld	a5,8(a5)
ffffffffc0203aa0:	397d                	addiw	s2,s2,-1
ffffffffc0203aa2:	9c99                	subw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203aa4:	fe879be3          	bne	a5,s0,ffffffffc0203a9a <swap_init+0x3f4>
     }
     assert(count==0);
ffffffffc0203aa8:	28091f63          	bnez	s2,ffffffffc0203d46 <swap_init+0x6a0>
     assert(total==0);
ffffffffc0203aac:	2a049d63          	bnez	s1,ffffffffc0203d66 <swap_init+0x6c0>

     cprintf("check_swap() succeeded!\n");
ffffffffc0203ab0:	00004517          	auipc	a0,0x4
ffffffffc0203ab4:	49050513          	addi	a0,a0,1168 # ffffffffc0207f40 <commands+0x1790>
ffffffffc0203ab8:	e18fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0203abc:	b92d                	j	ffffffffc02036f6 <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc0203abe:	4481                	li	s1,0
ffffffffc0203ac0:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203ac2:	4981                	li	s3,0
ffffffffc0203ac4:	b17d                	j	ffffffffc0203772 <swap_init+0xcc>
        assert(PageProperty(p));
ffffffffc0203ac6:	00004697          	auipc	a3,0x4
ffffffffc0203aca:	23a68693          	addi	a3,a3,570 # ffffffffc0207d00 <commands+0x1550>
ffffffffc0203ace:	00003617          	auipc	a2,0x3
ffffffffc0203ad2:	16260613          	addi	a2,a2,354 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203ad6:	0bc00593          	li	a1,188
ffffffffc0203ada:	00004517          	auipc	a0,0x4
ffffffffc0203ade:	1fe50513          	addi	a0,a0,510 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203ae2:	f34fc0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203ae6:	00003617          	auipc	a2,0x3
ffffffffc0203aea:	56a60613          	addi	a2,a2,1386 # ffffffffc0207050 <commands+0x8a0>
ffffffffc0203aee:	06200593          	li	a1,98
ffffffffc0203af2:	00003517          	auipc	a0,0x3
ffffffffc0203af6:	57e50513          	addi	a0,a0,1406 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0203afa:	f1cfc0ef          	jal	ra,ffffffffc0200216 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0203afe:	00004697          	auipc	a3,0x4
ffffffffc0203b02:	3ca68693          	addi	a3,a3,970 # ffffffffc0207ec8 <commands+0x1718>
ffffffffc0203b06:	00003617          	auipc	a2,0x3
ffffffffc0203b0a:	12a60613          	addi	a2,a2,298 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203b0e:	0fc00593          	li	a1,252
ffffffffc0203b12:	00004517          	auipc	a0,0x4
ffffffffc0203b16:	1c650513          	addi	a0,a0,454 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203b1a:	efcfc0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203b1e:	00003617          	auipc	a2,0x3
ffffffffc0203b22:	71260613          	addi	a2,a2,1810 # ffffffffc0207230 <commands+0xa80>
ffffffffc0203b26:	07400593          	li	a1,116
ffffffffc0203b2a:	00003517          	auipc	a0,0x3
ffffffffc0203b2e:	54650513          	addi	a0,a0,1350 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0203b32:	ee4fc0ef          	jal	ra,ffffffffc0200216 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0203b36:	00004697          	auipc	a3,0x4
ffffffffc0203b3a:	2ca68693          	addi	a3,a3,714 # ffffffffc0207e00 <commands+0x1650>
ffffffffc0203b3e:	00003617          	auipc	a2,0x3
ffffffffc0203b42:	0f260613          	addi	a2,a2,242 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203b46:	0dd00593          	li	a1,221
ffffffffc0203b4a:	00004517          	auipc	a0,0x4
ffffffffc0203b4e:	18e50513          	addi	a0,a0,398 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203b52:	ec4fc0ef          	jal	ra,ffffffffc0200216 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0203b56:	00004697          	auipc	a3,0x4
ffffffffc0203b5a:	29268693          	addi	a3,a3,658 # ffffffffc0207de8 <commands+0x1638>
ffffffffc0203b5e:	00003617          	auipc	a2,0x3
ffffffffc0203b62:	0d260613          	addi	a2,a2,210 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203b66:	0dc00593          	li	a1,220
ffffffffc0203b6a:	00004517          	auipc	a0,0x4
ffffffffc0203b6e:	16e50513          	addi	a0,a0,366 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203b72:	ea4fc0ef          	jal	ra,ffffffffc0200216 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0203b76:	00004697          	auipc	a3,0x4
ffffffffc0203b7a:	33a68693          	addi	a3,a3,826 # ffffffffc0207eb0 <commands+0x1700>
ffffffffc0203b7e:	00003617          	auipc	a2,0x3
ffffffffc0203b82:	0b260613          	addi	a2,a2,178 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203b86:	0fb00593          	li	a1,251
ffffffffc0203b8a:	00004517          	auipc	a0,0x4
ffffffffc0203b8e:	14e50513          	addi	a0,a0,334 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203b92:	e84fc0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0203b96:	00004617          	auipc	a2,0x4
ffffffffc0203b9a:	12260613          	addi	a2,a2,290 # ffffffffc0207cb8 <commands+0x1508>
ffffffffc0203b9e:	02800593          	li	a1,40
ffffffffc0203ba2:	00004517          	auipc	a0,0x4
ffffffffc0203ba6:	13650513          	addi	a0,a0,310 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203baa:	e6cfc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==2);
ffffffffc0203bae:	00004697          	auipc	a3,0x4
ffffffffc0203bb2:	2d268693          	addi	a3,a3,722 # ffffffffc0207e80 <commands+0x16d0>
ffffffffc0203bb6:	00003617          	auipc	a2,0x3
ffffffffc0203bba:	07a60613          	addi	a2,a2,122 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203bbe:	09700593          	li	a1,151
ffffffffc0203bc2:	00004517          	auipc	a0,0x4
ffffffffc0203bc6:	11650513          	addi	a0,a0,278 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203bca:	e4cfc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==2);
ffffffffc0203bce:	00004697          	auipc	a3,0x4
ffffffffc0203bd2:	2b268693          	addi	a3,a3,690 # ffffffffc0207e80 <commands+0x16d0>
ffffffffc0203bd6:	00003617          	auipc	a2,0x3
ffffffffc0203bda:	05a60613          	addi	a2,a2,90 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203bde:	09900593          	li	a1,153
ffffffffc0203be2:	00004517          	auipc	a0,0x4
ffffffffc0203be6:	0f650513          	addi	a0,a0,246 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203bea:	e2cfc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==3);
ffffffffc0203bee:	00004697          	auipc	a3,0x4
ffffffffc0203bf2:	2a268693          	addi	a3,a3,674 # ffffffffc0207e90 <commands+0x16e0>
ffffffffc0203bf6:	00003617          	auipc	a2,0x3
ffffffffc0203bfa:	03a60613          	addi	a2,a2,58 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203bfe:	09b00593          	li	a1,155
ffffffffc0203c02:	00004517          	auipc	a0,0x4
ffffffffc0203c06:	0d650513          	addi	a0,a0,214 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203c0a:	e0cfc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==3);
ffffffffc0203c0e:	00004697          	auipc	a3,0x4
ffffffffc0203c12:	28268693          	addi	a3,a3,642 # ffffffffc0207e90 <commands+0x16e0>
ffffffffc0203c16:	00003617          	auipc	a2,0x3
ffffffffc0203c1a:	01a60613          	addi	a2,a2,26 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203c1e:	09d00593          	li	a1,157
ffffffffc0203c22:	00004517          	auipc	a0,0x4
ffffffffc0203c26:	0b650513          	addi	a0,a0,182 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203c2a:	decfc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==1);
ffffffffc0203c2e:	00004697          	auipc	a3,0x4
ffffffffc0203c32:	24268693          	addi	a3,a3,578 # ffffffffc0207e70 <commands+0x16c0>
ffffffffc0203c36:	00003617          	auipc	a2,0x3
ffffffffc0203c3a:	ffa60613          	addi	a2,a2,-6 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203c3e:	09300593          	li	a1,147
ffffffffc0203c42:	00004517          	auipc	a0,0x4
ffffffffc0203c46:	09650513          	addi	a0,a0,150 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203c4a:	dccfc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==1);
ffffffffc0203c4e:	00004697          	auipc	a3,0x4
ffffffffc0203c52:	22268693          	addi	a3,a3,546 # ffffffffc0207e70 <commands+0x16c0>
ffffffffc0203c56:	00003617          	auipc	a2,0x3
ffffffffc0203c5a:	fda60613          	addi	a2,a2,-38 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203c5e:	09500593          	li	a1,149
ffffffffc0203c62:	00004517          	auipc	a0,0x4
ffffffffc0203c66:	07650513          	addi	a0,a0,118 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203c6a:	dacfc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==4);
ffffffffc0203c6e:	00004697          	auipc	a3,0x4
ffffffffc0203c72:	a1268693          	addi	a3,a3,-1518 # ffffffffc0207680 <commands+0xed0>
ffffffffc0203c76:	00003617          	auipc	a2,0x3
ffffffffc0203c7a:	fba60613          	addi	a2,a2,-70 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203c7e:	09f00593          	li	a1,159
ffffffffc0203c82:	00004517          	auipc	a0,0x4
ffffffffc0203c86:	05650513          	addi	a0,a0,86 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203c8a:	d8cfc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==4);
ffffffffc0203c8e:	00004697          	auipc	a3,0x4
ffffffffc0203c92:	9f268693          	addi	a3,a3,-1550 # ffffffffc0207680 <commands+0xed0>
ffffffffc0203c96:	00003617          	auipc	a2,0x3
ffffffffc0203c9a:	f9a60613          	addi	a2,a2,-102 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203c9e:	0a100593          	li	a1,161
ffffffffc0203ca2:	00004517          	auipc	a0,0x4
ffffffffc0203ca6:	03650513          	addi	a0,a0,54 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203caa:	d6cfc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0203cae:	00004697          	auipc	a3,0x4
ffffffffc0203cb2:	e9a68693          	addi	a3,a3,-358 # ffffffffc0207b48 <commands+0x1398>
ffffffffc0203cb6:	00003617          	auipc	a2,0x3
ffffffffc0203cba:	f7a60613          	addi	a2,a2,-134 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203cbe:	0cc00593          	li	a1,204
ffffffffc0203cc2:	00004517          	auipc	a0,0x4
ffffffffc0203cc6:	01650513          	addi	a0,a0,22 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203cca:	d4cfc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(vma != NULL);
ffffffffc0203cce:	00004697          	auipc	a3,0x4
ffffffffc0203cd2:	f1a68693          	addi	a3,a3,-230 # ffffffffc0207be8 <commands+0x1438>
ffffffffc0203cd6:	00003617          	auipc	a2,0x3
ffffffffc0203cda:	f5a60613          	addi	a2,a2,-166 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203cde:	0cf00593          	li	a1,207
ffffffffc0203ce2:	00004517          	auipc	a0,0x4
ffffffffc0203ce6:	ff650513          	addi	a0,a0,-10 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203cea:	d2cfc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0203cee:	00004697          	auipc	a3,0x4
ffffffffc0203cf2:	0ba68693          	addi	a3,a3,186 # ffffffffc0207da8 <commands+0x15f8>
ffffffffc0203cf6:	00003617          	auipc	a2,0x3
ffffffffc0203cfa:	f3a60613          	addi	a2,a2,-198 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203cfe:	0d700593          	li	a1,215
ffffffffc0203d02:	00004517          	auipc	a0,0x4
ffffffffc0203d06:	fd650513          	addi	a0,a0,-42 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203d0a:	d0cfc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert( nr_free == 0);         
ffffffffc0203d0e:	00004697          	auipc	a3,0x4
ffffffffc0203d12:	19268693          	addi	a3,a3,402 # ffffffffc0207ea0 <commands+0x16f0>
ffffffffc0203d16:	00003617          	auipc	a2,0x3
ffffffffc0203d1a:	f1a60613          	addi	a2,a2,-230 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203d1e:	0f300593          	li	a1,243
ffffffffc0203d22:	00004517          	auipc	a0,0x4
ffffffffc0203d26:	fb650513          	addi	a0,a0,-74 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203d2a:	cecfc0ef          	jal	ra,ffffffffc0200216 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203d2e:	00003617          	auipc	a2,0x3
ffffffffc0203d32:	2ea60613          	addi	a2,a2,746 # ffffffffc0207018 <commands+0x868>
ffffffffc0203d36:	06900593          	li	a1,105
ffffffffc0203d3a:	00003517          	auipc	a0,0x3
ffffffffc0203d3e:	33650513          	addi	a0,a0,822 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0203d42:	cd4fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(count==0);
ffffffffc0203d46:	00004697          	auipc	a3,0x4
ffffffffc0203d4a:	1da68693          	addi	a3,a3,474 # ffffffffc0207f20 <commands+0x1770>
ffffffffc0203d4e:	00003617          	auipc	a2,0x3
ffffffffc0203d52:	ee260613          	addi	a2,a2,-286 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203d56:	11d00593          	li	a1,285
ffffffffc0203d5a:	00004517          	auipc	a0,0x4
ffffffffc0203d5e:	f7e50513          	addi	a0,a0,-130 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203d62:	cb4fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(total==0);
ffffffffc0203d66:	00004697          	auipc	a3,0x4
ffffffffc0203d6a:	1ca68693          	addi	a3,a3,458 # ffffffffc0207f30 <commands+0x1780>
ffffffffc0203d6e:	00003617          	auipc	a2,0x3
ffffffffc0203d72:	ec260613          	addi	a2,a2,-318 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203d76:	11e00593          	li	a1,286
ffffffffc0203d7a:	00004517          	auipc	a0,0x4
ffffffffc0203d7e:	f5e50513          	addi	a0,a0,-162 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203d82:	c94fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203d86:	00004697          	auipc	a3,0x4
ffffffffc0203d8a:	09a68693          	addi	a3,a3,154 # ffffffffc0207e20 <commands+0x1670>
ffffffffc0203d8e:	00003617          	auipc	a2,0x3
ffffffffc0203d92:	ea260613          	addi	a2,a2,-350 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203d96:	0ea00593          	li	a1,234
ffffffffc0203d9a:	00004517          	auipc	a0,0x4
ffffffffc0203d9e:	f3e50513          	addi	a0,a0,-194 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203da2:	c74fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(mm != NULL);
ffffffffc0203da6:	00004697          	auipc	a3,0x4
ffffffffc0203daa:	c1a68693          	addi	a3,a3,-998 # ffffffffc02079c0 <commands+0x1210>
ffffffffc0203dae:	00003617          	auipc	a2,0x3
ffffffffc0203db2:	e8260613          	addi	a2,a2,-382 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203db6:	0c400593          	li	a1,196
ffffffffc0203dba:	00004517          	auipc	a0,0x4
ffffffffc0203dbe:	f1e50513          	addi	a0,a0,-226 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203dc2:	c54fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0203dc6:	00004697          	auipc	a3,0x4
ffffffffc0203dca:	f9268693          	addi	a3,a3,-110 # ffffffffc0207d58 <commands+0x15a8>
ffffffffc0203dce:	00003617          	auipc	a2,0x3
ffffffffc0203dd2:	e6260613          	addi	a2,a2,-414 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203dd6:	0c700593          	li	a1,199
ffffffffc0203dda:	00004517          	auipc	a0,0x4
ffffffffc0203dde:	efe50513          	addi	a0,a0,-258 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203de2:	c34fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(ret==0);
ffffffffc0203de6:	00004697          	auipc	a3,0x4
ffffffffc0203dea:	13268693          	addi	a3,a3,306 # ffffffffc0207f18 <commands+0x1768>
ffffffffc0203dee:	00003617          	auipc	a2,0x3
ffffffffc0203df2:	e4260613          	addi	a2,a2,-446 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203df6:	10200593          	li	a1,258
ffffffffc0203dfa:	00004517          	auipc	a0,0x4
ffffffffc0203dfe:	ede50513          	addi	a0,a0,-290 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203e02:	c14fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(total == nr_free_pages());
ffffffffc0203e06:	00004697          	auipc	a3,0x4
ffffffffc0203e0a:	f0a68693          	addi	a3,a3,-246 # ffffffffc0207d10 <commands+0x1560>
ffffffffc0203e0e:	00003617          	auipc	a2,0x3
ffffffffc0203e12:	e2260613          	addi	a2,a2,-478 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203e16:	0bf00593          	li	a1,191
ffffffffc0203e1a:	00004517          	auipc	a0,0x4
ffffffffc0203e1e:	ebe50513          	addi	a0,a0,-322 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203e22:	bf4fc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0203e26 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0203e26:	000a8797          	auipc	a5,0xa8
ffffffffc0203e2a:	5f278793          	addi	a5,a5,1522 # ffffffffc02ac418 <sm>
ffffffffc0203e2e:	639c                	ld	a5,0(a5)
ffffffffc0203e30:	0107b303          	ld	t1,16(a5)
ffffffffc0203e34:	8302                	jr	t1

ffffffffc0203e36 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0203e36:	000a8797          	auipc	a5,0xa8
ffffffffc0203e3a:	5e278793          	addi	a5,a5,1506 # ffffffffc02ac418 <sm>
ffffffffc0203e3e:	639c                	ld	a5,0(a5)
ffffffffc0203e40:	0207b303          	ld	t1,32(a5)
ffffffffc0203e44:	8302                	jr	t1

ffffffffc0203e46 <swap_out>:
{
ffffffffc0203e46:	711d                	addi	sp,sp,-96
ffffffffc0203e48:	ec86                	sd	ra,88(sp)
ffffffffc0203e4a:	e8a2                	sd	s0,80(sp)
ffffffffc0203e4c:	e4a6                	sd	s1,72(sp)
ffffffffc0203e4e:	e0ca                	sd	s2,64(sp)
ffffffffc0203e50:	fc4e                	sd	s3,56(sp)
ffffffffc0203e52:	f852                	sd	s4,48(sp)
ffffffffc0203e54:	f456                	sd	s5,40(sp)
ffffffffc0203e56:	f05a                	sd	s6,32(sp)
ffffffffc0203e58:	ec5e                	sd	s7,24(sp)
ffffffffc0203e5a:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203e5c:	cde9                	beqz	a1,ffffffffc0203f36 <swap_out+0xf0>
ffffffffc0203e5e:	8ab2                	mv	s5,a2
ffffffffc0203e60:	892a                	mv	s2,a0
ffffffffc0203e62:	8a2e                	mv	s4,a1
ffffffffc0203e64:	4401                	li	s0,0
ffffffffc0203e66:	000a8997          	auipc	s3,0xa8
ffffffffc0203e6a:	5b298993          	addi	s3,s3,1458 # ffffffffc02ac418 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203e6e:	00004b17          	auipc	s6,0x4
ffffffffc0203e72:	152b0b13          	addi	s6,s6,338 # ffffffffc0207fc0 <commands+0x1810>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203e76:	00004b97          	auipc	s7,0x4
ffffffffc0203e7a:	132b8b93          	addi	s7,s7,306 # ffffffffc0207fa8 <commands+0x17f8>
ffffffffc0203e7e:	a825                	j	ffffffffc0203eb6 <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203e80:	67a2                	ld	a5,8(sp)
ffffffffc0203e82:	8626                	mv	a2,s1
ffffffffc0203e84:	85a2                	mv	a1,s0
ffffffffc0203e86:	7f94                	ld	a3,56(a5)
ffffffffc0203e88:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0203e8a:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203e8c:	82b1                	srli	a3,a3,0xc
ffffffffc0203e8e:	0685                	addi	a3,a3,1
ffffffffc0203e90:	a40fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203e94:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203e96:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203e98:	7d1c                	ld	a5,56(a0)
ffffffffc0203e9a:	83b1                	srli	a5,a5,0xc
ffffffffc0203e9c:	0785                	addi	a5,a5,1
ffffffffc0203e9e:	07a2                	slli	a5,a5,0x8
ffffffffc0203ea0:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203ea4:	856fd0ef          	jal	ra,ffffffffc0200efa <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0203ea8:	01893503          	ld	a0,24(s2)
ffffffffc0203eac:	85a6                	mv	a1,s1
ffffffffc0203eae:	c64fe0ef          	jal	ra,ffffffffc0202312 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203eb2:	048a0d63          	beq	s4,s0,ffffffffc0203f0c <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203eb6:	0009b783          	ld	a5,0(s3)
ffffffffc0203eba:	8656                	mv	a2,s5
ffffffffc0203ebc:	002c                	addi	a1,sp,8
ffffffffc0203ebe:	7b9c                	ld	a5,48(a5)
ffffffffc0203ec0:	854a                	mv	a0,s2
ffffffffc0203ec2:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203ec4:	e12d                	bnez	a0,ffffffffc0203f26 <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0203ec6:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203ec8:	01893503          	ld	a0,24(s2)
ffffffffc0203ecc:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203ece:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203ed0:	85a6                	mv	a1,s1
ffffffffc0203ed2:	8aefd0ef          	jal	ra,ffffffffc0200f80 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203ed6:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203ed8:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203eda:	8b85                	andi	a5,a5,1
ffffffffc0203edc:	cfb9                	beqz	a5,ffffffffc0203f3a <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203ede:	65a2                	ld	a1,8(sp)
ffffffffc0203ee0:	7d9c                	ld	a5,56(a1)
ffffffffc0203ee2:	83b1                	srli	a5,a5,0xc
ffffffffc0203ee4:	00178513          	addi	a0,a5,1
ffffffffc0203ee8:	0522                	slli	a0,a0,0x8
ffffffffc0203eea:	509000ef          	jal	ra,ffffffffc0204bf2 <swapfs_write>
ffffffffc0203eee:	d949                	beqz	a0,ffffffffc0203e80 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203ef0:	855e                	mv	a0,s7
ffffffffc0203ef2:	9defc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203ef6:	0009b783          	ld	a5,0(s3)
ffffffffc0203efa:	6622                	ld	a2,8(sp)
ffffffffc0203efc:	4681                	li	a3,0
ffffffffc0203efe:	739c                	ld	a5,32(a5)
ffffffffc0203f00:	85a6                	mv	a1,s1
ffffffffc0203f02:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203f04:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203f06:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0203f08:	fa8a17e3          	bne	s4,s0,ffffffffc0203eb6 <swap_out+0x70>
}
ffffffffc0203f0c:	8522                	mv	a0,s0
ffffffffc0203f0e:	60e6                	ld	ra,88(sp)
ffffffffc0203f10:	6446                	ld	s0,80(sp)
ffffffffc0203f12:	64a6                	ld	s1,72(sp)
ffffffffc0203f14:	6906                	ld	s2,64(sp)
ffffffffc0203f16:	79e2                	ld	s3,56(sp)
ffffffffc0203f18:	7a42                	ld	s4,48(sp)
ffffffffc0203f1a:	7aa2                	ld	s5,40(sp)
ffffffffc0203f1c:	7b02                	ld	s6,32(sp)
ffffffffc0203f1e:	6be2                	ld	s7,24(sp)
ffffffffc0203f20:	6c42                	ld	s8,16(sp)
ffffffffc0203f22:	6125                	addi	sp,sp,96
ffffffffc0203f24:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203f26:	85a2                	mv	a1,s0
ffffffffc0203f28:	00004517          	auipc	a0,0x4
ffffffffc0203f2c:	03850513          	addi	a0,a0,56 # ffffffffc0207f60 <commands+0x17b0>
ffffffffc0203f30:	9a0fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
                  break;
ffffffffc0203f34:	bfe1                	j	ffffffffc0203f0c <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0203f36:	4401                	li	s0,0
ffffffffc0203f38:	bfd1                	j	ffffffffc0203f0c <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203f3a:	00004697          	auipc	a3,0x4
ffffffffc0203f3e:	05668693          	addi	a3,a3,86 # ffffffffc0207f90 <commands+0x17e0>
ffffffffc0203f42:	00003617          	auipc	a2,0x3
ffffffffc0203f46:	cee60613          	addi	a2,a2,-786 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203f4a:	06800593          	li	a1,104
ffffffffc0203f4e:	00004517          	auipc	a0,0x4
ffffffffc0203f52:	d8a50513          	addi	a0,a0,-630 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203f56:	ac0fc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0203f5a <swap_in>:
{
ffffffffc0203f5a:	7179                	addi	sp,sp,-48
ffffffffc0203f5c:	e84a                	sd	s2,16(sp)
ffffffffc0203f5e:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203f60:	4505                	li	a0,1
{
ffffffffc0203f62:	ec26                	sd	s1,24(sp)
ffffffffc0203f64:	e44e                	sd	s3,8(sp)
ffffffffc0203f66:	f406                	sd	ra,40(sp)
ffffffffc0203f68:	f022                	sd	s0,32(sp)
ffffffffc0203f6a:	84ae                	mv	s1,a1
ffffffffc0203f6c:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0203f6e:	f05fc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
     assert(result!=NULL);
ffffffffc0203f72:	c129                	beqz	a0,ffffffffc0203fb4 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203f74:	842a                	mv	s0,a0
ffffffffc0203f76:	01893503          	ld	a0,24(s2)
ffffffffc0203f7a:	4601                	li	a2,0
ffffffffc0203f7c:	85a6                	mv	a1,s1
ffffffffc0203f7e:	802fd0ef          	jal	ra,ffffffffc0200f80 <get_pte>
ffffffffc0203f82:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203f84:	6108                	ld	a0,0(a0)
ffffffffc0203f86:	85a2                	mv	a1,s0
ffffffffc0203f88:	3d3000ef          	jal	ra,ffffffffc0204b5a <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0203f8c:	00093583          	ld	a1,0(s2)
ffffffffc0203f90:	8626                	mv	a2,s1
ffffffffc0203f92:	00004517          	auipc	a0,0x4
ffffffffc0203f96:	ce650513          	addi	a0,a0,-794 # ffffffffc0207c78 <commands+0x14c8>
ffffffffc0203f9a:	81a1                	srli	a1,a1,0x8
ffffffffc0203f9c:	934fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
}
ffffffffc0203fa0:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203fa2:	0089b023          	sd	s0,0(s3)
}
ffffffffc0203fa6:	7402                	ld	s0,32(sp)
ffffffffc0203fa8:	64e2                	ld	s1,24(sp)
ffffffffc0203faa:	6942                	ld	s2,16(sp)
ffffffffc0203fac:	69a2                	ld	s3,8(sp)
ffffffffc0203fae:	4501                	li	a0,0
ffffffffc0203fb0:	6145                	addi	sp,sp,48
ffffffffc0203fb2:	8082                	ret
     assert(result!=NULL);
ffffffffc0203fb4:	00004697          	auipc	a3,0x4
ffffffffc0203fb8:	cb468693          	addi	a3,a3,-844 # ffffffffc0207c68 <commands+0x14b8>
ffffffffc0203fbc:	00003617          	auipc	a2,0x3
ffffffffc0203fc0:	c7460613          	addi	a2,a2,-908 # ffffffffc0206c30 <commands+0x480>
ffffffffc0203fc4:	07e00593          	li	a1,126
ffffffffc0203fc8:	00004517          	auipc	a0,0x4
ffffffffc0203fcc:	d1050513          	addi	a0,a0,-752 # ffffffffc0207cd8 <commands+0x1528>
ffffffffc0203fd0:	a46fc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0203fd4 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc0203fd4:	000a8797          	auipc	a5,0xa8
ffffffffc0203fd8:	57c78793          	addi	a5,a5,1404 # ffffffffc02ac550 <free_area>
ffffffffc0203fdc:	e79c                	sd	a5,8(a5)
ffffffffc0203fde:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0203fe0:	0007a823          	sw	zero,16(a5)
}
ffffffffc0203fe4:	8082                	ret

ffffffffc0203fe6 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0203fe6:	000a8517          	auipc	a0,0xa8
ffffffffc0203fea:	57a56503          	lwu	a0,1402(a0) # ffffffffc02ac560 <free_area+0x10>
ffffffffc0203fee:	8082                	ret

ffffffffc0203ff0 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0203ff0:	715d                	addi	sp,sp,-80
ffffffffc0203ff2:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc0203ff4:	000a8917          	auipc	s2,0xa8
ffffffffc0203ff8:	55c90913          	addi	s2,s2,1372 # ffffffffc02ac550 <free_area>
ffffffffc0203ffc:	00893783          	ld	a5,8(s2)
ffffffffc0204000:	e486                	sd	ra,72(sp)
ffffffffc0204002:	e0a2                	sd	s0,64(sp)
ffffffffc0204004:	fc26                	sd	s1,56(sp)
ffffffffc0204006:	f44e                	sd	s3,40(sp)
ffffffffc0204008:	f052                	sd	s4,32(sp)
ffffffffc020400a:	ec56                	sd	s5,24(sp)
ffffffffc020400c:	e85a                	sd	s6,16(sp)
ffffffffc020400e:	e45e                	sd	s7,8(sp)
ffffffffc0204010:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0204012:	31278463          	beq	a5,s2,ffffffffc020431a <default_check+0x32a>
ffffffffc0204016:	ff07b703          	ld	a4,-16(a5)
ffffffffc020401a:	8305                	srli	a4,a4,0x1
ffffffffc020401c:	8b05                	andi	a4,a4,1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020401e:	30070263          	beqz	a4,ffffffffc0204322 <default_check+0x332>
    int count = 0, total = 0;
ffffffffc0204022:	4401                	li	s0,0
ffffffffc0204024:	4481                	li	s1,0
ffffffffc0204026:	a031                	j	ffffffffc0204032 <default_check+0x42>
ffffffffc0204028:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc020402c:	8b09                	andi	a4,a4,2
ffffffffc020402e:	2e070a63          	beqz	a4,ffffffffc0204322 <default_check+0x332>
        count ++, total += p->property;
ffffffffc0204032:	ff87a703          	lw	a4,-8(a5)
ffffffffc0204036:	679c                	ld	a5,8(a5)
ffffffffc0204038:	2485                	addiw	s1,s1,1
ffffffffc020403a:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020403c:	ff2796e3          	bne	a5,s2,ffffffffc0204028 <default_check+0x38>
ffffffffc0204040:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0204042:	efffc0ef          	jal	ra,ffffffffc0200f40 <nr_free_pages>
ffffffffc0204046:	73351e63          	bne	a0,s3,ffffffffc0204782 <default_check+0x792>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020404a:	4505                	li	a0,1
ffffffffc020404c:	e27fc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0204050:	8a2a                	mv	s4,a0
ffffffffc0204052:	46050863          	beqz	a0,ffffffffc02044c2 <default_check+0x4d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0204056:	4505                	li	a0,1
ffffffffc0204058:	e1bfc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc020405c:	89aa                	mv	s3,a0
ffffffffc020405e:	74050263          	beqz	a0,ffffffffc02047a2 <default_check+0x7b2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0204062:	4505                	li	a0,1
ffffffffc0204064:	e0ffc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0204068:	8aaa                	mv	s5,a0
ffffffffc020406a:	4c050c63          	beqz	a0,ffffffffc0204542 <default_check+0x552>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020406e:	2d3a0a63          	beq	s4,s3,ffffffffc0204342 <default_check+0x352>
ffffffffc0204072:	2caa0863          	beq	s4,a0,ffffffffc0204342 <default_check+0x352>
ffffffffc0204076:	2ca98663          	beq	s3,a0,ffffffffc0204342 <default_check+0x352>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020407a:	000a2783          	lw	a5,0(s4)
ffffffffc020407e:	2e079263          	bnez	a5,ffffffffc0204362 <default_check+0x372>
ffffffffc0204082:	0009a783          	lw	a5,0(s3)
ffffffffc0204086:	2c079e63          	bnez	a5,ffffffffc0204362 <default_check+0x372>
ffffffffc020408a:	411c                	lw	a5,0(a0)
ffffffffc020408c:	2c079b63          	bnez	a5,ffffffffc0204362 <default_check+0x372>
    return page - pages + nbase;
ffffffffc0204090:	000a8797          	auipc	a5,0xa8
ffffffffc0204094:	3d878793          	addi	a5,a5,984 # ffffffffc02ac468 <pages>
ffffffffc0204098:	639c                	ld	a5,0(a5)
ffffffffc020409a:	00005717          	auipc	a4,0x5
ffffffffc020409e:	cce70713          	addi	a4,a4,-818 # ffffffffc0208d68 <nbase>
ffffffffc02040a2:	6310                	ld	a2,0(a4)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02040a4:	000a8717          	auipc	a4,0xa8
ffffffffc02040a8:	35c70713          	addi	a4,a4,860 # ffffffffc02ac400 <npage>
ffffffffc02040ac:	6314                	ld	a3,0(a4)
ffffffffc02040ae:	40fa0733          	sub	a4,s4,a5
ffffffffc02040b2:	8719                	srai	a4,a4,0x6
ffffffffc02040b4:	9732                	add	a4,a4,a2
ffffffffc02040b6:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02040b8:	0732                	slli	a4,a4,0xc
ffffffffc02040ba:	2cd77463          	bleu	a3,a4,ffffffffc0204382 <default_check+0x392>
    return page - pages + nbase;
ffffffffc02040be:	40f98733          	sub	a4,s3,a5
ffffffffc02040c2:	8719                	srai	a4,a4,0x6
ffffffffc02040c4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02040c6:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02040c8:	4ed77d63          	bleu	a3,a4,ffffffffc02045c2 <default_check+0x5d2>
    return page - pages + nbase;
ffffffffc02040cc:	40f507b3          	sub	a5,a0,a5
ffffffffc02040d0:	8799                	srai	a5,a5,0x6
ffffffffc02040d2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02040d4:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02040d6:	34d7f663          	bleu	a3,a5,ffffffffc0204422 <default_check+0x432>
    assert(alloc_page() == NULL);
ffffffffc02040da:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02040dc:	00093c03          	ld	s8,0(s2)
ffffffffc02040e0:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc02040e4:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc02040e8:	000a8797          	auipc	a5,0xa8
ffffffffc02040ec:	4727b823          	sd	s2,1136(a5) # ffffffffc02ac558 <free_area+0x8>
ffffffffc02040f0:	000a8797          	auipc	a5,0xa8
ffffffffc02040f4:	4727b023          	sd	s2,1120(a5) # ffffffffc02ac550 <free_area>
    nr_free = 0;
ffffffffc02040f8:	000a8797          	auipc	a5,0xa8
ffffffffc02040fc:	4607a423          	sw	zero,1128(a5) # ffffffffc02ac560 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0204100:	d73fc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0204104:	2e051f63          	bnez	a0,ffffffffc0204402 <default_check+0x412>
    free_page(p0);
ffffffffc0204108:	4585                	li	a1,1
ffffffffc020410a:	8552                	mv	a0,s4
ffffffffc020410c:	deffc0ef          	jal	ra,ffffffffc0200efa <free_pages>
    free_page(p1);
ffffffffc0204110:	4585                	li	a1,1
ffffffffc0204112:	854e                	mv	a0,s3
ffffffffc0204114:	de7fc0ef          	jal	ra,ffffffffc0200efa <free_pages>
    free_page(p2);
ffffffffc0204118:	4585                	li	a1,1
ffffffffc020411a:	8556                	mv	a0,s5
ffffffffc020411c:	ddffc0ef          	jal	ra,ffffffffc0200efa <free_pages>
    assert(nr_free == 3);
ffffffffc0204120:	01092703          	lw	a4,16(s2)
ffffffffc0204124:	478d                	li	a5,3
ffffffffc0204126:	2af71e63          	bne	a4,a5,ffffffffc02043e2 <default_check+0x3f2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020412a:	4505                	li	a0,1
ffffffffc020412c:	d47fc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0204130:	89aa                	mv	s3,a0
ffffffffc0204132:	28050863          	beqz	a0,ffffffffc02043c2 <default_check+0x3d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0204136:	4505                	li	a0,1
ffffffffc0204138:	d3bfc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc020413c:	8aaa                	mv	s5,a0
ffffffffc020413e:	3e050263          	beqz	a0,ffffffffc0204522 <default_check+0x532>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0204142:	4505                	li	a0,1
ffffffffc0204144:	d2ffc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0204148:	8a2a                	mv	s4,a0
ffffffffc020414a:	3a050c63          	beqz	a0,ffffffffc0204502 <default_check+0x512>
    assert(alloc_page() == NULL);
ffffffffc020414e:	4505                	li	a0,1
ffffffffc0204150:	d23fc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0204154:	38051763          	bnez	a0,ffffffffc02044e2 <default_check+0x4f2>
    free_page(p0);
ffffffffc0204158:	4585                	li	a1,1
ffffffffc020415a:	854e                	mv	a0,s3
ffffffffc020415c:	d9ffc0ef          	jal	ra,ffffffffc0200efa <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0204160:	00893783          	ld	a5,8(s2)
ffffffffc0204164:	23278f63          	beq	a5,s2,ffffffffc02043a2 <default_check+0x3b2>
    assert((p = alloc_page()) == p0);
ffffffffc0204168:	4505                	li	a0,1
ffffffffc020416a:	d09fc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc020416e:	32a99a63          	bne	s3,a0,ffffffffc02044a2 <default_check+0x4b2>
    assert(alloc_page() == NULL);
ffffffffc0204172:	4505                	li	a0,1
ffffffffc0204174:	cfffc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0204178:	30051563          	bnez	a0,ffffffffc0204482 <default_check+0x492>
    assert(nr_free == 0);
ffffffffc020417c:	01092783          	lw	a5,16(s2)
ffffffffc0204180:	2e079163          	bnez	a5,ffffffffc0204462 <default_check+0x472>
    free_page(p);
ffffffffc0204184:	854e                	mv	a0,s3
ffffffffc0204186:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0204188:	000a8797          	auipc	a5,0xa8
ffffffffc020418c:	3d87b423          	sd	s8,968(a5) # ffffffffc02ac550 <free_area>
ffffffffc0204190:	000a8797          	auipc	a5,0xa8
ffffffffc0204194:	3d77b423          	sd	s7,968(a5) # ffffffffc02ac558 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0204198:	000a8797          	auipc	a5,0xa8
ffffffffc020419c:	3d67a423          	sw	s6,968(a5) # ffffffffc02ac560 <free_area+0x10>
    free_page(p);
ffffffffc02041a0:	d5bfc0ef          	jal	ra,ffffffffc0200efa <free_pages>
    free_page(p1);
ffffffffc02041a4:	4585                	li	a1,1
ffffffffc02041a6:	8556                	mv	a0,s5
ffffffffc02041a8:	d53fc0ef          	jal	ra,ffffffffc0200efa <free_pages>
    free_page(p2);
ffffffffc02041ac:	4585                	li	a1,1
ffffffffc02041ae:	8552                	mv	a0,s4
ffffffffc02041b0:	d4bfc0ef          	jal	ra,ffffffffc0200efa <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02041b4:	4515                	li	a0,5
ffffffffc02041b6:	cbdfc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc02041ba:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02041bc:	28050363          	beqz	a0,ffffffffc0204442 <default_check+0x452>
ffffffffc02041c0:	651c                	ld	a5,8(a0)
ffffffffc02041c2:	8385                	srli	a5,a5,0x1
ffffffffc02041c4:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc02041c6:	54079e63          	bnez	a5,ffffffffc0204722 <default_check+0x732>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02041ca:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02041cc:	00093b03          	ld	s6,0(s2)
ffffffffc02041d0:	00893a83          	ld	s5,8(s2)
ffffffffc02041d4:	000a8797          	auipc	a5,0xa8
ffffffffc02041d8:	3727be23          	sd	s2,892(a5) # ffffffffc02ac550 <free_area>
ffffffffc02041dc:	000a8797          	auipc	a5,0xa8
ffffffffc02041e0:	3727be23          	sd	s2,892(a5) # ffffffffc02ac558 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc02041e4:	c8ffc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc02041e8:	50051d63          	bnez	a0,ffffffffc0204702 <default_check+0x712>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02041ec:	08098a13          	addi	s4,s3,128
ffffffffc02041f0:	8552                	mv	a0,s4
ffffffffc02041f2:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02041f4:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc02041f8:	000a8797          	auipc	a5,0xa8
ffffffffc02041fc:	3607a423          	sw	zero,872(a5) # ffffffffc02ac560 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0204200:	cfbfc0ef          	jal	ra,ffffffffc0200efa <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0204204:	4511                	li	a0,4
ffffffffc0204206:	c6dfc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc020420a:	4c051c63          	bnez	a0,ffffffffc02046e2 <default_check+0x6f2>
ffffffffc020420e:	0889b783          	ld	a5,136(s3)
ffffffffc0204212:	8385                	srli	a5,a5,0x1
ffffffffc0204214:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0204216:	4a078663          	beqz	a5,ffffffffc02046c2 <default_check+0x6d2>
ffffffffc020421a:	0909a703          	lw	a4,144(s3)
ffffffffc020421e:	478d                	li	a5,3
ffffffffc0204220:	4af71163          	bne	a4,a5,ffffffffc02046c2 <default_check+0x6d2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0204224:	450d                	li	a0,3
ffffffffc0204226:	c4dfc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc020422a:	8c2a                	mv	s8,a0
ffffffffc020422c:	46050b63          	beqz	a0,ffffffffc02046a2 <default_check+0x6b2>
    assert(alloc_page() == NULL);
ffffffffc0204230:	4505                	li	a0,1
ffffffffc0204232:	c41fc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0204236:	44051663          	bnez	a0,ffffffffc0204682 <default_check+0x692>
    assert(p0 + 2 == p1);
ffffffffc020423a:	438a1463          	bne	s4,s8,ffffffffc0204662 <default_check+0x672>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc020423e:	4585                	li	a1,1
ffffffffc0204240:	854e                	mv	a0,s3
ffffffffc0204242:	cb9fc0ef          	jal	ra,ffffffffc0200efa <free_pages>
    free_pages(p1, 3);
ffffffffc0204246:	458d                	li	a1,3
ffffffffc0204248:	8552                	mv	a0,s4
ffffffffc020424a:	cb1fc0ef          	jal	ra,ffffffffc0200efa <free_pages>
ffffffffc020424e:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0204252:	04098c13          	addi	s8,s3,64
ffffffffc0204256:	8385                	srli	a5,a5,0x1
ffffffffc0204258:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020425a:	3e078463          	beqz	a5,ffffffffc0204642 <default_check+0x652>
ffffffffc020425e:	0109a703          	lw	a4,16(s3)
ffffffffc0204262:	4785                	li	a5,1
ffffffffc0204264:	3cf71f63          	bne	a4,a5,ffffffffc0204642 <default_check+0x652>
ffffffffc0204268:	008a3783          	ld	a5,8(s4)
ffffffffc020426c:	8385                	srli	a5,a5,0x1
ffffffffc020426e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0204270:	3a078963          	beqz	a5,ffffffffc0204622 <default_check+0x632>
ffffffffc0204274:	010a2703          	lw	a4,16(s4)
ffffffffc0204278:	478d                	li	a5,3
ffffffffc020427a:	3af71463          	bne	a4,a5,ffffffffc0204622 <default_check+0x632>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020427e:	4505                	li	a0,1
ffffffffc0204280:	bf3fc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0204284:	36a99f63          	bne	s3,a0,ffffffffc0204602 <default_check+0x612>
    free_page(p0);
ffffffffc0204288:	4585                	li	a1,1
ffffffffc020428a:	c71fc0ef          	jal	ra,ffffffffc0200efa <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020428e:	4509                	li	a0,2
ffffffffc0204290:	be3fc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0204294:	34aa1763          	bne	s4,a0,ffffffffc02045e2 <default_check+0x5f2>

    free_pages(p0, 2);
ffffffffc0204298:	4589                	li	a1,2
ffffffffc020429a:	c61fc0ef          	jal	ra,ffffffffc0200efa <free_pages>
    free_page(p2);
ffffffffc020429e:	4585                	li	a1,1
ffffffffc02042a0:	8562                	mv	a0,s8
ffffffffc02042a2:	c59fc0ef          	jal	ra,ffffffffc0200efa <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02042a6:	4515                	li	a0,5
ffffffffc02042a8:	bcbfc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc02042ac:	89aa                	mv	s3,a0
ffffffffc02042ae:	48050a63          	beqz	a0,ffffffffc0204742 <default_check+0x752>
    assert(alloc_page() == NULL);
ffffffffc02042b2:	4505                	li	a0,1
ffffffffc02042b4:	bbffc0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc02042b8:	2e051563          	bnez	a0,ffffffffc02045a2 <default_check+0x5b2>

    assert(nr_free == 0);
ffffffffc02042bc:	01092783          	lw	a5,16(s2)
ffffffffc02042c0:	2c079163          	bnez	a5,ffffffffc0204582 <default_check+0x592>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02042c4:	4595                	li	a1,5
ffffffffc02042c6:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02042c8:	000a8797          	auipc	a5,0xa8
ffffffffc02042cc:	2977ac23          	sw	s7,664(a5) # ffffffffc02ac560 <free_area+0x10>
    free_list = free_list_store;
ffffffffc02042d0:	000a8797          	auipc	a5,0xa8
ffffffffc02042d4:	2967b023          	sd	s6,640(a5) # ffffffffc02ac550 <free_area>
ffffffffc02042d8:	000a8797          	auipc	a5,0xa8
ffffffffc02042dc:	2957b023          	sd	s5,640(a5) # ffffffffc02ac558 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc02042e0:	c1bfc0ef          	jal	ra,ffffffffc0200efa <free_pages>
    return listelm->next;
ffffffffc02042e4:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02042e8:	01278963          	beq	a5,s2,ffffffffc02042fa <default_check+0x30a>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02042ec:	ff87a703          	lw	a4,-8(a5)
ffffffffc02042f0:	679c                	ld	a5,8(a5)
ffffffffc02042f2:	34fd                	addiw	s1,s1,-1
ffffffffc02042f4:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02042f6:	ff279be3          	bne	a5,s2,ffffffffc02042ec <default_check+0x2fc>
    }
    assert(count == 0);
ffffffffc02042fa:	26049463          	bnez	s1,ffffffffc0204562 <default_check+0x572>
    assert(total == 0);
ffffffffc02042fe:	46041263          	bnez	s0,ffffffffc0204762 <default_check+0x772>
}
ffffffffc0204302:	60a6                	ld	ra,72(sp)
ffffffffc0204304:	6406                	ld	s0,64(sp)
ffffffffc0204306:	74e2                	ld	s1,56(sp)
ffffffffc0204308:	7942                	ld	s2,48(sp)
ffffffffc020430a:	79a2                	ld	s3,40(sp)
ffffffffc020430c:	7a02                	ld	s4,32(sp)
ffffffffc020430e:	6ae2                	ld	s5,24(sp)
ffffffffc0204310:	6b42                	ld	s6,16(sp)
ffffffffc0204312:	6ba2                	ld	s7,8(sp)
ffffffffc0204314:	6c02                	ld	s8,0(sp)
ffffffffc0204316:	6161                	addi	sp,sp,80
ffffffffc0204318:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020431a:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020431c:	4401                	li	s0,0
ffffffffc020431e:	4481                	li	s1,0
ffffffffc0204320:	b30d                	j	ffffffffc0204042 <default_check+0x52>
        assert(PageProperty(p));
ffffffffc0204322:	00004697          	auipc	a3,0x4
ffffffffc0204326:	9de68693          	addi	a3,a3,-1570 # ffffffffc0207d00 <commands+0x1550>
ffffffffc020432a:	00003617          	auipc	a2,0x3
ffffffffc020432e:	90660613          	addi	a2,a2,-1786 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204332:	0f000593          	li	a1,240
ffffffffc0204336:	00004517          	auipc	a0,0x4
ffffffffc020433a:	cca50513          	addi	a0,a0,-822 # ffffffffc0208000 <commands+0x1850>
ffffffffc020433e:	ed9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0204342:	00004697          	auipc	a3,0x4
ffffffffc0204346:	d3668693          	addi	a3,a3,-714 # ffffffffc0208078 <commands+0x18c8>
ffffffffc020434a:	00003617          	auipc	a2,0x3
ffffffffc020434e:	8e660613          	addi	a2,a2,-1818 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204352:	0bd00593          	li	a1,189
ffffffffc0204356:	00004517          	auipc	a0,0x4
ffffffffc020435a:	caa50513          	addi	a0,a0,-854 # ffffffffc0208000 <commands+0x1850>
ffffffffc020435e:	eb9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0204362:	00004697          	auipc	a3,0x4
ffffffffc0204366:	d3e68693          	addi	a3,a3,-706 # ffffffffc02080a0 <commands+0x18f0>
ffffffffc020436a:	00003617          	auipc	a2,0x3
ffffffffc020436e:	8c660613          	addi	a2,a2,-1850 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204372:	0be00593          	li	a1,190
ffffffffc0204376:	00004517          	auipc	a0,0x4
ffffffffc020437a:	c8a50513          	addi	a0,a0,-886 # ffffffffc0208000 <commands+0x1850>
ffffffffc020437e:	e99fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0204382:	00004697          	auipc	a3,0x4
ffffffffc0204386:	d5e68693          	addi	a3,a3,-674 # ffffffffc02080e0 <commands+0x1930>
ffffffffc020438a:	00003617          	auipc	a2,0x3
ffffffffc020438e:	8a660613          	addi	a2,a2,-1882 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204392:	0c000593          	li	a1,192
ffffffffc0204396:	00004517          	auipc	a0,0x4
ffffffffc020439a:	c6a50513          	addi	a0,a0,-918 # ffffffffc0208000 <commands+0x1850>
ffffffffc020439e:	e79fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02043a2:	00004697          	auipc	a3,0x4
ffffffffc02043a6:	dc668693          	addi	a3,a3,-570 # ffffffffc0208168 <commands+0x19b8>
ffffffffc02043aa:	00003617          	auipc	a2,0x3
ffffffffc02043ae:	88660613          	addi	a2,a2,-1914 # ffffffffc0206c30 <commands+0x480>
ffffffffc02043b2:	0d900593          	li	a1,217
ffffffffc02043b6:	00004517          	auipc	a0,0x4
ffffffffc02043ba:	c4a50513          	addi	a0,a0,-950 # ffffffffc0208000 <commands+0x1850>
ffffffffc02043be:	e59fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02043c2:	00004697          	auipc	a3,0x4
ffffffffc02043c6:	c5668693          	addi	a3,a3,-938 # ffffffffc0208018 <commands+0x1868>
ffffffffc02043ca:	00003617          	auipc	a2,0x3
ffffffffc02043ce:	86660613          	addi	a2,a2,-1946 # ffffffffc0206c30 <commands+0x480>
ffffffffc02043d2:	0d200593          	li	a1,210
ffffffffc02043d6:	00004517          	auipc	a0,0x4
ffffffffc02043da:	c2a50513          	addi	a0,a0,-982 # ffffffffc0208000 <commands+0x1850>
ffffffffc02043de:	e39fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_free == 3);
ffffffffc02043e2:	00004697          	auipc	a3,0x4
ffffffffc02043e6:	d7668693          	addi	a3,a3,-650 # ffffffffc0208158 <commands+0x19a8>
ffffffffc02043ea:	00003617          	auipc	a2,0x3
ffffffffc02043ee:	84660613          	addi	a2,a2,-1978 # ffffffffc0206c30 <commands+0x480>
ffffffffc02043f2:	0d000593          	li	a1,208
ffffffffc02043f6:	00004517          	auipc	a0,0x4
ffffffffc02043fa:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0208000 <commands+0x1850>
ffffffffc02043fe:	e19fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0204402:	00004697          	auipc	a3,0x4
ffffffffc0204406:	d3e68693          	addi	a3,a3,-706 # ffffffffc0208140 <commands+0x1990>
ffffffffc020440a:	00003617          	auipc	a2,0x3
ffffffffc020440e:	82660613          	addi	a2,a2,-2010 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204412:	0cb00593          	li	a1,203
ffffffffc0204416:	00004517          	auipc	a0,0x4
ffffffffc020441a:	bea50513          	addi	a0,a0,-1046 # ffffffffc0208000 <commands+0x1850>
ffffffffc020441e:	df9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0204422:	00004697          	auipc	a3,0x4
ffffffffc0204426:	cfe68693          	addi	a3,a3,-770 # ffffffffc0208120 <commands+0x1970>
ffffffffc020442a:	00003617          	auipc	a2,0x3
ffffffffc020442e:	80660613          	addi	a2,a2,-2042 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204432:	0c200593          	li	a1,194
ffffffffc0204436:	00004517          	auipc	a0,0x4
ffffffffc020443a:	bca50513          	addi	a0,a0,-1078 # ffffffffc0208000 <commands+0x1850>
ffffffffc020443e:	dd9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(p0 != NULL);
ffffffffc0204442:	00004697          	auipc	a3,0x4
ffffffffc0204446:	d5e68693          	addi	a3,a3,-674 # ffffffffc02081a0 <commands+0x19f0>
ffffffffc020444a:	00002617          	auipc	a2,0x2
ffffffffc020444e:	7e660613          	addi	a2,a2,2022 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204452:	0f800593          	li	a1,248
ffffffffc0204456:	00004517          	auipc	a0,0x4
ffffffffc020445a:	baa50513          	addi	a0,a0,-1110 # ffffffffc0208000 <commands+0x1850>
ffffffffc020445e:	db9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_free == 0);
ffffffffc0204462:	00004697          	auipc	a3,0x4
ffffffffc0204466:	a3e68693          	addi	a3,a3,-1474 # ffffffffc0207ea0 <commands+0x16f0>
ffffffffc020446a:	00002617          	auipc	a2,0x2
ffffffffc020446e:	7c660613          	addi	a2,a2,1990 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204472:	0df00593          	li	a1,223
ffffffffc0204476:	00004517          	auipc	a0,0x4
ffffffffc020447a:	b8a50513          	addi	a0,a0,-1142 # ffffffffc0208000 <commands+0x1850>
ffffffffc020447e:	d99fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0204482:	00004697          	auipc	a3,0x4
ffffffffc0204486:	cbe68693          	addi	a3,a3,-834 # ffffffffc0208140 <commands+0x1990>
ffffffffc020448a:	00002617          	auipc	a2,0x2
ffffffffc020448e:	7a660613          	addi	a2,a2,1958 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204492:	0dd00593          	li	a1,221
ffffffffc0204496:	00004517          	auipc	a0,0x4
ffffffffc020449a:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0208000 <commands+0x1850>
ffffffffc020449e:	d79fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02044a2:	00004697          	auipc	a3,0x4
ffffffffc02044a6:	cde68693          	addi	a3,a3,-802 # ffffffffc0208180 <commands+0x19d0>
ffffffffc02044aa:	00002617          	auipc	a2,0x2
ffffffffc02044ae:	78660613          	addi	a2,a2,1926 # ffffffffc0206c30 <commands+0x480>
ffffffffc02044b2:	0dc00593          	li	a1,220
ffffffffc02044b6:	00004517          	auipc	a0,0x4
ffffffffc02044ba:	b4a50513          	addi	a0,a0,-1206 # ffffffffc0208000 <commands+0x1850>
ffffffffc02044be:	d59fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02044c2:	00004697          	auipc	a3,0x4
ffffffffc02044c6:	b5668693          	addi	a3,a3,-1194 # ffffffffc0208018 <commands+0x1868>
ffffffffc02044ca:	00002617          	auipc	a2,0x2
ffffffffc02044ce:	76660613          	addi	a2,a2,1894 # ffffffffc0206c30 <commands+0x480>
ffffffffc02044d2:	0b900593          	li	a1,185
ffffffffc02044d6:	00004517          	auipc	a0,0x4
ffffffffc02044da:	b2a50513          	addi	a0,a0,-1238 # ffffffffc0208000 <commands+0x1850>
ffffffffc02044de:	d39fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02044e2:	00004697          	auipc	a3,0x4
ffffffffc02044e6:	c5e68693          	addi	a3,a3,-930 # ffffffffc0208140 <commands+0x1990>
ffffffffc02044ea:	00002617          	auipc	a2,0x2
ffffffffc02044ee:	74660613          	addi	a2,a2,1862 # ffffffffc0206c30 <commands+0x480>
ffffffffc02044f2:	0d600593          	li	a1,214
ffffffffc02044f6:	00004517          	auipc	a0,0x4
ffffffffc02044fa:	b0a50513          	addi	a0,a0,-1270 # ffffffffc0208000 <commands+0x1850>
ffffffffc02044fe:	d19fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0204502:	00004697          	auipc	a3,0x4
ffffffffc0204506:	b5668693          	addi	a3,a3,-1194 # ffffffffc0208058 <commands+0x18a8>
ffffffffc020450a:	00002617          	auipc	a2,0x2
ffffffffc020450e:	72660613          	addi	a2,a2,1830 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204512:	0d400593          	li	a1,212
ffffffffc0204516:	00004517          	auipc	a0,0x4
ffffffffc020451a:	aea50513          	addi	a0,a0,-1302 # ffffffffc0208000 <commands+0x1850>
ffffffffc020451e:	cf9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0204522:	00004697          	auipc	a3,0x4
ffffffffc0204526:	b1668693          	addi	a3,a3,-1258 # ffffffffc0208038 <commands+0x1888>
ffffffffc020452a:	00002617          	auipc	a2,0x2
ffffffffc020452e:	70660613          	addi	a2,a2,1798 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204532:	0d300593          	li	a1,211
ffffffffc0204536:	00004517          	auipc	a0,0x4
ffffffffc020453a:	aca50513          	addi	a0,a0,-1334 # ffffffffc0208000 <commands+0x1850>
ffffffffc020453e:	cd9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0204542:	00004697          	auipc	a3,0x4
ffffffffc0204546:	b1668693          	addi	a3,a3,-1258 # ffffffffc0208058 <commands+0x18a8>
ffffffffc020454a:	00002617          	auipc	a2,0x2
ffffffffc020454e:	6e660613          	addi	a2,a2,1766 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204552:	0bb00593          	li	a1,187
ffffffffc0204556:	00004517          	auipc	a0,0x4
ffffffffc020455a:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0208000 <commands+0x1850>
ffffffffc020455e:	cb9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(count == 0);
ffffffffc0204562:	00004697          	auipc	a3,0x4
ffffffffc0204566:	d8e68693          	addi	a3,a3,-626 # ffffffffc02082f0 <commands+0x1b40>
ffffffffc020456a:	00002617          	auipc	a2,0x2
ffffffffc020456e:	6c660613          	addi	a2,a2,1734 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204572:	12500593          	li	a1,293
ffffffffc0204576:	00004517          	auipc	a0,0x4
ffffffffc020457a:	a8a50513          	addi	a0,a0,-1398 # ffffffffc0208000 <commands+0x1850>
ffffffffc020457e:	c99fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_free == 0);
ffffffffc0204582:	00004697          	auipc	a3,0x4
ffffffffc0204586:	91e68693          	addi	a3,a3,-1762 # ffffffffc0207ea0 <commands+0x16f0>
ffffffffc020458a:	00002617          	auipc	a2,0x2
ffffffffc020458e:	6a660613          	addi	a2,a2,1702 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204592:	11a00593          	li	a1,282
ffffffffc0204596:	00004517          	auipc	a0,0x4
ffffffffc020459a:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0208000 <commands+0x1850>
ffffffffc020459e:	c79fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02045a2:	00004697          	auipc	a3,0x4
ffffffffc02045a6:	b9e68693          	addi	a3,a3,-1122 # ffffffffc0208140 <commands+0x1990>
ffffffffc02045aa:	00002617          	auipc	a2,0x2
ffffffffc02045ae:	68660613          	addi	a2,a2,1670 # ffffffffc0206c30 <commands+0x480>
ffffffffc02045b2:	11800593          	li	a1,280
ffffffffc02045b6:	00004517          	auipc	a0,0x4
ffffffffc02045ba:	a4a50513          	addi	a0,a0,-1462 # ffffffffc0208000 <commands+0x1850>
ffffffffc02045be:	c59fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02045c2:	00004697          	auipc	a3,0x4
ffffffffc02045c6:	b3e68693          	addi	a3,a3,-1218 # ffffffffc0208100 <commands+0x1950>
ffffffffc02045ca:	00002617          	auipc	a2,0x2
ffffffffc02045ce:	66660613          	addi	a2,a2,1638 # ffffffffc0206c30 <commands+0x480>
ffffffffc02045d2:	0c100593          	li	a1,193
ffffffffc02045d6:	00004517          	auipc	a0,0x4
ffffffffc02045da:	a2a50513          	addi	a0,a0,-1494 # ffffffffc0208000 <commands+0x1850>
ffffffffc02045de:	c39fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02045e2:	00004697          	auipc	a3,0x4
ffffffffc02045e6:	cce68693          	addi	a3,a3,-818 # ffffffffc02082b0 <commands+0x1b00>
ffffffffc02045ea:	00002617          	auipc	a2,0x2
ffffffffc02045ee:	64660613          	addi	a2,a2,1606 # ffffffffc0206c30 <commands+0x480>
ffffffffc02045f2:	11200593          	li	a1,274
ffffffffc02045f6:	00004517          	auipc	a0,0x4
ffffffffc02045fa:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0208000 <commands+0x1850>
ffffffffc02045fe:	c19fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0204602:	00004697          	auipc	a3,0x4
ffffffffc0204606:	c8e68693          	addi	a3,a3,-882 # ffffffffc0208290 <commands+0x1ae0>
ffffffffc020460a:	00002617          	auipc	a2,0x2
ffffffffc020460e:	62660613          	addi	a2,a2,1574 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204612:	11000593          	li	a1,272
ffffffffc0204616:	00004517          	auipc	a0,0x4
ffffffffc020461a:	9ea50513          	addi	a0,a0,-1558 # ffffffffc0208000 <commands+0x1850>
ffffffffc020461e:	bf9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0204622:	00004697          	auipc	a3,0x4
ffffffffc0204626:	c4668693          	addi	a3,a3,-954 # ffffffffc0208268 <commands+0x1ab8>
ffffffffc020462a:	00002617          	auipc	a2,0x2
ffffffffc020462e:	60660613          	addi	a2,a2,1542 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204632:	10e00593          	li	a1,270
ffffffffc0204636:	00004517          	auipc	a0,0x4
ffffffffc020463a:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0208000 <commands+0x1850>
ffffffffc020463e:	bd9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0204642:	00004697          	auipc	a3,0x4
ffffffffc0204646:	bfe68693          	addi	a3,a3,-1026 # ffffffffc0208240 <commands+0x1a90>
ffffffffc020464a:	00002617          	auipc	a2,0x2
ffffffffc020464e:	5e660613          	addi	a2,a2,1510 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204652:	10d00593          	li	a1,269
ffffffffc0204656:	00004517          	auipc	a0,0x4
ffffffffc020465a:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0208000 <commands+0x1850>
ffffffffc020465e:	bb9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0204662:	00004697          	auipc	a3,0x4
ffffffffc0204666:	bce68693          	addi	a3,a3,-1074 # ffffffffc0208230 <commands+0x1a80>
ffffffffc020466a:	00002617          	auipc	a2,0x2
ffffffffc020466e:	5c660613          	addi	a2,a2,1478 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204672:	10800593          	li	a1,264
ffffffffc0204676:	00004517          	auipc	a0,0x4
ffffffffc020467a:	98a50513          	addi	a0,a0,-1654 # ffffffffc0208000 <commands+0x1850>
ffffffffc020467e:	b99fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0204682:	00004697          	auipc	a3,0x4
ffffffffc0204686:	abe68693          	addi	a3,a3,-1346 # ffffffffc0208140 <commands+0x1990>
ffffffffc020468a:	00002617          	auipc	a2,0x2
ffffffffc020468e:	5a660613          	addi	a2,a2,1446 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204692:	10700593          	li	a1,263
ffffffffc0204696:	00004517          	auipc	a0,0x4
ffffffffc020469a:	96a50513          	addi	a0,a0,-1686 # ffffffffc0208000 <commands+0x1850>
ffffffffc020469e:	b79fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02046a2:	00004697          	auipc	a3,0x4
ffffffffc02046a6:	b6e68693          	addi	a3,a3,-1170 # ffffffffc0208210 <commands+0x1a60>
ffffffffc02046aa:	00002617          	auipc	a2,0x2
ffffffffc02046ae:	58660613          	addi	a2,a2,1414 # ffffffffc0206c30 <commands+0x480>
ffffffffc02046b2:	10600593          	li	a1,262
ffffffffc02046b6:	00004517          	auipc	a0,0x4
ffffffffc02046ba:	94a50513          	addi	a0,a0,-1718 # ffffffffc0208000 <commands+0x1850>
ffffffffc02046be:	b59fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02046c2:	00004697          	auipc	a3,0x4
ffffffffc02046c6:	b1e68693          	addi	a3,a3,-1250 # ffffffffc02081e0 <commands+0x1a30>
ffffffffc02046ca:	00002617          	auipc	a2,0x2
ffffffffc02046ce:	56660613          	addi	a2,a2,1382 # ffffffffc0206c30 <commands+0x480>
ffffffffc02046d2:	10500593          	li	a1,261
ffffffffc02046d6:	00004517          	auipc	a0,0x4
ffffffffc02046da:	92a50513          	addi	a0,a0,-1750 # ffffffffc0208000 <commands+0x1850>
ffffffffc02046de:	b39fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02046e2:	00004697          	auipc	a3,0x4
ffffffffc02046e6:	ae668693          	addi	a3,a3,-1306 # ffffffffc02081c8 <commands+0x1a18>
ffffffffc02046ea:	00002617          	auipc	a2,0x2
ffffffffc02046ee:	54660613          	addi	a2,a2,1350 # ffffffffc0206c30 <commands+0x480>
ffffffffc02046f2:	10400593          	li	a1,260
ffffffffc02046f6:	00004517          	auipc	a0,0x4
ffffffffc02046fa:	90a50513          	addi	a0,a0,-1782 # ffffffffc0208000 <commands+0x1850>
ffffffffc02046fe:	b19fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0204702:	00004697          	auipc	a3,0x4
ffffffffc0204706:	a3e68693          	addi	a3,a3,-1474 # ffffffffc0208140 <commands+0x1990>
ffffffffc020470a:	00002617          	auipc	a2,0x2
ffffffffc020470e:	52660613          	addi	a2,a2,1318 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204712:	0fe00593          	li	a1,254
ffffffffc0204716:	00004517          	auipc	a0,0x4
ffffffffc020471a:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0208000 <commands+0x1850>
ffffffffc020471e:	af9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(!PageProperty(p0));
ffffffffc0204722:	00004697          	auipc	a3,0x4
ffffffffc0204726:	a8e68693          	addi	a3,a3,-1394 # ffffffffc02081b0 <commands+0x1a00>
ffffffffc020472a:	00002617          	auipc	a2,0x2
ffffffffc020472e:	50660613          	addi	a2,a2,1286 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204732:	0f900593          	li	a1,249
ffffffffc0204736:	00004517          	auipc	a0,0x4
ffffffffc020473a:	8ca50513          	addi	a0,a0,-1846 # ffffffffc0208000 <commands+0x1850>
ffffffffc020473e:	ad9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0204742:	00004697          	auipc	a3,0x4
ffffffffc0204746:	b8e68693          	addi	a3,a3,-1138 # ffffffffc02082d0 <commands+0x1b20>
ffffffffc020474a:	00002617          	auipc	a2,0x2
ffffffffc020474e:	4e660613          	addi	a2,a2,1254 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204752:	11700593          	li	a1,279
ffffffffc0204756:	00004517          	auipc	a0,0x4
ffffffffc020475a:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0208000 <commands+0x1850>
ffffffffc020475e:	ab9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(total == 0);
ffffffffc0204762:	00004697          	auipc	a3,0x4
ffffffffc0204766:	b9e68693          	addi	a3,a3,-1122 # ffffffffc0208300 <commands+0x1b50>
ffffffffc020476a:	00002617          	auipc	a2,0x2
ffffffffc020476e:	4c660613          	addi	a2,a2,1222 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204772:	12600593          	li	a1,294
ffffffffc0204776:	00004517          	auipc	a0,0x4
ffffffffc020477a:	88a50513          	addi	a0,a0,-1910 # ffffffffc0208000 <commands+0x1850>
ffffffffc020477e:	a99fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(total == nr_free_pages());
ffffffffc0204782:	00003697          	auipc	a3,0x3
ffffffffc0204786:	58e68693          	addi	a3,a3,1422 # ffffffffc0207d10 <commands+0x1560>
ffffffffc020478a:	00002617          	auipc	a2,0x2
ffffffffc020478e:	4a660613          	addi	a2,a2,1190 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204792:	0f300593          	li	a1,243
ffffffffc0204796:	00004517          	auipc	a0,0x4
ffffffffc020479a:	86a50513          	addi	a0,a0,-1942 # ffffffffc0208000 <commands+0x1850>
ffffffffc020479e:	a79fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02047a2:	00004697          	auipc	a3,0x4
ffffffffc02047a6:	89668693          	addi	a3,a3,-1898 # ffffffffc0208038 <commands+0x1888>
ffffffffc02047aa:	00002617          	auipc	a2,0x2
ffffffffc02047ae:	48660613          	addi	a2,a2,1158 # ffffffffc0206c30 <commands+0x480>
ffffffffc02047b2:	0ba00593          	li	a1,186
ffffffffc02047b6:	00004517          	auipc	a0,0x4
ffffffffc02047ba:	84a50513          	addi	a0,a0,-1974 # ffffffffc0208000 <commands+0x1850>
ffffffffc02047be:	a59fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02047c2 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02047c2:	1141                	addi	sp,sp,-16
ffffffffc02047c4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02047c6:	16058e63          	beqz	a1,ffffffffc0204942 <default_free_pages+0x180>
    for (; p != base + n; p ++) {
ffffffffc02047ca:	00659693          	slli	a3,a1,0x6
ffffffffc02047ce:	96aa                	add	a3,a3,a0
ffffffffc02047d0:	02d50d63          	beq	a0,a3,ffffffffc020480a <default_free_pages+0x48>
ffffffffc02047d4:	651c                	ld	a5,8(a0)
ffffffffc02047d6:	8b85                	andi	a5,a5,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02047d8:	14079563          	bnez	a5,ffffffffc0204922 <default_free_pages+0x160>
ffffffffc02047dc:	651c                	ld	a5,8(a0)
ffffffffc02047de:	8385                	srli	a5,a5,0x1
ffffffffc02047e0:	8b85                	andi	a5,a5,1
ffffffffc02047e2:	14079063          	bnez	a5,ffffffffc0204922 <default_free_pages+0x160>
ffffffffc02047e6:	87aa                	mv	a5,a0
ffffffffc02047e8:	a809                	j	ffffffffc02047fa <default_free_pages+0x38>
ffffffffc02047ea:	6798                	ld	a4,8(a5)
ffffffffc02047ec:	8b05                	andi	a4,a4,1
ffffffffc02047ee:	12071a63          	bnez	a4,ffffffffc0204922 <default_free_pages+0x160>
ffffffffc02047f2:	6798                	ld	a4,8(a5)
ffffffffc02047f4:	8b09                	andi	a4,a4,2
ffffffffc02047f6:	12071663          	bnez	a4,ffffffffc0204922 <default_free_pages+0x160>
        p->flags = 0;
ffffffffc02047fa:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc02047fe:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0204802:	04078793          	addi	a5,a5,64
ffffffffc0204806:	fed792e3          	bne	a5,a3,ffffffffc02047ea <default_free_pages+0x28>
    base->property = n;
ffffffffc020480a:	2581                	sext.w	a1,a1
ffffffffc020480c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020480e:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204812:	4789                	li	a5,2
ffffffffc0204814:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0204818:	000a8697          	auipc	a3,0xa8
ffffffffc020481c:	d3868693          	addi	a3,a3,-712 # ffffffffc02ac550 <free_area>
ffffffffc0204820:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0204822:	669c                	ld	a5,8(a3)
ffffffffc0204824:	9db9                	addw	a1,a1,a4
ffffffffc0204826:	000a8717          	auipc	a4,0xa8
ffffffffc020482a:	d2b72d23          	sw	a1,-710(a4) # ffffffffc02ac560 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc020482e:	0cd78163          	beq	a5,a3,ffffffffc02048f0 <default_free_pages+0x12e>
            struct Page* page = le2page(le, page_link);
ffffffffc0204832:	fe878713          	addi	a4,a5,-24
ffffffffc0204836:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0204838:	4801                	li	a6,0
ffffffffc020483a:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc020483e:	00e56a63          	bltu	a0,a4,ffffffffc0204852 <default_free_pages+0x90>
    return listelm->next;
ffffffffc0204842:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0204844:	04d70f63          	beq	a4,a3,ffffffffc02048a2 <default_free_pages+0xe0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0204848:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020484a:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020484e:	fee57ae3          	bleu	a4,a0,ffffffffc0204842 <default_free_pages+0x80>
ffffffffc0204852:	00080663          	beqz	a6,ffffffffc020485e <default_free_pages+0x9c>
ffffffffc0204856:	000a8817          	auipc	a6,0xa8
ffffffffc020485a:	ceb83d23          	sd	a1,-774(a6) # ffffffffc02ac550 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc020485e:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc0204860:	e390                	sd	a2,0(a5)
ffffffffc0204862:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc0204864:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204866:	ed0c                	sd	a1,24(a0)
    if (le != &free_list) {
ffffffffc0204868:	06d58a63          	beq	a1,a3,ffffffffc02048dc <default_free_pages+0x11a>
        if (p + p->property == base) {
ffffffffc020486c:	ff85a603          	lw	a2,-8(a1) # ff8 <_binary_obj___user_faultread_out_size-0x8578>
        p = le2page(le, page_link);
ffffffffc0204870:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base) {
ffffffffc0204874:	02061793          	slli	a5,a2,0x20
ffffffffc0204878:	83e9                	srli	a5,a5,0x1a
ffffffffc020487a:	97ba                	add	a5,a5,a4
ffffffffc020487c:	04f51b63          	bne	a0,a5,ffffffffc02048d2 <default_free_pages+0x110>
            p->property += base->property;
ffffffffc0204880:	491c                	lw	a5,16(a0)
ffffffffc0204882:	9e3d                	addw	a2,a2,a5
ffffffffc0204884:	fec5ac23          	sw	a2,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204888:	57f5                	li	a5,-3
ffffffffc020488a:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020488e:	01853803          	ld	a6,24(a0)
ffffffffc0204892:	7110                	ld	a2,32(a0)
            base = p;
ffffffffc0204894:	853a                	mv	a0,a4
    prev->next = next;
ffffffffc0204896:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc020489a:	659c                	ld	a5,8(a1)
ffffffffc020489c:	01063023          	sd	a6,0(a2)
ffffffffc02048a0:	a815                	j	ffffffffc02048d4 <default_free_pages+0x112>
    prev->next = next->prev = elm;
ffffffffc02048a2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02048a4:	f114                	sd	a3,32(a0)
ffffffffc02048a6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02048a8:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02048aa:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02048ac:	00d70563          	beq	a4,a3,ffffffffc02048b6 <default_free_pages+0xf4>
ffffffffc02048b0:	4805                	li	a6,1
ffffffffc02048b2:	87ba                	mv	a5,a4
ffffffffc02048b4:	bf59                	j	ffffffffc020484a <default_free_pages+0x88>
ffffffffc02048b6:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02048b8:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc02048ba:	00d78d63          	beq	a5,a3,ffffffffc02048d4 <default_free_pages+0x112>
        if (p + p->property == base) {
ffffffffc02048be:	ff85a603          	lw	a2,-8(a1)
        p = le2page(le, page_link);
ffffffffc02048c2:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base) {
ffffffffc02048c6:	02061793          	slli	a5,a2,0x20
ffffffffc02048ca:	83e9                	srli	a5,a5,0x1a
ffffffffc02048cc:	97ba                	add	a5,a5,a4
ffffffffc02048ce:	faf509e3          	beq	a0,a5,ffffffffc0204880 <default_free_pages+0xbe>
ffffffffc02048d2:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02048d4:	fe878713          	addi	a4,a5,-24
ffffffffc02048d8:	00d78963          	beq	a5,a3,ffffffffc02048ea <default_free_pages+0x128>
        if (base + base->property == p) {
ffffffffc02048dc:	4910                	lw	a2,16(a0)
ffffffffc02048de:	02061693          	slli	a3,a2,0x20
ffffffffc02048e2:	82e9                	srli	a3,a3,0x1a
ffffffffc02048e4:	96aa                	add	a3,a3,a0
ffffffffc02048e6:	00d70e63          	beq	a4,a3,ffffffffc0204902 <default_free_pages+0x140>
}
ffffffffc02048ea:	60a2                	ld	ra,8(sp)
ffffffffc02048ec:	0141                	addi	sp,sp,16
ffffffffc02048ee:	8082                	ret
ffffffffc02048f0:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02048f2:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02048f6:	e398                	sd	a4,0(a5)
ffffffffc02048f8:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02048fa:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02048fc:	ed1c                	sd	a5,24(a0)
}
ffffffffc02048fe:	0141                	addi	sp,sp,16
ffffffffc0204900:	8082                	ret
            base->property += p->property;
ffffffffc0204902:	ff87a703          	lw	a4,-8(a5)
ffffffffc0204906:	ff078693          	addi	a3,a5,-16
ffffffffc020490a:	9e39                	addw	a2,a2,a4
ffffffffc020490c:	c910                	sw	a2,16(a0)
ffffffffc020490e:	5775                	li	a4,-3
ffffffffc0204910:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204914:	6398                	ld	a4,0(a5)
ffffffffc0204916:	679c                	ld	a5,8(a5)
}
ffffffffc0204918:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020491a:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020491c:	e398                	sd	a4,0(a5)
ffffffffc020491e:	0141                	addi	sp,sp,16
ffffffffc0204920:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0204922:	00004697          	auipc	a3,0x4
ffffffffc0204926:	9ee68693          	addi	a3,a3,-1554 # ffffffffc0208310 <commands+0x1b60>
ffffffffc020492a:	00002617          	auipc	a2,0x2
ffffffffc020492e:	30660613          	addi	a2,a2,774 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204932:	08300593          	li	a1,131
ffffffffc0204936:	00003517          	auipc	a0,0x3
ffffffffc020493a:	6ca50513          	addi	a0,a0,1738 # ffffffffc0208000 <commands+0x1850>
ffffffffc020493e:	8d9fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(n > 0);
ffffffffc0204942:	00004697          	auipc	a3,0x4
ffffffffc0204946:	9f668693          	addi	a3,a3,-1546 # ffffffffc0208338 <commands+0x1b88>
ffffffffc020494a:	00002617          	auipc	a2,0x2
ffffffffc020494e:	2e660613          	addi	a2,a2,742 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204952:	08000593          	li	a1,128
ffffffffc0204956:	00003517          	auipc	a0,0x3
ffffffffc020495a:	6aa50513          	addi	a0,a0,1706 # ffffffffc0208000 <commands+0x1850>
ffffffffc020495e:	8b9fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204962 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0204962:	c959                	beqz	a0,ffffffffc02049f8 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc0204964:	000a8597          	auipc	a1,0xa8
ffffffffc0204968:	bec58593          	addi	a1,a1,-1044 # ffffffffc02ac550 <free_area>
ffffffffc020496c:	0105a803          	lw	a6,16(a1)
ffffffffc0204970:	862a                	mv	a2,a0
ffffffffc0204972:	02081793          	slli	a5,a6,0x20
ffffffffc0204976:	9381                	srli	a5,a5,0x20
ffffffffc0204978:	00a7ee63          	bltu	a5,a0,ffffffffc0204994 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020497c:	87ae                	mv	a5,a1
ffffffffc020497e:	a801                	j	ffffffffc020498e <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0204980:	ff87a703          	lw	a4,-8(a5)
ffffffffc0204984:	02071693          	slli	a3,a4,0x20
ffffffffc0204988:	9281                	srli	a3,a3,0x20
ffffffffc020498a:	00c6f763          	bleu	a2,a3,ffffffffc0204998 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc020498e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0204990:	feb798e3          	bne	a5,a1,ffffffffc0204980 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0204994:	4501                	li	a0,0
}
ffffffffc0204996:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc0204998:	fe878513          	addi	a0,a5,-24
    if (page != NULL) {
ffffffffc020499c:	dd6d                	beqz	a0,ffffffffc0204996 <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc020499e:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02049a2:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc02049a6:	00060e1b          	sext.w	t3,a2
ffffffffc02049aa:	0068b423          	sd	t1,8(a7) # fffffffffff80008 <end+0x3fcd3a90>
    next->prev = prev;
ffffffffc02049ae:	01133023          	sd	a7,0(t1) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff5588>
        if (page->property > n) {
ffffffffc02049b2:	02d67863          	bleu	a3,a2,ffffffffc02049e2 <default_alloc_pages+0x80>
            struct Page *p = page + n;
ffffffffc02049b6:	061a                	slli	a2,a2,0x6
ffffffffc02049b8:	962a                	add	a2,a2,a0
            p->property = page->property - n;
ffffffffc02049ba:	41c7073b          	subw	a4,a4,t3
ffffffffc02049be:	ca18                	sw	a4,16(a2)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02049c0:	00860693          	addi	a3,a2,8
ffffffffc02049c4:	4709                	li	a4,2
ffffffffc02049c6:	40e6b02f          	amoor.d	zero,a4,(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc02049ca:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02049ce:	01860693          	addi	a3,a2,24
    prev->next = next->prev = elm;
ffffffffc02049d2:	0105a803          	lw	a6,16(a1)
ffffffffc02049d6:	e314                	sd	a3,0(a4)
ffffffffc02049d8:	00d8b423          	sd	a3,8(a7)
    elm->next = next;
ffffffffc02049dc:	f218                	sd	a4,32(a2)
    elm->prev = prev;
ffffffffc02049de:	01163c23          	sd	a7,24(a2)
        nr_free -= n;
ffffffffc02049e2:	41c8083b          	subw	a6,a6,t3
ffffffffc02049e6:	000a8717          	auipc	a4,0xa8
ffffffffc02049ea:	b7072d23          	sw	a6,-1158(a4) # ffffffffc02ac560 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02049ee:	5775                	li	a4,-3
ffffffffc02049f0:	17c1                	addi	a5,a5,-16
ffffffffc02049f2:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc02049f6:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02049f8:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02049fa:	00004697          	auipc	a3,0x4
ffffffffc02049fe:	93e68693          	addi	a3,a3,-1730 # ffffffffc0208338 <commands+0x1b88>
ffffffffc0204a02:	00002617          	auipc	a2,0x2
ffffffffc0204a06:	22e60613          	addi	a2,a2,558 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204a0a:	06200593          	li	a1,98
ffffffffc0204a0e:	00003517          	auipc	a0,0x3
ffffffffc0204a12:	5f250513          	addi	a0,a0,1522 # ffffffffc0208000 <commands+0x1850>
default_alloc_pages(size_t n) {
ffffffffc0204a16:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0204a18:	ffefb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204a1c <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0204a1c:	1141                	addi	sp,sp,-16
ffffffffc0204a1e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0204a20:	c1ed                	beqz	a1,ffffffffc0204b02 <default_init_memmap+0xe6>
    for (; p != base + n; p ++) {
ffffffffc0204a22:	00659693          	slli	a3,a1,0x6
ffffffffc0204a26:	96aa                	add	a3,a3,a0
ffffffffc0204a28:	02d50463          	beq	a0,a3,ffffffffc0204a50 <default_init_memmap+0x34>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0204a2c:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc0204a2e:	87aa                	mv	a5,a0
ffffffffc0204a30:	8b05                	andi	a4,a4,1
ffffffffc0204a32:	e709                	bnez	a4,ffffffffc0204a3c <default_init_memmap+0x20>
ffffffffc0204a34:	a07d                	j	ffffffffc0204ae2 <default_init_memmap+0xc6>
ffffffffc0204a36:	6798                	ld	a4,8(a5)
ffffffffc0204a38:	8b05                	andi	a4,a4,1
ffffffffc0204a3a:	c745                	beqz	a4,ffffffffc0204ae2 <default_init_memmap+0xc6>
        p->flags = p->property = 0;
ffffffffc0204a3c:	0007a823          	sw	zero,16(a5)
ffffffffc0204a40:	0007b423          	sd	zero,8(a5)
ffffffffc0204a44:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0204a48:	04078793          	addi	a5,a5,64
ffffffffc0204a4c:	fed795e3          	bne	a5,a3,ffffffffc0204a36 <default_init_memmap+0x1a>
    base->property = n;
ffffffffc0204a50:	2581                	sext.w	a1,a1
ffffffffc0204a52:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204a54:	4789                	li	a5,2
ffffffffc0204a56:	00850713          	addi	a4,a0,8
ffffffffc0204a5a:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0204a5e:	000a8697          	auipc	a3,0xa8
ffffffffc0204a62:	af268693          	addi	a3,a3,-1294 # ffffffffc02ac550 <free_area>
ffffffffc0204a66:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0204a68:	669c                	ld	a5,8(a3)
ffffffffc0204a6a:	9db9                	addw	a1,a1,a4
ffffffffc0204a6c:	000a8717          	auipc	a4,0xa8
ffffffffc0204a70:	aeb72a23          	sw	a1,-1292(a4) # ffffffffc02ac560 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0204a74:	04d78a63          	beq	a5,a3,ffffffffc0204ac8 <default_init_memmap+0xac>
            struct Page* page = le2page(le, page_link);
ffffffffc0204a78:	fe878713          	addi	a4,a5,-24
ffffffffc0204a7c:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0204a7e:	4801                	li	a6,0
ffffffffc0204a80:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0204a84:	00e56a63          	bltu	a0,a4,ffffffffc0204a98 <default_init_memmap+0x7c>
    return listelm->next;
ffffffffc0204a88:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0204a8a:	02d70563          	beq	a4,a3,ffffffffc0204ab4 <default_init_memmap+0x98>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0204a8e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0204a90:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0204a94:	fee57ae3          	bleu	a4,a0,ffffffffc0204a88 <default_init_memmap+0x6c>
ffffffffc0204a98:	00080663          	beqz	a6,ffffffffc0204aa4 <default_init_memmap+0x88>
ffffffffc0204a9c:	000a8717          	auipc	a4,0xa8
ffffffffc0204aa0:	aab73a23          	sd	a1,-1356(a4) # ffffffffc02ac550 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0204aa4:	6398                	ld	a4,0(a5)
}
ffffffffc0204aa6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0204aa8:	e390                	sd	a2,0(a5)
ffffffffc0204aaa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0204aac:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204aae:	ed18                	sd	a4,24(a0)
ffffffffc0204ab0:	0141                	addi	sp,sp,16
ffffffffc0204ab2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0204ab4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204ab6:	f114                	sd	a3,32(a0)
ffffffffc0204ab8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0204aba:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0204abc:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0204abe:	00d70e63          	beq	a4,a3,ffffffffc0204ada <default_init_memmap+0xbe>
ffffffffc0204ac2:	4805                	li	a6,1
ffffffffc0204ac4:	87ba                	mv	a5,a4
ffffffffc0204ac6:	b7e9                	j	ffffffffc0204a90 <default_init_memmap+0x74>
}
ffffffffc0204ac8:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0204aca:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0204ace:	e398                	sd	a4,0(a5)
ffffffffc0204ad0:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0204ad2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204ad4:	ed1c                	sd	a5,24(a0)
}
ffffffffc0204ad6:	0141                	addi	sp,sp,16
ffffffffc0204ad8:	8082                	ret
ffffffffc0204ada:	60a2                	ld	ra,8(sp)
ffffffffc0204adc:	e290                	sd	a2,0(a3)
ffffffffc0204ade:	0141                	addi	sp,sp,16
ffffffffc0204ae0:	8082                	ret
        assert(PageReserved(p));
ffffffffc0204ae2:	00004697          	auipc	a3,0x4
ffffffffc0204ae6:	85e68693          	addi	a3,a3,-1954 # ffffffffc0208340 <commands+0x1b90>
ffffffffc0204aea:	00002617          	auipc	a2,0x2
ffffffffc0204aee:	14660613          	addi	a2,a2,326 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204af2:	04900593          	li	a1,73
ffffffffc0204af6:	00003517          	auipc	a0,0x3
ffffffffc0204afa:	50a50513          	addi	a0,a0,1290 # ffffffffc0208000 <commands+0x1850>
ffffffffc0204afe:	f18fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(n > 0);
ffffffffc0204b02:	00004697          	auipc	a3,0x4
ffffffffc0204b06:	83668693          	addi	a3,a3,-1994 # ffffffffc0208338 <commands+0x1b88>
ffffffffc0204b0a:	00002617          	auipc	a2,0x2
ffffffffc0204b0e:	12660613          	addi	a2,a2,294 # ffffffffc0206c30 <commands+0x480>
ffffffffc0204b12:	04600593          	li	a1,70
ffffffffc0204b16:	00003517          	auipc	a0,0x3
ffffffffc0204b1a:	4ea50513          	addi	a0,a0,1258 # ffffffffc0208000 <commands+0x1850>
ffffffffc0204b1e:	ef8fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204b22 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204b22:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b24:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204b26:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b28:	a0dfb0ef          	jal	ra,ffffffffc0200534 <ide_device_valid>
ffffffffc0204b2c:	cd01                	beqz	a0,ffffffffc0204b44 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204b2e:	4505                	li	a0,1
ffffffffc0204b30:	a0bfb0ef          	jal	ra,ffffffffc020053a <ide_device_size>
}
ffffffffc0204b34:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204b36:	810d                	srli	a0,a0,0x3
ffffffffc0204b38:	000a8797          	auipc	a5,0xa8
ffffffffc0204b3c:	9ca7bc23          	sd	a0,-1576(a5) # ffffffffc02ac510 <max_swap_offset>
}
ffffffffc0204b40:	0141                	addi	sp,sp,16
ffffffffc0204b42:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204b44:	00004617          	auipc	a2,0x4
ffffffffc0204b48:	85c60613          	addi	a2,a2,-1956 # ffffffffc02083a0 <default_pmm_manager+0x50>
ffffffffc0204b4c:	45b5                	li	a1,13
ffffffffc0204b4e:	00004517          	auipc	a0,0x4
ffffffffc0204b52:	87250513          	addi	a0,a0,-1934 # ffffffffc02083c0 <default_pmm_manager+0x70>
ffffffffc0204b56:	ec0fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204b5a <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204b5a:	1141                	addi	sp,sp,-16
ffffffffc0204b5c:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204b5e:	00855793          	srli	a5,a0,0x8
ffffffffc0204b62:	cfb9                	beqz	a5,ffffffffc0204bc0 <swapfs_read+0x66>
ffffffffc0204b64:	000a8717          	auipc	a4,0xa8
ffffffffc0204b68:	9ac70713          	addi	a4,a4,-1620 # ffffffffc02ac510 <max_swap_offset>
ffffffffc0204b6c:	6318                	ld	a4,0(a4)
ffffffffc0204b6e:	04e7f963          	bleu	a4,a5,ffffffffc0204bc0 <swapfs_read+0x66>
    return page - pages + nbase;
ffffffffc0204b72:	000a8717          	auipc	a4,0xa8
ffffffffc0204b76:	8f670713          	addi	a4,a4,-1802 # ffffffffc02ac468 <pages>
ffffffffc0204b7a:	6310                	ld	a2,0(a4)
ffffffffc0204b7c:	00004717          	auipc	a4,0x4
ffffffffc0204b80:	1ec70713          	addi	a4,a4,492 # ffffffffc0208d68 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204b84:	000a8697          	auipc	a3,0xa8
ffffffffc0204b88:	87c68693          	addi	a3,a3,-1924 # ffffffffc02ac400 <npage>
    return page - pages + nbase;
ffffffffc0204b8c:	40c58633          	sub	a2,a1,a2
ffffffffc0204b90:	630c                	ld	a1,0(a4)
ffffffffc0204b92:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204b94:	577d                	li	a4,-1
ffffffffc0204b96:	6294                	ld	a3,0(a3)
    return page - pages + nbase;
ffffffffc0204b98:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204b9a:	8331                	srli	a4,a4,0xc
ffffffffc0204b9c:	8f71                	and	a4,a4,a2
ffffffffc0204b9e:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ba2:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204ba4:	02d77a63          	bleu	a3,a4,ffffffffc0204bd8 <swapfs_read+0x7e>
ffffffffc0204ba8:	000a8797          	auipc	a5,0xa8
ffffffffc0204bac:	8b078793          	addi	a5,a5,-1872 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0204bb0:	639c                	ld	a5,0(a5)
}
ffffffffc0204bb2:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204bb4:	46a1                	li	a3,8
ffffffffc0204bb6:	963e                	add	a2,a2,a5
ffffffffc0204bb8:	4505                	li	a0,1
}
ffffffffc0204bba:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204bbc:	985fb06f          	j	ffffffffc0200540 <ide_read_secs>
ffffffffc0204bc0:	86aa                	mv	a3,a0
ffffffffc0204bc2:	00004617          	auipc	a2,0x4
ffffffffc0204bc6:	81660613          	addi	a2,a2,-2026 # ffffffffc02083d8 <default_pmm_manager+0x88>
ffffffffc0204bca:	45d1                	li	a1,20
ffffffffc0204bcc:	00003517          	auipc	a0,0x3
ffffffffc0204bd0:	7f450513          	addi	a0,a0,2036 # ffffffffc02083c0 <default_pmm_manager+0x70>
ffffffffc0204bd4:	e42fb0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0204bd8:	86b2                	mv	a3,a2
ffffffffc0204bda:	06900593          	li	a1,105
ffffffffc0204bde:	00002617          	auipc	a2,0x2
ffffffffc0204be2:	43a60613          	addi	a2,a2,1082 # ffffffffc0207018 <commands+0x868>
ffffffffc0204be6:	00002517          	auipc	a0,0x2
ffffffffc0204bea:	48a50513          	addi	a0,a0,1162 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0204bee:	e28fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204bf2 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204bf2:	1141                	addi	sp,sp,-16
ffffffffc0204bf4:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204bf6:	00855793          	srli	a5,a0,0x8
ffffffffc0204bfa:	cfb9                	beqz	a5,ffffffffc0204c58 <swapfs_write+0x66>
ffffffffc0204bfc:	000a8717          	auipc	a4,0xa8
ffffffffc0204c00:	91470713          	addi	a4,a4,-1772 # ffffffffc02ac510 <max_swap_offset>
ffffffffc0204c04:	6318                	ld	a4,0(a4)
ffffffffc0204c06:	04e7f963          	bleu	a4,a5,ffffffffc0204c58 <swapfs_write+0x66>
    return page - pages + nbase;
ffffffffc0204c0a:	000a8717          	auipc	a4,0xa8
ffffffffc0204c0e:	85e70713          	addi	a4,a4,-1954 # ffffffffc02ac468 <pages>
ffffffffc0204c12:	6310                	ld	a2,0(a4)
ffffffffc0204c14:	00004717          	auipc	a4,0x4
ffffffffc0204c18:	15470713          	addi	a4,a4,340 # ffffffffc0208d68 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204c1c:	000a7697          	auipc	a3,0xa7
ffffffffc0204c20:	7e468693          	addi	a3,a3,2020 # ffffffffc02ac400 <npage>
    return page - pages + nbase;
ffffffffc0204c24:	40c58633          	sub	a2,a1,a2
ffffffffc0204c28:	630c                	ld	a1,0(a4)
ffffffffc0204c2a:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204c2c:	577d                	li	a4,-1
ffffffffc0204c2e:	6294                	ld	a3,0(a3)
    return page - pages + nbase;
ffffffffc0204c30:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204c32:	8331                	srli	a4,a4,0xc
ffffffffc0204c34:	8f71                	and	a4,a4,a2
ffffffffc0204c36:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c3a:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204c3c:	02d77a63          	bleu	a3,a4,ffffffffc0204c70 <swapfs_write+0x7e>
ffffffffc0204c40:	000a8797          	auipc	a5,0xa8
ffffffffc0204c44:	81878793          	addi	a5,a5,-2024 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0204c48:	639c                	ld	a5,0(a5)
}
ffffffffc0204c4a:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c4c:	46a1                	li	a3,8
ffffffffc0204c4e:	963e                	add	a2,a2,a5
ffffffffc0204c50:	4505                	li	a0,1
}
ffffffffc0204c52:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c54:	911fb06f          	j	ffffffffc0200564 <ide_write_secs>
ffffffffc0204c58:	86aa                	mv	a3,a0
ffffffffc0204c5a:	00003617          	auipc	a2,0x3
ffffffffc0204c5e:	77e60613          	addi	a2,a2,1918 # ffffffffc02083d8 <default_pmm_manager+0x88>
ffffffffc0204c62:	45e5                	li	a1,25
ffffffffc0204c64:	00003517          	auipc	a0,0x3
ffffffffc0204c68:	75c50513          	addi	a0,a0,1884 # ffffffffc02083c0 <default_pmm_manager+0x70>
ffffffffc0204c6c:	daafb0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0204c70:	86b2                	mv	a3,a2
ffffffffc0204c72:	06900593          	li	a1,105
ffffffffc0204c76:	00002617          	auipc	a2,0x2
ffffffffc0204c7a:	3a260613          	addi	a2,a2,930 # ffffffffc0207018 <commands+0x868>
ffffffffc0204c7e:	00002517          	auipc	a0,0x2
ffffffffc0204c82:	3f250513          	addi	a0,a0,1010 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0204c86:	d90fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204c8a <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204c8a:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204c8c:	9402                	jalr	s0

	jal do_exit
ffffffffc0204c8e:	7ca000ef          	jal	ra,ffffffffc0205458 <do_exit>

ffffffffc0204c92 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204c92:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204c96:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204c9a:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204c9c:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204c9e:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204ca2:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204ca6:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204caa:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204cae:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204cb2:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204cb6:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204cba:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204cbe:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204cc2:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204cc6:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204cca:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204cce:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204cd0:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204cd2:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204cd6:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204cda:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204cde:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204ce2:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204ce6:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204cea:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204cee:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204cf2:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204cf6:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204cfa:	8082                	ret

ffffffffc0204cfc <alloc_proc>:
↓
这个流程图的进程的父亲调用do_wait(状态：结束)
*/
// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204cfc:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204cfe:	10800513          	li	a0,264
alloc_proc(void) {
ffffffffc0204d02:	e022                	sd	s0,0(sp)
ffffffffc0204d04:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204d06:	fc0fe0ef          	jal	ra,ffffffffc02034c6 <kmalloc>
ffffffffc0204d0a:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204d0c:	cd29                	beqz	a0,ffffffffc0204d66 <alloc_proc+0x6a>
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */

    // 检查idleproc初始化的条件语句已经指明了该如何设置这些值
    proc->state = PROC_UNINIT;                           // 此时未分配该PCB对应的资源，故状态为初始态
ffffffffc0204d0e:	57fd                	li	a5,-1
ffffffffc0204d10:	1782                	slli	a5,a5,0x20
ffffffffc0204d12:	e11c                	sd	a5,0(a0)
    proc->runs = 0;                                      // 分配阶段故运行次数为0
    proc->kstack = 0;                                    // 内核栈暂未分配
    proc->need_resched = 0;                              // 不用调度其他进程、即CPU资源不分配
    proc->parent = NULL;                                 // 当前无父进程
    proc->mm = NULL;                                     // 当前未分配内存
    memset(&(proc->context), 0, sizeof(struct context)); // 上下文置零
ffffffffc0204d14:	07000613          	li	a2,112
ffffffffc0204d18:	4581                	li	a1,0
    proc->runs = 0;                                      // 分配阶段故运行次数为0
ffffffffc0204d1a:	00052423          	sw	zero,8(a0)
    proc->kstack = 0;                                    // 内核栈暂未分配
ffffffffc0204d1e:	00053823          	sd	zero,16(a0)
    proc->need_resched = 0;                              // 不用调度其他进程、即CPU资源不分配
ffffffffc0204d22:	00053c23          	sd	zero,24(a0)
    proc->parent = NULL;                                 // 当前无父进程
ffffffffc0204d26:	02053023          	sd	zero,32(a0)
    proc->mm = NULL;                                     // 当前未分配内存
ffffffffc0204d2a:	02053423          	sd	zero,40(a0)
    memset(&(proc->context), 0, sizeof(struct context)); // 上下文置零
ffffffffc0204d2e:	03050513          	addi	a0,a0,48
ffffffffc0204d32:	4d2010ef          	jal	ra,ffffffffc0206204 <memset>
    proc->tf = NULL;                                     // 当前无中断帧
    proc->cr3 = boot_cr3;                                // 内核线程同属于一个内核大进程，共享内核空间，故页表相同
ffffffffc0204d36:	000a7797          	auipc	a5,0xa7
ffffffffc0204d3a:	72a78793          	addi	a5,a5,1834 # ffffffffc02ac460 <boot_cr3>
ffffffffc0204d3e:	639c                	ld	a5,0(a5)
    proc->tf = NULL;                                     // 当前无中断帧
ffffffffc0204d40:	0a043023          	sd	zero,160(s0)
    proc->flags = 0;                                     // 当前暂无
ffffffffc0204d44:	0a042823          	sw	zero,176(s0)
    proc->cr3 = boot_cr3;                                // 内核线程同属于一个内核大进程，共享内核空间，故页表相同
ffffffffc0204d48:	f45c                	sd	a5,168(s0)
    memset(&(proc->name), 0, PROC_NAME_LEN);             // 当前暂无
ffffffffc0204d4a:	463d                	li	a2,15
ffffffffc0204d4c:	4581                	li	a1,0
ffffffffc0204d4e:	0b440513          	addi	a0,s0,180
ffffffffc0204d52:	4b2010ef          	jal	ra,ffffffffc0206204 <memset>
children:         proc->cptr    (proc is parent)
older sibling:    proc->optr    (proc is younger sibling)
younger sibling:  proc->yptr    (proc is older sibling)

     */
    proc->wait_state = 0;
ffffffffc0204d56:	0e042623          	sw	zero,236(s0)
    proc->cptr = NULL;
ffffffffc0204d5a:	0e043823          	sd	zero,240(s0)
    proc->yptr = NULL;
ffffffffc0204d5e:	0e043c23          	sd	zero,248(s0)
    proc->optr = NULL;
ffffffffc0204d62:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc0204d66:	8522                	mv	a0,s0
ffffffffc0204d68:	60a2                	ld	ra,8(sp)
ffffffffc0204d6a:	6402                	ld	s0,0(sp)
ffffffffc0204d6c:	0141                	addi	sp,sp,16
ffffffffc0204d6e:	8082                	ret

ffffffffc0204d70 <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc0204d70:	000a7797          	auipc	a5,0xa7
ffffffffc0204d74:	6b878793          	addi	a5,a5,1720 # ffffffffc02ac428 <current>
ffffffffc0204d78:	639c                	ld	a5,0(a5)
ffffffffc0204d7a:	73c8                	ld	a0,160(a5)
ffffffffc0204d7c:	82efc06f          	j	ffffffffc0200daa <forkrets>

ffffffffc0204d80 <user_main>:

// user_main - kernel thread used to exec a user program
static int
user_main(void *arg) {
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d80:	000a7797          	auipc	a5,0xa7
ffffffffc0204d84:	6a878793          	addi	a5,a5,1704 # ffffffffc02ac428 <current>
ffffffffc0204d88:	639c                	ld	a5,0(a5)
user_main(void *arg) {
ffffffffc0204d8a:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d8c:	00004617          	auipc	a2,0x4
ffffffffc0204d90:	aac60613          	addi	a2,a2,-1364 # ffffffffc0208838 <default_pmm_manager+0x4e8>
ffffffffc0204d94:	43cc                	lw	a1,4(a5)
ffffffffc0204d96:	00004517          	auipc	a0,0x4
ffffffffc0204d9a:	ab250513          	addi	a0,a0,-1358 # ffffffffc0208848 <default_pmm_manager+0x4f8>
user_main(void *arg) {
ffffffffc0204d9e:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204da0:	b30fb0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0204da4:	00004797          	auipc	a5,0x4
ffffffffc0204da8:	a9478793          	addi	a5,a5,-1388 # ffffffffc0208838 <default_pmm_manager+0x4e8>
ffffffffc0204dac:	3fe05717          	auipc	a4,0x3fe05
ffffffffc0204db0:	52c70713          	addi	a4,a4,1324 # a2d8 <_binary_obj___user_forktest_out_size>
ffffffffc0204db4:	e43a                	sd	a4,8(sp)
    int64_t ret=0, len = strlen(name);
ffffffffc0204db6:	853e                	mv	a0,a5
ffffffffc0204db8:	00088717          	auipc	a4,0x88
ffffffffc0204dbc:	79070713          	addi	a4,a4,1936 # ffffffffc028d548 <_binary_obj___user_forktest_out_start>
ffffffffc0204dc0:	f03a                	sd	a4,32(sp)
ffffffffc0204dc2:	f43e                	sd	a5,40(sp)
ffffffffc0204dc4:	e802                	sd	zero,16(sp)
ffffffffc0204dc6:	3a0010ef          	jal	ra,ffffffffc0206166 <strlen>
ffffffffc0204dca:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204dcc:	4511                	li	a0,4
ffffffffc0204dce:	55a2                	lw	a1,40(sp)
ffffffffc0204dd0:	4662                	lw	a2,24(sp)
ffffffffc0204dd2:	5682                	lw	a3,32(sp)
ffffffffc0204dd4:	4722                	lw	a4,8(sp)
ffffffffc0204dd6:	48a9                	li	a7,10
ffffffffc0204dd8:	9002                	ebreak
ffffffffc0204dda:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204ddc:	65c2                	ld	a1,16(sp)
ffffffffc0204dde:	00004517          	auipc	a0,0x4
ffffffffc0204de2:	a9250513          	addi	a0,a0,-1390 # ffffffffc0208870 <default_pmm_manager+0x520>
ffffffffc0204de6:	aeafb0ef          	jal	ra,ffffffffc02000d0 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204dea:	00004617          	auipc	a2,0x4
ffffffffc0204dee:	a9660613          	addi	a2,a2,-1386 # ffffffffc0208880 <default_pmm_manager+0x530>
ffffffffc0204df2:	47c00593          	li	a1,1148
ffffffffc0204df6:	00004517          	auipc	a0,0x4
ffffffffc0204dfa:	aaa50513          	addi	a0,a0,-1366 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0204dfe:	c18fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204e02 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204e02:	6d14                	ld	a3,24(a0)
put_pgdir(struct mm_struct *mm) {
ffffffffc0204e04:	1141                	addi	sp,sp,-16
ffffffffc0204e06:	e406                	sd	ra,8(sp)
ffffffffc0204e08:	c02007b7          	lui	a5,0xc0200
ffffffffc0204e0c:	04f6e263          	bltu	a3,a5,ffffffffc0204e50 <put_pgdir+0x4e>
ffffffffc0204e10:	000a7797          	auipc	a5,0xa7
ffffffffc0204e14:	64878793          	addi	a5,a5,1608 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0204e18:	6388                	ld	a0,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0204e1a:	000a7797          	auipc	a5,0xa7
ffffffffc0204e1e:	5e678793          	addi	a5,a5,1510 # ffffffffc02ac400 <npage>
ffffffffc0204e22:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0204e24:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc0204e26:	82b1                	srli	a3,a3,0xc
ffffffffc0204e28:	04f6f063          	bleu	a5,a3,ffffffffc0204e68 <put_pgdir+0x66>
    return &pages[PPN(pa) - nbase];
ffffffffc0204e2c:	00004797          	auipc	a5,0x4
ffffffffc0204e30:	f3c78793          	addi	a5,a5,-196 # ffffffffc0208d68 <nbase>
ffffffffc0204e34:	639c                	ld	a5,0(a5)
ffffffffc0204e36:	000a7717          	auipc	a4,0xa7
ffffffffc0204e3a:	63270713          	addi	a4,a4,1586 # ffffffffc02ac468 <pages>
ffffffffc0204e3e:	6308                	ld	a0,0(a4)
}
ffffffffc0204e40:	60a2                	ld	ra,8(sp)
ffffffffc0204e42:	8e9d                	sub	a3,a3,a5
ffffffffc0204e44:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204e46:	4585                	li	a1,1
ffffffffc0204e48:	9536                	add	a0,a0,a3
}
ffffffffc0204e4a:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204e4c:	8aefc06f          	j	ffffffffc0200efa <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204e50:	00002617          	auipc	a2,0x2
ffffffffc0204e54:	2a060613          	addi	a2,a2,672 # ffffffffc02070f0 <commands+0x940>
ffffffffc0204e58:	06e00593          	li	a1,110
ffffffffc0204e5c:	00002517          	auipc	a0,0x2
ffffffffc0204e60:	21450513          	addi	a0,a0,532 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0204e64:	bb2fb0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204e68:	00002617          	auipc	a2,0x2
ffffffffc0204e6c:	1e860613          	addi	a2,a2,488 # ffffffffc0207050 <commands+0x8a0>
ffffffffc0204e70:	06200593          	li	a1,98
ffffffffc0204e74:	00002517          	auipc	a0,0x2
ffffffffc0204e78:	1fc50513          	addi	a0,a0,508 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0204e7c:	b9afb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204e80 <setup_pgdir>:
setup_pgdir(struct mm_struct *mm) {
ffffffffc0204e80:	1101                	addi	sp,sp,-32
ffffffffc0204e82:	e426                	sd	s1,8(sp)
ffffffffc0204e84:	84aa                	mv	s1,a0
    if ((page = alloc_page()) == NULL) {
ffffffffc0204e86:	4505                	li	a0,1
setup_pgdir(struct mm_struct *mm) {
ffffffffc0204e88:	ec06                	sd	ra,24(sp)
ffffffffc0204e8a:	e822                	sd	s0,16(sp)
    if ((page = alloc_page()) == NULL) {
ffffffffc0204e8c:	fe7fb0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
ffffffffc0204e90:	c125                	beqz	a0,ffffffffc0204ef0 <setup_pgdir+0x70>
    return page - pages + nbase;
ffffffffc0204e92:	000a7797          	auipc	a5,0xa7
ffffffffc0204e96:	5d678793          	addi	a5,a5,1494 # ffffffffc02ac468 <pages>
ffffffffc0204e9a:	6394                	ld	a3,0(a5)
ffffffffc0204e9c:	00004797          	auipc	a5,0x4
ffffffffc0204ea0:	ecc78793          	addi	a5,a5,-308 # ffffffffc0208d68 <nbase>
ffffffffc0204ea4:	6380                	ld	s0,0(a5)
ffffffffc0204ea6:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204eaa:	000a7717          	auipc	a4,0xa7
ffffffffc0204eae:	55670713          	addi	a4,a4,1366 # ffffffffc02ac400 <npage>
    return page - pages + nbase;
ffffffffc0204eb2:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204eb4:	57fd                	li	a5,-1
ffffffffc0204eb6:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0204eb8:	96a2                	add	a3,a3,s0
    return KADDR(page2pa(page));
ffffffffc0204eba:	83b1                	srli	a5,a5,0xc
ffffffffc0204ebc:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ebe:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ec0:	02e7fa63          	bleu	a4,a5,ffffffffc0204ef4 <setup_pgdir+0x74>
ffffffffc0204ec4:	000a7797          	auipc	a5,0xa7
ffffffffc0204ec8:	59478793          	addi	a5,a5,1428 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0204ecc:	6380                	ld	s0,0(a5)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc0204ece:	000a7797          	auipc	a5,0xa7
ffffffffc0204ed2:	52a78793          	addi	a5,a5,1322 # ffffffffc02ac3f8 <boot_pgdir>
ffffffffc0204ed6:	638c                	ld	a1,0(a5)
ffffffffc0204ed8:	9436                	add	s0,s0,a3
ffffffffc0204eda:	6605                	lui	a2,0x1
ffffffffc0204edc:	8522                	mv	a0,s0
ffffffffc0204ede:	338010ef          	jal	ra,ffffffffc0206216 <memcpy>
    return 0;
ffffffffc0204ee2:	4501                	li	a0,0
    mm->pgdir = pgdir;
ffffffffc0204ee4:	ec80                	sd	s0,24(s1)
}
ffffffffc0204ee6:	60e2                	ld	ra,24(sp)
ffffffffc0204ee8:	6442                	ld	s0,16(sp)
ffffffffc0204eea:	64a2                	ld	s1,8(sp)
ffffffffc0204eec:	6105                	addi	sp,sp,32
ffffffffc0204eee:	8082                	ret
        return -E_NO_MEM;
ffffffffc0204ef0:	5571                	li	a0,-4
ffffffffc0204ef2:	bfd5                	j	ffffffffc0204ee6 <setup_pgdir+0x66>
ffffffffc0204ef4:	00002617          	auipc	a2,0x2
ffffffffc0204ef8:	12460613          	addi	a2,a2,292 # ffffffffc0207018 <commands+0x868>
ffffffffc0204efc:	06900593          	li	a1,105
ffffffffc0204f00:	00002517          	auipc	a0,0x2
ffffffffc0204f04:	17050513          	addi	a0,a0,368 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0204f08:	b0efb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204f0c <set_proc_name>:
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204f0c:	1101                	addi	sp,sp,-32
ffffffffc0204f0e:	e822                	sd	s0,16(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f10:	0b450413          	addi	s0,a0,180
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204f14:	e426                	sd	s1,8(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f16:	4641                	li	a2,16
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204f18:	84ae                	mv	s1,a1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f1a:	8522                	mv	a0,s0
ffffffffc0204f1c:	4581                	li	a1,0
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204f1e:	ec06                	sd	ra,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f20:	2e4010ef          	jal	ra,ffffffffc0206204 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f24:	8522                	mv	a0,s0
}
ffffffffc0204f26:	6442                	ld	s0,16(sp)
ffffffffc0204f28:	60e2                	ld	ra,24(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f2a:	85a6                	mv	a1,s1
}
ffffffffc0204f2c:	64a2                	ld	s1,8(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f2e:	463d                	li	a2,15
}
ffffffffc0204f30:	6105                	addi	sp,sp,32
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f32:	2e40106f          	j	ffffffffc0206216 <memcpy>

ffffffffc0204f36 <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc0204f36:	1101                	addi	sp,sp,-32
ffffffffc0204f38:	e426                	sd	s1,8(sp)
    if (proc != current) {
ffffffffc0204f3a:	000a7497          	auipc	s1,0xa7
ffffffffc0204f3e:	4ee48493          	addi	s1,s1,1262 # ffffffffc02ac428 <current>
ffffffffc0204f42:	6098                	ld	a4,0(s1)
proc_run(struct proc_struct *proc) {
ffffffffc0204f44:	ec06                	sd	ra,24(sp)
ffffffffc0204f46:	e822                	sd	s0,16(sp)
ffffffffc0204f48:	e04a                	sd	s2,0(sp)
    if (proc != current) {
ffffffffc0204f4a:	02a70b63          	beq	a4,a0,ffffffffc0204f80 <proc_run+0x4a>
ffffffffc0204f4e:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204f50:	100027f3          	csrr	a5,sstatus
ffffffffc0204f54:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204f56:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204f58:	e3a9                	bnez	a5,ffffffffc0204f9a <proc_run+0x64>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204f5a:	745c                	ld	a5,168(s0)
            current = proc;
ffffffffc0204f5c:	000a7697          	auipc	a3,0xa7
ffffffffc0204f60:	4c86b623          	sd	s0,1228(a3) # ffffffffc02ac428 <current>
ffffffffc0204f64:	56fd                	li	a3,-1
ffffffffc0204f66:	16fe                	slli	a3,a3,0x3f
ffffffffc0204f68:	83b1                	srli	a5,a5,0xc
ffffffffc0204f6a:	8fd5                	or	a5,a5,a3
ffffffffc0204f6c:	18079073          	csrw	satp,a5
            switch_to(&(temp_proc->context), &(current->context));
ffffffffc0204f70:	03040593          	addi	a1,s0,48
ffffffffc0204f74:	03070513          	addi	a0,a4,48
ffffffffc0204f78:	d1bff0ef          	jal	ra,ffffffffc0204c92 <switch_to>
    if (flag) {
ffffffffc0204f7c:	00091863          	bnez	s2,ffffffffc0204f8c <proc_run+0x56>
}
ffffffffc0204f80:	60e2                	ld	ra,24(sp)
ffffffffc0204f82:	6442                	ld	s0,16(sp)
ffffffffc0204f84:	64a2                	ld	s1,8(sp)
ffffffffc0204f86:	6902                	ld	s2,0(sp)
ffffffffc0204f88:	6105                	addi	sp,sp,32
ffffffffc0204f8a:	8082                	ret
ffffffffc0204f8c:	6442                	ld	s0,16(sp)
ffffffffc0204f8e:	60e2                	ld	ra,24(sp)
ffffffffc0204f90:	64a2                	ld	s1,8(sp)
ffffffffc0204f92:	6902                	ld	s2,0(sp)
ffffffffc0204f94:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204f96:	ec0fb06f          	j	ffffffffc0200656 <intr_enable>
        intr_disable();
ffffffffc0204f9a:	ec2fb0ef          	jal	ra,ffffffffc020065c <intr_disable>
        return 1;
ffffffffc0204f9e:	6098                	ld	a4,0(s1)
ffffffffc0204fa0:	4905                	li	s2,1
ffffffffc0204fa2:	bf65                	j	ffffffffc0204f5a <proc_run+0x24>

ffffffffc0204fa4 <find_proc>:
    if (0 < pid && pid < MAX_PID) {
ffffffffc0204fa4:	0005071b          	sext.w	a4,a0
ffffffffc0204fa8:	6789                	lui	a5,0x2
ffffffffc0204faa:	fff7069b          	addiw	a3,a4,-1
ffffffffc0204fae:	17f9                	addi	a5,a5,-2
ffffffffc0204fb0:	04d7e063          	bltu	a5,a3,ffffffffc0204ff0 <find_proc+0x4c>
find_proc(int pid) {
ffffffffc0204fb4:	1141                	addi	sp,sp,-16
ffffffffc0204fb6:	e022                	sd	s0,0(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204fb8:	45a9                	li	a1,10
ffffffffc0204fba:	842a                	mv	s0,a0
ffffffffc0204fbc:	853a                	mv	a0,a4
find_proc(int pid) {
ffffffffc0204fbe:	e406                	sd	ra,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204fc0:	666010ef          	jal	ra,ffffffffc0206626 <hash32>
ffffffffc0204fc4:	02051693          	slli	a3,a0,0x20
ffffffffc0204fc8:	82f1                	srli	a3,a3,0x1c
ffffffffc0204fca:	000a3517          	auipc	a0,0xa3
ffffffffc0204fce:	41e50513          	addi	a0,a0,1054 # ffffffffc02a83e8 <hash_list>
ffffffffc0204fd2:	96aa                	add	a3,a3,a0
ffffffffc0204fd4:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc0204fd6:	a029                	j	ffffffffc0204fe0 <find_proc+0x3c>
            if (proc->pid == pid) {
ffffffffc0204fd8:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7644>
ffffffffc0204fdc:	00870c63          	beq	a4,s0,ffffffffc0204ff4 <find_proc+0x50>
    return listelm->next;
ffffffffc0204fe0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0204fe2:	fef69be3          	bne	a3,a5,ffffffffc0204fd8 <find_proc+0x34>
}
ffffffffc0204fe6:	60a2                	ld	ra,8(sp)
ffffffffc0204fe8:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc0204fea:	4501                	li	a0,0
}
ffffffffc0204fec:	0141                	addi	sp,sp,16
ffffffffc0204fee:	8082                	ret
    return NULL;
ffffffffc0204ff0:	4501                	li	a0,0
}
ffffffffc0204ff2:	8082                	ret
ffffffffc0204ff4:	60a2                	ld	ra,8(sp)
ffffffffc0204ff6:	6402                	ld	s0,0(sp)
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204ff8:	f2878513          	addi	a0,a5,-216
}
ffffffffc0204ffc:	0141                	addi	sp,sp,16
ffffffffc0204ffe:	8082                	ret

ffffffffc0205000 <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0205000:	7159                	addi	sp,sp,-112
ffffffffc0205002:	e0d2                	sd	s4,64(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0205004:	000a7a17          	auipc	s4,0xa7
ffffffffc0205008:	43ca0a13          	addi	s4,s4,1084 # ffffffffc02ac440 <nr_process>
ffffffffc020500c:	000a2703          	lw	a4,0(s4)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0205010:	f486                	sd	ra,104(sp)
ffffffffc0205012:	f0a2                	sd	s0,96(sp)
ffffffffc0205014:	eca6                	sd	s1,88(sp)
ffffffffc0205016:	e8ca                	sd	s2,80(sp)
ffffffffc0205018:	e4ce                	sd	s3,72(sp)
ffffffffc020501a:	fc56                	sd	s5,56(sp)
ffffffffc020501c:	f85a                	sd	s6,48(sp)
ffffffffc020501e:	f45e                	sd	s7,40(sp)
ffffffffc0205020:	f062                	sd	s8,32(sp)
ffffffffc0205022:	ec66                	sd	s9,24(sp)
ffffffffc0205024:	e86a                	sd	s10,16(sp)
ffffffffc0205026:	e46e                	sd	s11,8(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0205028:	6785                	lui	a5,0x1
ffffffffc020502a:	32f75863          	ble	a5,a4,ffffffffc020535a <do_fork+0x35a>
ffffffffc020502e:	89aa                	mv	s3,a0
ffffffffc0205030:	892e                	mv	s2,a1
ffffffffc0205032:	84b2                	mv	s1,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0205034:	cc9ff0ef          	jal	ra,ffffffffc0204cfc <alloc_proc>
ffffffffc0205038:	842a                	mv	s0,a0
ffffffffc020503a:	32050263          	beqz	a0,ffffffffc020535e <do_fork+0x35e>
    proc->parent = current;
ffffffffc020503e:	000a7c17          	auipc	s8,0xa7
ffffffffc0205042:	3eac0c13          	addi	s8,s8,1002 # ffffffffc02ac428 <current>
ffffffffc0205046:	000c3783          	ld	a5,0(s8)
    assert(current->wait_state == 0);
ffffffffc020504a:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8484>
    proc->parent = current;
ffffffffc020504e:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0205050:	32071b63          	bnez	a4,ffffffffc0205386 <do_fork+0x386>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0205054:	4509                	li	a0,2
ffffffffc0205056:	e1dfb0ef          	jal	ra,ffffffffc0200e72 <alloc_pages>
    if (page != NULL) {
ffffffffc020505a:	2e050963          	beqz	a0,ffffffffc020534c <do_fork+0x34c>
    return page - pages + nbase;
ffffffffc020505e:	000a7a97          	auipc	s5,0xa7
ffffffffc0205062:	40aa8a93          	addi	s5,s5,1034 # ffffffffc02ac468 <pages>
ffffffffc0205066:	000ab683          	ld	a3,0(s5)
ffffffffc020506a:	00004b17          	auipc	s6,0x4
ffffffffc020506e:	cfeb0b13          	addi	s6,s6,-770 # ffffffffc0208d68 <nbase>
ffffffffc0205072:	000b3783          	ld	a5,0(s6)
ffffffffc0205076:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc020507a:	000a7b97          	auipc	s7,0xa7
ffffffffc020507e:	386b8b93          	addi	s7,s7,902 # ffffffffc02ac400 <npage>
    return page - pages + nbase;
ffffffffc0205082:	8699                	srai	a3,a3,0x6
ffffffffc0205084:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205086:	000bb703          	ld	a4,0(s7)
ffffffffc020508a:	57fd                	li	a5,-1
ffffffffc020508c:	83b1                	srli	a5,a5,0xc
ffffffffc020508e:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0205090:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205092:	2ce7fe63          	bleu	a4,a5,ffffffffc020536e <do_fork+0x36e>
ffffffffc0205096:	000a7c97          	auipc	s9,0xa7
ffffffffc020509a:	3c2c8c93          	addi	s9,s9,962 # ffffffffc02ac458 <va_pa_offset>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc020509e:	000c3703          	ld	a4,0(s8)
ffffffffc02050a2:	000cb783          	ld	a5,0(s9)
ffffffffc02050a6:	02873c03          	ld	s8,40(a4)
ffffffffc02050aa:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02050ac:	e814                	sd	a3,16(s0)
    if (oldmm == NULL) {
ffffffffc02050ae:	020c0863          	beqz	s8,ffffffffc02050de <do_fork+0xde>
    if (clone_flags & CLONE_VM) {
ffffffffc02050b2:	1009f993          	andi	s3,s3,256
ffffffffc02050b6:	1e098163          	beqz	s3,ffffffffc0205298 <do_fork+0x298>
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
ffffffffc02050ba:	030c2703          	lw	a4,48(s8)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc02050be:	018c3783          	ld	a5,24(s8)
ffffffffc02050c2:	c02006b7          	lui	a3,0xc0200
ffffffffc02050c6:	2705                	addiw	a4,a4,1
ffffffffc02050c8:	02ec2823          	sw	a4,48(s8)
    proc->mm = mm;
ffffffffc02050cc:	03843423          	sd	s8,40(s0)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc02050d0:	2cd7eb63          	bltu	a5,a3,ffffffffc02053a6 <do_fork+0x3a6>
ffffffffc02050d4:	000cb703          	ld	a4,0(s9)
ffffffffc02050d8:	6814                	ld	a3,16(s0)
ffffffffc02050da:	8f99                	sub	a5,a5,a4
ffffffffc02050dc:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02050de:	6789                	lui	a5,0x2
ffffffffc02050e0:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7690>
ffffffffc02050e4:	96be                	add	a3,a3,a5
ffffffffc02050e6:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc02050e8:	87b6                	mv	a5,a3
ffffffffc02050ea:	12048813          	addi	a6,s1,288
ffffffffc02050ee:	6088                	ld	a0,0(s1)
ffffffffc02050f0:	648c                	ld	a1,8(s1)
ffffffffc02050f2:	6890                	ld	a2,16(s1)
ffffffffc02050f4:	6c98                	ld	a4,24(s1)
ffffffffc02050f6:	e388                	sd	a0,0(a5)
ffffffffc02050f8:	e78c                	sd	a1,8(a5)
ffffffffc02050fa:	eb90                	sd	a2,16(a5)
ffffffffc02050fc:	ef98                	sd	a4,24(a5)
ffffffffc02050fe:	02048493          	addi	s1,s1,32
ffffffffc0205102:	02078793          	addi	a5,a5,32
ffffffffc0205106:	ff0494e3          	bne	s1,a6,ffffffffc02050ee <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc020510a:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x1a>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020510e:	12090e63          	beqz	s2,ffffffffc020524a <do_fork+0x24a>
ffffffffc0205112:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0205116:	00000797          	auipc	a5,0x0
ffffffffc020511a:	c5a78793          	addi	a5,a5,-934 # ffffffffc0204d70 <forkret>
ffffffffc020511e:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0205120:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205122:	100027f3          	csrr	a5,sstatus
ffffffffc0205126:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205128:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020512a:	12079f63          	bnez	a5,ffffffffc0205268 <do_fork+0x268>
    if (++ last_pid >= MAX_PID) {
ffffffffc020512e:	0009c797          	auipc	a5,0x9c
ffffffffc0205132:	eb278793          	addi	a5,a5,-334 # ffffffffc02a0fe0 <last_pid.1691>
ffffffffc0205136:	439c                	lw	a5,0(a5)
ffffffffc0205138:	6709                	lui	a4,0x2
ffffffffc020513a:	0017851b          	addiw	a0,a5,1
ffffffffc020513e:	0009c697          	auipc	a3,0x9c
ffffffffc0205142:	eaa6a123          	sw	a0,-350(a3) # ffffffffc02a0fe0 <last_pid.1691>
ffffffffc0205146:	14e55263          	ble	a4,a0,ffffffffc020528a <do_fork+0x28a>
    if (last_pid >= next_safe) {
ffffffffc020514a:	0009c797          	auipc	a5,0x9c
ffffffffc020514e:	e9a78793          	addi	a5,a5,-358 # ffffffffc02a0fe4 <next_safe.1690>
ffffffffc0205152:	439c                	lw	a5,0(a5)
ffffffffc0205154:	000a7497          	auipc	s1,0xa7
ffffffffc0205158:	41448493          	addi	s1,s1,1044 # ffffffffc02ac568 <proc_list>
ffffffffc020515c:	06f54063          	blt	a0,a5,ffffffffc02051bc <do_fork+0x1bc>
        next_safe = MAX_PID;
ffffffffc0205160:	6789                	lui	a5,0x2
ffffffffc0205162:	0009c717          	auipc	a4,0x9c
ffffffffc0205166:	e8f72123          	sw	a5,-382(a4) # ffffffffc02a0fe4 <next_safe.1690>
ffffffffc020516a:	4581                	li	a1,0
ffffffffc020516c:	87aa                	mv	a5,a0
ffffffffc020516e:	000a7497          	auipc	s1,0xa7
ffffffffc0205172:	3fa48493          	addi	s1,s1,1018 # ffffffffc02ac568 <proc_list>
    repeat:
ffffffffc0205176:	6889                	lui	a7,0x2
ffffffffc0205178:	882e                	mv	a6,a1
ffffffffc020517a:	6609                	lui	a2,0x2
        le = list;
ffffffffc020517c:	000a7697          	auipc	a3,0xa7
ffffffffc0205180:	3ec68693          	addi	a3,a3,1004 # ffffffffc02ac568 <proc_list>
ffffffffc0205184:	6694                	ld	a3,8(a3)
        while ((le = list_next(le)) != list) {
ffffffffc0205186:	00968f63          	beq	a3,s1,ffffffffc02051a4 <do_fork+0x1a4>
            if (proc->pid == last_pid) {
ffffffffc020518a:	f3c6a703          	lw	a4,-196(a3)
ffffffffc020518e:	0ae78963          	beq	a5,a4,ffffffffc0205240 <do_fork+0x240>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc0205192:	fee7d9e3          	ble	a4,a5,ffffffffc0205184 <do_fork+0x184>
ffffffffc0205196:	fec757e3          	ble	a2,a4,ffffffffc0205184 <do_fork+0x184>
ffffffffc020519a:	6694                	ld	a3,8(a3)
ffffffffc020519c:	863a                	mv	a2,a4
ffffffffc020519e:	4805                	li	a6,1
        while ((le = list_next(le)) != list) {
ffffffffc02051a0:	fe9695e3          	bne	a3,s1,ffffffffc020518a <do_fork+0x18a>
ffffffffc02051a4:	c591                	beqz	a1,ffffffffc02051b0 <do_fork+0x1b0>
ffffffffc02051a6:	0009c717          	auipc	a4,0x9c
ffffffffc02051aa:	e2f72d23          	sw	a5,-454(a4) # ffffffffc02a0fe0 <last_pid.1691>
ffffffffc02051ae:	853e                	mv	a0,a5
ffffffffc02051b0:	00080663          	beqz	a6,ffffffffc02051bc <do_fork+0x1bc>
ffffffffc02051b4:	0009c797          	auipc	a5,0x9c
ffffffffc02051b8:	e2c7a823          	sw	a2,-464(a5) # ffffffffc02a0fe4 <next_safe.1690>
        proc->pid = get_pid();
ffffffffc02051bc:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02051be:	45a9                	li	a1,10
ffffffffc02051c0:	2501                	sext.w	a0,a0
ffffffffc02051c2:	464010ef          	jal	ra,ffffffffc0206626 <hash32>
ffffffffc02051c6:	1502                	slli	a0,a0,0x20
ffffffffc02051c8:	000a3797          	auipc	a5,0xa3
ffffffffc02051cc:	22078793          	addi	a5,a5,544 # ffffffffc02a83e8 <hash_list>
ffffffffc02051d0:	8171                	srli	a0,a0,0x1c
ffffffffc02051d2:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02051d4:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc02051d6:	7014                	ld	a3,32(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02051d8:	0d840793          	addi	a5,s0,216
    prev->next = next->prev = elm;
ffffffffc02051dc:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02051de:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc02051e0:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc02051e2:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02051e4:	0c840793          	addi	a5,s0,200
    elm->next = next;
ffffffffc02051e8:	f06c                	sd	a1,224(s0)
    elm->prev = prev;
ffffffffc02051ea:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc02051ec:	e21c                	sd	a5,0(a2)
ffffffffc02051ee:	000a7597          	auipc	a1,0xa7
ffffffffc02051f2:	38f5b123          	sd	a5,898(a1) # ffffffffc02ac570 <proc_list+0x8>
    elm->next = next;
ffffffffc02051f6:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc02051f8:	e464                	sd	s1,200(s0)
    proc->yptr = NULL;
ffffffffc02051fa:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc02051fe:	10e43023          	sd	a4,256(s0)
ffffffffc0205202:	c311                	beqz	a4,ffffffffc0205206 <do_fork+0x206>
        proc->optr->yptr = proc;
ffffffffc0205204:	ff60                	sd	s0,248(a4)
    nr_process ++;
ffffffffc0205206:	000a2783          	lw	a5,0(s4)
    proc->parent->cptr = proc;
ffffffffc020520a:	fae0                	sd	s0,240(a3)
    nr_process ++;
ffffffffc020520c:	2785                	addiw	a5,a5,1
ffffffffc020520e:	000a7717          	auipc	a4,0xa7
ffffffffc0205212:	22f72923          	sw	a5,562(a4) # ffffffffc02ac440 <nr_process>
    if (flag) {
ffffffffc0205216:	10091f63          	bnez	s2,ffffffffc0205334 <do_fork+0x334>
    wakeup_proc(proc);
ffffffffc020521a:	8522                	mv	a0,s0
ffffffffc020521c:	559000ef          	jal	ra,ffffffffc0205f74 <wakeup_proc>
    ret = proc->pid;
ffffffffc0205220:	4048                	lw	a0,4(s0)
}
ffffffffc0205222:	70a6                	ld	ra,104(sp)
ffffffffc0205224:	7406                	ld	s0,96(sp)
ffffffffc0205226:	64e6                	ld	s1,88(sp)
ffffffffc0205228:	6946                	ld	s2,80(sp)
ffffffffc020522a:	69a6                	ld	s3,72(sp)
ffffffffc020522c:	6a06                	ld	s4,64(sp)
ffffffffc020522e:	7ae2                	ld	s5,56(sp)
ffffffffc0205230:	7b42                	ld	s6,48(sp)
ffffffffc0205232:	7ba2                	ld	s7,40(sp)
ffffffffc0205234:	7c02                	ld	s8,32(sp)
ffffffffc0205236:	6ce2                	ld	s9,24(sp)
ffffffffc0205238:	6d42                	ld	s10,16(sp)
ffffffffc020523a:	6da2                	ld	s11,8(sp)
ffffffffc020523c:	6165                	addi	sp,sp,112
ffffffffc020523e:	8082                	ret
                if (++ last_pid >= next_safe) {
ffffffffc0205240:	2785                	addiw	a5,a5,1
ffffffffc0205242:	0ec7dc63          	ble	a2,a5,ffffffffc020533a <do_fork+0x33a>
ffffffffc0205246:	4585                	li	a1,1
ffffffffc0205248:	bf35                	j	ffffffffc0205184 <do_fork+0x184>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020524a:	8936                	mv	s2,a3
ffffffffc020524c:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0205250:	00000797          	auipc	a5,0x0
ffffffffc0205254:	b2078793          	addi	a5,a5,-1248 # ffffffffc0204d70 <forkret>
ffffffffc0205258:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020525a:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020525c:	100027f3          	csrr	a5,sstatus
ffffffffc0205260:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205262:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205264:	ec0785e3          	beqz	a5,ffffffffc020512e <do_fork+0x12e>
        intr_disable();
ffffffffc0205268:	bf4fb0ef          	jal	ra,ffffffffc020065c <intr_disable>
    if (++ last_pid >= MAX_PID) {
ffffffffc020526c:	0009c797          	auipc	a5,0x9c
ffffffffc0205270:	d7478793          	addi	a5,a5,-652 # ffffffffc02a0fe0 <last_pid.1691>
ffffffffc0205274:	439c                	lw	a5,0(a5)
ffffffffc0205276:	6709                	lui	a4,0x2
        return 1;
ffffffffc0205278:	4905                	li	s2,1
ffffffffc020527a:	0017851b          	addiw	a0,a5,1
ffffffffc020527e:	0009c697          	auipc	a3,0x9c
ffffffffc0205282:	d6a6a123          	sw	a0,-670(a3) # ffffffffc02a0fe0 <last_pid.1691>
ffffffffc0205286:	ece542e3          	blt	a0,a4,ffffffffc020514a <do_fork+0x14a>
        last_pid = 1;
ffffffffc020528a:	4785                	li	a5,1
ffffffffc020528c:	0009c717          	auipc	a4,0x9c
ffffffffc0205290:	d4f72a23          	sw	a5,-684(a4) # ffffffffc02a0fe0 <last_pid.1691>
ffffffffc0205294:	4505                	li	a0,1
ffffffffc0205296:	b5e9                	j	ffffffffc0205160 <do_fork+0x160>
    if ((mm = mm_create()) == NULL) {
ffffffffc0205298:	d20fd0ef          	jal	ra,ffffffffc02027b8 <mm_create>
ffffffffc020529c:	8daa                	mv	s11,a0
ffffffffc020529e:	c921                	beqz	a0,ffffffffc02052ee <do_fork+0x2ee>
    if (setup_pgdir(mm) != 0) {
ffffffffc02052a0:	be1ff0ef          	jal	ra,ffffffffc0204e80 <setup_pgdir>
ffffffffc02052a4:	e145                	bnez	a0,ffffffffc0205344 <do_fork+0x344>
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc02052a6:	038c0993          	addi	s3,s8,56
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02052aa:	4785                	li	a5,1
ffffffffc02052ac:	40f9b7af          	amoor.d	a5,a5,(s3)
ffffffffc02052b0:	8b85                	andi	a5,a5,1
ffffffffc02052b2:	4d05                	li	s10,1
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc02052b4:	c799                	beqz	a5,ffffffffc02052c2 <do_fork+0x2c2>
        schedule();
ffffffffc02052b6:	53b000ef          	jal	ra,ffffffffc0205ff0 <schedule>
ffffffffc02052ba:	41a9b7af          	amoor.d	a5,s10,(s3)
ffffffffc02052be:	8b85                	andi	a5,a5,1
    while (!try_lock(lock)) {
ffffffffc02052c0:	fbfd                	bnez	a5,ffffffffc02052b6 <do_fork+0x2b6>
        ret = dup_mmap(mm, oldmm);
ffffffffc02052c2:	85e2                	mv	a1,s8
ffffffffc02052c4:	856e                	mv	a0,s11
ffffffffc02052c6:	f7cfd0ef          	jal	ra,ffffffffc0202a42 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02052ca:	57f9                	li	a5,-2
ffffffffc02052cc:	60f9b7af          	amoand.d	a5,a5,(s3)
ffffffffc02052d0:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc02052d2:	0e078763          	beqz	a5,ffffffffc02053c0 <do_fork+0x3c0>
    if (ret != 0) {
ffffffffc02052d6:	8c6e                	mv	s8,s11
ffffffffc02052d8:	de0501e3          	beqz	a0,ffffffffc02050ba <do_fork+0xba>
    exit_mmap(mm);
ffffffffc02052dc:	856e                	mv	a0,s11
ffffffffc02052de:	801fd0ef          	jal	ra,ffffffffc0202ade <exit_mmap>
    put_pgdir(mm);
ffffffffc02052e2:	856e                	mv	a0,s11
ffffffffc02052e4:	b1fff0ef          	jal	ra,ffffffffc0204e02 <put_pgdir>
    mm_destroy(mm);
ffffffffc02052e8:	856e                	mv	a0,s11
ffffffffc02052ea:	e54fd0ef          	jal	ra,ffffffffc020293e <mm_destroy>
        cprintf("cannot duplicate or share mm.\n");
ffffffffc02052ee:	00003517          	auipc	a0,0x3
ffffffffc02052f2:	36250513          	addi	a0,a0,866 # ffffffffc0208650 <default_pmm_manager+0x300>
ffffffffc02052f6:	ddbfa0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02052fa:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02052fc:	c02007b7          	lui	a5,0xc0200
ffffffffc0205300:	0ef6e863          	bltu	a3,a5,ffffffffc02053f0 <do_fork+0x3f0>
ffffffffc0205304:	000cb783          	ld	a5,0(s9)
    if (PPN(pa) >= npage) {
ffffffffc0205308:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc020530c:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0205310:	83b1                	srli	a5,a5,0xc
ffffffffc0205312:	0ce7f363          	bleu	a4,a5,ffffffffc02053d8 <do_fork+0x3d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0205316:	000b3703          	ld	a4,0(s6)
ffffffffc020531a:	000ab503          	ld	a0,0(s5)
ffffffffc020531e:	4589                	li	a1,2
ffffffffc0205320:	8f99                	sub	a5,a5,a4
ffffffffc0205322:	079a                	slli	a5,a5,0x6
ffffffffc0205324:	953e                	add	a0,a0,a5
ffffffffc0205326:	bd5fb0ef          	jal	ra,ffffffffc0200efa <free_pages>
    kfree(proc);
ffffffffc020532a:	8522                	mv	a0,s0
ffffffffc020532c:	a56fe0ef          	jal	ra,ffffffffc0203582 <kfree>
    ret = -E_NO_MEM;
ffffffffc0205330:	5571                	li	a0,-4
    return ret;
ffffffffc0205332:	bdc5                	j	ffffffffc0205222 <do_fork+0x222>
        intr_enable();
ffffffffc0205334:	b22fb0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc0205338:	b5cd                	j	ffffffffc020521a <do_fork+0x21a>
                    if (last_pid >= MAX_PID) {
ffffffffc020533a:	0117c363          	blt	a5,a7,ffffffffc0205340 <do_fork+0x340>
                        last_pid = 1;
ffffffffc020533e:	4785                	li	a5,1
                    goto repeat;
ffffffffc0205340:	4585                	li	a1,1
ffffffffc0205342:	bd1d                	j	ffffffffc0205178 <do_fork+0x178>
    mm_destroy(mm);
ffffffffc0205344:	856e                	mv	a0,s11
ffffffffc0205346:	df8fd0ef          	jal	ra,ffffffffc020293e <mm_destroy>
ffffffffc020534a:	b755                	j	ffffffffc02052ee <do_fork+0x2ee>
        cprintf("cannot alloc kernel stack for initproc.\n");
ffffffffc020534c:	00003517          	auipc	a0,0x3
ffffffffc0205350:	2ac50513          	addi	a0,a0,684 # ffffffffc02085f8 <default_pmm_manager+0x2a8>
ffffffffc0205354:	d7dfa0ef          	jal	ra,ffffffffc02000d0 <cprintf>
        goto bad_fork_cleanup_proc;
ffffffffc0205358:	bfc9                	j	ffffffffc020532a <do_fork+0x32a>
    int ret = -E_NO_FREE_PROC;
ffffffffc020535a:	556d                	li	a0,-5
ffffffffc020535c:	b5d9                	j	ffffffffc0205222 <do_fork+0x222>
        cprintf("cannot alloc idleproc.\n");
ffffffffc020535e:	00003517          	auipc	a0,0x3
ffffffffc0205362:	26250513          	addi	a0,a0,610 # ffffffffc02085c0 <default_pmm_manager+0x270>
ffffffffc0205366:	d6bfa0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    ret = -E_NO_MEM;
ffffffffc020536a:	5571                	li	a0,-4
        goto fork_out;
ffffffffc020536c:	bd5d                	j	ffffffffc0205222 <do_fork+0x222>
    return KADDR(page2pa(page));
ffffffffc020536e:	00002617          	auipc	a2,0x2
ffffffffc0205372:	caa60613          	addi	a2,a2,-854 # ffffffffc0207018 <commands+0x868>
ffffffffc0205376:	06900593          	li	a1,105
ffffffffc020537a:	00002517          	auipc	a0,0x2
ffffffffc020537e:	cf650513          	addi	a0,a0,-778 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0205382:	e95fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(current->wait_state == 0);
ffffffffc0205386:	00003697          	auipc	a3,0x3
ffffffffc020538a:	25268693          	addi	a3,a3,594 # ffffffffc02085d8 <default_pmm_manager+0x288>
ffffffffc020538e:	00002617          	auipc	a2,0x2
ffffffffc0205392:	8a260613          	addi	a2,a2,-1886 # ffffffffc0206c30 <commands+0x480>
ffffffffc0205396:	20400593          	li	a1,516
ffffffffc020539a:	00003517          	auipc	a0,0x3
ffffffffc020539e:	50650513          	addi	a0,a0,1286 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc02053a2:	e75fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc02053a6:	86be                	mv	a3,a5
ffffffffc02053a8:	00002617          	auipc	a2,0x2
ffffffffc02053ac:	d4860613          	addi	a2,a2,-696 # ffffffffc02070f0 <commands+0x940>
ffffffffc02053b0:	19a00593          	li	a1,410
ffffffffc02053b4:	00003517          	auipc	a0,0x3
ffffffffc02053b8:	4ec50513          	addi	a0,a0,1260 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc02053bc:	e5bfa0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("Unlock failed.\n");
ffffffffc02053c0:	00003617          	auipc	a2,0x3
ffffffffc02053c4:	26860613          	addi	a2,a2,616 # ffffffffc0208628 <default_pmm_manager+0x2d8>
ffffffffc02053c8:	03100593          	li	a1,49
ffffffffc02053cc:	00003517          	auipc	a0,0x3
ffffffffc02053d0:	26c50513          	addi	a0,a0,620 # ffffffffc0208638 <default_pmm_manager+0x2e8>
ffffffffc02053d4:	e43fa0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02053d8:	00002617          	auipc	a2,0x2
ffffffffc02053dc:	c7860613          	addi	a2,a2,-904 # ffffffffc0207050 <commands+0x8a0>
ffffffffc02053e0:	06200593          	li	a1,98
ffffffffc02053e4:	00002517          	auipc	a0,0x2
ffffffffc02053e8:	c8c50513          	addi	a0,a0,-884 # ffffffffc0207070 <commands+0x8c0>
ffffffffc02053ec:	e2bfa0ef          	jal	ra,ffffffffc0200216 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02053f0:	00002617          	auipc	a2,0x2
ffffffffc02053f4:	d0060613          	addi	a2,a2,-768 # ffffffffc02070f0 <commands+0x940>
ffffffffc02053f8:	06e00593          	li	a1,110
ffffffffc02053fc:	00002517          	auipc	a0,0x2
ffffffffc0205400:	c7450513          	addi	a0,a0,-908 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0205404:	e13fa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0205408 <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc0205408:	7129                	addi	sp,sp,-320
ffffffffc020540a:	fa22                	sd	s0,304(sp)
ffffffffc020540c:	f626                	sd	s1,296(sp)
ffffffffc020540e:	f24a                	sd	s2,288(sp)
ffffffffc0205410:	84ae                	mv	s1,a1
ffffffffc0205412:	892a                	mv	s2,a0
ffffffffc0205414:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0205416:	4581                	li	a1,0
ffffffffc0205418:	12000613          	li	a2,288
ffffffffc020541c:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc020541e:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0205420:	5e5000ef          	jal	ra,ffffffffc0206204 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0205424:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0205426:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0205428:	100027f3          	csrr	a5,sstatus
ffffffffc020542c:	edd7f793          	andi	a5,a5,-291
ffffffffc0205430:	1207e793          	ori	a5,a5,288
ffffffffc0205434:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205436:	860a                	mv	a2,sp
ffffffffc0205438:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020543c:	00000797          	auipc	a5,0x0
ffffffffc0205440:	84e78793          	addi	a5,a5,-1970 # ffffffffc0204c8a <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205444:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0205446:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205448:	bb9ff0ef          	jal	ra,ffffffffc0205000 <do_fork>
}
ffffffffc020544c:	70f2                	ld	ra,312(sp)
ffffffffc020544e:	7452                	ld	s0,304(sp)
ffffffffc0205450:	74b2                	ld	s1,296(sp)
ffffffffc0205452:	7912                	ld	s2,288(sp)
ffffffffc0205454:	6131                	addi	sp,sp,320
ffffffffc0205456:	8082                	ret

ffffffffc0205458 <do_exit>:
do_exit(int error_code) {
ffffffffc0205458:	7179                	addi	sp,sp,-48
ffffffffc020545a:	e84a                	sd	s2,16(sp)
    if (current == idleproc) {
ffffffffc020545c:	000a7717          	auipc	a4,0xa7
ffffffffc0205460:	fd470713          	addi	a4,a4,-44 # ffffffffc02ac430 <idleproc>
ffffffffc0205464:	000a7917          	auipc	s2,0xa7
ffffffffc0205468:	fc490913          	addi	s2,s2,-60 # ffffffffc02ac428 <current>
ffffffffc020546c:	00093783          	ld	a5,0(s2)
ffffffffc0205470:	6318                	ld	a4,0(a4)
do_exit(int error_code) {
ffffffffc0205472:	f406                	sd	ra,40(sp)
ffffffffc0205474:	f022                	sd	s0,32(sp)
ffffffffc0205476:	ec26                	sd	s1,24(sp)
ffffffffc0205478:	e44e                	sd	s3,8(sp)
ffffffffc020547a:	e052                	sd	s4,0(sp)
    if (current == idleproc) {
ffffffffc020547c:	0ce78c63          	beq	a5,a4,ffffffffc0205554 <do_exit+0xfc>
    if (current == initproc) {
ffffffffc0205480:	000a7417          	auipc	s0,0xa7
ffffffffc0205484:	fb840413          	addi	s0,s0,-72 # ffffffffc02ac438 <initproc>
ffffffffc0205488:	6018                	ld	a4,0(s0)
ffffffffc020548a:	0ee78b63          	beq	a5,a4,ffffffffc0205580 <do_exit+0x128>
    struct mm_struct *mm = current->mm;
ffffffffc020548e:	7784                	ld	s1,40(a5)
ffffffffc0205490:	89aa                	mv	s3,a0
    if (mm != NULL) {
ffffffffc0205492:	c48d                	beqz	s1,ffffffffc02054bc <do_exit+0x64>
        lcr3(boot_cr3);
ffffffffc0205494:	000a7797          	auipc	a5,0xa7
ffffffffc0205498:	fcc78793          	addi	a5,a5,-52 # ffffffffc02ac460 <boot_cr3>
ffffffffc020549c:	639c                	ld	a5,0(a5)
ffffffffc020549e:	577d                	li	a4,-1
ffffffffc02054a0:	177e                	slli	a4,a4,0x3f
ffffffffc02054a2:	83b1                	srli	a5,a5,0xc
ffffffffc02054a4:	8fd9                	or	a5,a5,a4
ffffffffc02054a6:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02054aa:	589c                	lw	a5,48(s1)
ffffffffc02054ac:	fff7871b          	addiw	a4,a5,-1
ffffffffc02054b0:	d898                	sw	a4,48(s1)
        if (mm_count_dec(mm) == 0) {
ffffffffc02054b2:	cf4d                	beqz	a4,ffffffffc020556c <do_exit+0x114>
        current->mm = NULL;
ffffffffc02054b4:	00093783          	ld	a5,0(s2)
ffffffffc02054b8:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02054bc:	00093783          	ld	a5,0(s2)
ffffffffc02054c0:	470d                	li	a4,3
ffffffffc02054c2:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02054c4:	0f37a423          	sw	s3,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02054c8:	100027f3          	csrr	a5,sstatus
ffffffffc02054cc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02054ce:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02054d0:	e7e1                	bnez	a5,ffffffffc0205598 <do_exit+0x140>
        proc = current->parent;
ffffffffc02054d2:	00093703          	ld	a4,0(s2)
        if (proc->wait_state == WT_CHILD) {
ffffffffc02054d6:	800007b7          	lui	a5,0x80000
ffffffffc02054da:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc02054dc:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD) {
ffffffffc02054de:	0ec52703          	lw	a4,236(a0)
ffffffffc02054e2:	0af70f63          	beq	a4,a5,ffffffffc02055a0 <do_exit+0x148>
ffffffffc02054e6:	00093683          	ld	a3,0(s2)
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02054ea:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02054ee:	448d                	li	s1,3
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02054f0:	0985                	addi	s3,s3,1
        while (current->cptr != NULL) {
ffffffffc02054f2:	7afc                	ld	a5,240(a3)
ffffffffc02054f4:	cb95                	beqz	a5,ffffffffc0205528 <do_exit+0xd0>
            current->cptr = proc->optr;
ffffffffc02054f6:	1007b703          	ld	a4,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff5688>
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02054fa:	6008                	ld	a0,0(s0)
            current->cptr = proc->optr;
ffffffffc02054fc:	faf8                	sd	a4,240(a3)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02054fe:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0205500:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc0205504:	10e7b023          	sd	a4,256(a5)
ffffffffc0205508:	c311                	beqz	a4,ffffffffc020550c <do_exit+0xb4>
                initproc->cptr->yptr = proc;
ffffffffc020550a:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020550c:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020550e:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0205510:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205512:	fe9710e3          	bne	a4,s1,ffffffffc02054f2 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc0205516:	0ec52783          	lw	a5,236(a0)
ffffffffc020551a:	fd379ce3          	bne	a5,s3,ffffffffc02054f2 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc020551e:	257000ef          	jal	ra,ffffffffc0205f74 <wakeup_proc>
ffffffffc0205522:	00093683          	ld	a3,0(s2)
ffffffffc0205526:	b7f1                	j	ffffffffc02054f2 <do_exit+0x9a>
    if (flag) {
ffffffffc0205528:	020a1363          	bnez	s4,ffffffffc020554e <do_exit+0xf6>
    schedule();
ffffffffc020552c:	2c5000ef          	jal	ra,ffffffffc0205ff0 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0205530:	00093783          	ld	a5,0(s2)
ffffffffc0205534:	00003617          	auipc	a2,0x3
ffffffffc0205538:	06c60613          	addi	a2,a2,108 # ffffffffc02085a0 <default_pmm_manager+0x250>
ffffffffc020553c:	29700593          	li	a1,663
ffffffffc0205540:	43d4                	lw	a3,4(a5)
ffffffffc0205542:	00003517          	auipc	a0,0x3
ffffffffc0205546:	35e50513          	addi	a0,a0,862 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc020554a:	ccdfa0ef          	jal	ra,ffffffffc0200216 <__panic>
        intr_enable();
ffffffffc020554e:	908fb0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc0205552:	bfe9                	j	ffffffffc020552c <do_exit+0xd4>
        panic("idleproc exit.\n");
ffffffffc0205554:	00003617          	auipc	a2,0x3
ffffffffc0205558:	02c60613          	addi	a2,a2,44 # ffffffffc0208580 <default_pmm_manager+0x230>
ffffffffc020555c:	25e00593          	li	a1,606
ffffffffc0205560:	00003517          	auipc	a0,0x3
ffffffffc0205564:	34050513          	addi	a0,a0,832 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205568:	caffa0ef          	jal	ra,ffffffffc0200216 <__panic>
            exit_mmap(mm);
ffffffffc020556c:	8526                	mv	a0,s1
ffffffffc020556e:	d70fd0ef          	jal	ra,ffffffffc0202ade <exit_mmap>
            put_pgdir(mm);
ffffffffc0205572:	8526                	mv	a0,s1
ffffffffc0205574:	88fff0ef          	jal	ra,ffffffffc0204e02 <put_pgdir>
            mm_destroy(mm);
ffffffffc0205578:	8526                	mv	a0,s1
ffffffffc020557a:	bc4fd0ef          	jal	ra,ffffffffc020293e <mm_destroy>
ffffffffc020557e:	bf1d                	j	ffffffffc02054b4 <do_exit+0x5c>
        panic("initproc exit.\n");
ffffffffc0205580:	00003617          	auipc	a2,0x3
ffffffffc0205584:	01060613          	addi	a2,a2,16 # ffffffffc0208590 <default_pmm_manager+0x240>
ffffffffc0205588:	26100593          	li	a1,609
ffffffffc020558c:	00003517          	auipc	a0,0x3
ffffffffc0205590:	31450513          	addi	a0,a0,788 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205594:	c83fa0ef          	jal	ra,ffffffffc0200216 <__panic>
        intr_disable();
ffffffffc0205598:	8c4fb0ef          	jal	ra,ffffffffc020065c <intr_disable>
        return 1;
ffffffffc020559c:	4a05                	li	s4,1
ffffffffc020559e:	bf15                	j	ffffffffc02054d2 <do_exit+0x7a>
            wakeup_proc(proc);
ffffffffc02055a0:	1d5000ef          	jal	ra,ffffffffc0205f74 <wakeup_proc>
ffffffffc02055a4:	b789                	j	ffffffffc02054e6 <do_exit+0x8e>

ffffffffc02055a6 <do_wait.part.1>:
do_wait(int pid, int *code_store) {
ffffffffc02055a6:	7139                	addi	sp,sp,-64
ffffffffc02055a8:	e852                	sd	s4,16(sp)
        current->wait_state = WT_CHILD;
ffffffffc02055aa:	80000a37          	lui	s4,0x80000
do_wait(int pid, int *code_store) {
ffffffffc02055ae:	f426                	sd	s1,40(sp)
ffffffffc02055b0:	f04a                	sd	s2,32(sp)
ffffffffc02055b2:	ec4e                	sd	s3,24(sp)
ffffffffc02055b4:	e456                	sd	s5,8(sp)
ffffffffc02055b6:	e05a                	sd	s6,0(sp)
ffffffffc02055b8:	fc06                	sd	ra,56(sp)
ffffffffc02055ba:	f822                	sd	s0,48(sp)
ffffffffc02055bc:	89aa                	mv	s3,a0
ffffffffc02055be:	8b2e                	mv	s6,a1
        proc = current->cptr;
ffffffffc02055c0:	000a7917          	auipc	s2,0xa7
ffffffffc02055c4:	e6890913          	addi	s2,s2,-408 # ffffffffc02ac428 <current>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02055c8:	448d                	li	s1,3
        current->state = PROC_SLEEPING;
ffffffffc02055ca:	4a85                	li	s5,1
        current->wait_state = WT_CHILD;
ffffffffc02055cc:	2a05                	addiw	s4,s4,1
    if (pid != 0) {
ffffffffc02055ce:	02098f63          	beqz	s3,ffffffffc020560c <do_wait.part.1+0x66>
        proc = find_proc(pid);
ffffffffc02055d2:	854e                	mv	a0,s3
ffffffffc02055d4:	9d1ff0ef          	jal	ra,ffffffffc0204fa4 <find_proc>
ffffffffc02055d8:	842a                	mv	s0,a0
        if (proc != NULL && proc->parent == current) {
ffffffffc02055da:	12050063          	beqz	a0,ffffffffc02056fa <do_wait.part.1+0x154>
ffffffffc02055de:	00093703          	ld	a4,0(s2)
ffffffffc02055e2:	711c                	ld	a5,32(a0)
ffffffffc02055e4:	10e79b63          	bne	a5,a4,ffffffffc02056fa <do_wait.part.1+0x154>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02055e8:	411c                	lw	a5,0(a0)
ffffffffc02055ea:	02978c63          	beq	a5,s1,ffffffffc0205622 <do_wait.part.1+0x7c>
        current->state = PROC_SLEEPING;
ffffffffc02055ee:	01572023          	sw	s5,0(a4)
        current->wait_state = WT_CHILD;
ffffffffc02055f2:	0f472623          	sw	s4,236(a4)
        schedule();
ffffffffc02055f6:	1fb000ef          	jal	ra,ffffffffc0205ff0 <schedule>
        if (current->flags & PF_EXITING) {
ffffffffc02055fa:	00093783          	ld	a5,0(s2)
ffffffffc02055fe:	0b07a783          	lw	a5,176(a5)
ffffffffc0205602:	8b85                	andi	a5,a5,1
ffffffffc0205604:	d7e9                	beqz	a5,ffffffffc02055ce <do_wait.part.1+0x28>
            do_exit(-E_KILLED);
ffffffffc0205606:	555d                	li	a0,-9
ffffffffc0205608:	e51ff0ef          	jal	ra,ffffffffc0205458 <do_exit>
        proc = current->cptr;
ffffffffc020560c:	00093703          	ld	a4,0(s2)
ffffffffc0205610:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr) {
ffffffffc0205612:	e409                	bnez	s0,ffffffffc020561c <do_wait.part.1+0x76>
ffffffffc0205614:	a0dd                	j	ffffffffc02056fa <do_wait.part.1+0x154>
ffffffffc0205616:	10043403          	ld	s0,256(s0)
ffffffffc020561a:	d871                	beqz	s0,ffffffffc02055ee <do_wait.part.1+0x48>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020561c:	401c                	lw	a5,0(s0)
ffffffffc020561e:	fe979ce3          	bne	a5,s1,ffffffffc0205616 <do_wait.part.1+0x70>
    if (proc == idleproc || proc == initproc) {
ffffffffc0205622:	000a7797          	auipc	a5,0xa7
ffffffffc0205626:	e0e78793          	addi	a5,a5,-498 # ffffffffc02ac430 <idleproc>
ffffffffc020562a:	639c                	ld	a5,0(a5)
ffffffffc020562c:	0c878d63          	beq	a5,s0,ffffffffc0205706 <do_wait.part.1+0x160>
ffffffffc0205630:	000a7797          	auipc	a5,0xa7
ffffffffc0205634:	e0878793          	addi	a5,a5,-504 # ffffffffc02ac438 <initproc>
ffffffffc0205638:	639c                	ld	a5,0(a5)
ffffffffc020563a:	0cf40663          	beq	s0,a5,ffffffffc0205706 <do_wait.part.1+0x160>
    if (code_store != NULL) {
ffffffffc020563e:	000b0663          	beqz	s6,ffffffffc020564a <do_wait.part.1+0xa4>
        *code_store = proc->exit_code;
ffffffffc0205642:	0e842783          	lw	a5,232(s0)
ffffffffc0205646:	00fb2023          	sw	a5,0(s6)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020564a:	100027f3          	csrr	a5,sstatus
ffffffffc020564e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205650:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205652:	e7d5                	bnez	a5,ffffffffc02056fe <do_wait.part.1+0x158>
    __list_del(listelm->prev, listelm->next);
ffffffffc0205654:	6c70                	ld	a2,216(s0)
ffffffffc0205656:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL) {
ffffffffc0205658:	10043703          	ld	a4,256(s0)
ffffffffc020565c:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc020565e:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0205660:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0205662:	6470                	ld	a2,200(s0)
ffffffffc0205664:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0205666:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0205668:	e290                	sd	a2,0(a3)
ffffffffc020566a:	c319                	beqz	a4,ffffffffc0205670 <do_wait.part.1+0xca>
        proc->optr->yptr = proc->yptr;
ffffffffc020566c:	ff7c                	sd	a5,248(a4)
ffffffffc020566e:	7c7c                	ld	a5,248(s0)
    if (proc->yptr != NULL) {
ffffffffc0205670:	c3d1                	beqz	a5,ffffffffc02056f4 <do_wait.part.1+0x14e>
        proc->yptr->optr = proc->optr;
ffffffffc0205672:	10e7b023          	sd	a4,256(a5)
    nr_process --;
ffffffffc0205676:	000a7797          	auipc	a5,0xa7
ffffffffc020567a:	dca78793          	addi	a5,a5,-566 # ffffffffc02ac440 <nr_process>
ffffffffc020567e:	439c                	lw	a5,0(a5)
ffffffffc0205680:	37fd                	addiw	a5,a5,-1
ffffffffc0205682:	000a7717          	auipc	a4,0xa7
ffffffffc0205686:	daf72f23          	sw	a5,-578(a4) # ffffffffc02ac440 <nr_process>
    if (flag) {
ffffffffc020568a:	e1b5                	bnez	a1,ffffffffc02056ee <do_wait.part.1+0x148>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020568c:	6814                	ld	a3,16(s0)
ffffffffc020568e:	c02007b7          	lui	a5,0xc0200
ffffffffc0205692:	0af6e263          	bltu	a3,a5,ffffffffc0205736 <do_wait.part.1+0x190>
ffffffffc0205696:	000a7797          	auipc	a5,0xa7
ffffffffc020569a:	dc278793          	addi	a5,a5,-574 # ffffffffc02ac458 <va_pa_offset>
ffffffffc020569e:	6398                	ld	a4,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc02056a0:	000a7797          	auipc	a5,0xa7
ffffffffc02056a4:	d6078793          	addi	a5,a5,-672 # ffffffffc02ac400 <npage>
ffffffffc02056a8:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc02056aa:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc02056ac:	82b1                	srli	a3,a3,0xc
ffffffffc02056ae:	06f6f863          	bleu	a5,a3,ffffffffc020571e <do_wait.part.1+0x178>
    return &pages[PPN(pa) - nbase];
ffffffffc02056b2:	00003797          	auipc	a5,0x3
ffffffffc02056b6:	6b678793          	addi	a5,a5,1718 # ffffffffc0208d68 <nbase>
ffffffffc02056ba:	639c                	ld	a5,0(a5)
ffffffffc02056bc:	000a7717          	auipc	a4,0xa7
ffffffffc02056c0:	dac70713          	addi	a4,a4,-596 # ffffffffc02ac468 <pages>
ffffffffc02056c4:	6308                	ld	a0,0(a4)
ffffffffc02056c6:	8e9d                	sub	a3,a3,a5
ffffffffc02056c8:	069a                	slli	a3,a3,0x6
ffffffffc02056ca:	9536                	add	a0,a0,a3
ffffffffc02056cc:	4589                	li	a1,2
ffffffffc02056ce:	82dfb0ef          	jal	ra,ffffffffc0200efa <free_pages>
    kfree(proc);
ffffffffc02056d2:	8522                	mv	a0,s0
ffffffffc02056d4:	eaffd0ef          	jal	ra,ffffffffc0203582 <kfree>
    return 0;
ffffffffc02056d8:	4501                	li	a0,0
}
ffffffffc02056da:	70e2                	ld	ra,56(sp)
ffffffffc02056dc:	7442                	ld	s0,48(sp)
ffffffffc02056de:	74a2                	ld	s1,40(sp)
ffffffffc02056e0:	7902                	ld	s2,32(sp)
ffffffffc02056e2:	69e2                	ld	s3,24(sp)
ffffffffc02056e4:	6a42                	ld	s4,16(sp)
ffffffffc02056e6:	6aa2                	ld	s5,8(sp)
ffffffffc02056e8:	6b02                	ld	s6,0(sp)
ffffffffc02056ea:	6121                	addi	sp,sp,64
ffffffffc02056ec:	8082                	ret
        intr_enable();
ffffffffc02056ee:	f69fa0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc02056f2:	bf69                	j	ffffffffc020568c <do_wait.part.1+0xe6>
       proc->parent->cptr = proc->optr;
ffffffffc02056f4:	701c                	ld	a5,32(s0)
ffffffffc02056f6:	fbf8                	sd	a4,240(a5)
ffffffffc02056f8:	bfbd                	j	ffffffffc0205676 <do_wait.part.1+0xd0>
    return -E_BAD_PROC;
ffffffffc02056fa:	5579                	li	a0,-2
ffffffffc02056fc:	bff9                	j	ffffffffc02056da <do_wait.part.1+0x134>
        intr_disable();
ffffffffc02056fe:	f5ffa0ef          	jal	ra,ffffffffc020065c <intr_disable>
        return 1;
ffffffffc0205702:	4585                	li	a1,1
ffffffffc0205704:	bf81                	j	ffffffffc0205654 <do_wait.part.1+0xae>
        panic("wait idleproc or initproc.\n");
ffffffffc0205706:	00003617          	auipc	a2,0x3
ffffffffc020570a:	f6a60613          	addi	a2,a2,-150 # ffffffffc0208670 <default_pmm_manager+0x320>
ffffffffc020570e:	42500593          	li	a1,1061
ffffffffc0205712:	00003517          	auipc	a0,0x3
ffffffffc0205716:	18e50513          	addi	a0,a0,398 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc020571a:	afdfa0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020571e:	00002617          	auipc	a2,0x2
ffffffffc0205722:	93260613          	addi	a2,a2,-1742 # ffffffffc0207050 <commands+0x8a0>
ffffffffc0205726:	06200593          	li	a1,98
ffffffffc020572a:	00002517          	auipc	a0,0x2
ffffffffc020572e:	94650513          	addi	a0,a0,-1722 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0205732:	ae5fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0205736:	00002617          	auipc	a2,0x2
ffffffffc020573a:	9ba60613          	addi	a2,a2,-1606 # ffffffffc02070f0 <commands+0x940>
ffffffffc020573e:	06e00593          	li	a1,110
ffffffffc0205742:	00002517          	auipc	a0,0x2
ffffffffc0205746:	92e50513          	addi	a0,a0,-1746 # ffffffffc0207070 <commands+0x8c0>
ffffffffc020574a:	acdfa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020574e <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
ffffffffc020574e:	1141                	addi	sp,sp,-16
ffffffffc0205750:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0205752:	feefb0ef          	jal	ra,ffffffffc0200f40 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0205756:	d6dfd0ef          	jal	ra,ffffffffc02034c2 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc020575a:	4601                	li	a2,0
ffffffffc020575c:	4581                	li	a1,0
ffffffffc020575e:	fffff517          	auipc	a0,0xfffff
ffffffffc0205762:	62250513          	addi	a0,a0,1570 # ffffffffc0204d80 <user_main>
ffffffffc0205766:	ca3ff0ef          	jal	ra,ffffffffc0205408 <kernel_thread>
    if (pid <= 0) {
ffffffffc020576a:	00a04563          	bgtz	a0,ffffffffc0205774 <init_main+0x26>
ffffffffc020576e:	a841                	j	ffffffffc02057fe <init_main+0xb0>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0) {
        schedule();
ffffffffc0205770:	081000ef          	jal	ra,ffffffffc0205ff0 <schedule>
    if (code_store != NULL) {
ffffffffc0205774:	4581                	li	a1,0
ffffffffc0205776:	4501                	li	a0,0
ffffffffc0205778:	e2fff0ef          	jal	ra,ffffffffc02055a6 <do_wait.part.1>
    while (do_wait(0, NULL) == 0) {
ffffffffc020577c:	d975                	beqz	a0,ffffffffc0205770 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc020577e:	00003517          	auipc	a0,0x3
ffffffffc0205782:	f3250513          	addi	a0,a0,-206 # ffffffffc02086b0 <default_pmm_manager+0x360>
ffffffffc0205786:	94bfa0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020578a:	000a7797          	auipc	a5,0xa7
ffffffffc020578e:	cae78793          	addi	a5,a5,-850 # ffffffffc02ac438 <initproc>
ffffffffc0205792:	639c                	ld	a5,0(a5)
ffffffffc0205794:	7bf8                	ld	a4,240(a5)
ffffffffc0205796:	e721                	bnez	a4,ffffffffc02057de <init_main+0x90>
ffffffffc0205798:	7ff8                	ld	a4,248(a5)
ffffffffc020579a:	e331                	bnez	a4,ffffffffc02057de <init_main+0x90>
ffffffffc020579c:	1007b703          	ld	a4,256(a5)
ffffffffc02057a0:	ef1d                	bnez	a4,ffffffffc02057de <init_main+0x90>
    assert(nr_process == 2);
ffffffffc02057a2:	000a7717          	auipc	a4,0xa7
ffffffffc02057a6:	c9e70713          	addi	a4,a4,-866 # ffffffffc02ac440 <nr_process>
ffffffffc02057aa:	4314                	lw	a3,0(a4)
ffffffffc02057ac:	4709                	li	a4,2
ffffffffc02057ae:	0ae69463          	bne	a3,a4,ffffffffc0205856 <init_main+0x108>
    return listelm->next;
ffffffffc02057b2:	000a7697          	auipc	a3,0xa7
ffffffffc02057b6:	db668693          	addi	a3,a3,-586 # ffffffffc02ac568 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02057ba:	6698                	ld	a4,8(a3)
ffffffffc02057bc:	0c878793          	addi	a5,a5,200
ffffffffc02057c0:	06f71b63          	bne	a4,a5,ffffffffc0205836 <init_main+0xe8>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02057c4:	629c                	ld	a5,0(a3)
ffffffffc02057c6:	04f71863          	bne	a4,a5,ffffffffc0205816 <init_main+0xc8>

    cprintf("init check memory pass.\n");
ffffffffc02057ca:	00003517          	auipc	a0,0x3
ffffffffc02057ce:	fce50513          	addi	a0,a0,-50 # ffffffffc0208798 <default_pmm_manager+0x448>
ffffffffc02057d2:	8fffa0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    return 0;
}
ffffffffc02057d6:	60a2                	ld	ra,8(sp)
ffffffffc02057d8:	4501                	li	a0,0
ffffffffc02057da:	0141                	addi	sp,sp,16
ffffffffc02057dc:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02057de:	00003697          	auipc	a3,0x3
ffffffffc02057e2:	efa68693          	addi	a3,a3,-262 # ffffffffc02086d8 <default_pmm_manager+0x388>
ffffffffc02057e6:	00001617          	auipc	a2,0x1
ffffffffc02057ea:	44a60613          	addi	a2,a2,1098 # ffffffffc0206c30 <commands+0x480>
ffffffffc02057ee:	48f00593          	li	a1,1167
ffffffffc02057f2:	00003517          	auipc	a0,0x3
ffffffffc02057f6:	0ae50513          	addi	a0,a0,174 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc02057fa:	a1dfa0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("create user_main failed.\n");
ffffffffc02057fe:	00003617          	auipc	a2,0x3
ffffffffc0205802:	e9260613          	addi	a2,a2,-366 # ffffffffc0208690 <default_pmm_manager+0x340>
ffffffffc0205806:	48700593          	li	a1,1159
ffffffffc020580a:	00003517          	auipc	a0,0x3
ffffffffc020580e:	09650513          	addi	a0,a0,150 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205812:	a05fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205816:	00003697          	auipc	a3,0x3
ffffffffc020581a:	f5268693          	addi	a3,a3,-174 # ffffffffc0208768 <default_pmm_manager+0x418>
ffffffffc020581e:	00001617          	auipc	a2,0x1
ffffffffc0205822:	41260613          	addi	a2,a2,1042 # ffffffffc0206c30 <commands+0x480>
ffffffffc0205826:	49200593          	li	a1,1170
ffffffffc020582a:	00003517          	auipc	a0,0x3
ffffffffc020582e:	07650513          	addi	a0,a0,118 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205832:	9e5fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0205836:	00003697          	auipc	a3,0x3
ffffffffc020583a:	f0268693          	addi	a3,a3,-254 # ffffffffc0208738 <default_pmm_manager+0x3e8>
ffffffffc020583e:	00001617          	auipc	a2,0x1
ffffffffc0205842:	3f260613          	addi	a2,a2,1010 # ffffffffc0206c30 <commands+0x480>
ffffffffc0205846:	49100593          	li	a1,1169
ffffffffc020584a:	00003517          	auipc	a0,0x3
ffffffffc020584e:	05650513          	addi	a0,a0,86 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205852:	9c5fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_process == 2);
ffffffffc0205856:	00003697          	auipc	a3,0x3
ffffffffc020585a:	ed268693          	addi	a3,a3,-302 # ffffffffc0208728 <default_pmm_manager+0x3d8>
ffffffffc020585e:	00001617          	auipc	a2,0x1
ffffffffc0205862:	3d260613          	addi	a2,a2,978 # ffffffffc0206c30 <commands+0x480>
ffffffffc0205866:	49000593          	li	a1,1168
ffffffffc020586a:	00003517          	auipc	a0,0x3
ffffffffc020586e:	03650513          	addi	a0,a0,54 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205872:	9a5fa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0205876 <do_execve>:
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205876:	7135                	addi	sp,sp,-160
ffffffffc0205878:	f8d2                	sd	s4,112(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020587a:	000a7a17          	auipc	s4,0xa7
ffffffffc020587e:	baea0a13          	addi	s4,s4,-1106 # ffffffffc02ac428 <current>
ffffffffc0205882:	000a3783          	ld	a5,0(s4)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205886:	e14a                	sd	s2,128(sp)
ffffffffc0205888:	e922                	sd	s0,144(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020588a:	0287b903          	ld	s2,40(a5)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc020588e:	fcce                	sd	s3,120(sp)
ffffffffc0205890:	f0da                	sd	s6,96(sp)
ffffffffc0205892:	89aa                	mv	s3,a0
ffffffffc0205894:	842e                	mv	s0,a1
ffffffffc0205896:	8b32                	mv	s6,a2
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc0205898:	4681                	li	a3,0
ffffffffc020589a:	862e                	mv	a2,a1
ffffffffc020589c:	85aa                	mv	a1,a0
ffffffffc020589e:	854a                	mv	a0,s2
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02058a0:	ed06                	sd	ra,152(sp)
ffffffffc02058a2:	e526                	sd	s1,136(sp)
ffffffffc02058a4:	f4d6                	sd	s5,104(sp)
ffffffffc02058a6:	ecde                	sd	s7,88(sp)
ffffffffc02058a8:	e8e2                	sd	s8,80(sp)
ffffffffc02058aa:	e4e6                	sd	s9,72(sp)
ffffffffc02058ac:	e0ea                	sd	s10,64(sp)
ffffffffc02058ae:	fc6e                	sd	s11,56(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc02058b0:	8d1fd0ef          	jal	ra,ffffffffc0203180 <user_mem_check>
ffffffffc02058b4:	40050463          	beqz	a0,ffffffffc0205cbc <do_execve+0x446>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02058b8:	4641                	li	a2,16
ffffffffc02058ba:	4581                	li	a1,0
ffffffffc02058bc:	1008                	addi	a0,sp,32
ffffffffc02058be:	147000ef          	jal	ra,ffffffffc0206204 <memset>
    memcpy(local_name, name, len);
ffffffffc02058c2:	47bd                	li	a5,15
ffffffffc02058c4:	8622                	mv	a2,s0
ffffffffc02058c6:	0687ee63          	bltu	a5,s0,ffffffffc0205942 <do_execve+0xcc>
ffffffffc02058ca:	85ce                	mv	a1,s3
ffffffffc02058cc:	1008                	addi	a0,sp,32
ffffffffc02058ce:	149000ef          	jal	ra,ffffffffc0206216 <memcpy>
    if (mm != NULL) {          // 此时的当前进程initproc为内核线程，故mm为NULL
ffffffffc02058d2:	06090f63          	beqz	s2,ffffffffc0205950 <do_execve+0xda>
        cputs("mm != NULL");
ffffffffc02058d6:	00002517          	auipc	a0,0x2
ffffffffc02058da:	0ea50513          	addi	a0,a0,234 # ffffffffc02079c0 <commands+0x1210>
ffffffffc02058de:	82bfa0ef          	jal	ra,ffffffffc0200108 <cputs>
        lcr3(boot_cr3);
ffffffffc02058e2:	000a7797          	auipc	a5,0xa7
ffffffffc02058e6:	b7e78793          	addi	a5,a5,-1154 # ffffffffc02ac460 <boot_cr3>
ffffffffc02058ea:	639c                	ld	a5,0(a5)
ffffffffc02058ec:	577d                	li	a4,-1
ffffffffc02058ee:	177e                	slli	a4,a4,0x3f
ffffffffc02058f0:	83b1                	srli	a5,a5,0xc
ffffffffc02058f2:	8fd9                	or	a5,a5,a4
ffffffffc02058f4:	18079073          	csrw	satp,a5
ffffffffc02058f8:	03092783          	lw	a5,48(s2)
ffffffffc02058fc:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205900:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0) {   // 条件成立则说明该mm仅被当前进程引用，故表明此后无进程需要此进程所占用的内存空间
ffffffffc0205904:	28070b63          	beqz	a4,ffffffffc0205b9a <do_execve+0x324>
        current->mm = NULL;
ffffffffc0205908:	000a3783          	ld	a5,0(s4)
ffffffffc020590c:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL) {
ffffffffc0205910:	ea9fc0ef          	jal	ra,ffffffffc02027b8 <mm_create>
ffffffffc0205914:	892a                	mv	s2,a0
ffffffffc0205916:	c135                	beqz	a0,ffffffffc020597a <do_execve+0x104>
    if (setup_pgdir(mm) != 0) {
ffffffffc0205918:	d68ff0ef          	jal	ra,ffffffffc0204e80 <setup_pgdir>
ffffffffc020591c:	e931                	bnez	a0,ffffffffc0205970 <do_execve+0xfa>
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc020591e:	000b2703          	lw	a4,0(s6)
ffffffffc0205922:	464c47b7          	lui	a5,0x464c4
ffffffffc0205926:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9b07>
ffffffffc020592a:	04f70a63          	beq	a4,a5,ffffffffc020597e <do_execve+0x108>
    put_pgdir(mm);
ffffffffc020592e:	854a                	mv	a0,s2
ffffffffc0205930:	cd2ff0ef          	jal	ra,ffffffffc0204e02 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205934:	854a                	mv	a0,s2
ffffffffc0205936:	808fd0ef          	jal	ra,ffffffffc020293e <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc020593a:	59e1                	li	s3,-8
    do_exit(ret); // 执行出错，退出当前进程，并传递错误码ret
ffffffffc020593c:	854e                	mv	a0,s3
ffffffffc020593e:	b1bff0ef          	jal	ra,ffffffffc0205458 <do_exit>
    memcpy(local_name, name, len);
ffffffffc0205942:	463d                	li	a2,15
ffffffffc0205944:	85ce                	mv	a1,s3
ffffffffc0205946:	1008                	addi	a0,sp,32
ffffffffc0205948:	0cf000ef          	jal	ra,ffffffffc0206216 <memcpy>
    if (mm != NULL) {          // 此时的当前进程initproc为内核线程，故mm为NULL
ffffffffc020594c:	f80915e3          	bnez	s2,ffffffffc02058d6 <do_execve+0x60>
    if (current->mm != NULL) {
ffffffffc0205950:	000a3783          	ld	a5,0(s4)
ffffffffc0205954:	779c                	ld	a5,40(a5)
ffffffffc0205956:	dfcd                	beqz	a5,ffffffffc0205910 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0205958:	00003617          	auipc	a2,0x3
ffffffffc020595c:	aa060613          	addi	a2,a2,-1376 # ffffffffc02083f8 <default_pmm_manager+0xa8>
ffffffffc0205960:	2c000593          	li	a1,704
ffffffffc0205964:	00003517          	auipc	a0,0x3
ffffffffc0205968:	f3c50513          	addi	a0,a0,-196 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc020596c:	8abfa0ef          	jal	ra,ffffffffc0200216 <__panic>
    mm_destroy(mm);
ffffffffc0205970:	854a                	mv	a0,s2
ffffffffc0205972:	fcdfc0ef          	jal	ra,ffffffffc020293e <mm_destroy>
    int ret = -E_NO_MEM;
ffffffffc0205976:	59f1                	li	s3,-4
ffffffffc0205978:	b7d1                	j	ffffffffc020593c <do_execve+0xc6>
ffffffffc020597a:	59f1                	li	s3,-4
ffffffffc020597c:	b7c1                	j	ffffffffc020593c <do_execve+0xc6>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020597e:	038b5703          	lhu	a4,56(s6)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0205982:	020b3403          	ld	s0,32(s6)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205986:	00371793          	slli	a5,a4,0x3
ffffffffc020598a:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020598c:	945a                	add	s0,s0,s6
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020598e:	078e                	slli	a5,a5,0x3
ffffffffc0205990:	97a2                	add	a5,a5,s0
ffffffffc0205992:	ec3e                	sd	a5,24(sp)
    for (; ph < ph_end; ph ++) {          
ffffffffc0205994:	02f47b63          	bleu	a5,s0,ffffffffc02059ca <do_execve+0x154>
    return KADDR(page2pa(page));
ffffffffc0205998:	5bfd                	li	s7,-1
ffffffffc020599a:	00cbd793          	srli	a5,s7,0xc
    return page - pages + nbase;
ffffffffc020599e:	000a7d97          	auipc	s11,0xa7
ffffffffc02059a2:	acad8d93          	addi	s11,s11,-1334 # ffffffffc02ac468 <pages>
ffffffffc02059a6:	00003d17          	auipc	s10,0x3
ffffffffc02059aa:	3c2d0d13          	addi	s10,s10,962 # ffffffffc0208d68 <nbase>
    return KADDR(page2pa(page));
ffffffffc02059ae:	e43e                	sd	a5,8(sp)
ffffffffc02059b0:	000a7c97          	auipc	s9,0xa7
ffffffffc02059b4:	a50c8c93          	addi	s9,s9,-1456 # ffffffffc02ac400 <npage>
        if (ph->p_type != ELF_PT_LOAD) {     // 程序段需要满足一定类型
ffffffffc02059b8:	4018                	lw	a4,0(s0)
ffffffffc02059ba:	4785                	li	a5,1
ffffffffc02059bc:	0ef70d63          	beq	a4,a5,ffffffffc0205ab6 <do_execve+0x240>
    for (; ph < ph_end; ph ++) {          
ffffffffc02059c0:	67e2                	ld	a5,24(sp)
ffffffffc02059c2:	03840413          	addi	s0,s0,56
ffffffffc02059c6:	fef469e3          	bltu	s0,a5,ffffffffc02059b8 <do_execve+0x142>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
ffffffffc02059ca:	4701                	li	a4,0
ffffffffc02059cc:	46ad                	li	a3,11
ffffffffc02059ce:	00100637          	lui	a2,0x100
ffffffffc02059d2:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02059d6:	854a                	mv	a0,s2
ffffffffc02059d8:	fb9fc0ef          	jal	ra,ffffffffc0202990 <mm_map>
ffffffffc02059dc:	89aa                	mv	s3,a0
ffffffffc02059de:	1a051463          	bnez	a0,ffffffffc0205b86 <do_execve+0x310>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc02059e2:	01893503          	ld	a0,24(s2)
ffffffffc02059e6:	467d                	li	a2,31
ffffffffc02059e8:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02059ec:	92dfc0ef          	jal	ra,ffffffffc0202318 <pgdir_alloc_page>
ffffffffc02059f0:	36050263          	beqz	a0,ffffffffc0205d54 <do_execve+0x4de>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc02059f4:	01893503          	ld	a0,24(s2)
ffffffffc02059f8:	467d                	li	a2,31
ffffffffc02059fa:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc02059fe:	91bfc0ef          	jal	ra,ffffffffc0202318 <pgdir_alloc_page>
ffffffffc0205a02:	32050963          	beqz	a0,ffffffffc0205d34 <do_execve+0x4be>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205a06:	01893503          	ld	a0,24(s2)
ffffffffc0205a0a:	467d                	li	a2,31
ffffffffc0205a0c:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0205a10:	909fc0ef          	jal	ra,ffffffffc0202318 <pgdir_alloc_page>
ffffffffc0205a14:	30050063          	beqz	a0,ffffffffc0205d14 <do_execve+0x49e>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205a18:	01893503          	ld	a0,24(s2)
ffffffffc0205a1c:	467d                	li	a2,31
ffffffffc0205a1e:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0205a22:	8f7fc0ef          	jal	ra,ffffffffc0202318 <pgdir_alloc_page>
ffffffffc0205a26:	2c050763          	beqz	a0,ffffffffc0205cf4 <do_execve+0x47e>
    mm->mm_count += 1;
ffffffffc0205a2a:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0205a2e:	000a3603          	ld	a2,0(s4)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205a32:	01893683          	ld	a3,24(s2)
ffffffffc0205a36:	2785                	addiw	a5,a5,1
ffffffffc0205a38:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0205a3c:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf55b0>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205a40:	c02007b7          	lui	a5,0xc0200
ffffffffc0205a44:	28f6ec63          	bltu	a3,a5,ffffffffc0205cdc <do_execve+0x466>
ffffffffc0205a48:	000a7797          	auipc	a5,0xa7
ffffffffc0205a4c:	a1078793          	addi	a5,a5,-1520 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0205a50:	639c                	ld	a5,0(a5)
ffffffffc0205a52:	577d                	li	a4,-1
ffffffffc0205a54:	177e                	slli	a4,a4,0x3f
ffffffffc0205a56:	8e9d                	sub	a3,a3,a5
ffffffffc0205a58:	00c6d793          	srli	a5,a3,0xc
ffffffffc0205a5c:	f654                	sd	a3,168(a2)
ffffffffc0205a5e:	8fd9                	or	a5,a5,a4
ffffffffc0205a60:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0205a64:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205a66:	4581                	li	a1,0
ffffffffc0205a68:	12000613          	li	a2,288
ffffffffc0205a6c:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0205a6e:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205a72:	792000ef          	jal	ra,ffffffffc0206204 <memset>
    tf->epc = elf->e_entry;
ffffffffc0205a76:	018b3703          	ld	a4,24(s6)
    tf->gpr.sp = USTACKTOP;
ffffffffc0205a7a:	4785                	li	a5,1
    set_proc_name(current, local_name);
ffffffffc0205a7c:	000a3503          	ld	a0,0(s4)
 tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc0205a80:	edf4f493          	andi	s1,s1,-289
    tf->gpr.sp = USTACKTOP;
ffffffffc0205a84:	07fe                	slli	a5,a5,0x1f
ffffffffc0205a86:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0205a88:	10e43423          	sd	a4,264(s0)
 tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc0205a8c:	10943023          	sd	s1,256(s0)
    set_proc_name(current, local_name);
ffffffffc0205a90:	100c                	addi	a1,sp,32
ffffffffc0205a92:	c7aff0ef          	jal	ra,ffffffffc0204f0c <set_proc_name>
}
ffffffffc0205a96:	60ea                	ld	ra,152(sp)
ffffffffc0205a98:	644a                	ld	s0,144(sp)
ffffffffc0205a9a:	854e                	mv	a0,s3
ffffffffc0205a9c:	64aa                	ld	s1,136(sp)
ffffffffc0205a9e:	690a                	ld	s2,128(sp)
ffffffffc0205aa0:	79e6                	ld	s3,120(sp)
ffffffffc0205aa2:	7a46                	ld	s4,112(sp)
ffffffffc0205aa4:	7aa6                	ld	s5,104(sp)
ffffffffc0205aa6:	7b06                	ld	s6,96(sp)
ffffffffc0205aa8:	6be6                	ld	s7,88(sp)
ffffffffc0205aaa:	6c46                	ld	s8,80(sp)
ffffffffc0205aac:	6ca6                	ld	s9,72(sp)
ffffffffc0205aae:	6d06                	ld	s10,64(sp)
ffffffffc0205ab0:	7de2                	ld	s11,56(sp)
ffffffffc0205ab2:	610d                	addi	sp,sp,160
ffffffffc0205ab4:	8082                	ret
        if (ph->p_filesz > ph->p_memsz) {    // 似乎是文件大小和一个设定值的比较
ffffffffc0205ab6:	7410                	ld	a2,40(s0)
ffffffffc0205ab8:	701c                	ld	a5,32(s0)
ffffffffc0205aba:	20f66363          	bltu	a2,a5,ffffffffc0205cc0 <do_execve+0x44a>
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205abe:	405c                	lw	a5,4(s0)
ffffffffc0205ac0:	0017f693          	andi	a3,a5,1
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205ac4:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205ac8:	068a                	slli	a3,a3,0x2
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205aca:	0e071263          	bnez	a4,ffffffffc0205bae <do_execve+0x338>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205ace:	4745                	li	a4,17
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205ad0:	8b91                	andi	a5,a5,4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205ad2:	e03a                	sd	a4,0(sp)
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205ad4:	c789                	beqz	a5,ffffffffc0205ade <do_execve+0x268>
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205ad6:	47cd                	li	a5,19
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205ad8:	0016e693          	ori	a3,a3,1
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205adc:	e03e                	sd	a5,0(sp)
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205ade:	0026f793          	andi	a5,a3,2
ffffffffc0205ae2:	efe1                	bnez	a5,ffffffffc0205bba <do_execve+0x344>
        if (vm_flags & VM_EXEC) perm |= PTE_X;
ffffffffc0205ae4:	0046f793          	andi	a5,a3,4
ffffffffc0205ae8:	c789                	beqz	a5,ffffffffc0205af2 <do_execve+0x27c>
ffffffffc0205aea:	6782                	ld	a5,0(sp)
ffffffffc0205aec:	0087e793          	ori	a5,a5,8
ffffffffc0205af0:	e03e                	sd	a5,0(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {   // 似乎是根据上述vm_flags将该程序段映射到当前进程的虚拟地址空间中？？？好像又不是
ffffffffc0205af2:	680c                	ld	a1,16(s0)
ffffffffc0205af4:	4701                	li	a4,0
ffffffffc0205af6:	854a                	mv	a0,s2
ffffffffc0205af8:	e99fc0ef          	jal	ra,ffffffffc0202990 <mm_map>
ffffffffc0205afc:	89aa                	mv	s3,a0
ffffffffc0205afe:	e541                	bnez	a0,ffffffffc0205b86 <do_execve+0x310>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205b00:	01043b83          	ld	s7,16(s0)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205b04:	02043983          	ld	s3,32(s0)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205b08:	00843a83          	ld	s5,8(s0)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205b0c:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205b0e:	99de                	add	s3,s3,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205b10:	9ada                	add	s5,s5,s6
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205b12:	00fbfc33          	and	s8,s7,a5
        while (start < end) {
ffffffffc0205b16:	053bef63          	bltu	s7,s3,ffffffffc0205b74 <do_execve+0x2fe>
ffffffffc0205b1a:	aa79                	j	ffffffffc0205cb8 <do_execve+0x442>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205b1c:	6785                	lui	a5,0x1
ffffffffc0205b1e:	418b8533          	sub	a0,s7,s8
ffffffffc0205b22:	9c3e                	add	s8,s8,a5
ffffffffc0205b24:	417c0833          	sub	a6,s8,s7
            if (end < la) {   // 当前页超出程序段边界
ffffffffc0205b28:	0189f463          	bleu	s8,s3,ffffffffc0205b30 <do_execve+0x2ba>
                size -= la - end;
ffffffffc0205b2c:	41798833          	sub	a6,s3,s7
    return page - pages + nbase;
ffffffffc0205b30:	000db683          	ld	a3,0(s11)
ffffffffc0205b34:	000d3583          	ld	a1,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205b38:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205b3a:	40d486b3          	sub	a3,s1,a3
ffffffffc0205b3e:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205b40:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205b44:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0205b46:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205b4a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205b4c:	16c5fc63          	bleu	a2,a1,ffffffffc0205cc4 <do_execve+0x44e>
ffffffffc0205b50:	000a7797          	auipc	a5,0xa7
ffffffffc0205b54:	90878793          	addi	a5,a5,-1784 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0205b58:	0007b883          	ld	a7,0(a5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205b5c:	85d6                	mv	a1,s5
ffffffffc0205b5e:	8642                	mv	a2,a6
ffffffffc0205b60:	96c6                	add	a3,a3,a7
ffffffffc0205b62:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0205b64:	9bc2                	add	s7,s7,a6
ffffffffc0205b66:	e842                	sd	a6,16(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205b68:	6ae000ef          	jal	ra,ffffffffc0206216 <memcpy>
            start += size, from += size;
ffffffffc0205b6c:	6842                	ld	a6,16(sp)
ffffffffc0205b6e:	9ac2                	add	s5,s5,a6
        while (start < end) {
ffffffffc0205b70:	053bf863          	bleu	s3,s7,ffffffffc0205bc0 <do_execve+0x34a>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {   // 根据进程页目录表给该程序段分配一个页
ffffffffc0205b74:	01893503          	ld	a0,24(s2)
ffffffffc0205b78:	6602                	ld	a2,0(sp)
ffffffffc0205b7a:	85e2                	mv	a1,s8
ffffffffc0205b7c:	f9cfc0ef          	jal	ra,ffffffffc0202318 <pgdir_alloc_page>
ffffffffc0205b80:	84aa                	mv	s1,a0
ffffffffc0205b82:	fd49                	bnez	a0,ffffffffc0205b1c <do_execve+0x2a6>
        ret = -E_NO_MEM;
ffffffffc0205b84:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc0205b86:	854a                	mv	a0,s2
ffffffffc0205b88:	f57fc0ef          	jal	ra,ffffffffc0202ade <exit_mmap>
    put_pgdir(mm);
ffffffffc0205b8c:	854a                	mv	a0,s2
ffffffffc0205b8e:	a74ff0ef          	jal	ra,ffffffffc0204e02 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205b92:	854a                	mv	a0,s2
ffffffffc0205b94:	dabfc0ef          	jal	ra,ffffffffc020293e <mm_destroy>
    return ret;
ffffffffc0205b98:	b355                	j	ffffffffc020593c <do_execve+0xc6>
            exit_mmap(mm);     // 清空内存管理部分和对应页表
ffffffffc0205b9a:	854a                	mv	a0,s2
ffffffffc0205b9c:	f43fc0ef          	jal	ra,ffffffffc0202ade <exit_mmap>
            put_pgdir(mm);     // 清空页表
ffffffffc0205ba0:	854a                	mv	a0,s2
ffffffffc0205ba2:	a60ff0ef          	jal	ra,ffffffffc0204e02 <put_pgdir>
            mm_destroy(mm);    // 清空页表
ffffffffc0205ba6:	854a                	mv	a0,s2
ffffffffc0205ba8:	d97fc0ef          	jal	ra,ffffffffc020293e <mm_destroy>
ffffffffc0205bac:	bbb1                	j	ffffffffc0205908 <do_execve+0x92>
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205bae:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205bb2:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205bb4:	2681                	sext.w	a3,a3
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205bb6:	f20790e3          	bnez	a5,ffffffffc0205ad6 <do_execve+0x260>
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205bba:	47dd                	li	a5,23
ffffffffc0205bbc:	e03e                	sd	a5,0(sp)
ffffffffc0205bbe:	b71d                	j	ffffffffc0205ae4 <do_execve+0x26e>
ffffffffc0205bc0:	01043983          	ld	s3,16(s0)
        end = ph->p_va + ph->p_memsz;
ffffffffc0205bc4:	7414                	ld	a3,40(s0)
ffffffffc0205bc6:	99b6                	add	s3,s3,a3
        if (start < la) {
ffffffffc0205bc8:	098bf163          	bleu	s8,s7,ffffffffc0205c4a <do_execve+0x3d4>
            if (start == end) {
ffffffffc0205bcc:	df798ae3          	beq	s3,s7,ffffffffc02059c0 <do_execve+0x14a>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205bd0:	6505                	lui	a0,0x1
ffffffffc0205bd2:	955e                	add	a0,a0,s7
ffffffffc0205bd4:	41850533          	sub	a0,a0,s8
                size -= la - end;
ffffffffc0205bd8:	41798ab3          	sub	s5,s3,s7
            if (end < la) {
ffffffffc0205bdc:	0d89fb63          	bleu	s8,s3,ffffffffc0205cb2 <do_execve+0x43c>
    return page - pages + nbase;
ffffffffc0205be0:	000db683          	ld	a3,0(s11)
ffffffffc0205be4:	000d3583          	ld	a1,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205be8:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205bea:	40d486b3          	sub	a3,s1,a3
ffffffffc0205bee:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205bf0:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205bf4:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0205bf6:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205bfa:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205bfc:	0cc5f463          	bleu	a2,a1,ffffffffc0205cc4 <do_execve+0x44e>
ffffffffc0205c00:	000a7617          	auipc	a2,0xa7
ffffffffc0205c04:	85860613          	addi	a2,a2,-1960 # ffffffffc02ac458 <va_pa_offset>
ffffffffc0205c08:	00063803          	ld	a6,0(a2)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205c0c:	4581                	li	a1,0
ffffffffc0205c0e:	8656                	mv	a2,s5
ffffffffc0205c10:	96c2                	add	a3,a3,a6
ffffffffc0205c12:	9536                	add	a0,a0,a3
ffffffffc0205c14:	5f0000ef          	jal	ra,ffffffffc0206204 <memset>
            start += size;
ffffffffc0205c18:	017a8733          	add	a4,s5,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205c1c:	0389f463          	bleu	s8,s3,ffffffffc0205c44 <do_execve+0x3ce>
ffffffffc0205c20:	dae980e3          	beq	s3,a4,ffffffffc02059c0 <do_execve+0x14a>
ffffffffc0205c24:	00002697          	auipc	a3,0x2
ffffffffc0205c28:	7fc68693          	addi	a3,a3,2044 # ffffffffc0208420 <default_pmm_manager+0xd0>
ffffffffc0205c2c:	00001617          	auipc	a2,0x1
ffffffffc0205c30:	00460613          	addi	a2,a2,4 # ffffffffc0206c30 <commands+0x480>
ffffffffc0205c34:	32300593          	li	a1,803
ffffffffc0205c38:	00003517          	auipc	a0,0x3
ffffffffc0205c3c:	c6850513          	addi	a0,a0,-920 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205c40:	dd6fa0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0205c44:	ff8710e3          	bne	a4,s8,ffffffffc0205c24 <do_execve+0x3ae>
ffffffffc0205c48:	8be2                	mv	s7,s8
ffffffffc0205c4a:	000a7a97          	auipc	s5,0xa7
ffffffffc0205c4e:	80ea8a93          	addi	s5,s5,-2034 # ffffffffc02ac458 <va_pa_offset>
        while (start < end) {
ffffffffc0205c52:	053be763          	bltu	s7,s3,ffffffffc0205ca0 <do_execve+0x42a>
ffffffffc0205c56:	b3ad                	j	ffffffffc02059c0 <do_execve+0x14a>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205c58:	6785                	lui	a5,0x1
ffffffffc0205c5a:	418b8533          	sub	a0,s7,s8
ffffffffc0205c5e:	9c3e                	add	s8,s8,a5
ffffffffc0205c60:	417c0633          	sub	a2,s8,s7
            if (end < la) {
ffffffffc0205c64:	0189f463          	bleu	s8,s3,ffffffffc0205c6c <do_execve+0x3f6>
                size -= la - end;
ffffffffc0205c68:	41798633          	sub	a2,s3,s7
    return page - pages + nbase;
ffffffffc0205c6c:	000db683          	ld	a3,0(s11)
ffffffffc0205c70:	000d3803          	ld	a6,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205c74:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205c76:	40d486b3          	sub	a3,s1,a3
ffffffffc0205c7a:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205c7c:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0205c80:	96c2                	add	a3,a3,a6
    return KADDR(page2pa(page));
ffffffffc0205c82:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205c86:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205c88:	02b87e63          	bleu	a1,a6,ffffffffc0205cc4 <do_execve+0x44e>
ffffffffc0205c8c:	000ab803          	ld	a6,0(s5)
            start += size;
ffffffffc0205c90:	9bb2                	add	s7,s7,a2
            memset(page2kva(page) + off, 0, size);
ffffffffc0205c92:	4581                	li	a1,0
ffffffffc0205c94:	96c2                	add	a3,a3,a6
ffffffffc0205c96:	9536                	add	a0,a0,a3
ffffffffc0205c98:	56c000ef          	jal	ra,ffffffffc0206204 <memset>
        while (start < end) {
ffffffffc0205c9c:	d33bf2e3          	bleu	s3,s7,ffffffffc02059c0 <do_execve+0x14a>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205ca0:	01893503          	ld	a0,24(s2)
ffffffffc0205ca4:	6602                	ld	a2,0(sp)
ffffffffc0205ca6:	85e2                	mv	a1,s8
ffffffffc0205ca8:	e70fc0ef          	jal	ra,ffffffffc0202318 <pgdir_alloc_page>
ffffffffc0205cac:	84aa                	mv	s1,a0
ffffffffc0205cae:	f54d                	bnez	a0,ffffffffc0205c58 <do_execve+0x3e2>
ffffffffc0205cb0:	bdd1                	j	ffffffffc0205b84 <do_execve+0x30e>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205cb2:	417c0ab3          	sub	s5,s8,s7
ffffffffc0205cb6:	b72d                	j	ffffffffc0205be0 <do_execve+0x36a>
        while (start < end) {
ffffffffc0205cb8:	89de                	mv	s3,s7
ffffffffc0205cba:	b729                	j	ffffffffc0205bc4 <do_execve+0x34e>
        return -E_INVAL;
ffffffffc0205cbc:	59f5                	li	s3,-3
ffffffffc0205cbe:	bbe1                	j	ffffffffc0205a96 <do_execve+0x220>
            ret = -E_INVAL_ELF;
ffffffffc0205cc0:	59e1                	li	s3,-8
ffffffffc0205cc2:	b5d1                	j	ffffffffc0205b86 <do_execve+0x310>
ffffffffc0205cc4:	00001617          	auipc	a2,0x1
ffffffffc0205cc8:	35460613          	addi	a2,a2,852 # ffffffffc0207018 <commands+0x868>
ffffffffc0205ccc:	06900593          	li	a1,105
ffffffffc0205cd0:	00001517          	auipc	a0,0x1
ffffffffc0205cd4:	3a050513          	addi	a0,a0,928 # ffffffffc0207070 <commands+0x8c0>
ffffffffc0205cd8:	d3efa0ef          	jal	ra,ffffffffc0200216 <__panic>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205cdc:	00001617          	auipc	a2,0x1
ffffffffc0205ce0:	41460613          	addi	a2,a2,1044 # ffffffffc02070f0 <commands+0x940>
ffffffffc0205ce4:	34000593          	li	a1,832
ffffffffc0205ce8:	00003517          	auipc	a0,0x3
ffffffffc0205cec:	bb850513          	addi	a0,a0,-1096 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205cf0:	d26fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205cf4:	00003697          	auipc	a3,0x3
ffffffffc0205cf8:	84468693          	addi	a3,a3,-1980 # ffffffffc0208538 <default_pmm_manager+0x1e8>
ffffffffc0205cfc:	00001617          	auipc	a2,0x1
ffffffffc0205d00:	f3460613          	addi	a2,a2,-204 # ffffffffc0206c30 <commands+0x480>
ffffffffc0205d04:	33a00593          	li	a1,826
ffffffffc0205d08:	00003517          	auipc	a0,0x3
ffffffffc0205d0c:	b9850513          	addi	a0,a0,-1128 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205d10:	d06fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205d14:	00002697          	auipc	a3,0x2
ffffffffc0205d18:	7dc68693          	addi	a3,a3,2012 # ffffffffc02084f0 <default_pmm_manager+0x1a0>
ffffffffc0205d1c:	00001617          	auipc	a2,0x1
ffffffffc0205d20:	f1460613          	addi	a2,a2,-236 # ffffffffc0206c30 <commands+0x480>
ffffffffc0205d24:	33900593          	li	a1,825
ffffffffc0205d28:	00003517          	auipc	a0,0x3
ffffffffc0205d2c:	b7850513          	addi	a0,a0,-1160 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205d30:	ce6fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205d34:	00002697          	auipc	a3,0x2
ffffffffc0205d38:	77468693          	addi	a3,a3,1908 # ffffffffc02084a8 <default_pmm_manager+0x158>
ffffffffc0205d3c:	00001617          	auipc	a2,0x1
ffffffffc0205d40:	ef460613          	addi	a2,a2,-268 # ffffffffc0206c30 <commands+0x480>
ffffffffc0205d44:	33800593          	li	a1,824
ffffffffc0205d48:	00003517          	auipc	a0,0x3
ffffffffc0205d4c:	b5850513          	addi	a0,a0,-1192 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205d50:	cc6fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205d54:	00002697          	auipc	a3,0x2
ffffffffc0205d58:	70c68693          	addi	a3,a3,1804 # ffffffffc0208460 <default_pmm_manager+0x110>
ffffffffc0205d5c:	00001617          	auipc	a2,0x1
ffffffffc0205d60:	ed460613          	addi	a2,a2,-300 # ffffffffc0206c30 <commands+0x480>
ffffffffc0205d64:	33700593          	li	a1,823
ffffffffc0205d68:	00003517          	auipc	a0,0x3
ffffffffc0205d6c:	b3850513          	addi	a0,a0,-1224 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205d70:	ca6fa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0205d74 <do_yield>:
    current->need_resched = 1;
ffffffffc0205d74:	000a6797          	auipc	a5,0xa6
ffffffffc0205d78:	6b478793          	addi	a5,a5,1716 # ffffffffc02ac428 <current>
ffffffffc0205d7c:	639c                	ld	a5,0(a5)
ffffffffc0205d7e:	4705                	li	a4,1
}
ffffffffc0205d80:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0205d82:	ef98                	sd	a4,24(a5)
}
ffffffffc0205d84:	8082                	ret

ffffffffc0205d86 <do_wait>:
do_wait(int pid, int *code_store) {
ffffffffc0205d86:	1101                	addi	sp,sp,-32
ffffffffc0205d88:	e822                	sd	s0,16(sp)
ffffffffc0205d8a:	e426                	sd	s1,8(sp)
ffffffffc0205d8c:	ec06                	sd	ra,24(sp)
ffffffffc0205d8e:	842e                	mv	s0,a1
ffffffffc0205d90:	84aa                	mv	s1,a0
    if (code_store != NULL) {
ffffffffc0205d92:	cd81                	beqz	a1,ffffffffc0205daa <do_wait+0x24>
    struct mm_struct *mm = current->mm;
ffffffffc0205d94:	000a6797          	auipc	a5,0xa6
ffffffffc0205d98:	69478793          	addi	a5,a5,1684 # ffffffffc02ac428 <current>
ffffffffc0205d9c:	639c                	ld	a5,0(a5)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
ffffffffc0205d9e:	4685                	li	a3,1
ffffffffc0205da0:	4611                	li	a2,4
ffffffffc0205da2:	7788                	ld	a0,40(a5)
ffffffffc0205da4:	bdcfd0ef          	jal	ra,ffffffffc0203180 <user_mem_check>
ffffffffc0205da8:	c909                	beqz	a0,ffffffffc0205dba <do_wait+0x34>
ffffffffc0205daa:	85a2                	mv	a1,s0
}
ffffffffc0205dac:	6442                	ld	s0,16(sp)
ffffffffc0205dae:	60e2                	ld	ra,24(sp)
ffffffffc0205db0:	8526                	mv	a0,s1
ffffffffc0205db2:	64a2                	ld	s1,8(sp)
ffffffffc0205db4:	6105                	addi	sp,sp,32
ffffffffc0205db6:	ff0ff06f          	j	ffffffffc02055a6 <do_wait.part.1>
ffffffffc0205dba:	60e2                	ld	ra,24(sp)
ffffffffc0205dbc:	6442                	ld	s0,16(sp)
ffffffffc0205dbe:	64a2                	ld	s1,8(sp)
ffffffffc0205dc0:	5575                	li	a0,-3
ffffffffc0205dc2:	6105                	addi	sp,sp,32
ffffffffc0205dc4:	8082                	ret

ffffffffc0205dc6 <do_kill>:
do_kill(int pid) {
ffffffffc0205dc6:	1141                	addi	sp,sp,-16
ffffffffc0205dc8:	e406                	sd	ra,8(sp)
ffffffffc0205dca:	e022                	sd	s0,0(sp)
    if ((proc = find_proc(pid)) != NULL) {
ffffffffc0205dcc:	9d8ff0ef          	jal	ra,ffffffffc0204fa4 <find_proc>
ffffffffc0205dd0:	cd0d                	beqz	a0,ffffffffc0205e0a <do_kill+0x44>
        if (!(proc->flags & PF_EXITING)) {
ffffffffc0205dd2:	0b052703          	lw	a4,176(a0)
ffffffffc0205dd6:	00177693          	andi	a3,a4,1
ffffffffc0205dda:	e695                	bnez	a3,ffffffffc0205e06 <do_kill+0x40>
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205ddc:	0ec52683          	lw	a3,236(a0)
            proc->flags |= PF_EXITING;
ffffffffc0205de0:	00176713          	ori	a4,a4,1
ffffffffc0205de4:	0ae52823          	sw	a4,176(a0)
            return 0;
ffffffffc0205de8:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205dea:	0006c763          	bltz	a3,ffffffffc0205df8 <do_kill+0x32>
}
ffffffffc0205dee:	8522                	mv	a0,s0
ffffffffc0205df0:	60a2                	ld	ra,8(sp)
ffffffffc0205df2:	6402                	ld	s0,0(sp)
ffffffffc0205df4:	0141                	addi	sp,sp,16
ffffffffc0205df6:	8082                	ret
                wakeup_proc(proc);
ffffffffc0205df8:	17c000ef          	jal	ra,ffffffffc0205f74 <wakeup_proc>
}
ffffffffc0205dfc:	8522                	mv	a0,s0
ffffffffc0205dfe:	60a2                	ld	ra,8(sp)
ffffffffc0205e00:	6402                	ld	s0,0(sp)
ffffffffc0205e02:	0141                	addi	sp,sp,16
ffffffffc0205e04:	8082                	ret
        return -E_KILLED;
ffffffffc0205e06:	545d                	li	s0,-9
ffffffffc0205e08:	b7dd                	j	ffffffffc0205dee <do_kill+0x28>
    return -E_INVAL;
ffffffffc0205e0a:	5475                	li	s0,-3
ffffffffc0205e0c:	b7cd                	j	ffffffffc0205dee <do_kill+0x28>

ffffffffc0205e0e <proc_init>:
    elm->prev = elm->next = elm;
ffffffffc0205e0e:	000a6797          	auipc	a5,0xa6
ffffffffc0205e12:	75a78793          	addi	a5,a5,1882 # ffffffffc02ac568 <proc_list>

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc0205e16:	1101                	addi	sp,sp,-32
ffffffffc0205e18:	000a6717          	auipc	a4,0xa6
ffffffffc0205e1c:	74f73c23          	sd	a5,1880(a4) # ffffffffc02ac570 <proc_list+0x8>
ffffffffc0205e20:	000a6717          	auipc	a4,0xa6
ffffffffc0205e24:	74f73423          	sd	a5,1864(a4) # ffffffffc02ac568 <proc_list>
ffffffffc0205e28:	ec06                	sd	ra,24(sp)
ffffffffc0205e2a:	e822                	sd	s0,16(sp)
ffffffffc0205e2c:	e426                	sd	s1,8(sp)
ffffffffc0205e2e:	000a2797          	auipc	a5,0xa2
ffffffffc0205e32:	5ba78793          	addi	a5,a5,1466 # ffffffffc02a83e8 <hash_list>
ffffffffc0205e36:	000a6717          	auipc	a4,0xa6
ffffffffc0205e3a:	5b270713          	addi	a4,a4,1458 # ffffffffc02ac3e8 <is_panic>
ffffffffc0205e3e:	e79c                	sd	a5,8(a5)
ffffffffc0205e40:	e39c                	sd	a5,0(a5)
ffffffffc0205e42:	07c1                	addi	a5,a5,16
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0205e44:	fee79de3          	bne	a5,a4,ffffffffc0205e3e <proc_init+0x30>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc0205e48:	eb5fe0ef          	jal	ra,ffffffffc0204cfc <alloc_proc>
ffffffffc0205e4c:	000a6717          	auipc	a4,0xa6
ffffffffc0205e50:	5ea73223          	sd	a0,1508(a4) # ffffffffc02ac430 <idleproc>
ffffffffc0205e54:	000a6497          	auipc	s1,0xa6
ffffffffc0205e58:	5dc48493          	addi	s1,s1,1500 # ffffffffc02ac430 <idleproc>
ffffffffc0205e5c:	c559                	beqz	a0,ffffffffc0205eea <proc_init+0xdc>
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205e5e:	4709                	li	a4,2
ffffffffc0205e60:	e118                	sd	a4,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
ffffffffc0205e62:	4405                	li	s0,1
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205e64:	00003717          	auipc	a4,0x3
ffffffffc0205e68:	19c70713          	addi	a4,a4,412 # ffffffffc0209000 <bootstack>
    set_proc_name(idleproc, "idle");
ffffffffc0205e6c:	00003597          	auipc	a1,0x3
ffffffffc0205e70:	94c58593          	addi	a1,a1,-1716 # ffffffffc02087b8 <default_pmm_manager+0x468>
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205e74:	e918                	sd	a4,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205e76:	ed00                	sd	s0,24(a0)
    set_proc_name(idleproc, "idle");
ffffffffc0205e78:	894ff0ef          	jal	ra,ffffffffc0204f0c <set_proc_name>
    nr_process ++;
ffffffffc0205e7c:	000a6797          	auipc	a5,0xa6
ffffffffc0205e80:	5c478793          	addi	a5,a5,1476 # ffffffffc02ac440 <nr_process>
ffffffffc0205e84:	439c                	lw	a5,0(a5)

    current = idleproc;
ffffffffc0205e86:	6098                	ld	a4,0(s1)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205e88:	4601                	li	a2,0
    nr_process ++;
ffffffffc0205e8a:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205e8c:	4581                	li	a1,0
ffffffffc0205e8e:	00000517          	auipc	a0,0x0
ffffffffc0205e92:	8c050513          	addi	a0,a0,-1856 # ffffffffc020574e <init_main>
    nr_process ++;
ffffffffc0205e96:	000a6697          	auipc	a3,0xa6
ffffffffc0205e9a:	5af6a523          	sw	a5,1450(a3) # ffffffffc02ac440 <nr_process>
    current = idleproc;
ffffffffc0205e9e:	000a6797          	auipc	a5,0xa6
ffffffffc0205ea2:	58e7b523          	sd	a4,1418(a5) # ffffffffc02ac428 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205ea6:	d62ff0ef          	jal	ra,ffffffffc0205408 <kernel_thread>
    if (pid <= 0) {
ffffffffc0205eaa:	08a05c63          	blez	a0,ffffffffc0205f42 <proc_init+0x134>
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205eae:	8f6ff0ef          	jal	ra,ffffffffc0204fa4 <find_proc>
    set_proc_name(initproc, "init");
ffffffffc0205eb2:	00003597          	auipc	a1,0x3
ffffffffc0205eb6:	92e58593          	addi	a1,a1,-1746 # ffffffffc02087e0 <default_pmm_manager+0x490>
    initproc = find_proc(pid);
ffffffffc0205eba:	000a6797          	auipc	a5,0xa6
ffffffffc0205ebe:	56a7bf23          	sd	a0,1406(a5) # ffffffffc02ac438 <initproc>
    set_proc_name(initproc, "init");
ffffffffc0205ec2:	84aff0ef          	jal	ra,ffffffffc0204f0c <set_proc_name>

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205ec6:	609c                	ld	a5,0(s1)
ffffffffc0205ec8:	cfa9                	beqz	a5,ffffffffc0205f22 <proc_init+0x114>
ffffffffc0205eca:	43dc                	lw	a5,4(a5)
ffffffffc0205ecc:	ebb9                	bnez	a5,ffffffffc0205f22 <proc_init+0x114>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205ece:	000a6797          	auipc	a5,0xa6
ffffffffc0205ed2:	56a78793          	addi	a5,a5,1386 # ffffffffc02ac438 <initproc>
ffffffffc0205ed6:	639c                	ld	a5,0(a5)
ffffffffc0205ed8:	c78d                	beqz	a5,ffffffffc0205f02 <proc_init+0xf4>
ffffffffc0205eda:	43dc                	lw	a5,4(a5)
ffffffffc0205edc:	02879363          	bne	a5,s0,ffffffffc0205f02 <proc_init+0xf4>
}
ffffffffc0205ee0:	60e2                	ld	ra,24(sp)
ffffffffc0205ee2:	6442                	ld	s0,16(sp)
ffffffffc0205ee4:	64a2                	ld	s1,8(sp)
ffffffffc0205ee6:	6105                	addi	sp,sp,32
ffffffffc0205ee8:	8082                	ret
        panic("cannot alloc idleproc.\n");
ffffffffc0205eea:	00002617          	auipc	a2,0x2
ffffffffc0205eee:	6d660613          	addi	a2,a2,1750 # ffffffffc02085c0 <default_pmm_manager+0x270>
ffffffffc0205ef2:	4a400593          	li	a1,1188
ffffffffc0205ef6:	00003517          	auipc	a0,0x3
ffffffffc0205efa:	9aa50513          	addi	a0,a0,-1622 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205efe:	b18fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205f02:	00003697          	auipc	a3,0x3
ffffffffc0205f06:	90e68693          	addi	a3,a3,-1778 # ffffffffc0208810 <default_pmm_manager+0x4c0>
ffffffffc0205f0a:	00001617          	auipc	a2,0x1
ffffffffc0205f0e:	d2660613          	addi	a2,a2,-730 # ffffffffc0206c30 <commands+0x480>
ffffffffc0205f12:	4b900593          	li	a1,1209
ffffffffc0205f16:	00003517          	auipc	a0,0x3
ffffffffc0205f1a:	98a50513          	addi	a0,a0,-1654 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205f1e:	af8fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205f22:	00003697          	auipc	a3,0x3
ffffffffc0205f26:	8c668693          	addi	a3,a3,-1850 # ffffffffc02087e8 <default_pmm_manager+0x498>
ffffffffc0205f2a:	00001617          	auipc	a2,0x1
ffffffffc0205f2e:	d0660613          	addi	a2,a2,-762 # ffffffffc0206c30 <commands+0x480>
ffffffffc0205f32:	4b800593          	li	a1,1208
ffffffffc0205f36:	00003517          	auipc	a0,0x3
ffffffffc0205f3a:	96a50513          	addi	a0,a0,-1686 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205f3e:	ad8fa0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("create init_main failed.\n");
ffffffffc0205f42:	00003617          	auipc	a2,0x3
ffffffffc0205f46:	87e60613          	addi	a2,a2,-1922 # ffffffffc02087c0 <default_pmm_manager+0x470>
ffffffffc0205f4a:	4b200593          	li	a1,1202
ffffffffc0205f4e:	00003517          	auipc	a0,0x3
ffffffffc0205f52:	95250513          	addi	a0,a0,-1710 # ffffffffc02088a0 <default_pmm_manager+0x550>
ffffffffc0205f56:	ac0fa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0205f5a <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc0205f5a:	1141                	addi	sp,sp,-16
ffffffffc0205f5c:	e022                	sd	s0,0(sp)
ffffffffc0205f5e:	e406                	sd	ra,8(sp)
ffffffffc0205f60:	000a6417          	auipc	s0,0xa6
ffffffffc0205f64:	4c840413          	addi	s0,s0,1224 # ffffffffc02ac428 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc0205f68:	6018                	ld	a4,0(s0)
ffffffffc0205f6a:	6f1c                	ld	a5,24(a4)
ffffffffc0205f6c:	dffd                	beqz	a5,ffffffffc0205f6a <cpu_idle+0x10>
            schedule();
ffffffffc0205f6e:	082000ef          	jal	ra,ffffffffc0205ff0 <schedule>
ffffffffc0205f72:	bfdd                	j	ffffffffc0205f68 <cpu_idle+0xe>

ffffffffc0205f74 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f74:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc0205f76:	1101                	addi	sp,sp,-32
ffffffffc0205f78:	ec06                	sd	ra,24(sp)
ffffffffc0205f7a:	e822                	sd	s0,16(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f7c:	478d                	li	a5,3
ffffffffc0205f7e:	04f70a63          	beq	a4,a5,ffffffffc0205fd2 <wakeup_proc+0x5e>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f82:	100027f3          	csrr	a5,sstatus
ffffffffc0205f86:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205f88:	4401                	li	s0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f8a:	ef8d                	bnez	a5,ffffffffc0205fc4 <wakeup_proc+0x50>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205f8c:	4789                	li	a5,2
ffffffffc0205f8e:	00f70f63          	beq	a4,a5,ffffffffc0205fac <wakeup_proc+0x38>
            proc->state = PROC_RUNNABLE;
ffffffffc0205f92:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc0205f94:	0e052623          	sw	zero,236(a0)
    if (flag) {
ffffffffc0205f98:	e409                	bnez	s0,ffffffffc0205fa2 <wakeup_proc+0x2e>
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205f9a:	60e2                	ld	ra,24(sp)
ffffffffc0205f9c:	6442                	ld	s0,16(sp)
ffffffffc0205f9e:	6105                	addi	sp,sp,32
ffffffffc0205fa0:	8082                	ret
ffffffffc0205fa2:	6442                	ld	s0,16(sp)
ffffffffc0205fa4:	60e2                	ld	ra,24(sp)
ffffffffc0205fa6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205fa8:	eaefa06f          	j	ffffffffc0200656 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205fac:	00003617          	auipc	a2,0x3
ffffffffc0205fb0:	94460613          	addi	a2,a2,-1724 # ffffffffc02088f0 <default_pmm_manager+0x5a0>
ffffffffc0205fb4:	45c9                	li	a1,18
ffffffffc0205fb6:	00003517          	auipc	a0,0x3
ffffffffc0205fba:	92250513          	addi	a0,a0,-1758 # ffffffffc02088d8 <default_pmm_manager+0x588>
ffffffffc0205fbe:	ac4fa0ef          	jal	ra,ffffffffc0200282 <__warn>
ffffffffc0205fc2:	bfd9                	j	ffffffffc0205f98 <wakeup_proc+0x24>
ffffffffc0205fc4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0205fc6:	e96fa0ef          	jal	ra,ffffffffc020065c <intr_disable>
        return 1;
ffffffffc0205fca:	6522                	ld	a0,8(sp)
ffffffffc0205fcc:	4405                	li	s0,1
ffffffffc0205fce:	4118                	lw	a4,0(a0)
ffffffffc0205fd0:	bf75                	j	ffffffffc0205f8c <wakeup_proc+0x18>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205fd2:	00003697          	auipc	a3,0x3
ffffffffc0205fd6:	8e668693          	addi	a3,a3,-1818 # ffffffffc02088b8 <default_pmm_manager+0x568>
ffffffffc0205fda:	00001617          	auipc	a2,0x1
ffffffffc0205fde:	c5660613          	addi	a2,a2,-938 # ffffffffc0206c30 <commands+0x480>
ffffffffc0205fe2:	45a5                	li	a1,9
ffffffffc0205fe4:	00003517          	auipc	a0,0x3
ffffffffc0205fe8:	8f450513          	addi	a0,a0,-1804 # ffffffffc02088d8 <default_pmm_manager+0x588>
ffffffffc0205fec:	a2afa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0205ff0 <schedule>:

void
schedule(void) {
ffffffffc0205ff0:	1141                	addi	sp,sp,-16
ffffffffc0205ff2:	e406                	sd	ra,8(sp)
ffffffffc0205ff4:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205ff6:	100027f3          	csrr	a5,sstatus
ffffffffc0205ffa:	8b89                	andi	a5,a5,2
ffffffffc0205ffc:	4401                	li	s0,0
ffffffffc0205ffe:	e3d1                	bnez	a5,ffffffffc0206082 <schedule+0x92>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0206000:	000a6797          	auipc	a5,0xa6
ffffffffc0206004:	42878793          	addi	a5,a5,1064 # ffffffffc02ac428 <current>
ffffffffc0206008:	0007b883          	ld	a7,0(a5)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020600c:	000a6797          	auipc	a5,0xa6
ffffffffc0206010:	42478793          	addi	a5,a5,1060 # ffffffffc02ac430 <idleproc>
ffffffffc0206014:	6388                	ld	a0,0(a5)
        current->need_resched = 0;
ffffffffc0206016:	0008bc23          	sd	zero,24(a7) # 2018 <_binary_obj___user_faultread_out_size-0x7558>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020601a:	04a88e63          	beq	a7,a0,ffffffffc0206076 <schedule+0x86>
ffffffffc020601e:	0c888693          	addi	a3,a7,200
ffffffffc0206022:	000a6617          	auipc	a2,0xa6
ffffffffc0206026:	54660613          	addi	a2,a2,1350 # ffffffffc02ac568 <proc_list>
        le = last;
ffffffffc020602a:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020602c:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc020602e:	4809                	li	a6,2
    return listelm->next;
ffffffffc0206030:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0206032:	00c78863          	beq	a5,a2,ffffffffc0206042 <schedule+0x52>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0206036:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020603a:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc020603e:	01070463          	beq	a4,a6,ffffffffc0206046 <schedule+0x56>
                    break;
                }
            }
        } while (le != last);
ffffffffc0206042:	fef697e3          	bne	a3,a5,ffffffffc0206030 <schedule+0x40>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0206046:	c589                	beqz	a1,ffffffffc0206050 <schedule+0x60>
ffffffffc0206048:	4198                	lw	a4,0(a1)
ffffffffc020604a:	4789                	li	a5,2
ffffffffc020604c:	00f70e63          	beq	a4,a5,ffffffffc0206068 <schedule+0x78>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0206050:	451c                	lw	a5,8(a0)
ffffffffc0206052:	2785                	addiw	a5,a5,1
ffffffffc0206054:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0206056:	00a88463          	beq	a7,a0,ffffffffc020605e <schedule+0x6e>
            proc_run(next);
ffffffffc020605a:	eddfe0ef          	jal	ra,ffffffffc0204f36 <proc_run>
    if (flag) {
ffffffffc020605e:	e419                	bnez	s0,ffffffffc020606c <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0206060:	60a2                	ld	ra,8(sp)
ffffffffc0206062:	6402                	ld	s0,0(sp)
ffffffffc0206064:	0141                	addi	sp,sp,16
ffffffffc0206066:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0206068:	852e                	mv	a0,a1
ffffffffc020606a:	b7dd                	j	ffffffffc0206050 <schedule+0x60>
}
ffffffffc020606c:	6402                	ld	s0,0(sp)
ffffffffc020606e:	60a2                	ld	ra,8(sp)
ffffffffc0206070:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0206072:	de4fa06f          	j	ffffffffc0200656 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0206076:	000a6617          	auipc	a2,0xa6
ffffffffc020607a:	4f260613          	addi	a2,a2,1266 # ffffffffc02ac568 <proc_list>
ffffffffc020607e:	86b2                	mv	a3,a2
ffffffffc0206080:	b76d                	j	ffffffffc020602a <schedule+0x3a>
        intr_disable();
ffffffffc0206082:	ddafa0ef          	jal	ra,ffffffffc020065c <intr_disable>
        return 1;
ffffffffc0206086:	4405                	li	s0,1
ffffffffc0206088:	bfa5                	j	ffffffffc0206000 <schedule+0x10>

ffffffffc020608a <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc020608a:	000a6797          	auipc	a5,0xa6
ffffffffc020608e:	39e78793          	addi	a5,a5,926 # ffffffffc02ac428 <current>
ffffffffc0206092:	639c                	ld	a5,0(a5)
}
ffffffffc0206094:	43c8                	lw	a0,4(a5)
ffffffffc0206096:	8082                	ret

ffffffffc0206098 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0206098:	4501                	li	a0,0
ffffffffc020609a:	8082                	ret

ffffffffc020609c <sys_putc>:
    cputchar(c);
ffffffffc020609c:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc020609e:	1141                	addi	sp,sp,-16
ffffffffc02060a0:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02060a2:	862fa0ef          	jal	ra,ffffffffc0200104 <cputchar>
}
ffffffffc02060a6:	60a2                	ld	ra,8(sp)
ffffffffc02060a8:	4501                	li	a0,0
ffffffffc02060aa:	0141                	addi	sp,sp,16
ffffffffc02060ac:	8082                	ret

ffffffffc02060ae <sys_kill>:
    return do_kill(pid);
ffffffffc02060ae:	4108                	lw	a0,0(a0)
ffffffffc02060b0:	d17ff06f          	j	ffffffffc0205dc6 <do_kill>

ffffffffc02060b4 <sys_yield>:
    return do_yield();
ffffffffc02060b4:	cc1ff06f          	j	ffffffffc0205d74 <do_yield>

ffffffffc02060b8 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02060b8:	6d14                	ld	a3,24(a0)
ffffffffc02060ba:	6910                	ld	a2,16(a0)
ffffffffc02060bc:	650c                	ld	a1,8(a0)
ffffffffc02060be:	6108                	ld	a0,0(a0)
ffffffffc02060c0:	fb6ff06f          	j	ffffffffc0205876 <do_execve>

ffffffffc02060c4 <sys_wait>:
    return do_wait(pid, store);
ffffffffc02060c4:	650c                	ld	a1,8(a0)
ffffffffc02060c6:	4108                	lw	a0,0(a0)
ffffffffc02060c8:	cbfff06f          	j	ffffffffc0205d86 <do_wait>

ffffffffc02060cc <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02060cc:	000a6797          	auipc	a5,0xa6
ffffffffc02060d0:	35c78793          	addi	a5,a5,860 # ffffffffc02ac428 <current>
ffffffffc02060d4:	639c                	ld	a5,0(a5)
    return do_fork(0, stack, tf);
ffffffffc02060d6:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc02060d8:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02060da:	6a0c                	ld	a1,16(a2)
ffffffffc02060dc:	f25fe06f          	j	ffffffffc0205000 <do_fork>

ffffffffc02060e0 <sys_exit>:
    return do_exit(error_code);
ffffffffc02060e0:	4108                	lw	a0,0(a0)
ffffffffc02060e2:	b76ff06f          	j	ffffffffc0205458 <do_exit>

ffffffffc02060e6 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02060e6:	715d                	addi	sp,sp,-80
ffffffffc02060e8:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060ea:	000a6497          	auipc	s1,0xa6
ffffffffc02060ee:	33e48493          	addi	s1,s1,830 # ffffffffc02ac428 <current>
ffffffffc02060f2:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02060f4:	e0a2                	sd	s0,64(sp)
ffffffffc02060f6:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060f8:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02060fa:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02060fc:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02060fe:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0206102:	0327ee63          	bltu	a5,s2,ffffffffc020613e <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0206106:	00391713          	slli	a4,s2,0x3
ffffffffc020610a:	00003797          	auipc	a5,0x3
ffffffffc020610e:	84e78793          	addi	a5,a5,-1970 # ffffffffc0208958 <syscalls>
ffffffffc0206112:	97ba                	add	a5,a5,a4
ffffffffc0206114:	639c                	ld	a5,0(a5)
ffffffffc0206116:	c785                	beqz	a5,ffffffffc020613e <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0206118:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc020611a:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc020611c:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc020611e:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0206120:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0206122:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0206124:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0206126:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0206128:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc020612a:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020612c:	0028                	addi	a0,sp,8
ffffffffc020612e:	9782                	jalr	a5
ffffffffc0206130:	e828                	sd	a0,80(s0)
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0206132:	60a6                	ld	ra,72(sp)
ffffffffc0206134:	6406                	ld	s0,64(sp)
ffffffffc0206136:	74e2                	ld	s1,56(sp)
ffffffffc0206138:	7942                	ld	s2,48(sp)
ffffffffc020613a:	6161                	addi	sp,sp,80
ffffffffc020613c:	8082                	ret
    print_trapframe(tf);
ffffffffc020613e:	8522                	mv	a0,s0
ffffffffc0206140:	f0afa0ef          	jal	ra,ffffffffc020084a <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0206144:	609c                	ld	a5,0(s1)
ffffffffc0206146:	86ca                	mv	a3,s2
ffffffffc0206148:	00002617          	auipc	a2,0x2
ffffffffc020614c:	7c860613          	addi	a2,a2,1992 # ffffffffc0208910 <default_pmm_manager+0x5c0>
ffffffffc0206150:	43d8                	lw	a4,4(a5)
ffffffffc0206152:	08500593          	li	a1,133
ffffffffc0206156:	0b478793          	addi	a5,a5,180
ffffffffc020615a:	00002517          	auipc	a0,0x2
ffffffffc020615e:	7e650513          	addi	a0,a0,2022 # ffffffffc0208940 <default_pmm_manager+0x5f0>
ffffffffc0206162:	8b4fa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0206166 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0206166:	00054783          	lbu	a5,0(a0)
ffffffffc020616a:	cb91                	beqz	a5,ffffffffc020617e <strlen+0x18>
    size_t cnt = 0;
ffffffffc020616c:	4781                	li	a5,0
        cnt ++;
ffffffffc020616e:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0206170:	00f50733          	add	a4,a0,a5
ffffffffc0206174:	00074703          	lbu	a4,0(a4)
ffffffffc0206178:	fb7d                	bnez	a4,ffffffffc020616e <strlen+0x8>
    }
    return cnt;
}
ffffffffc020617a:	853e                	mv	a0,a5
ffffffffc020617c:	8082                	ret
    size_t cnt = 0;
ffffffffc020617e:	4781                	li	a5,0
}
ffffffffc0206180:	853e                	mv	a0,a5
ffffffffc0206182:	8082                	ret

ffffffffc0206184 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206184:	c185                	beqz	a1,ffffffffc02061a4 <strnlen+0x20>
ffffffffc0206186:	00054783          	lbu	a5,0(a0)
ffffffffc020618a:	cf89                	beqz	a5,ffffffffc02061a4 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc020618c:	4781                	li	a5,0
ffffffffc020618e:	a021                	j	ffffffffc0206196 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206190:	00074703          	lbu	a4,0(a4)
ffffffffc0206194:	c711                	beqz	a4,ffffffffc02061a0 <strnlen+0x1c>
        cnt ++;
ffffffffc0206196:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206198:	00f50733          	add	a4,a0,a5
ffffffffc020619c:	fef59ae3          	bne	a1,a5,ffffffffc0206190 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc02061a0:	853e                	mv	a0,a5
ffffffffc02061a2:	8082                	ret
    size_t cnt = 0;
ffffffffc02061a4:	4781                	li	a5,0
}
ffffffffc02061a6:	853e                	mv	a0,a5
ffffffffc02061a8:	8082                	ret

ffffffffc02061aa <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02061aa:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02061ac:	0585                	addi	a1,a1,1
ffffffffc02061ae:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02061b2:	0785                	addi	a5,a5,1
ffffffffc02061b4:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02061b8:	fb75                	bnez	a4,ffffffffc02061ac <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02061ba:	8082                	ret

ffffffffc02061bc <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02061bc:	00054783          	lbu	a5,0(a0)
ffffffffc02061c0:	0005c703          	lbu	a4,0(a1)
ffffffffc02061c4:	cb91                	beqz	a5,ffffffffc02061d8 <strcmp+0x1c>
ffffffffc02061c6:	00e79c63          	bne	a5,a4,ffffffffc02061de <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc02061ca:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02061cc:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc02061d0:	0585                	addi	a1,a1,1
ffffffffc02061d2:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02061d6:	fbe5                	bnez	a5,ffffffffc02061c6 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02061d8:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02061da:	9d19                	subw	a0,a0,a4
ffffffffc02061dc:	8082                	ret
ffffffffc02061de:	0007851b          	sext.w	a0,a5
ffffffffc02061e2:	9d19                	subw	a0,a0,a4
ffffffffc02061e4:	8082                	ret

ffffffffc02061e6 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02061e6:	00054783          	lbu	a5,0(a0)
ffffffffc02061ea:	cb91                	beqz	a5,ffffffffc02061fe <strchr+0x18>
        if (*s == c) {
ffffffffc02061ec:	00b79563          	bne	a5,a1,ffffffffc02061f6 <strchr+0x10>
ffffffffc02061f0:	a809                	j	ffffffffc0206202 <strchr+0x1c>
ffffffffc02061f2:	00b78763          	beq	a5,a1,ffffffffc0206200 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc02061f6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02061f8:	00054783          	lbu	a5,0(a0)
ffffffffc02061fc:	fbfd                	bnez	a5,ffffffffc02061f2 <strchr+0xc>
    }
    return NULL;
ffffffffc02061fe:	4501                	li	a0,0
}
ffffffffc0206200:	8082                	ret
ffffffffc0206202:	8082                	ret

ffffffffc0206204 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0206204:	ca01                	beqz	a2,ffffffffc0206214 <memset+0x10>
ffffffffc0206206:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0206208:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020620a:	0785                	addi	a5,a5,1
ffffffffc020620c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0206210:	fec79de3          	bne	a5,a2,ffffffffc020620a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0206214:	8082                	ret

ffffffffc0206216 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0206216:	ca19                	beqz	a2,ffffffffc020622c <memcpy+0x16>
ffffffffc0206218:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc020621a:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc020621c:	0585                	addi	a1,a1,1
ffffffffc020621e:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0206222:	0785                	addi	a5,a5,1
ffffffffc0206224:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0206228:	fec59ae3          	bne	a1,a2,ffffffffc020621c <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc020622c:	8082                	ret

ffffffffc020622e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020622e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206232:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0206234:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206238:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020623a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020623e:	f022                	sd	s0,32(sp)
ffffffffc0206240:	ec26                	sd	s1,24(sp)
ffffffffc0206242:	e84a                	sd	s2,16(sp)
ffffffffc0206244:	f406                	sd	ra,40(sp)
ffffffffc0206246:	e44e                	sd	s3,8(sp)
ffffffffc0206248:	84aa                	mv	s1,a0
ffffffffc020624a:	892e                	mv	s2,a1
ffffffffc020624c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0206250:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0206252:	03067e63          	bleu	a6,a2,ffffffffc020628e <printnum+0x60>
ffffffffc0206256:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0206258:	00805763          	blez	s0,ffffffffc0206266 <printnum+0x38>
ffffffffc020625c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020625e:	85ca                	mv	a1,s2
ffffffffc0206260:	854e                	mv	a0,s3
ffffffffc0206262:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0206264:	fc65                	bnez	s0,ffffffffc020625c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206266:	1a02                	slli	s4,s4,0x20
ffffffffc0206268:	020a5a13          	srli	s4,s4,0x20
ffffffffc020626c:	00003797          	auipc	a5,0x3
ffffffffc0206270:	a0c78793          	addi	a5,a5,-1524 # ffffffffc0208c78 <error_string+0xc8>
ffffffffc0206274:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0206276:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206278:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020627c:	70a2                	ld	ra,40(sp)
ffffffffc020627e:	69a2                	ld	s3,8(sp)
ffffffffc0206280:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206282:	85ca                	mv	a1,s2
ffffffffc0206284:	8326                	mv	t1,s1
}
ffffffffc0206286:	6942                	ld	s2,16(sp)
ffffffffc0206288:	64e2                	ld	s1,24(sp)
ffffffffc020628a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020628c:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020628e:	03065633          	divu	a2,a2,a6
ffffffffc0206292:	8722                	mv	a4,s0
ffffffffc0206294:	f9bff0ef          	jal	ra,ffffffffc020622e <printnum>
ffffffffc0206298:	b7f9                	j	ffffffffc0206266 <printnum+0x38>

ffffffffc020629a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020629a:	7119                	addi	sp,sp,-128
ffffffffc020629c:	f4a6                	sd	s1,104(sp)
ffffffffc020629e:	f0ca                	sd	s2,96(sp)
ffffffffc02062a0:	e8d2                	sd	s4,80(sp)
ffffffffc02062a2:	e4d6                	sd	s5,72(sp)
ffffffffc02062a4:	e0da                	sd	s6,64(sp)
ffffffffc02062a6:	fc5e                	sd	s7,56(sp)
ffffffffc02062a8:	f862                	sd	s8,48(sp)
ffffffffc02062aa:	f06a                	sd	s10,32(sp)
ffffffffc02062ac:	fc86                	sd	ra,120(sp)
ffffffffc02062ae:	f8a2                	sd	s0,112(sp)
ffffffffc02062b0:	ecce                	sd	s3,88(sp)
ffffffffc02062b2:	f466                	sd	s9,40(sp)
ffffffffc02062b4:	ec6e                	sd	s11,24(sp)
ffffffffc02062b6:	892a                	mv	s2,a0
ffffffffc02062b8:	84ae                	mv	s1,a1
ffffffffc02062ba:	8d32                	mv	s10,a2
ffffffffc02062bc:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02062be:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02062c0:	00002a17          	auipc	s4,0x2
ffffffffc02062c4:	798a0a13          	addi	s4,s4,1944 # ffffffffc0208a58 <syscalls+0x100>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02062c8:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02062cc:	00003c17          	auipc	s8,0x3
ffffffffc02062d0:	8e4c0c13          	addi	s8,s8,-1820 # ffffffffc0208bb0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02062d4:	000d4503          	lbu	a0,0(s10)
ffffffffc02062d8:	02500793          	li	a5,37
ffffffffc02062dc:	001d0413          	addi	s0,s10,1
ffffffffc02062e0:	00f50e63          	beq	a0,a5,ffffffffc02062fc <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc02062e4:	c521                	beqz	a0,ffffffffc020632c <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02062e6:	02500993          	li	s3,37
ffffffffc02062ea:	a011                	j	ffffffffc02062ee <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc02062ec:	c121                	beqz	a0,ffffffffc020632c <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc02062ee:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02062f0:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02062f2:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02062f4:	fff44503          	lbu	a0,-1(s0)
ffffffffc02062f8:	ff351ae3          	bne	a0,s3,ffffffffc02062ec <vprintfmt+0x52>
ffffffffc02062fc:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0206300:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0206304:	4981                	li	s3,0
ffffffffc0206306:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0206308:	5cfd                	li	s9,-1
ffffffffc020630a:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020630c:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0206310:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206312:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0206316:	0ff6f693          	andi	a3,a3,255
ffffffffc020631a:	00140d13          	addi	s10,s0,1
ffffffffc020631e:	20d5e563          	bltu	a1,a3,ffffffffc0206528 <vprintfmt+0x28e>
ffffffffc0206322:	068a                	slli	a3,a3,0x2
ffffffffc0206324:	96d2                	add	a3,a3,s4
ffffffffc0206326:	4294                	lw	a3,0(a3)
ffffffffc0206328:	96d2                	add	a3,a3,s4
ffffffffc020632a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020632c:	70e6                	ld	ra,120(sp)
ffffffffc020632e:	7446                	ld	s0,112(sp)
ffffffffc0206330:	74a6                	ld	s1,104(sp)
ffffffffc0206332:	7906                	ld	s2,96(sp)
ffffffffc0206334:	69e6                	ld	s3,88(sp)
ffffffffc0206336:	6a46                	ld	s4,80(sp)
ffffffffc0206338:	6aa6                	ld	s5,72(sp)
ffffffffc020633a:	6b06                	ld	s6,64(sp)
ffffffffc020633c:	7be2                	ld	s7,56(sp)
ffffffffc020633e:	7c42                	ld	s8,48(sp)
ffffffffc0206340:	7ca2                	ld	s9,40(sp)
ffffffffc0206342:	7d02                	ld	s10,32(sp)
ffffffffc0206344:	6de2                	ld	s11,24(sp)
ffffffffc0206346:	6109                	addi	sp,sp,128
ffffffffc0206348:	8082                	ret
    if (lflag >= 2) {
ffffffffc020634a:	4705                	li	a4,1
ffffffffc020634c:	008a8593          	addi	a1,s5,8
ffffffffc0206350:	01074463          	blt	a4,a6,ffffffffc0206358 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0206354:	26080363          	beqz	a6,ffffffffc02065ba <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc0206358:	000ab603          	ld	a2,0(s5)
ffffffffc020635c:	46c1                	li	a3,16
ffffffffc020635e:	8aae                	mv	s5,a1
ffffffffc0206360:	a06d                	j	ffffffffc020640a <vprintfmt+0x170>
            goto reswitch;
ffffffffc0206362:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0206366:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206368:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020636a:	b765                	j	ffffffffc0206312 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc020636c:	000aa503          	lw	a0,0(s5)
ffffffffc0206370:	85a6                	mv	a1,s1
ffffffffc0206372:	0aa1                	addi	s5,s5,8
ffffffffc0206374:	9902                	jalr	s2
            break;
ffffffffc0206376:	bfb9                	j	ffffffffc02062d4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0206378:	4705                	li	a4,1
ffffffffc020637a:	008a8993          	addi	s3,s5,8
ffffffffc020637e:	01074463          	blt	a4,a6,ffffffffc0206386 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0206382:	22080463          	beqz	a6,ffffffffc02065aa <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc0206386:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc020638a:	24044463          	bltz	s0,ffffffffc02065d2 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc020638e:	8622                	mv	a2,s0
ffffffffc0206390:	8ace                	mv	s5,s3
ffffffffc0206392:	46a9                	li	a3,10
ffffffffc0206394:	a89d                	j	ffffffffc020640a <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc0206396:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020639a:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc020639c:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc020639e:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02063a2:	8fb5                	xor	a5,a5,a3
ffffffffc02063a4:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02063a8:	1ad74363          	blt	a4,a3,ffffffffc020654e <vprintfmt+0x2b4>
ffffffffc02063ac:	00369793          	slli	a5,a3,0x3
ffffffffc02063b0:	97e2                	add	a5,a5,s8
ffffffffc02063b2:	639c                	ld	a5,0(a5)
ffffffffc02063b4:	18078d63          	beqz	a5,ffffffffc020654e <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc02063b8:	86be                	mv	a3,a5
ffffffffc02063ba:	00000617          	auipc	a2,0x0
ffffffffc02063be:	2ae60613          	addi	a2,a2,686 # ffffffffc0206668 <etext+0x2a>
ffffffffc02063c2:	85a6                	mv	a1,s1
ffffffffc02063c4:	854a                	mv	a0,s2
ffffffffc02063c6:	240000ef          	jal	ra,ffffffffc0206606 <printfmt>
ffffffffc02063ca:	b729                	j	ffffffffc02062d4 <vprintfmt+0x3a>
            lflag ++;
ffffffffc02063cc:	00144603          	lbu	a2,1(s0)
ffffffffc02063d0:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063d2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02063d4:	bf3d                	j	ffffffffc0206312 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc02063d6:	4705                	li	a4,1
ffffffffc02063d8:	008a8593          	addi	a1,s5,8
ffffffffc02063dc:	01074463          	blt	a4,a6,ffffffffc02063e4 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02063e0:	1e080263          	beqz	a6,ffffffffc02065c4 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc02063e4:	000ab603          	ld	a2,0(s5)
ffffffffc02063e8:	46a1                	li	a3,8
ffffffffc02063ea:	8aae                	mv	s5,a1
ffffffffc02063ec:	a839                	j	ffffffffc020640a <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc02063ee:	03000513          	li	a0,48
ffffffffc02063f2:	85a6                	mv	a1,s1
ffffffffc02063f4:	e03e                	sd	a5,0(sp)
ffffffffc02063f6:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02063f8:	85a6                	mv	a1,s1
ffffffffc02063fa:	07800513          	li	a0,120
ffffffffc02063fe:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0206400:	0aa1                	addi	s5,s5,8
ffffffffc0206402:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0206406:	6782                	ld	a5,0(sp)
ffffffffc0206408:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020640a:	876e                	mv	a4,s11
ffffffffc020640c:	85a6                	mv	a1,s1
ffffffffc020640e:	854a                	mv	a0,s2
ffffffffc0206410:	e1fff0ef          	jal	ra,ffffffffc020622e <printnum>
            break;
ffffffffc0206414:	b5c1                	j	ffffffffc02062d4 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206416:	000ab603          	ld	a2,0(s5)
ffffffffc020641a:	0aa1                	addi	s5,s5,8
ffffffffc020641c:	1c060663          	beqz	a2,ffffffffc02065e8 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0206420:	00160413          	addi	s0,a2,1
ffffffffc0206424:	17b05c63          	blez	s11,ffffffffc020659c <vprintfmt+0x302>
ffffffffc0206428:	02d00593          	li	a1,45
ffffffffc020642c:	14b79263          	bne	a5,a1,ffffffffc0206570 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206430:	00064783          	lbu	a5,0(a2)
ffffffffc0206434:	0007851b          	sext.w	a0,a5
ffffffffc0206438:	c905                	beqz	a0,ffffffffc0206468 <vprintfmt+0x1ce>
ffffffffc020643a:	000cc563          	bltz	s9,ffffffffc0206444 <vprintfmt+0x1aa>
ffffffffc020643e:	3cfd                	addiw	s9,s9,-1
ffffffffc0206440:	036c8263          	beq	s9,s6,ffffffffc0206464 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0206444:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206446:	18098463          	beqz	s3,ffffffffc02065ce <vprintfmt+0x334>
ffffffffc020644a:	3781                	addiw	a5,a5,-32
ffffffffc020644c:	18fbf163          	bleu	a5,s7,ffffffffc02065ce <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0206450:	03f00513          	li	a0,63
ffffffffc0206454:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206456:	0405                	addi	s0,s0,1
ffffffffc0206458:	fff44783          	lbu	a5,-1(s0)
ffffffffc020645c:	3dfd                	addiw	s11,s11,-1
ffffffffc020645e:	0007851b          	sext.w	a0,a5
ffffffffc0206462:	fd61                	bnez	a0,ffffffffc020643a <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc0206464:	e7b058e3          	blez	s11,ffffffffc02062d4 <vprintfmt+0x3a>
ffffffffc0206468:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020646a:	85a6                	mv	a1,s1
ffffffffc020646c:	02000513          	li	a0,32
ffffffffc0206470:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0206472:	e60d81e3          	beqz	s11,ffffffffc02062d4 <vprintfmt+0x3a>
ffffffffc0206476:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0206478:	85a6                	mv	a1,s1
ffffffffc020647a:	02000513          	li	a0,32
ffffffffc020647e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0206480:	fe0d94e3          	bnez	s11,ffffffffc0206468 <vprintfmt+0x1ce>
ffffffffc0206484:	bd81                	j	ffffffffc02062d4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0206486:	4705                	li	a4,1
ffffffffc0206488:	008a8593          	addi	a1,s5,8
ffffffffc020648c:	01074463          	blt	a4,a6,ffffffffc0206494 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0206490:	12080063          	beqz	a6,ffffffffc02065b0 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0206494:	000ab603          	ld	a2,0(s5)
ffffffffc0206498:	46a9                	li	a3,10
ffffffffc020649a:	8aae                	mv	s5,a1
ffffffffc020649c:	b7bd                	j	ffffffffc020640a <vprintfmt+0x170>
ffffffffc020649e:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc02064a2:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02064a6:	846a                	mv	s0,s10
ffffffffc02064a8:	b5ad                	j	ffffffffc0206312 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc02064aa:	85a6                	mv	a1,s1
ffffffffc02064ac:	02500513          	li	a0,37
ffffffffc02064b0:	9902                	jalr	s2
            break;
ffffffffc02064b2:	b50d                	j	ffffffffc02062d4 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc02064b4:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc02064b8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02064bc:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02064be:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc02064c0:	e40dd9e3          	bgez	s11,ffffffffc0206312 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc02064c4:	8de6                	mv	s11,s9
ffffffffc02064c6:	5cfd                	li	s9,-1
ffffffffc02064c8:	b5a9                	j	ffffffffc0206312 <vprintfmt+0x78>
            goto reswitch;
ffffffffc02064ca:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc02064ce:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02064d2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02064d4:	bd3d                	j	ffffffffc0206312 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc02064d6:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc02064da:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02064de:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02064e0:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02064e4:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02064e8:	fcd56ce3          	bltu	a0,a3,ffffffffc02064c0 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc02064ec:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02064ee:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02064f2:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02064f6:	0196873b          	addw	a4,a3,s9
ffffffffc02064fa:	0017171b          	slliw	a4,a4,0x1
ffffffffc02064fe:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0206502:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0206506:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020650a:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc020650e:	fcd57fe3          	bleu	a3,a0,ffffffffc02064ec <vprintfmt+0x252>
ffffffffc0206512:	b77d                	j	ffffffffc02064c0 <vprintfmt+0x226>
            if (width < 0)
ffffffffc0206514:	fffdc693          	not	a3,s11
ffffffffc0206518:	96fd                	srai	a3,a3,0x3f
ffffffffc020651a:	00ddfdb3          	and	s11,s11,a3
ffffffffc020651e:	00144603          	lbu	a2,1(s0)
ffffffffc0206522:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206524:	846a                	mv	s0,s10
ffffffffc0206526:	b3f5                	j	ffffffffc0206312 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0206528:	85a6                	mv	a1,s1
ffffffffc020652a:	02500513          	li	a0,37
ffffffffc020652e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0206530:	fff44703          	lbu	a4,-1(s0)
ffffffffc0206534:	02500793          	li	a5,37
ffffffffc0206538:	8d22                	mv	s10,s0
ffffffffc020653a:	d8f70de3          	beq	a4,a5,ffffffffc02062d4 <vprintfmt+0x3a>
ffffffffc020653e:	02500713          	li	a4,37
ffffffffc0206542:	1d7d                	addi	s10,s10,-1
ffffffffc0206544:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0206548:	fee79de3          	bne	a5,a4,ffffffffc0206542 <vprintfmt+0x2a8>
ffffffffc020654c:	b361                	j	ffffffffc02062d4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020654e:	00003617          	auipc	a2,0x3
ffffffffc0206552:	80a60613          	addi	a2,a2,-2038 # ffffffffc0208d58 <error_string+0x1a8>
ffffffffc0206556:	85a6                	mv	a1,s1
ffffffffc0206558:	854a                	mv	a0,s2
ffffffffc020655a:	0ac000ef          	jal	ra,ffffffffc0206606 <printfmt>
ffffffffc020655e:	bb9d                	j	ffffffffc02062d4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0206560:	00002617          	auipc	a2,0x2
ffffffffc0206564:	7f060613          	addi	a2,a2,2032 # ffffffffc0208d50 <error_string+0x1a0>
            if (width > 0 && padc != '-') {
ffffffffc0206568:	00002417          	auipc	s0,0x2
ffffffffc020656c:	7e940413          	addi	s0,s0,2025 # ffffffffc0208d51 <error_string+0x1a1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206570:	8532                	mv	a0,a2
ffffffffc0206572:	85e6                	mv	a1,s9
ffffffffc0206574:	e032                	sd	a2,0(sp)
ffffffffc0206576:	e43e                	sd	a5,8(sp)
ffffffffc0206578:	c0dff0ef          	jal	ra,ffffffffc0206184 <strnlen>
ffffffffc020657c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0206580:	6602                	ld	a2,0(sp)
ffffffffc0206582:	01b05d63          	blez	s11,ffffffffc020659c <vprintfmt+0x302>
ffffffffc0206586:	67a2                	ld	a5,8(sp)
ffffffffc0206588:	2781                	sext.w	a5,a5
ffffffffc020658a:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc020658c:	6522                	ld	a0,8(sp)
ffffffffc020658e:	85a6                	mv	a1,s1
ffffffffc0206590:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206592:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0206594:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206596:	6602                	ld	a2,0(sp)
ffffffffc0206598:	fe0d9ae3          	bnez	s11,ffffffffc020658c <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020659c:	00064783          	lbu	a5,0(a2)
ffffffffc02065a0:	0007851b          	sext.w	a0,a5
ffffffffc02065a4:	e8051be3          	bnez	a0,ffffffffc020643a <vprintfmt+0x1a0>
ffffffffc02065a8:	b335                	j	ffffffffc02062d4 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc02065aa:	000aa403          	lw	s0,0(s5)
ffffffffc02065ae:	bbf1                	j	ffffffffc020638a <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc02065b0:	000ae603          	lwu	a2,0(s5)
ffffffffc02065b4:	46a9                	li	a3,10
ffffffffc02065b6:	8aae                	mv	s5,a1
ffffffffc02065b8:	bd89                	j	ffffffffc020640a <vprintfmt+0x170>
ffffffffc02065ba:	000ae603          	lwu	a2,0(s5)
ffffffffc02065be:	46c1                	li	a3,16
ffffffffc02065c0:	8aae                	mv	s5,a1
ffffffffc02065c2:	b5a1                	j	ffffffffc020640a <vprintfmt+0x170>
ffffffffc02065c4:	000ae603          	lwu	a2,0(s5)
ffffffffc02065c8:	46a1                	li	a3,8
ffffffffc02065ca:	8aae                	mv	s5,a1
ffffffffc02065cc:	bd3d                	j	ffffffffc020640a <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc02065ce:	9902                	jalr	s2
ffffffffc02065d0:	b559                	j	ffffffffc0206456 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc02065d2:	85a6                	mv	a1,s1
ffffffffc02065d4:	02d00513          	li	a0,45
ffffffffc02065d8:	e03e                	sd	a5,0(sp)
ffffffffc02065da:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02065dc:	8ace                	mv	s5,s3
ffffffffc02065de:	40800633          	neg	a2,s0
ffffffffc02065e2:	46a9                	li	a3,10
ffffffffc02065e4:	6782                	ld	a5,0(sp)
ffffffffc02065e6:	b515                	j	ffffffffc020640a <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02065e8:	01b05663          	blez	s11,ffffffffc02065f4 <vprintfmt+0x35a>
ffffffffc02065ec:	02d00693          	li	a3,45
ffffffffc02065f0:	f6d798e3          	bne	a5,a3,ffffffffc0206560 <vprintfmt+0x2c6>
ffffffffc02065f4:	00002417          	auipc	s0,0x2
ffffffffc02065f8:	75d40413          	addi	s0,s0,1885 # ffffffffc0208d51 <error_string+0x1a1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02065fc:	02800513          	li	a0,40
ffffffffc0206600:	02800793          	li	a5,40
ffffffffc0206604:	bd1d                	j	ffffffffc020643a <vprintfmt+0x1a0>

ffffffffc0206606 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206606:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0206608:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020660c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020660e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206610:	ec06                	sd	ra,24(sp)
ffffffffc0206612:	f83a                	sd	a4,48(sp)
ffffffffc0206614:	fc3e                	sd	a5,56(sp)
ffffffffc0206616:	e0c2                	sd	a6,64(sp)
ffffffffc0206618:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020661a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020661c:	c7fff0ef          	jal	ra,ffffffffc020629a <vprintfmt>
}
ffffffffc0206620:	60e2                	ld	ra,24(sp)
ffffffffc0206622:	6161                	addi	sp,sp,80
ffffffffc0206624:	8082                	ret

ffffffffc0206626 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0206626:	9e3707b7          	lui	a5,0x9e370
ffffffffc020662a:	2785                	addiw	a5,a5,1
ffffffffc020662c:	02f5053b          	mulw	a0,a0,a5
    return (hash >> (32 - bits));
ffffffffc0206630:	02000793          	li	a5,32
ffffffffc0206634:	40b785bb          	subw	a1,a5,a1
}
ffffffffc0206638:	00b5553b          	srlw	a0,a0,a1
ffffffffc020663c:	8082                	ret
