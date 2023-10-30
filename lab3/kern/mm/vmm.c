#include <vmm.h>
#include <sync.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <error.h>
#include <pmm.h>
#include <riscv.h>
#include <swap.h>

/* 
  vmm design include two parts: mm_struct (mm) & vma_struct (vma)
  mm is the memory manager for the set of continuous virtual memory  
  area which have the same PDT. vma is a continuous virtual memory area.
  There a linear link list for vma & a redblack link list for vma in mm.
  vmm 设计包括两个部分：mm_struct (mm) 和 vma_struct (vma)。
mm 是一组具有相同 PDT 的连续虚拟内存区域的内存管理器。vma 是一个连续的虚拟内存区域。
mm 中有一个线性链表用于 vma，还有一个红黑链表用于 vma。
---------------
  mm related functions:
   golbal functions
     struct mm_struct * mm_create(void)
     void mm_destroy(struct mm_struct *mm)
     int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr)

--------------
  vma related functions:
   global functions
     struct vma_struct * vma_create (uintptr_t vm_start, uintptr_t vm_end,...)
     void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
     struct vma_struct * find_vma(struct mm_struct *mm, uintptr_t addr)
   local functions
     inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
---------------
   check correctness functions
     void check_vmm(void);
     void check_vma_struct(void);
     void check_pgfault(void);
*/

// szx func : print_vma and print_mm
//vitual memery area
/*
打印 “name”，在输出中用于标识当前打印的虚拟内存区域。
使用 cprintf 函数打印 “print_vma” 的标识信息。
打印虚拟内存区域所属的内存管理器 (mm_struct) 的地址。
打印虚拟内存区域的起始地址 (vm_start) 和结束地址 (vm_end)。
打印虚拟内存区域的标志 (vm_flags)。
打印虚拟内存区域的链表节点 (list_entry_t) 的地址。*/
void print_vma(char *name, struct vma_struct *vma){
	cprintf("-- %s print_vma --\n", name);
	cprintf("   mm_struct: %p\n",vma->vm_mm);
	cprintf("   vm_start,vm_end: %x,%x\n",vma->vm_start,vma->vm_end);
	cprintf("   vm_flags: %x\n",vma->vm_flags);
	cprintf("   list_entry_t: %p\n",&vma->list_link);
}
/*
打印 “name”，在输出中用于标识当前打印的内存管理器。
使用 cprintf 函数打印 “print_mm” 的标识信息。
打印内存管理器的 mmap_list 的地址。
打印内存管理器的 map_count，表示内存管理器中的虚拟内存区域 (VMA) 的数量。
创建一个指向 mmap_list 的链表节点指针 list。
使用 for 循环遍历 mmap_list 链表中的每个 VMA。
在循环中，通过 list_next 函数将指针 list 移动到下一个链表节点。
调用 “print_vma” 函数来打印当前 VMA 的信息。*/
void print_mm(char *name, struct mm_struct *mm){
	cprintf("-- %s print_mm --\n",name);
	cprintf("   mmap_list: %p\n",&mm->mmap_list);
	cprintf("   map_count: %d\n",mm->map_count);
	list_entry_t *list = &mm->mmap_list;
	for(int i=0;i<mm->map_count;i++){
		list = list_next(list);
		print_vma(name, le2vma(list,list_link));
	}
}

static void check_vmm(void);
static void check_vma_struct(void);
static void check_pgfault(void);

// mm_create -  alloc a mm_struct & initialize it.
//分配一个 mm_struct 结构并进行初始化
struct mm_struct *
mm_create(void) {
    //分配一个mm_struct结构并进行初始化
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));

    //如果分配成功
    if (mm != NULL) {
        //mmap_list字段初始化为空链表
        list_init(&(mm->mmap_list));
        mm->mmap_cache = NULL;
        mm->pgdir = NULL;
        mm->map_count = 0;
        //如果 swap_init_ok 为真，则调用 swap_init_mm 函数进行交换初始化。
    //否则，将 sm_priv 字段设置为 NULL。
        if (swap_init_ok) swap_init_mm(mm);
        else mm->sm_priv = NULL;
    }
    return mm;
}

