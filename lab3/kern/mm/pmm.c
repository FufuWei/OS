#include <default_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <sync.h>
#include <vmm.h>
#include <riscv.h>

// virtual address of physical page array
// 物理页面数组的虚拟地址
struct Page *pages;
// amount of physical memory (in pages)
// 物理内存的数量（以页面为单位）
size_t npage = 0;
// The kernel image is mapped at VA=KERNBASE and PA=info.base
// 内核映像在VA=KERNBASE和PA=info.base处映射
uint_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
 RISC-V中内存从0x80000000开始
const size_t nbase = DRAM_BASE / PGSIZE;

// virtual address of boot-time page directory
//引导时页目录的虚拟地址
pde_t *boot_pgdir = NULL;
// physical address of boot-time page directory
// 引导时页目录的物理地址
uintptr_t boot_cr3;

// physical memory management
//物理内存管理
const struct pmm_manager *pmm_manager;


static void check_alloc_page(void);
static void check_pgdir(void);
static void check_boot_pgdir(void);

// init_pmm_manager - initialize a pmm_manager instance

static void init_pmm_manager(void) {
    pmm_manager = &default_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
// 调用pmm->init_memmap来构建空闲内存的Page结构
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
//// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;

    while (1) {
        // // 禁止中断
        local_intr_save(intr_flag);
        { page = pmm_manager->alloc_pages(n); }
        //恢复中断
        local_intr_restore(intr_flag);
        //如果成功分配到内存页面，或者需要分配的页面数量大于1，或者交换空间未初始化，则跳出循环
        if (page != NULL || n > 1 || swap_init_ok == 0) break;

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        // // 调用swap_out函数将页面交换到磁盘
        swap_out(check_mm_struct, n, 0);
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
//释放连续的n个页面大小的内存空间。它首先保存中断标志，
//然后调用pmm_manager的free_pages方法来实际释放内存，最后恢复中断标志。
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;

    local_intr_save(intr_flag);
    { pmm_manager->free_pages(base, n); }
    local_intr_restore(intr_flag);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
//获取当前可用内存的大小，即空闲内存的数量乘以页面大小
//通过保存和恢复中断标志来保证操作的原子性，
//然后调用pmm_manager的nr_free_pages方法来获取可用内存的大
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    { ret = pmm_manager->nr_free_pages(); }
    local_intr_restore(intr_flag);
    return ret;
}

/* page_init - initialize the physical memory management */
static void page_init(void) {
    extern char kern_entry[];// 引入内核入口地址

    va_pa_offset = KERNBASE - 0x80200000;// 虚拟地址和物理地址的偏移量
    uint64_t mem_begin = KERNEL_BEGIN_PADDR; // 内核物理地址起始位置
    uint64_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;// 内存大小
    uint64_t mem_end = PHYSICAL_MEMORY_END; //硬编码取代 sbi_query_memory()接口
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
    cprintf("physcial memory map:\n");
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
            mem_end - 1);
    uint64_t maxpa = mem_end;最大物理地址

    if (maxpa > KERNTOP) {// 如果最大物理地址超过了内核顶部地址
        maxpa = KERNTOP; // 将最大物理地址设为内核顶部地址
    }

    extern char end[]; // 引入内核末尾地址

    npage = maxpa / PGSIZE; // 计算内存页的数量
    // BBL has put the initial page table at the first available page after the
    // kernel
    // so stay away from it by adding extra offset to end
    // BBL已经将初始页表放在内核之后的第一个可用页上
// 所以通过在末尾添加额外的偏移量来避免它
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
    for (size_t i = 0; i < npage - nbase; i++) {
        SetPageReserved(pages + i);//将页标记为保留页
    }

     // 空闲内存的起始物理地址
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
    mem_begin = ROUNDUP(freemem, PGSIZE);//对齐空闲内存的起始物理地址
    mem_end = ROUNDDOWN(mem_end, PGSIZE);//对齐内存结束位置
    if (freemem < mem_end) {
        //初始化内存映射
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

static void enable_paging(void) {
    //启用分页机制，通过写入satp寄存器的值来实现。
    //1、最高位设置为1，表示使用Sv39分页模式。
// 2、其余位设置为boot_cr3右移RISCV_PGSHIFT位的值。
// 这里假设boot_cr3是有效的根页表的物理地址。
    write_csr(satp, (0x8000000000000000) | (boot_cr3 >> RISCV_PGSHIFT));
}

/**
 * @brief      setup and enable the paging mechanism//设置和启用分页机制
 *
 * @param      pgdir  The page dir页目录的指针。
 * @param[in]  la     Linear address of this memory need to map需要映射的线性地址
 * @param[in]  size   Memory size内存的大小
 * @param[in]  pa     Physical address of this memory内存的物理地址
 * @param[in]  perm   The permission of this memory内存的权限
 */
//将指定的线性地址范围映射到指定的物理地址范围。
static void boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size,
                             uintptr_t pa, uint32_t perm) {
    //确保线性地址和物理地址的偏移相同（PGOFF(la) == PGOFF(pa)）
    assert(PGOFF(la) == PGOFF(pa));
    //计算需要映射的页表项数量（n）
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    //将线性地址和物理地址都向下对齐到页的边界（PGSIZE）
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    //使用循环遍历每个页表项，为每个页表项设置对应的物理地址，
    //并设置有效位（PTE_V）和权限（perm）。
    //循环结束后，线性地址和物理地址都会增加一个页的大小（PGSIZE）。
    for (; n > 0; n--, la += PGSIZE, pa += PGSIZE) {
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pte_create(pa >> PGSHIFT, PTE_V | perm);
    }
}
//分配一页内存并返回内核虚拟地址
// boot_alloc_page - allocate one page using pmm->alloc_pages(1)
// return value: the kernel virtual address of this allocated page
// note: this function is used to get the memory for PDT(Page Directory
// Table)&PT(Page Table)
static void *boot_alloc_page(void) {
    struct Page *p = alloc_page();//调用alloc_page函数分配一页物理内存，将返回的物理页结构体指针赋值给变量p
    if (p == NULL) {
        panic("boot_alloc_page failed.\n");
    }
    //将物理页结构体指针转换为内核虚拟地址，并将其作为函数返回值
    return page2kva(p);
}
//设置pmm来管理物理内存，并构建PDT和PT来设置分页机制。
// pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup

// paging mechanism
//         - check the correctness of pmm & paging mechanism, print PDT&PT
//检查pmm和分页机制的正确性，并打印出PDT和PT
void pmm_init(void) {
    // 首先，我们需要根据pmm.h中的框架初始化一个物理内存管理器(pmm)。
// 然后，pmm可以用于分配/释放物理内存。
// 现在可以使用first_fit/best_fit/worst_fit/buddy_system的pmm。
    // We need to alloc/free the physical memory (granularity is 4KB or other
    // size).
    // So a framework of physical memory manager (struct pmm_manager)is defined
    // in pmm.h
    // First we should init a physical memory manager(pmm) based on the
    // framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();
// 接下来，检测物理内存空间，保留已使用的内存，
// 然后使用pmm->init_memmap创建空闲页面列表。
    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
// 使用pmm->check函数来验证pmm中的分配/释放功能的正确性。
    // use pmm->check to verify the correctness of the alloc/free function in a
    // pmm
    check_alloc_page();
    // 创建boot_pgdir，即初始页目录表(PDT)
    // create boot_pgdir, an initial page directory(Page Directory Table, PDT)
    // extern char boot_page_table_sv39[];声明了一个名为boot_page_table_sv39的数组，用于存储页表的内容。
// boot_pgdir被赋值为boot_page_table_sv39的物理地址，并且boot_cr3被赋值为boot_pgdir的物理地址。
// 最后，使用check_pgdir函数来检查boot_pgdir的正确性。

// static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);用于在编译时检查KERNBASE和KERNTOP是否是PTSIZE的倍数。
    extern char boot_page_table_sv39[];
    boot_pgdir = (pte_t*)boot_page_table_sv39;
    boot_cr3 = PADDR(boot_pgdir);
    check_pgdir();
    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);
// 将所有物理内存映射到线性内存，基线性地址为KERNBASE
// 线性地址KERNBASE~KERNBASE+KMEMSIZE 对应物理地址0~KMEMSIZE
// 但在enable_paging()和gdt_init()完成之前，不应使用此映射。
    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE~KERNBASE+KMEMSIZE = phy_addr 0~KMEMSIZE
    // But shouldn't use this map until enable_paging() & gdt_init() finished.
    //boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, PADDR(KERNBASE),
     //                READ_WRITE_EXEC);

    // temporary map:
    // 临时映射:
// 虚拟地址3G~3G+4M = 线性地址0~4M = 线性地址3G~3G+4M = 物理地址0~4M
    // virtual_addr 3G~3G+4M = linear_addr 0~4M = linear_addr 3G~3G+4M =
    // phy_addr 0~4M
    // boot_pgdir[0] = boot_pgdir[PDX(KERNBASE)];

    //    enable_paging();
// 现在基本的虚拟内存映射已经建立。
// 检查基本虚拟内存映射的正确性。
    // now the basic virtual memory map(see memalyout.h) is established.
    // check the correctness of the basic virtual memory map.
    check_boot_pgdir();

}

