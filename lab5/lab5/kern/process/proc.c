#include <proc.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <trap.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <unistd.h>

/* ------------- process/thread mechanism design&implementation -------------
(an simplified Linux process/thread mechanism )
introduction:
  ucore implements a simple process/thread mechanism. process contains the independent memory sapce, at least one threads
for execution, the kernel data(for management), processor state (for context switch), files(in lab6), etc. ucore needs to
manage all these details efficiently. In ucore, a thread is just a special kind of process(share process's memory).
------------------------------
process state       :     meaning               -- reason
    PROC_UNINIT     :   uninitialized           -- alloc_proc
    PROC_SLEEPING   :   sleeping                -- try_free_pages, do_wait, do_sleep
    PROC_RUNNABLE   :   runnable(maybe running) -- proc_init, wakeup_proc, 
    PROC_ZOMBIE     :   almost dead             -- do_exit

-----------------------------
process state changing:
                                            
  alloc_proc                                 RUNNING
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+ 
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  + 
                                           -----------------------wakeup_proc----------------------------------
-----------------------------
process relations
parent:           proc->parent  (proc is children)
children:         proc->cptr    (proc is parent)
older sibling:    proc->optr    (proc is younger sibling)
younger sibling:  proc->yptr    (proc is older sibling)
-----------------------------
related syscall for process:
SYS_exit        : process exit,                           -->do_exit
SYS_fork        : create child process, dup mm            -->do_fork-->wakeup_proc
SYS_wait        : wait process                            -->
SYS_exec        : after fork, process execute a program   -->load a program and refresh the mm
SYS_clone       : create child thread                     -->do_fork-->wakeup_proc
SYS_yield       : process flag itself need resecheduling, -- proc->need_sched=1, then scheduler will rescheule this process
SYS_sleep       : process sleep                           -->do_sleep 
SYS_kill        : kill process                            -->do_kill-->proc->flags |= PF_EXITING
                                                                 -->wakeup_proc-->do_wait-->do_exit   
SYS_getpid      : get the process's pid

*/

// the process set's list
list_entry_t proc_list;

#define HASH_SHIFT          10
#define HASH_LIST_SIZE      (1 << HASH_SHIFT)
#define pid_hashfn(x)       (hash32(x, HASH_SHIFT))

// has list for process set based on pid
static list_entry_t hash_list[HASH_LIST_SIZE];

// idle proc
struct proc_struct *idleproc = NULL;
// init proc
struct proc_struct *initproc = NULL;
// current proc
struct proc_struct *current = NULL;

static int nr_process = 0;

void kernel_thread_entry(void);
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

/*
(alloc_proc) (wakeup_proc)(proc_run)(do_exit)(do_wait) 
---------------> NEW ----------------> READY
                                         |
                                         >
EXIT <---------- ZOMBIE <-------------- RUNNING

/*

alloc_proc()(状态:PROC_UNINIT) 
↓
proc_init()(状态:PROC_RUNNABLE,但不一定在run) 
↓
wakeup_proc()(状态：PROC_RUNNABLE，而且可以run)
↓
proc_run()(状态：开始run)
↓
在遇到类似do_yield（自愿让出运行权）、遇到一个IRQ_S_TIMER（当前进程时间片用完了）、理论上来说应该在写文件等慢操作时也这样但这里还没有文件系统所以没写的慢操作等情况下，状态还是就绪的PROC_RUNNABLE但是不能实际的run了。
↓
如果我是个父进程，那么在等待子进程结束前一直处于PROC_SLEEPING。而且我sleep的目的是WT_CHILD。
↓
do_exit()(状态：PROC_ZOMBIE)
↓
这个流程图的进程的父亲调用do_wait(状态：结束)
*/
// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
    //LAB4:EXERCISE1 YOUR CODE
    /*
     * below fields in proc_struct need to be initialized
     *       enum proc_state state;                      // Process state
     *       int pid;                                    // Process ID
     *       int runs;                                   // the running times of Proces
     *       uintptr_t kstack;                           // Process kernel stack
     *       volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
     *       struct proc_struct *parent;                 // the parent process
     *       struct mm_struct *mm;                       // Process's memory management field
     *       struct context context;                     // Switch here to run process
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */

    // 检查idleproc初始化的条件语句已经指明了该如何设置这些值
    proc->state = PROC_UNINIT;                           // 此时未分配该PCB对应的资源，故状态为初始态
    proc->pid = -1;                                      // 与state对应，表示无法运行
    proc->runs = 0;                                      // 分配阶段故运行次数为0
    proc->kstack = 0;                                    // 内核栈暂未分配
    proc->need_resched = 0;                              // 不用调度其他进程、即CPU资源不分配
    proc->parent = NULL;                                 // 当前无父进程
    proc->mm = NULL;                                     // 当前未分配内存
    memset(&(proc->context), 0, sizeof(struct context)); // 上下文置零
    proc->tf = NULL;                                     // 当前无中断帧
    proc->cr3 = boot_cr3;                                // 内核线程同属于一个内核大进程，共享内核空间，故页表相同
    proc->flags = 0;                                     // 当前暂无
    memset(&(proc->name), 0, PROC_NAME_LEN);             // 当前暂无

     //LAB5 YOUR CODE : (update LAB4 steps)
     /*
     * below fields(add in LAB5) in proc_struct need to be initialized  
     *       uint32_t wait_state;                        // waiting state
     *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
     * process relations
parent:           proc->parent  (proc is children)
children:         proc->cptr    (proc is parent)
older sibling:    proc->optr    (proc is younger sibling)
younger sibling:  proc->yptr    (proc is older sibling)

     */
    proc->wait_state = 0;
    proc->cptr = NULL;
    proc->yptr = NULL;
    proc->optr = NULL;
    }
    return proc;
}