//分配一个vma_struct结构体并进行初始化
// vma_create - alloc a vma_struct & initialize it. (addr range: vm_start~vm_end)
//接受三个参数：vm_start表示虚拟内存区域的起始地址，vm_end表示虚拟内存区域的结束地址，vm_flags表示虚拟内存区域的标志
struct vma_struct *
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
    //使用kmalloc函数来分配一个vma_struct结构体的内存空间，并将其地址赋值给指针变量vma
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));

    //如果分配成功，则将传入的参数值分别赋值给vma结构体的成员变量vm_start、vm_end和vm_flags。
    if (vma != NULL) {
        vma->vm_start = vm_start;
        vma->vm_end = vm_end;
        vma->vm_flags = vm_flags;
    }
    return vma;
}

/*
在给定的内存管理结构中查找包含给定地址的虚拟内存区域，并返回对应的 vma_struct 结构。
*/
// find_vma - find a vma  (vma->vm_start <= addr <= vma_vm_end)
//根据给定的内存管理结构 mm 和地址 addr，在虚拟内存区域链表中查找并返回对应的 vma_struct 结构。
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr) {
    struct vma_struct *vma = NULL;
    if (mm != NULL) {
        //如果 mm 不为 NULL，则先尝试从 mmap_cache 字段中获取 vma 结构。
        vma = mm->mmap_cache;
        //如果 vma 为 NULL，或者 addr 不在 vma 的范围内，则需要遍历 mmap_list 链表来查找对应的 vma 结构。
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
                bool found = 0;
                //使用 list_entry_t 结构体的指针 le 来遍历链表，初始时将其指向 mmap_list。
                list_entry_t *list = &(mm->mmap_list), *le = list;
                //在循环中，将 le 赋值为链表的下一个节点，并将其转换为 vma_struct 结构指针 vma。然后判断 addr 是否在当前 vma 的范围内。
                while ((le = list_next(le)) != list) {
                    vma = le2vma(le, list_link);
                    //如果 addr 在 vma 的范围内，则将 found 标志设置为1，并跳出循环。
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
                        found = 1;
                        break;
                    }
                }
                //如果遍历完整个链表后，found 仍为0，则表示没有找到对应的 vma 结构，将 vma 设置为 NULL
                if (!found) {
                    vma = NULL;
                }
        }
        //如果找到了对应的 vma 结构，则将其赋值给 mmap_cache 字段，以便下次查找时可以直接使用
        if (vma != NULL) {
            mm->mmap_cache = vma;
        }
    }
    return vma;
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
//用于检查两个vma（虚拟内存区域）是否重叠的函数。该函数使用了三个断言来确保输入的两个vma之间没有重叠
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
    /*
    第一个断言 assert(prev->vm_start < prev->vm_end); 确保前一个vma的起始地址小于结束地址。

第二个断言 assert(prev->vm_end <= next->vm_start); 确保前一个vma的结束地址小于或等于后一个vma的起始地址，以确保它们之间没有重叠。

第三个断言 assert(next->vm_start < next->vm_end); 确保后一个vma的起始地址小于结束地址。

如果有任何一个断言失败，将会触发一个断言错误，表示vma之间存在重叠。*/
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
}