//根据给定的页目录和线性地址la，获取对应的页表项pte_t
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    /*
     *
     * If you need to visit a physical address, please use KADDR()
     * please read pmm.h for useful macros
     *
     * Maybe you want help comment, BELOW comments can help you finish the code
     *
     * Some Useful MACROs and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     * PDX(la) = 虚拟地址la的页目录条目索引。
KADDR(pa)：接受一个物理地址并返回相应的内核虚拟地址。
set_page_ref(page,1)：表示该页面被引用一次。
page2pa(page)：获取此（struct Page *）页面管理的内存的物理地址。
struct Page * alloc_page()：分配一个页面。
memset(void *s, char c, size_t n)：将指针s指向的内存区域的前n个字节设置为指定的值c。
     *   PDX(la) = the index of page directory entry of VIRTUAL ADDRESS la.
     *   KADDR(pa) : takes a physical address and returns the corresponding
     * kernel virtual address.
     *   set_page_ref(page,1) : means the page be referenced by one time
     *   page2pa(page): get the physical address of memory which this (struct
     * Page *) page  manages
     *   struct Page * alloc_page() : allocation a page
     *   memset(void *s, char c, size_t n) : sets the first n bytes of the
     * memory area pointed by s
     *                                       to the specified value c.
     * PTE_P 0x001 // 页表/目录条目标志位：存在
PTE_W 0x002 // 页表/目录条目标志位：可写
PTE_U 0x004 // 页表/目录条目标志位：用户可访问
     * DEFINEs:
     *   PTE_P           0x001                   // page table/directory entry
     * flags bit : Present
     *   PTE_W           0x002                   // page table/directory entry
     * flags bit : Writeable
     *   PTE_U           0x004                   // page table/directory entry
     * flags bit : User can access
     */
    //通过PDX1宏获取一级页表项的索引，然后通过&pdepgdir[PDX1(la)]获取一级页表项的地址pdep1
    pde_t *pdep1  &pgdir[PDX1(la)];
    //检查一级页表项是否有效。如果无效且create为false，或者create为true但没有空闲页面可用，则返回NULL。
    if (!(*pdep1 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        //如果一级页表项无效且有空闲页面可用，就通过alloc_page函数分配一个页面，并将页面引用计数设置为1。
        //然后获取该页面的物理地址pa，并使用memset函数将该页面清零。
        //最后，使用pte_create宏根据页面的物理页号和标志位PTE_U | PTE_V创建一个新的页表项，并将该页表项设置到一级页表项pdep1所指向的位置。
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    //通过PDX0宏获取二级页表项的索引，然后通过&pdep1[PDX0(la)]获取二级页表项的地址pdep0。
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    //检查二级页表项是否有效。如果无效且create为false，或者create为true但没有空闲页面可用，则返回NULL。
//    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
    		return NULL;
    	}
        //如果二级页表项无效且有空闲页面可用，就通过alloc_page函数分配一个页面，并将页面引用计数设置为1。
        //然后获取该页面的物理地址pa，并使用memset函数将该页面清零。
        //最后，使用pte_create宏根据页面的物理页号和标志位PTE_U | PTE_V创建一个新的页表项，并将该页表项设置到二级页表项pdep0所指向的位置。
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
 //   	memset(pa, 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    //PTX宏获取线性地址la对应的页表项的索引，然后通过&PDE_ADDR(*pdep0)[PTX(la)]获取线性地址la对应的页表项pte_t的地址，并将该地址返回。
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}

