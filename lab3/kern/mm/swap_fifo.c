#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_fifo.h>
#include <list.h>

/* 
最简单的页面替换算法（PRA）是先进先出（FIFO）算法。
先进先出的页面替换算法是一种开销较低的算法，操作系统在处理方面需要很少的记录。
从名称就可以看出其思想-操作系统使用一个队列来跟踪内存中的所有页面，最近到达的页面在队列的末尾，最早到达的页面在队列的前面。
当需要替换页面时，选择队列前面（最旧的）的页面。尽管FIFO算法廉价且直观，但在实际应用中性能较差。
因此，它很少以其未修改的形式使用。该算法会出现Belady的异常现象。[wikipedia]The simplest Page Replacement Algorithm(PRA) is a FIFO algorithm. The first-in, first-out
 * page replacement algorithm is a low-overhead algorithm that requires little book-keeping on
 * the part of the operating system. The idea is obvious from the name - the operating system
 * keeps track of all the pages in memory in a queue, with the most recent arrival at the back,
 * and the earliest arrival in front. When a page needs to be replaced, the page at the front
 * of the queue (the oldest page) is selected. While FIFO is cheap and intuitive, it performs
 * poorly in practical application. Thus, it is rarely used in its unmodified form. This
 * algorithm experiences Belady's anomaly.
 *
 * Details of FIFO PRA
 * （1）准备：为了实现FIFO PRA，我们应该管理所有可交换的页面，因此我们可以按照时间顺序将这些页面链接到pra_list_head中。
 * 首先，您应该熟悉list.h中的struct list结构。struct list是一个简单的双向链表实现。您应该了解如何使用：
 * list_init、list_add（list_add_after）、list_add_before、list_del、list_next、list_prev。
 * 另一个棘手的方法是将通用的链表结构转换为特殊的结构（如struct page）。
 * 您可以找到一些宏：le2page（在memlayout.h中），（在将来的实验中：le2vma（在vmm.h中），le2proc（在proc.h中），等等）
 * (1) Prepare: In order to implement FIFO PRA, we should manage all swappable pages, so we can
 *              link these pages into pra_list_head according the time order. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list
 *              implementation. You should know howto USE: list_init, list_add(list_add_after),
 *              list_add_before, list_del, list_next, list_prev. Another tricky method is to transform
 *              a general list struct to a special struct (such as struct page). You can find some MACRO:
 *              le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.
 */

list_entry_t pra_list_head;
/*
初始化pra_list_head，并让mm->sm_priv指向pra_list_head的地址。
现在，通过内存控制结构体mm_struct，我们可以访问FIFO PRA（先进先出页面置换算法）
 * (2) _fifo_init_mm: init pra_list_head and let  mm->sm_priv point to the addr of pra_list_head.
 *              Now, From the memory control struct mm_struct, we can access FIFO PRA
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
    //初始化pra_list_head，并让mm->sm_priv指向pra_list_head的地址。
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
/*
根据FIFO PRA（先进先出页面置换算法），我们应该将最近到达的页面链接到pra_list_head队列的末尾。
 * (3)_fifo_map_swappable: According FIFO PRA, we should link the most recent arrival page at the back of pra_list_head qeueue
 */
static int
_fifo_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;//获取FIFO PRA链表头部地址
    list_entry_t *entry=&(page->pra_page_link);// 获取当前页面的链表入口
 
    assert(entry != NULL && head != NULL);// 确保entry和head不为空
    //record the page access situlation
// 记录页面访问情况

// (1) 将最近到达的页面链接到pra_list_head队列的末尾
    //(1)link the most recent arrival page at the back of the pra_list_head qeueue.
    list_add(head, entry);
    return 0;
}
/*
 *  (4)_fifo_swap_out_victim: According FIFO PRA, we should unlink the  earliest arrival page in front of pra_list_head qeueue,
 *                            then set the addr of addr of this page to ptr_page.
 *  根据FIFO PRA（先进先出页面置换算法），我们应该从pra_list_head队列的前面取消链接最早到达的页面，
然后将该页面的地址设置为ptr_page
 */
 /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
     //FIFO（先进先出）页面置换算法中选择victim页面
     //ptr_page：指向Page结构体指针的指针，用于存储选中的victim页面的地址。
     //in_tick：表示是否在时钟中断中调用此函数，为0表示不是在时钟中断中调用。
static int
_fifo_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{//将mm的私有成员sm_priv强制转换为list_entry_t类型的指针，并赋值给head变量。
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
     //断言assert来确保head不为空
         assert(head != NULL);
        //断言assert来确保in_tick的值为0
     assert(in_tick==0);
     //从head的前一个节点开始，查找最早到达的页面，将其赋值给entry变量
    list_entry_t* entry = list_prev(head);
    //如果找到了最早到达的页面（entry不等于head），
    //则从链表中删除该页面（调用list_del函数），
    //并将其转换为Page结构体的指针赋值给*ptr_page
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    } else {
        //如果没有找到最早到达的页面（entry等于head），则将*ptr_page设置为NULL。
        *ptr_page = NULL;
    }
    return 0;
}

static int
_fifo_check_swap(void) {
    //每次访问一个虚拟地址，都会引发页面错误，pgfault_num会相应地增加。
    //函数中的断言语句用于检查pgfault_num的值是否符合预期
    cprintf("write Virt Page c in fifo_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==4);
    cprintf("write Virt Page a in fifo_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==4);
    cprintf("write Virt Page d in fifo_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==4);
    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==4);
    cprintf("write Virt Page e in fifo_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==5);
    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==5);
    cprintf("write Virt Page a in fifo_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==6);
    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==7);
    cprintf("write Virt Page c in fifo_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==8);
    cprintf("write Virt Page d in fifo_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==9);
    cprintf("write Virt Page e in fifo_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==10);
    cprintf("write Virt Page a in fifo_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==11);
    return 0;
}


static int
_fifo_init(void)
{
    return 0;
}

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }


struct swap_manager swap_manager_fifo =
{
     .name            = "fifo swap manager",
     .init            = &_fifo_init,
     .init_mm         = &_fifo_init_mm,
     .tick_event      = &_fifo_tick_event,
     .map_swappable   = &_fifo_map_swappable,
     .set_unswappable = &_fifo_set_unswappable,
     .swap_out_victim = &_fifo_swap_out_victim,
     .check_swap      = &_fifo_check_swap,
};