// set_proc_name - set the name of proc
char *
set_proc_name(struct proc_struct *proc, const char *name) {
    memset(proc->name, 0, sizeof(proc->name));
    return memcpy(proc->name, name, PROC_NAME_LEN);
}

// get_proc_name - get the name of proc
char *
get_proc_name(struct proc_struct *proc) {
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
    return memcpy(name, proc->name, PROC_NAME_LEN);
}

// set_links - set the relation links of process
static void
set_links(struct proc_struct *proc) {
    list_add(&proc_list, &(proc->list_link));
    proc->yptr = NULL;
    if ((proc->optr = proc->parent->cptr) != NULL) {
        proc->optr->yptr = proc;
    }
    proc->parent->cptr = proc;
    nr_process ++;
}

// remove_links - clean the relation links of process
static void
remove_links(struct proc_struct *proc) {
    list_del(&(proc->list_link));
    if (proc->optr != NULL) {
        proc->optr->yptr = proc->yptr;
    }
    if (proc->yptr != NULL) {
        proc->yptr->optr = proc->optr;
    }
    else {
       proc->parent->cptr = proc->optr;
    }
    nr_process --;
}

// get_pid - alloc a unique pid for process
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++ last_pid >= MAX_PID) {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe) {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list) {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid) {
                if (++ last_pid >= next_safe) {
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}

// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
/*proc_run做以下三件事：
a. 设置userproc的栈指针esp为userproc->kstack + 2 * 4096，即指向userproc申请到的2页栈空间的栈顶。
b. 加载userproc的页目录表。用户态的页目录表与内核态的页目录表不同，因此要重新加载页目录表。
c. 切换进程上下文，然后跳转到forkret。forkret函数直接调用forkrets函数，forkrets将栈指针指向userproc->tf的地址，然后跳到__trapret。
*/
void
proc_run(struct proc_struct *proc) {
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */

       bool x;
        local_intr_save(x);
        {
            struct proc_struct *temp_proc = current;
            // 当前进程设为被选中进程
            current = proc;
            // 修改CR3寄存器的值，PDT
            //The CR3 register is used to switch between different page directory tables when a context switch occurs between processes.
            lcr3(proc->cr3);
            // 保存原进程环境，加载现进程环境
            switch_to(&(temp_proc->context), &(current->context));
        }
        local_intr_restore(x);

    }
}

// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
}

// hash_proc - add proc into proc hash_list
static void
hash_proc(struct proc_struct *proc) {
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}

// unhash_proc - delete proc from proc hash_list
static void
unhash_proc(struct proc_struct *proc) {
    list_del(&(proc->hash_link));
}

// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list) {
            struct proc_struct *proc = le2proc(le, hash_link);
            if (proc->pid == pid) {
                return proc;
            }
        }
    }
    return NULL;
}

// kernel_thread - create a kernel thread using "fn" function
// NOTE: the contents of temp trapframe tf will be copied to 
//       proc->tf in do_fork-->copy_thread function
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));
    tf.gpr.s0 = (uintptr_t)fn;
    tf.gpr.s1 = (uintptr_t)arg;
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
    tf.epc = (uintptr_t)kernel_thread_entry;
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
}

// setup_kstack - alloc pages with size KSTACKPAGE as process kernel stack
static int
setup_kstack(struct proc_struct *proc) {
    struct Page *page = alloc_pages(KSTACKPAGE);
    if (page != NULL) {
        proc->kstack = (uintptr_t)page2kva(page);
        return 0;
    }
    return -E_NO_MEM;
}

// put_kstack - free the memory space of process kernel stack
static void
put_kstack(struct proc_struct *proc) {
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
}

// setup_pgdir - alloc one page as PDT
static int
setup_pgdir(struct mm_struct *mm) {
    struct Page *page;
    if ((page = alloc_page()) == NULL) {
        return -E_NO_MEM;
    }
    pde_t *pgdir = page2kva(page);
    memcpy(pgdir, boot_pgdir, PGSIZE);

    mm->pgdir = pgdir;
    return 0;
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm) {
    free_page(kva2page(mm->pgdir));
}


//实现了进程的内存复制或共享功能。根据传入的clone_flags参数，如果是CLONE_VM，则表示共享内存，即新进程和当前进程共享同一个内存空间；
//否则表示复制内存，即新进程拥有一个独立的内存空间。
// copy_mm - process "proc" duplicate OR share process "current"'s mm according clone_flags
//         - if clone_flags & CLONE_VM, then "share" ; else "duplicate"
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc) {
    struct mm_struct *mm, *oldmm = current->mm;

    /* current is a kernel thread */
    //判断当前进程是否是内核线程，如果是，则直接返回
    if (oldmm == NULL) {
        return 0;
    }
    //如果clone_flags & CLONE_VM为真，则说明要共享内存，将新进程的mm指针指向当前进程的mm，然后增加mm的引用计数。
    if (clone_flags & CLONE_VM) {
        mm = oldmm;
        goto good_mm;
    }

    int ret = -E_NO_MEM;
    //如果clone_flags & CLONE_VM为假，则说明要复制内存，需要创建一个新的mm结构，并为其设置页目录。
    //然后锁定当前进程的mm，复制当前进程的mmap区域到新的mm中，解锁当前进程的mm。
    //如果复制mmap区域失败，则释放新的mm并返回错误。
    if ((mm = mm_create()) == NULL) {
        goto bad_mm;
    }
    if (setup_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;
    }
    lock_mm(oldmm);
    {
        ret = dup_mmap(mm, oldmm);
    }
    unlock_mm(oldmm);

    if (ret != 0) {
        goto bad_dup_cleanup_mmap;
    }

good_mm:
    mm_count_inc(mm);
    proc->mm = mm;
    proc->cr3 = PADDR(mm->pgdir);
    return 0;
bad_dup_cleanup_mmap:
    exit_mmap(mm);
    put_pgdir(mm);
bad_pgdir_cleanup_mm:
    mm_destroy(mm);
bad_mm:
    return ret;
}

