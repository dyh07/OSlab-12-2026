#include <list.h>
#include <sync.h>
#include <proc.h>
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    proc->state = PROC_RUNNABLE;
}

//LAB4 function3 YOUR CODE
//2510720 董隽仪

void
schedule(void)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    current->need_resched = 0;

    // 从当前线程的下一个节点开始，最多扫描进程链表一圈。
    list_entry_t *head = &proc_list;
    list_entry_t *start = current == idleproc ? head : &current->list_link;
    list_entry_t *entry = start;
    struct proc_struct *next = idleproc;
    do
    {
        entry = list_next(entry);
        if (entry != head)
        {
            struct proc_struct *candidate = le2proc(entry, list_link);
            if (candidate->state == PROC_RUNNABLE)
            {
                next = candidate;
                break;
            }
        }
    } while (entry != start);

    next->runs++;
    if (next != current)
    {
        proc_run(next);
    }
    local_intr_restore(intr_flag);
}