// insert_vma_struct -insert vma in mm's list link
//将vma插入到mm的链表中
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    //通过断言 assert(vma->vm_start < vma->vm_end); 确保vma的起始地址小于结束地址
    assert(vma->vm_start < vma->vm_end);

    list_entry_t *list = &(mm->mmap_list);
    list_entry_t *le_prev = list, *le_next;
    //遍历mm的链表，找到合适的位置将vma插入
        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            //遍历过程中，函数比较每个vma的起始地址和vma要插入的起始地址，
            //找到第一个起始地址大于vma的起始地址的vma，将其前一个vma记录在le_prev中。
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
                break;
            }
            le_prev = le;
        }
    // list_next(le_prev) 找到le_prev的下一个节点le_next
    le_next = list_next(le_prev);

    /* check overlap */
    //调用了check_vma_overlap函数来检查vma和le_prev、le_next之间是否有重叠。如果有重叠，则会触发断言错误。
    if (le_prev != list) {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
    }
    if (le_next != list) {
        check_vma_overlap(vma, le2vma(le_next, list_link));
    }
    //置vma所属的mm为mm，并将vma插入到le_prev之后的位置，即插入到链表中。
    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));
//增加了mm的map_count计数器
    mm->map_count ++;
}

// mm_destroy - free mm and mm internal fields
//释放mm和mm内部字段的函数
void
mm_destroy(struct mm_struct *mm) {
    //获取mm的链表头部list，并定义一个指针le来遍历链表。
    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
        //循环遍历链表，每次从链表中取出一个节点le，并使用list_del函数将该节点从链表中删除。
        //然后，函数使用kfree函数释放le所指向的vma结构体的内存空间。
        list_del(le);
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
    }
    //kfree函数释放mm结构体的内存空间
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
    //将mm指针设置为NULL，以防止出现野指针
    mm=NULL;
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
//初始化虚拟内存管理
void
vmm_init(void) {
    check_vmm();
}

// check_vmm - check correctness of vmm
//检查虚拟内存管理正确性
static void
check_vmm(void) {
    //获取当前系统中可用的空闲页面数量，并将其保存在nr_free_pages_store变量中
    size_t nr_free_pages_store = nr_free_pages();
    //调用check_vma_struct函数，用于检查vma_struct结构体的正确性
    check_vma_struct();
    //调用check_pgfault函数，用于检查页面错误处理的正确性
    check_pgfault();

    nr_free_pages_store--;	// szx : Sv39三级页表多占一个内存页，所以执行此操作
    //使用assert函数来断言nr_free_pages_store与当前系统中可用的空闲页面数量相等，如果不相等则会触发断言失败
    assert(nr_free_pages_store == nr_free_pages());

    cprintf("check_vmm() succeeded.\n");
}

//用于检查vma_struct结构,创建一个mm_struct结构，然后在其中插入一系列vma_struct结构，并对其进行一些断言检查。
static void
check_vma_struct(void) {
    //保存当前的可用页面数量
    size_t nr_free_pages_store = nr_free_pages();
    //创建一个mm_struct结构
    struct mm_struct *mm = mm_create();
    assert(mm != NULL);

    //定义了两个变量step1和step2，并使用循环分别创建了step1和step2范围内的vma_struct结构，并将其插入mm_struct的mmap_list中。
    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    for (i = step1 + 1; i <= step2; i ++) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }
    //使用list_next函数遍历mm_struct的mmap_list，并对每个vma_struct结构进行一些断言检查，
    //确保其vm_start和vm_end字段的值符合预期。
    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
        struct vma_struct *vma1 = find_vma(mm, i);
        assert(vma1 != NULL);
        struct vma_struct *vma2 = find_vma(mm, i+1);
        assert(vma2 != NULL);
        struct vma_struct *vma3 = find_vma(mm, i+2);
        assert(vma3 == NULL);
        struct vma_struct *vma4 = find_vma(mm, i+3);
        assert(vma4 == NULL);
        struct vma_struct *vma5 = find_vma(mm, i+4);
        assert(vma5 == NULL);

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
    }

    for (i =4; i>=0; i--) {
        //使用find_vma函数在特定范围内查找vma_struct结构，并对返回的结果进行一些断言检查，确保它们的vm_start和vm_end字段的值符合预期。
        struct vma_struct *vma_below_5= find_vma(mm,i);
        if (vma_below_5 != NULL ) {
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
        }
        assert(vma_below_5 == NULL);
    }

    //销毁mm_struct结构，并再次检查保存的可用页面数量是否与之前保存的值相同
    mm_destroy(mm);

    assert(nr_free_pages_store == nr_free_pages());

    cprintf("check_vma_struct() succeeded!\n");
}

struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
//检查pgfault处理程序的正确性
static void
check_pgfault(void) {
	// char *name = "check_pgfault";
    size_t nr_free_pages_store = nr_free_pages();
    // 保存当前系统空闲页的数量
    // 创建一个新的mm_struct结构体
    check_mm_struct = mm_create();
    // 断言check_mm_struct结构体不为空
    assert(check_mm_struct != NULL);
    // 将mm_struct的pgdir指向boot_pgdir
    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
    // 断言pgdir的第一个元素为0
    assert(pgdir[0] == 0);
    //// 创建一个新的vma_struct结构体，起始地址为0，大小为PTSIZE，标志为VM_WRITE
    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    //断言vma_struct结构体不为空
    assert(vma != NULL);
    //// 在mm_struct的vma链表中插入vma_struct结构体
    insert_vma_struct(mm, vma);
    //定义一个地址变量addr，初始值为0x100
    uintptr_t addr = 0x100;
    // 断言在mm_struct的vma链表中可以找到地址为addr的vma_struct结构体
    assert(find_vma(mm, addr) == vma);

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
        //将地址为addr+i的字节赋值为i
        *(char *)(addr + i) = i;
        //将i累加到sum中
        sum += i;
    }
    for (i = 0; i < 100; i ++) {
        //将地址为addr+i的字节的值从sum中减去
        sum -= *(char *)(addr + i);
    }
    // 断言sum的值为0
    assert(sum == 0);
    //移除pgdir指向的页表中addr所在的页
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
    //释放pgdir的第一个页表所对应的物理页
    free_page(pde2page(pgdir[0]));
    // 将pgdir的第一个元素置为0
    pgdir[0] = 0;
    //将mm_struct的pgdir置为NULL
    mm->pgdir = NULL;
    //销毁mm_struct结构体
    mm_destroy(mm);
    //将check_mm_struct置为NULL
    check_mm_struct = NULL;
    nr_free_pages_store--;	// szx : Sv39第二级页表多占了一个内存页，所以执行此操作
    // 断言当前系统空闲页的数量与之前保存的数量相等
    assert(nr_free_pages_store == nr_free_pages());

    cprintf("check_pgfault() succeeded!\n");
}
//page fault number
volatile unsigned int pgfault_num=0;

