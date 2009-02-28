
#define UAP_PROGRAM_COUNTER(context) \
	(((struct vregs*)context)->eip)

INLINE void *ucontext_stack_pointer(void *uap) {
	struct vregs *vr = (struct vregs*)uap;
	return (void*)vr->esp;
}