// get_page - get related 
Page struct for linear address la using PDT pgdir
//根据线性地址la和页目录表pgdir获取相关的Page结构体
//参数包括页目录表pgdir、线性地址la，以及一个指向pte_t指针的指针ptep_store。
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
    //调用get_pte函数，传入pgdir、la和0作为参数，获取与线性地址相对应的页表项pte_t
    pte_t *ptep = get_pte(pgdir, la, 0);
    //如果ptep_store不为NULL，将ptep的值存储到ptep_store指向的位置
    if (ptep_store != NULL) {
        *ptep_store = ptep;
    }
    //判断ptep是否为NULL且ptep指向的页表项具有有效位PTE_V。

//如果满足条件，将pte2page函数应用于ptep指向的页表项，将其转换为Page结构体，并返回该结构体。
    if (ptep != NULL && *ptep & PTE_V) {
        return pte2page(*ptep);
    }
    return NULL;
}
//释放与线性地址la相关联的Page结构体，并清除（使无效）与线性地址la相关联的页表项pte
// page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
//页表发生了变化，因此需要使TLB无效化
// note: PT is changed, so the TLB need to be invalidate
static inline void page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
    /*
     *
     * Please check if ptep is valid, and tlb must be manually updated if
     * mapping is updated
     *请检查ptep是否有效，并且如果映射被更新，则必须手动更新tlb。

下面是一些有用的宏和定义，你可以在下面的实现中使用它们。

宏或函数：

struct Page *page pte2page(*ptep): 从ptep的值中获取相应的Page结构体。
free_page: 释放一个Page结构体。
page_ref_dec(page): 减少page->ref的值。注意：如果page->ref等于0，则应该释放该Page结构体。
tlb_invalidate(pde_t *pgdir, uintptr_t la): 使TLB条目无效化，但仅当正在编辑的页表是处理器当前使用的页表时。
定义：

PTE_P 0x001：页表/目录项的标志位：存在。
     * Maybe you want help comment, BELOW comments can help you finish the code
     *
     * Some Useful MACROs and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   struct Page *page pte2page(*ptep): get the according page from the
     * value of a ptep
     *   free_page : free a page
     *   page_ref_dec(page) : decrease page->ref. NOTICE: ff page->ref == 0 ,
     * then this page should be free.
     *   tlb_invalidate(pde_t *pgdir, uintptr_t la) : Invalidate a TLB entry,
     * but only if the page tables being
     *                        edited are the ones currently in use by the
     * processor.
     * DEFINEs:
     *   PTE_P           0x001                   // page table/directory entry
     * flags bit : Present
     */
