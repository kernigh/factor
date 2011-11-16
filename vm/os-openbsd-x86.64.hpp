namespace factor
{

static inline unsigned int uap_fpu_status(void *uap) { return 0; }
static inline void uap_clear_fpu_status(void *uap) {}

/* Info from /usr/include/machine/signal.h, included from os-openbsd.hpp. */
#define UAP_STACK_POINTER(ucontext) (((struct sigcontext *)ucontext)->sc_rsp)
#define UAP_PROGRAM_COUNTER(ucontext) (((struct sigcontext *)ucontext)->sc_rip)
#define UAP_SET_TOC_POINTER(uap, ptr) (void)0
#define UAP_STACK_POINTER_TYPE long
}