// copy_thread - setup the trapframe on the  process's kernel stack top and
//             - setup the kernel entry point and stack of process
//// copy_thread - 设置进程的内核栈顶部的中断帧
// - 设置进程的内核入口点和栈
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
    // 将中断帧的指针指向进程的内核栈顶部
    //
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
    *(proc->tf) = *tf;

    // Set a0 to 0 so a child process knows it's just forked
    //将a0设置为0，这样子进程就知道自己刚刚被fork了
    proc->tf->gpr.a0 = 0;
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
    //设置了进程上下文的返回地址（return address），
    //这里将返回地址设置为forkret函数的地址，该函数在进程结束或返回时会执行一些清理工作。
    proc->context.ra = (uintptr_t)forkret;

    proc->context.sp = (uintptr_t)(proc->tf);
}

/* do_fork -     parent process for a new child process
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 * clone_flags：用于指导如何克隆子进程的标志。这些标志可以指定是否共享父进程的地址空间、文件描述符等资源。
stack：父进程的用户栈指针。如果stack等于0，表示要创建一个内核线程。
tf：包含陷阱帧信息的结构体，将被复制到子进程的proc->tf中。
 */
/*
fork：执行完毕后，如果创建新进程成功，则出现两个进程，一个是子进程，一个是父进程。在子进
程中，fork函数返回0，在父进程中，fork返回新创建子进程的进程ID。我们可以通过fork返回的值来判
断当前进程是子进程还是父进程
// 调用过程：fork->SYS_fork->do_fork + wakeup_proc
// wakeup_proc 函数主要是将进程的状态设置为等待。
// do_fork()
1、分配并初始化进程控制块(alloc_proc 函数);
2、分配并初始化内核栈(setup_stack 函数);
3、根据 clone_flag标志复制或共享进程内存管理结构(copy_mm 函数);
4、设置进程在内核(将来也包括用户态)正常运行和调度所需的中断帧和执行上下文(copy_thread 函数);
5、把设置好的进程控制块放入hash_list 和 proc_list 两个全局进程链表中;
6、自此,进程已经准备好执行了,把进程状态设置为“就绪”态;
7、设置返回码为子进程的 id 号
*/
/*
do_fork函数调用copy_mm函数实现进程mm的复制，后者根据clone_flags & CLONE_VM的取值调用了dup_mmap函数。

dup_mmap函数在两个进程之间复制内存映射关系。具体来说，该函数的两个参数分别表示目标进程和源进程的内存管理结构mm。
然后通过循环迭代，每次创建一个新的内存映射区域（vma），然后将其插入到目标进程的mm中，之后调用copy_range函数将源进程的内存映射区域的内容复制到目标进程中。


*/
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    //LAB4:EXERCISE2 YOUR CODE
    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

    //    1. call alloc_proc to allocate a proc_struct
    //    2. call setup_kstack to allocate a kernel stack for child process
    //    3. call copy_mm to dup OR share mm according clone_flag
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid

    // 分配并初始化PCB
    if ((proc = alloc_proc()) == NULL) {
        cprintf("cannot alloc idleproc.\n");
        goto fork_out;
    }
    // proc->pid = get_pid();
    // 这个initproc的父进程闲逛进程？
    proc->parent = current;
    assert(current->wait_state == 0);

    // 分配并初始化内核栈
    if (setup_kstack(proc) != 0) {
        cprintf("cannot alloc kernel stack for initproc.\n");
        goto bad_fork_cleanup_proc;
    }

    // 根据clone_flags决定是复制还是共享内存管理系统
    // 注意传参的时候，clone_flags中已经包含了CLONE_VM
    if(copy_mm(clone_flags, proc) != 0) {
        cprintf("cannot duplicate or share mm.\n");
        goto bad_fork_cleanup_kstack;
    }

    // 设置进程中断帧和上下文
    copy_thread(proc, stack, tf);

    // 把设置好的进程加入链表
    /*
    hash_proc(proc);
    list_add(&proc_list, &proc->list_link);
    nr_process++;
    */
    bool intr_flag;
    //使能中断
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
        hash_proc(proc);
        set_links(proc);
    }
    local_intr_restore(intr_flag);

    
    // 将新建的进程设为就绪态
    //initproc->state = PROC_RUNNABLE;
    wakeup_proc(proc);

    
    // 将返回值设为线程id
    ret = proc->pid;

    //LAB5 YOUR CODE : (update LAB4 steps)
    //TIPS: you should modify your written code in lab4(step1 and step5), not add more code.
   /* Some Functions
    *    set_links:  set the relation links of process.  ALSO SEE: remove_links:  lean the relation links of process 
    将子进程的父进程设置为当前进程，并确保当前进程的等待状态为0
    *    -------------------
    *    update step 1: set child proc's parent to current process, make sure current process's wait_state is 0
    *    update step 5: insert proc_struct into hash_list && proc_list, set the relation links of process
    * 将proc_struct插入到hash_list和proc_list中，并设置进程的关系链接
    */
 
fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}

// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
/*
会把一个退出码error_code传递给ucore，ucore通过执行内核函数do_exit来完成对当前进程的
退出处理，主要工作简单地说就是回收当前进程所占的大部分内存资源，并通知父进程完成最后的回收
工作。
// 调用过程： SYS_exit->exit
1、先判断是否是用户进程，如果是，则开始回收此用户进程所占用的用户态虚拟内存空间;（具体的回收过程
不作详细说明）
2、设置当前进程的中hi性状态为PROC_ZOMBIE，然后设置当前进程的退出码为error_code。表明此时这个
进程已经无法再被调度了，只能等待父进程来完成最后的回收工作（主要是回收该子进程的内核栈、进程控制
块）
3、如果当前父进程已经处于等待子进程的状态，即父进程的wait_state被置为WT_CHILD，则此时就可以唤
醒父进程，让父进程来帮子进程完成最后的资源回收工作。
4、如果当前进程还有子进程,则需要把这些子进程的父进程指针设置为内核线程init,且各个子进程指针需要
插入到init的子进程链表中。如果某个子进程的执行状态是 PROC_ZOMBIE,则需要唤醒 init来完成对此子
进程的最后回收工作。
5、执行schedule()调度函数，选择新的进程执行。
*/
int
do_exit(int error_code) {
    // 检查当前进程是否为idleproc或initproc，如果是，发出panic
    // 因此，正常情况下其不应该是上述二者
    if (current == idleproc) {
        panic("idleproc exit.\n");
    }
    if (current == initproc) {
        panic("initproc exit.\n");
    }
    // 获取当前进程的内存管理结构mm
    struct mm_struct *mm = current->mm;
    // 如果mm不为空，说明是用户进程
    if (mm != NULL) {
        // 切换到内核页表，确保接下来的操作在内核空间执行
        lcr3(boot_cr3);
        // 如果mm引用计数减到0，说明没有其他进程共享此mm
        if (mm_count_dec(mm) == 0) {
            // 释放用户虚拟内存空间相关的资源
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        // 将当前进程的mm设置为NULL，表示资源已经释放
        current->mm = NULL;
    }
    // 设置进程状态为PROC_ZOMBIE，表示进程已退出
    current->state = PROC_ZOMBIE;
    current->exit_code = error_code;
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        // 获取当前进程的父进程
        proc = current->parent;
        // 如果父进程处于等待子进程状态，则唤醒父进程
        if (proc->wait_state == WT_CHILD) {
            wakeup_proc(proc);
        }
        // 当前进程将退出，所以要对它的所有子进程作处理
        // 遍历当前进程的所有子进程
        while (current->cptr != NULL) {
            proc = current->cptr;
            current->cptr = proc->optr;
            // 设置子进程的父进程为initproc，并加入initproc的子进程链表
            proc->yptr = NULL;
            if ((proc->optr = initproc->cptr) != NULL) {
                initproc->cptr->yptr = proc;
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            // 如果子进程也处于退出状态，唤醒initproc
            if (proc->state == PROC_ZOMBIE) {
                if (initproc->wait_state == WT_CHILD) {
                    wakeup_proc(initproc);
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    // 调用调度器，选择新的进程执行
    schedule();
    panic("do_exit will not return!! %d.\n", current->pid);
}

/* load_icode - load the content of binary program(ELF format) as the new content of current process
 * @binary:  the memory addr of the content of binary program
 * @size:  the size of the content of binary program
 * load_icode - 将二进制程序（ELF格式）的内容加载到当前进程的新内容中
@binary：二进制程序内容的内存地址
@size：二进制程序内容的大小

调用mm_create函数来申请进程的内存管理数据结构mm所需内存空间，并对mm进行初始化。

调用setup_pgdir来申请一个页目录表所需的一个页大小的内存空间，并把描述ucore内核虚空间映
射的内核页表（boot_pgdir所指）的内容拷贝到此新目录表中，最后mm->pgdir指向此页目录表，
这就是进程新的页目录表了，且能够正确映射内核。

根据应用程序执行码的起始位置来解析此ELF格式的执行程序，并调用mm_map函数根据ELF格式
的执行程序说明的各个段（代码段、数据段、BSS段等）的起始位置和大小建立对应的vma结构，
并把vma插入到mm结构中，从而表明了用户进程的合法用户态虚拟地址空间。

调用根据执行程序各个段的大小分配物理内存空间，并根据执行程序各个段的起始位置确定虚拟地
址，并在页表中建立好物理地址和虚拟地址的映射关系，然后把执行程序各个段的内容拷贝到相应
的内核虚拟地址中，至此应用程序执行码和数据已经根据编译时设定地址放置到虚拟内存中了；

需要给用户进程设置用户栈，为此调用mm_mmap函数建立用户栈的vma结构，明确用户栈的位
置在用户虚空间的顶端，大小为256个页，即1MB，并分配一定数量的物理内存且建立好栈的虚地
址<–>物理地址映射关系；

至此,进程内的内存管理vma和mm数据结构已经建立完成，于是把mm->pgdir赋值到cr3寄存器
中，即更新了用户进程的虚拟内存空间，此时的initproc已经被hello的代码和数据覆盖，成为了第
一个用户进程，但此时这个用户进程的执行现场还没建立好；

先清空进程的中断帧，再重新设置进程的中断帧，使得在执行中断返回指令“iret”后，能够让CPU转
到用户态特权级，并回到用户态内存空间，使用用户态的代码段、数据段和堆栈，且能够跳转到用
户进程的第一条指令执行，并确保在用户态能够响应中断
 */
//load_icode加载应用程序的各个program section到新申请的内存上，为BSS section分配内存并初始化为全0，分配用户栈内存空间。
static int
load_icode(unsigned char *binary, size_t size) {
    //1、检查当前进程的内存管理数据结构（mm）是否为空，如果不为空则报错。
    if (current->mm != NULL) {
        panic("load_icode: current->mm must be empty.\n");
    }

    int ret = -E_NO_MEM;
    //创建一个新的mm结构并进行初始化。
    struct mm_struct *mm;
    //(1) create a new mm for current process
    // 申请用户进程内存管理数据结构mm所需的内存空间，并对其进行初始化
    if ((mm = mm_create()) == NULL) {
        goto bad_mm;
    }
    //(2) create a new PDT, and mm->pgdir= kernel virtual addr of PDT
    // 创建进程所需页目录表，该页目录表内容为内核虚拟空间映射的内核页表，
    //地址赋给mm->pgdir
    if (setup_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;
    }
    //(3) copy TEXT/DATA section, build BSS parts in binary to memory space of process
    //将二进制文件的TEXT/DATA部分复制到进程的内存空间中，并构建BSS部分。
    struct Page *page;
    //(3.1) get the file header of the bianry program (ELF format)
    //获取二进制文件的文件头（ELF格式）和程序段头（ELF格式）的入口地址
    struct elfhdr *elf = (struct elfhdr *)binary;
    //(3.2) get the entry of the program section headers of the bianry program (ELF format)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
    //(3.3) This program is valid?
    //检查二进制文件是否合法
    if (elf->e_magic != ELF_MAGIC) {
        ret = -E_INVAL_ELF;
        goto bad_elf_cleanup_pgdir;
    }

    uint32_t vm_flags, perm;
    struct proghdr *ph_end = ph + elf->e_phnum;
    //遍历每个程序段头
    for (; ph < ph_end; ph ++) {          
    //(3.4) find every program section headers
    //a. 如果程序段类型不是ELF_PT_LOAD，则跳过。
        if (ph->p_type != ELF_PT_LOAD) {     // 程序段需要满足一定类型
            continue ;
        }
        //b. 如果文件大小大于内存大小，则报错
        if (ph->p_filesz > ph->p_memsz) {    // 似乎是文件大小和一个设定值的比较
            ret = -E_INVAL_ELF;
            goto bad_cleanup_mmap;
        }
        //c. 如果文件大小为0，则继续。
        if (ph->p_filesz == 0) {
            // continue ;
        }
    //(3.5) call mm_map fun to setup the new vma ( ph->p_va, ph->p_memsz)
        // 设置该程序段对应的vma的权限标志位
        vm_flags = 0, perm = PTE_U | PTE_V;
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
        // modify the perm bits here for RISC-V
        if (vm_flags & VM_READ) perm |= PTE_R;
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
        if (vm_flags & VM_EXEC) perm |= PTE_X;
        //d. 调用mm_map函数设置新的虚拟内存区域（vma）（ph->p_va, ph->p_memsz）。
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {   // 似乎是根据上述vm_flags将该程序段映射到当前进程的虚拟地址空间中？？？好像又不是
            goto bad_cleanup_mmap;
        }
        unsigned char *from = binary + ph->p_offset;
        size_t off, size;
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);

        ret = -E_NO_MEM;

     //(3.6) alloc memory, and  copy the contents of every program section (from, from+end) to process's memory (la, la+end)
        end = ph->p_va + ph->p_filesz;
     //(3.6.1) copy TEXT/DATA section of bianry program
        while (start < end) {
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {   // 根据进程页目录表给该程序段分配一个页
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la) {   // 当前页超出程序段边界
                size -= la - end;
            }
            // 从from指向的二进制文件中复制size大小数据到进程内存页中，起始位置为page2kva(page) + off
            memcpy(page2kva(page) + off, from, size);
            start += size, from += size;
        }
//未初始化的全局静态变量和静态数组所占用的内存空间。BSS段在程序加载时会被清零，因此不需要将其数据从可执行文件中复制到内存中，而是直接在内存中分配相应大小的空间。BSS段通常位于程序的数据段的末尾。
      //(3.6.2) build BSS section of binary program
        end = ph->p_va + ph->p_memsz;
        if (start < la) {
            /* ph->p_memsz == ph->p_filesz */
            if (start == end) {
                continue ;
            }
            off = start + PGSIZE - la, size = PGSIZE - off;
            if (end < la) {
                size -= la - end;
            }
            memset(page2kva(page) + off, 0, size);
            start += size;
            assert((end < la && start == end) || (end >= la && start == la));
        }
        while (start < end) {
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la) {
                size -= la - end;
            }
            memset(page2kva(page) + off, 0, size);
            start += size;
        }
    }
    //(4) build user stack memory
    vm_flags = VM_READ | VM_WRITE | VM_STACK;
    // 创建用户栈的vma结构，用户栈位于用户虚空间的顶端
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
        goto bad_cleanup_mmap;
    }
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
    
    //(5) set current process's mm, sr3, and set CR3 reg = physical addr of Page Directory
    // 执行下列代码后，initproc已经被hello的代码和数据覆盖，成为了第一个用户进程，但该用户进程的执行现场此时还未建立好
    mm_count_inc(mm);
    current->mm = mm;
    current->cr3 = PADDR(mm->pgdir);
    lcr3(PADDR(mm->pgdir));

    //(6) setup trapframe for user environment
    struct trapframe *tf = current->tf;
    // Keep sstatus
    uintptr_t sstatus = tf->status;
    memset(tf, 0, sizeof(struct trapframe));
    /* LAB5:EXERCISE1 2110957
     * should set tf->gpr.sp, tf->epc, tf->status
     * NOTICE: If we set trapframe correctly, then the user level process can return to USER MODE from kernel. So
     *          tf->gpr.sp should be user stack top (the value of sp)
     *          tf->epc should be entry point of user program (the value of sepc)
     *          tf->status should be appropriate for user program (the value of sstatus)
     *          hint: check meaning of SPP, SPIE in SSTATUS, use them by SSTATUS_SPP, SSTATUS_SPIE(defined in risv.h)
     *  应该设置tf->gpr.sp，tf->epc，tf->status
* 注意：如果我们正确设置了陷阱帧，那么用户级进程可以从内核返回到用户模式。所以
* tf->gpr.sp 应该是用户栈顶（即sp的值）
* tf->epc 应该是用户程序的入口点（即sepc的值）
* tf->status 应该适合用户程序（即sstatus的值）
* 提示：检查SSTATUS中SPP，SPIE的含义，可以通过SSTATUS_SPP，SSTATUS_SPIE（在risv.h中定义）使用它们
1、SPP（Supervisor Previous Privilege）：该位表示之前的特权级别。
当SPP为0时，表示之前处于用户态（User Mode），当SPP为1时，表示之前处于超级用户态（Supervisor Mode）。

2、SPIE（Supervisor Previous Interrupt Enable）：该位表示之前的中断使能状态。
当SPIE为0时，表示之前的中断被禁用，当SPIE为1时，表示之前的中断被使能。

这两个位字段在设置SSTATUS寄存器时非常重要，特别是在设置Trapframe结构体时。通过正确设置Trapframe结构体中的SPP和SPIE字段，
可以确保用户级进程从内核返回到用户模式时，特权级别和中断使能状态正确恢复，从而确保进程的正常执行。

     */

    //将 tf 结构中的通用寄存器（gpr）中的栈指针（sp）设置为 USTACKTOP。这表明将用户栈的顶部
//地址赋给用户进程的栈指针。
    tf->gpr.sp = USTACKTOP;
    //将 tf 结构中的程序计数器（epc）设置为 ELF 文件的入口点地址。这是用户程序的启动地址，将控
//制权转移到用户程序的执行起点
    tf->epc = elf->e_entry;
    //将 tf 结构中的状态寄存器（status）设置为给定的 sstatus，但清除了 SPP（Supervisor Previous
//Privilege）和 SPIE（Supervisor Previous Interrupt Enable）标志。这两个标志通常用于处理从
//内核返回用户模式时的特权级别和中断使能状态。
 tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
/*tf->gpr.sp = USTACKTOP;：在用户模式下，栈通常从高地址向低地址增长，而 USTACKTOP 是用户栈的顶部地址，
    因此将 tf->gpr.sp 设置为 USTACKTOP 可以确保用户程序在正确的栈空间中运行。
    tf->epc = elf->e_entry;：elf->e_entry 是可执行文件的入口地址，也就是用户程序的起始地址。
    通过将该地址赋值给 tf->epc，在执行 mret 指令后，处理器将会跳转到用户程序的入口开始执行。
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP & ~SSTATUS_SPIE);：sstatus 寄存器中的 SPP 位表示当前特权级别，SPIE 位表示之前的特权级别是否启用中断。
    通过清除这两个位，可以确保在切换到用户模式时，特权级别被正确设置为用户模式，并且中断被禁用，以便用户程序可以在预期的环境中执行。
    */
    ret = 0;
out:
    return ret;
bad_cleanup_mmap:
    exit_mmap(mm);
bad_elf_cleanup_pgdir:
    put_pgdir(mm);
bad_pgdir_cleanup_mm:
    mm_destroy(mm);
bad_mm:
    goto out;
}

// do_execve - call exit_mmap(mm)&put_pgdir(mm) to reclaim memory space of current process
//           - call load_icode to setup new memory space accroding binary prog.
// do_execve - 调用exit_mmap(mm)和put_pgdir(mm)来回收当前进程的内存空间
// - 调用load_icode根据二进制程序设置新的内存空间。
//在 do_execve 函数中，先获取当前进程的内存管理结构，将当前进程的页表换用内核页表之后，
//调用 load_icode 函数给用户进程建立一个能够让用户进程正常运行的用户环境，

/*
execve：完成用户进程的创建工作。首先为加载新的执行码做好用户态内存空间清空准备。接下来的
一步是加载应用程序执行码到当前进程的新创建的用户态虚拟空间中。
// 调用过程： SYS_exec->do_execve
1、首先为加载新的执行码做好用户态内存空间清空准备。如果mm不为NULL，则设置页表为内核空间页表，且
进一步判断mm的引用计数减1后是否为0，如果为0，则表明没有进程再需要此进程所占用的内存空间，为此将
根据mm中的记录，释放进程所占用户空间内存和进程页表本身所占空间。最后把当前进程的mm内存管理指针为
空。
2、接下来是加载应用程序执行码到当前进程的新创建的用户态虚拟空间中。之后就是调用load_icode从而使
之准备好执行。
用户态程序调用sys_exec()系统调用，通过syscall进入内核态。
内核态处理sys_exec()系统调用，调用do_execve()函数加载新的程序，但由于当前是在S mode
下，无法直接进行上下文切换。因此使用ebreak产生断点中断，转发到syscall()函数，在该函数 中
完成上下文切换，最终返回到用户态。
*/

//do_wait函数确认存在RUNNABLE的子进程后，调用schedule函数
//schedule函数通过调用proc_run来运行新线程
/*forkret函数直接调用forkrets函数，forkrets将栈指针指向userproc->tf的地址，然后跳到__trapret。
__trapret函数将userproc->tf的内容pop给相应寄存器，然后通过iret指令，跳转到userproc->tf.epc指向的函数，即kernel_thread_entry。
kernel_thread_entry先将edx保存的输入参数压栈，然后跳转到user_main。
user_main打印userproc的pid和name信息，然后调用kernel_execve
load_icode

do_execve检查虚拟内存空间的合法性，释放虚拟内存空间，加载应用程序，创建新的mm结构和页目录表。
do_execve调用load_icode函数，load_icode加载应用程序的各个program section到新申请的内存上，为BSS section分配内存并初始化为全0，分配用户栈内存空间。
*/
// 主要目的在于清理原来进程的内存空间，为新进程执行准备好空间和资源
int
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
    //1、首先，检查当前进程的内存管理结构（mm）是否为NULL。如果不为NULL，表示当前进程是一个用户进程，需要释放该进程所占用的内存空间
    struct mm_struct *mm = current->mm;
    
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
        return -E_INVAL;
    }
    //如果名称的长度超过了限制（PROC_NAME_LEN），则截断名称长度。
    if (len > PROC_NAME_LEN) {
        len = PROC_NAME_LEN;
    }
    //创建一个本地变量local_name，用来保存名称，并将其初始化为0，并将传入的名称拷贝到local_name中。
    char local_name[PROC_NAME_LEN + 1];
    memset(local_name, 0, sizeof(local_name));
    memcpy(local_name, name, len);

    //如果当前进程的内存管理结构不为NULL，说明当前进程是一个用户进程，需要释放该进程所占用的内存空间。
    //首先切换到内核的页目录表（lcr3(boot_cr3)），然后判断当前进程的内存引用计数是否为0，如果为0，说明该进程是唯一引用该内存管理结构的进程，需要释放该内存管理结构所占用的内存空间，
    //并将当前进程的内存管理结构设置为NULL。

    // 如果当前进程具有内存管理结构体mm，则进行清理操作
    if (mm != NULL) {          // 此时的当前进程initproc为内核线程，故mm为NULL
        cputs("mm != NULL");
        lcr3(boot_cr3);
        // 如果当前进程的内存管理结构引用计数减为0，则清空相关内存管理区域和页表
        if (mm_count_dec(mm) == 0) {   // 条件成立则说明该mm仅被当前进程引用，故表明此后无进程需要此进程所占用的内存空间
            exit_mmap(mm);     // 清空内存管理部分和对应页表
            put_pgdir(mm);     // 清空页表
            mm_destroy(mm);    // 清空页表
        }
        // 将当前进程的内存管理结构指针设为NULL，表示没有有效的内存管理结构
        current->mm = NULL;
    }
    //调用load_icode函数将应用程序的执行码加载到当前进程的用户虚拟内存空间中。如果加载失败，则跳转到execve_exit标签处，执行do_exit函数并打印错误信息。
    
    // 加载应用程序执行码到当前进程新创建的用户虚拟内存空间中
    int ret;
    // 加载新的可执行程序并建立新的内存映射关系
    if ((ret = load_icode(binary, size)) != 0) {
        goto execve_exit;
    }
    //调用set_proc_name函数设置当前进程的名称，并返回执行成功
    set_proc_name(current, local_name);
    return 0;

execve_exit:
    do_exit(ret); // 执行出错，退出当前进程，并传递错误码ret
    panic("already exit: %e.\n", ret);
}