// 从页目录中移除指定线性地址的页表项
// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
    //获取指定线性地址对应的页表项
    pte_t *ptep = get_pte(pgdir, la, 0);
    if (ptep != NULL) {
        //调用 page_remove_pte 函数移除页表项
        page_remove_pte(pgdir, la, ptep);
    }
}
}
// page_insert - 构建一个 Page 的物理地址与线性地址 la 的映射
// 参数:
// pgdir: PDT 的内核虚拟基地址
// page: 需要映射的 Page
// la: 需要映射的线性地址
// perm: 在相关 pte 中设置的该 Page 的权限
// 返回值: 总是返回 0
// 注意: PT 被修改，因此需要使 TLB 失效
// page_insert - build the map of phy addr of an Page with the linear addr la
// paramemters:
//  pgdir: the kernel virtual base address of PDT
//  page:  the Page which need to map
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
    // 获取线性地址 la 对应的页表项
    pte_t *ptep = get_pte(pgdir, la, 1);
    if (ptep == NULL) {
        return -E_NO_MEM;; // 没有足够的内存创建页表项
    }
    // 增加 Page 的引用计数
    page_ref_inc(page);
    if (*ptep & PTE_V) {
        struct Page *p = pte2page(*ptep);
        if (p == page) {
            page_ref_dec(page);//如果映射的 Page 已经存在，减少其引用计数
        } else {
            page_remove_pte(pgdir, la, ptep);//移除原来映射的 Page
        }
    }
    // 创建新的页表项并设置权限
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
    //使 TLB 失效
    tlb_invalidate(pgdir, la);
    return 0;
}
// 使 TLB 失效，但仅当正在编辑的页表是当前处理器正在使用的页表时。
// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb();//刷新tlb }

