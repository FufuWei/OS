#include <unistd.h>
#include <proc.h>
#include <syscall.h>
#include <trap.h>
#include <stdio.h>
#include <pmm.h>
#include <assert.h>

static int
sys_exit(uint64_t arg[]) {
    int error_code = (int)arg[0];
    return do_exit(error_code);
}

static int
sys_fork(uint64_t arg[]) {
    struct trapframe *tf = current->tf;
    uintptr_t stack = tf->gpr.sp;
    return do_fork(0, stack, tf);
}

static int
sys_wait(uint64_t arg[]) {
    int pid = (int)arg[0];
    int *store = (int *)arg[1];
    return do_wait(pid, store);
}

static int
sys_exec(uint64_t arg[]) {
    const char *name = (const char *)arg[0];
    size_t len = (size_t)arg[1];
    unsigned char *binary = (unsigned char *)arg[2];
    size_t size = (size_t)arg[3];
    return do_execve(name, len, binary, size);
}

static int
sys_yield(uint64_t arg[]) {
    return do_yield();
}

static int
sys_kill(uint64_t arg[]) {
    int pid = (int)arg[0];
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
}

static int
sys_putc(uint64_t arg[]) {
    int c = (int)arg[0];
    cputchar(c);
    return 0;
}

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
/*
static int (*syscalls[])(uint64_t arg[]) = {
    [SYS_exit]              sys_exit,       // 系统调用号为SYS_exit时调用sys_exit函数
    [SYS_fork]              sys_fork,       // 系统调用号为SYS_fork时调用sys_fork函数
    [SYS_wait]              sys_wait,       // 系统调用号为SYS_wait时调用sys_wait函数
    [SYS_exec]              sys_exec,       // 系统调用号为SYS_exec时调用sys_exec函数
    [SYS_yield]             sys_yield,      // 系统调用号为SYS_yield时调用sys_yield函数
    [SYS_kill]              sys_kill,       // 系统调用号为SYS_kill时调用sys_kill函数
    [SYS_getpid]            sys_getpid,     // 系统调用号为SYS_getpid时调用sys_getpid函数
    [SYS_putc]              sys_putc,       // 系统调用号为SYS_putc时调用sys_putc函数
    [SYS_pgdir]             sys_pgdir,      // 系统调用号为SYS_pgdir时调用sys_pgdir函数
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void syscall(void) {
    struct trapframe *tf = current->tf;     // 获取当前进程的中断帧信息
    uint64_t arg[5];                        // 定义一个长度为5的参数数组
    int num = tf->gpr.a0;                    // 获取系统调用号
    if (num >= 0 && num < NUM_SYSCALLS) {    // 判断系统调用号是否合法
        if (syscalls[num] != NULL) {         // 判断系统调用对应的函数指针是否为空
            arg[0] = tf->gpr.a1;             // 获取系统调用的参数
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg); // 调用相应的系统调用函数，并传入参数，返回值存放在寄存器a0中
            return ;
        }
    }
    print_trapframe(tf);                     // 打印中断帧信息
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);  // 输出错误信息并终止程序
}
*/
static int (*syscalls[])(uint64_t arg[]) = {
    [SYS_exit]              sys_exit,
    [SYS_fork]              sys_fork,
    [SYS_wait]              sys_wait,
    [SYS_exec]              sys_exec,
    [SYS_yield]             sys_yield,
    [SYS_kill]              sys_kill,
    [SYS_getpid]            sys_getpid,
    [SYS_putc]              sys_putc,
    [SYS_pgdir]             sys_pgdir,
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
        if (syscalls[num] != NULL) {
            arg[0] = tf->gpr.a1;
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
            return ;
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}