// do_yield - ask the scheduler to reschedule
int
do_yield(void) {
    current->need_resched = 1;
    return 0;
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
// do_wait - 等待一个或任意一个处于PROC_ZOMBIE状态的子进程，并释放内核栈的内存空间
// - 释放该子进程的proc结构体。
// 注意：只有在do_wait函数之后，子进程的所有资源才会被释放。
/*
④wait：等待任意子进程的结束通知。wait_pid函数等待进程id号为pid的子进程结束通知。这两个函数
最终访问sys_wait系统调用接口让ucore来完成对子进程的最后回收工作。
// 调用过程： SYS_wait->do_wait
1、 如果 pid!=0，表示只找一个进程 id 号为 pid 的退出状态的子进程，否则找任意一个处于退出状态
的子进程;
2、 如果此子进程的执行状态不为PROC_ZOMBIE，表明此子进程还没有退出，则当前进程设置执行状态为
PROC_SLEEPING（睡眠），睡眠原因为WT_CHILD(即等待子进程退出)，调用schedule()函数选择新的进
程执行，自己睡眠等待，如果被唤醒，则重复跳回步骤 1 处执行;
3、 如果此子进程的执行状态为 PROC_ZOMBIE，表明此子进程处于退出状态，需要当前进程(即子进程的父
进程)完成对子进程的最终回收工作，即首先把子进程控制块从两个进程队列proc_list和hash_list中删
除，并释放子进程的内核堆栈和进程控制块。自此，子进程才彻底地结束了它的执行过程，它所占用的所有资
源均已释放。
用户态程序调用sys_wait()系统调用，通过syscall进入内核态。
内核态处理sys_wait()系统调用，调用do_wait()函数等待子进程退出，完成后返回到用户态
*/
int
do_wait(int pid, int *code_store) {
    struct mm_struct *mm = current->mm;
    //检查传入的参数code_store是否为NULL
    if (code_store != NULL) {
        //检查code_store指向的内存是否可访问
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
            return -E_INVAL;
        }
    }

    struct proc_struct *proc;
    bool intr_flag, haskid;
repeat:
    haskid = 0;
    if (pid != 0) {
        //pid不为0，则它会通过find_proc函数找到对应的子进程，并检查该子进程是否是当前进程的子进程。如果是，则设置haskid为1，
        proc = find_proc(pid);
        if (proc != NULL && proc->parent == current) {
            haskid = 1;
            //子进程的状态是否为PROC_ZOMBIE。如果是，则跳转到found标签处
            if (proc->state == PROC_ZOMBIE) {
                goto found;
            }
        }
    }
    else {
        //pid为0，则它会遍历当前进程的所有子进程，设置haskid为1，并检查每个子进程的状态是否为PROC_ZOMBIE。如果是，则跳转到found标签处
        proc = current->cptr;
        for (; proc != NULL; proc = proc->optr) {
            haskid = 1;
            if (proc->state == PROC_ZOMBIE) {
                goto found;
            }
        }
    }
    //haskid为1，则表示已经找到了一个已退出的子进程。此时，将当前进程的状态设置为PROC_SLEEPING，并设置wait_state为WT_CHILD，
    //然后调用schedule函数进行进程调度。如果当前进程的flags标志位中包含PF_EXITING，说明当前进程正在被杀死，这时候会调用do_exit函数退出当前进程。然后重新回到repeat标签处继续执行
    if (haskid) {
       
        current->state = PROC_SLEEPING;
        current->wait_state = WT_CHILD;
        schedule();
        if (current->flags & PF_EXITING) {
            do_exit(-E_KILLED);
        }
        goto repeat;
    }
    return -E_BAD_PROC;

found:
    if (proc == idleproc || proc == initproc) {
        panic("wait idleproc or initproc.\n");
    }
    if (code_store != NULL) {
        *code_store = proc->exit_code;
    }
    local_intr_save(intr_flag);
    {
        unhash_proc(proc);
        remove_links(proc);
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}

// do_kill - 通过将进程的标志位设置为PF_EXITING来终止具有特定pid的进程。
// do_kill - kill process with pid by set this process's flags with PF_EXITING
int
do_kill(int pid) {
    struct proc_struct *proc;
    if ((proc = find_proc(pid)) != NULL) {
        if (!(proc->flags & PF_EXITING)) {
            proc->flags |= PF_EXITING;
            if (proc->wait_state & WT_INTERRUPTED) {
                wakeup_proc(proc);
            }
            return 0;
        }
        return -E_KILLED;
    }
    return -E_INVAL;
}
//在用户主内核线程调用时执行SYS_exec系统调用来执行一个用户程序
// kernel_execve - do SYS_exec syscall to exec a user program called by user_main kernel_thread
static int
kernel_execve(const char *name, unsigned char *binary, size_t size) {
    int64_t ret=0, len = strlen(name);
 //   ret = do_execve(name, len, binary, size);
    // 内联汇编实现系统调用
    // 参数传递给a0-a4，系统调用号传递给a7
    // ebreak指令触发异常
    // 系统调用返回值存储在ret中
    asm volatile(
        "li a0, %1\n"
        "lw a1, %2\n"
        "lw a2, %3\n"
        "lw a3, %4\n"
        "lw a4, %5\n"
    	"li a7, 10\n"
        "ebreak\n"
        "sw a0, %0\n"
        : "=m"(ret)
        : "i"(SYS_exec), "m"(name), "m"(len), "m"(binary), "m"(size)
        : "memory");
    cprintf("ret = %d\n", ret);
    return ret;
}

#define __KERNEL_EXECVE(name, binary, size) ({                          \
            cprintf("kernel_execve: pid = %d, name = \"%s\".\n",        \
                    current->pid, name);                                \
            kernel_execve(name, binary, (size_t)(size));                \
        })