// pgdir_alloc_page - call alloc_page & page_insert functions to
//                  - allocate a page size memory & setup an addr map
//                  - pa<->la with linear address la and the PDT pgdir
//调用 alloc_page 和 page_insert 函数来
// - 分配一个页大小的内存，并设置地址映射
// - pa<->la，其中 la 是线性地址，pgdir 是页目录表
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
    struct Page *page = alloc_page();// 分配一个页面
    if (page != NULL) { // 如果分配成功
        if (page_insert(pgdir, page, la, perm) != 0) { // 将页面插入到页表中
            free_page(page);// 如果插入失败，则释放页面
            return NULL;
        }
        if (swap_init_ok) { // 如果交换初始化
            swap_map_swappable(check_mm_struct, la, page, 0);// 将页面标记为可交换
            page->pra_vaddr = la; // 设置页面的虚拟地址
            assert(page_ref(page) == 1);  // 确保页面的引用计数为1
            // cprintf("get No. %d  page: pra_vaddr %x, pra_link.prev %x,
            // pra_link_next %x in pgdir_alloc_page\n", (page-pages),
            // page->pra_vaddr,page->pra_page_link.prev,
            // page->pra_page_link.next);
        }
    }

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}
//检查页目录的正确性，断言（assert）语句，用于验证各种操作的正确性
static void check_pgdir(void) {
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);//检查npage是否小于等于KERNTOP / PGSIZE，其中npage表示页的数量，KERNTOP表示内核结束的地址。
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);//检查boot_pgdir是否不为空，并且boot_pgdir的低12位是否为0。
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);//检查get_page(boot_pgdir, 0x0, NULL)是否返回NULL

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);//调用page_insert(boot_pgdir, p1, 0x0, 0)函数将p1插入到boot_pgdir的0x0位置，并检查返回值是否为0。
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);//调用get_pte(boot_pgdir, 0x0, 0)函数获取boot_pgdir中0x0位置的页表项地址，并检查是否不为NULL。
    assert(pte2page(*ptep) == p1);//检查pte2page(*ptep)是否等于p1。
    assert(page_ref(p1) == 1);//检查page_ref(p1)是否等于1

//检查页表项的正确性，包括插入页、设置用户访问权限和写权限等。

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);

    p2 = alloc_page();
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
    assert(*ptep & PTE_U);
    assert(*ptep & PTE_W);
    assert(boot_pgdir[0] & PTE_U);
    assert(page_ref(p2) == 1);

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
    assert(page_ref(p1) == 2);
    assert(page_ref(p2) == 0);
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
    assert(pte2page(*ptep) == p1);
    assert((*ptep & PTE_U) == 0);
