#ifndef __KERN_MM_VMM_H__
#define __KERN_MM_VMM_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <sync.h>

//pre define
struct mm_struct;

// 虚拟连续内存区域（vma），[vm_start, vm_end)，
// 如果地址属于一个vma，则满足 vma.vm_start <= addr < vma.vm_end
// the virtual continuous memory area(vma), [vm_start, vm_end), 
// addr belong to a vma means  vma.vm_start<= addr <vma.vm_end 
struct vma_struct {
     // 使用相同PDT的vma集合
    struct mm_struct *vm_mm; // the set of vma using the same PDT 
    uintptr_t vm_start;      // start addr of vma      
    uintptr_t vm_end;        // end addr of vma, not include the vm_end itself
    uint_t vm_flags;       // flags of vma
    // 通过vma的起始地址排序的线性链表链接
    list_entry_t list_link;  // linear list link which sorted by start addr of vma
};

#define le2vma(le, member)                  \
    to_struct((le), struct vma_struct, member)

#define VM_READ                 0x00000001
#define VM_WRITE                0x00000002
#define VM_EXEC                 0x00000004

// the control struct for a set of vma using the same PDT
struct mm_struct {
  //按vma的起始地址排序的线性链表的链接。
    list_entry_t mmap_list;        // linear list link which sorted by start addr of vma
    //当前访问的vma
    struct vma_struct *mmap_cache; // current accessed vma, used for speed purpose
    //这些vma的PDT（页目录表）。
    pde_t *pgdir;                  // the PDT of tvma的数量hese vma
    //vma的数量
    int map_count;                 // the count of these vma
    //交换管理器的私有数据。
    void *sm_priv;                   // the private data for swap manager
};

struct vma_struct *find_vma(struct mm_struct *mm, uintptr_t addr);
struct vma_struct *vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags);
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma);

struct mm_struct *mm_create(void);
void mm_destroy(struct mm_struct *mm);

void vmm_init(void);

int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr);

extern volatile unsigned int pgfault_num;
extern struct mm_struct *check_mm_struct;

#endif /* !__KERN_MM_VMM_H__ */