#define KERNEL_EXECVE(x) ({                                             \
            extern unsigned char _binary_obj___user_##x##_out_start[],  \
                _binary_obj___user_##x##_out_size[];                    \
            __KERNEL_EXECVE(#x, _binary_obj___user_##x##_out_start,     \
                            _binary_obj___user_##x##_out_size);         \
        })

#define __KERNEL_EXECVE2(x, xstart, xsize) ({                           \
            extern unsigned char xstart[], xsize[];                     \
            __KERNEL_EXECVE(#x, xstart, (size_t)xsize);                 \
        })

#define KERNEL_EXECVE2(x, xstart, xsize)        __KERNEL_EXECVE2(x, xstart, xsize)

// user_main - kernel thread used to exec a user program
static int
user_main(void *arg) {
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
    size_t nr_free_pages_store = nr_free_pages();
    size_t kernel_allocated_store = kallocated();

    int pid = kernel_thread(user_main, NULL, 0);
    if (pid <= 0) {
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0) {
        schedule();
    }

    cprintf("all user-mode processes have quit.\n");
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
    assert(nr_process == 2);
    assert(list_next(&proc_list) == &(initproc->list_link));
    assert(list_prev(&proc_list) == &(initproc->list_link));

    cprintf("init check memory pass.\n");
    return 0;
}

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
    set_proc_name(idleproc, "idle");
    nr_process ++;

    current = idleproc;

    int pid = kernel_thread(init_main, NULL, 0);
    if (pid <= 0) {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
    while (1) {
        if (current->need_resched) {
            schedule();
        }
    }
}