//最后，进行一些清理工作，包括移除页表项、释放页等，并进行一些断言检查。
    page_remove(boot_pgdir, 0x0);
    assert(page_ref(p1) == 1);
    assert(page_ref(p2) == 0);

    page_remove(boot_pgdir, PGSIZE);
    assert(page_ref(p1) == 0);
    assert(page_ref(p2) == 0);

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;

    assert(nr_free_store==nr_free_pages());

    cprintf("check_pgdir() succeeded!\n");
}

//检查引导页目录（boot_pgdir）的正确性
static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;
    //获取可用的空闲页面数量
    nr_free_store=nr_free_pages();
//使用循环遍历引导页目录中的每个页表项，验证每个页表项的内容是否正确。
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

//确保引导页目录的第0个页目录项（boot_pgdir[0]）为0
    assert(boot_pgdir[0] == 0);
//分配一个页面（Page结构），并将其插入到引导页目录中的0x100虚拟地址处，并设置页面的写入和读取权限。
    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
    //验证页面的引用计数是否为1。
    assert(page_ref(p) == 1);
    //再次将页面插入到引导页目录中的0x100 + PGSIZE虚拟地址处，并设置页面的写入和读取权限。
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
    //验证页面的引用计数是否为2
    assert(page_ref(p) == 2);
//将字符串"ucore: Hello world!!“复制到0x100虚拟地址处。
    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
    //验证0x100虚拟地址处的字符串与0x100 + PGSIZE虚拟地址处的字符串相等。
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
//将0x100虚拟地址处的字符设置为’\0’，即字符串结尾
    *(char *)(page2kva(p) + 0x100) = '\0';
    //验证0x100虚拟地址处的字符串长度为0
    assert(strlen((const char *)0x100) == 0);

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    //释放页面p及其对应的页目录项。
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    //将引导页目录的第0个页目录项设置为0。
    boot_pgdir[0] = 0;
//验证空闲页面数量未变化
    assert(nr_free_store==nr_free_pages());
//打印输出"check_boot_pgdir() succeeded!”
    cprintf("check_boot_pgdir() succeeded!\n");
}
//动态分配内存,分配一定大小的内存块，并返回指向该内存块的指针
void *kmalloc(size_t n) {
    void *ptr = NULL;
    struct Page *base = NULL;
    //使用assert语句验证输入的大小n是否在有效范围内，即大于0且小于1024 * 0124
    assert(n > 0 && n < 1024 * 0124);
    //计算需要分配的页面数量，将n除以页面大小PGSIZE并向上取整，得到num_pages
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
    //调用alloc_pages函数分配num_pages个页面，并将返回的页面结构体指针赋值给base
    base = alloc_pages(num_pages);
    //assert语句验证base是否为NULL，即判断分配页面是否成功
    assert(base != NULL);
    //调用page2kva函数将base转换为内核虚拟地址，并将结果赋值给ptr。
    ptr = page2kva(base);
    //返回ptr，即指向分配的内存块的指针。
    return ptr;
}
//释放动态分配内存的函数kfree
void kfree(void *ptr, size_t n) {
    //使用assert语句验证输入的大小n是否在有效范围内，即大于0且小于1024 * 0124
    assert(n > 0 && n < 1024 * 0124);
    //使用assert语句验证指针ptr是否为NULL，即判断是否指向有效的内存块。
    assert(ptr != NULL);
    //声明一个结构体Page类型的指针变量base，并将其初始化为NULL
    struct Page *base = NULL;
    //计算需要释放的页面数量，将n除以页面大小PGSIZE并向上取整，得到num_pages
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
    //调用kva2page函数将ptr转换为对应的页面结构体指针，并将结果赋值给base
    base = kva2page(ptr);
    //调用free_pages函数释放base指向的num_pages个页面
    free_pages(base, num_pages);
}