//处理页面错误异常的中断处理程序。
/* do_pgfault - interrupt handler to process the page fault execption
//控制一组使用相同页目录表（PDT）的vma的结构体
 * @mm         : the control struct for a set of vma using the same PDT
 //记录在trapframe->tf_err中的错误码，由x86硬件设置。
 * @error_code : the error code recorded in trapframe->tf_err which is setted by x86 hardware
 //addr：导致内存访问异常的地址（CR2寄存器的内容）
 * @addr       : the addr which causes a memory access exception, (the contents of the CR2 register)
 *
 * CALL GRAPH: trap--> trap_dispatch-->pgfault_handler-->do_pgfault
 * //处理器向ucore的do_pgfault函数提供了两个信息，以帮助诊断异常并从中恢复
 * The processor provides ucore's do_pgfault function with two items of information to aid in diagnosing
 * the exception and recovering from it.
 * //CR2寄存器的内容。处理器使用32位线性地址加载CR2寄存器，该地址生成了异常。do_pgfault函数可以使用此地址定位相应的页目录和页表项。
 *   (1) The contents of the CR2 register. The processor loads the CR2 register with the
 *       32-bit linear address that generated the exception. The do_pgfault fun can
 *       use this address to locate the corresponding page directory and page-table
 *       entries.
 * //内核堆栈上的错误码。页面错误的错误码格式与其他异常的格式不同。错误码告诉异常处理程序三件事：

P标志（位0）指示异常是由于页不在内存中（0）还是由于访问权限违规或使用了保留位（1）引起的。
W/R标志（位1）指示导致异常的内存访问是读取（0）还是写入（1）。
U/S标志（位2）指示处理器在异常发生时是在用户模式（1）还是内核模式（0）下执行。
 *   (2) An error code on the kernel stack. The error code for a page fault has a format different from
 *       that for other exceptions. The error code tells the exception handler three things:
 *         -- The P flag   (bit 0) indicates whether the exception was due to a not-present page (0)
 *            or to either an access rights violation or the use of a reserved bit (1).
 *         -- The W/R flag (bit 1) indicates whether the memory access that caused the exception
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    //将ret初始化为-E_INVAL
    int ret = -E_INVAL;
    //try to find a vma which include addr
    //在mm的vma链表中找到包含addr的vma，赋值给vma变量。接着，递增pgfault_num变量的值。
    struct vma_struct *vma = find_vma(mm, addr);

    pgfault_num++;
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }

    /* IF (write an existed addr ) OR
     *    (write an non_existed addr && addr is writable) OR
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    //如果vma的vm_flags属性中包含VM_WRITE，则将perm设置为PTE_U、PTE_R和PTE_W的按位或操作结果。然后，将addr向下舍入到页面大小的倍数。
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);

    ret = -E_NO_MEM;

    pte_t *ptep=NULL;
    /*
    * Maybe you want help comment, BELOW comments can help you finish the code
    *
    * Some Useful MACROs and DEFINEs, you can use them in below implementation.
    * MACROs or Functions:
    * get_pte：获取一个PTE，并返回该PTE的内核虚拟地址（对于线性地址la）。如果PT中不存在该PTE，则为PT分配一个页面（注意第三个参数’1’）。
    *   get_pte : get an pte and return the kernel virtual address of this pte for la
    *             if the PT contians this pte didn't exist, alloc a page for PT (notice the 3th parameter '1')
    * //pgdir_alloc_page：调用alloc_page和page_insert函数来分配一个页面大小的内存，并设置一个地址映射pa<—>la，其中线性地址la和PDT pgdir相关。
    *   pgdir_alloc_page : call alloc_page & page_insert functions to allocate a page size memory & setup
    *             an addr map pa<--->la with linear address la and the PDT pgdir
    * DEFINES:
    *   VM_WRITE  : If vma->vm_flags & VM_WRITE == 1/0, then the vma is writable/non writable
    *   PTE_W           0x002                   // page table/directory entry flags bit : Writeable
    *   PTE_U           0x004                   // page table/directory entry flags bit : User can access
    * VARIABLES:
    *   mm->pgdir : the PDT of these vma
    *
    */

   //调用get_pte函数尝试查找一个页表项（pte）。如果pte所对应的页表（PT）不存在，则创建一个新的页表。
    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
                                         //PT(Page Table) isn't existed, then
                                         //create a PT.
    if (*ptep == 0) {
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    } else {
        /*LAB3 EXERCISE 3: YOUR CODE
        * 请你根据以下信息提示，补充函数
        * 现在我们认为pte是一个交换条目，那我们应该从磁盘加载数据并放到带有phy addr的页面，
        * 并将phy addr与逻辑addr映射，触发交换管理器记录该页面的访问情况
        *
        *  一些有用的宏和定义，可能会对你接下来代码的编写产生帮助(显然是有帮助的)
        *  宏或函数:
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            //根据mm和addr，尝试将磁盘页面的内容加载到已管理的内存页面中。
            ret = swap_in(mm,addr,&page);
            if(ret != 0){
                cprintf("swap failed\n");
                goto failed;
            }
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //根据mm、addr和page，设置物理地址<—>逻辑地址的映射
            page_insert(mm->pgdir,page,addr,perm);
            //logical addr
            //(3) make the page swappable
            //使页面可交换
            swap_map_swappable(mm,addr,page,1);
            page->pra_vaddr = addr;
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
failed:
    return ret;
}

