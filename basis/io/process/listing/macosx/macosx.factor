! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: alien alien.c-types alien.data alien.syntax byte-arrays
classes.struct generalizations kernel literals locals math
sequences specialized-arrays unix unix.ffi unix.time unix.types ;
SPECIALIZED-ARRAY: int
FROM: alien.c-types => short ;
IN: io.process.listing.macosx

CONSTANT:  CTL_UNSPEC  0       
CONSTANT:  CTL_KERN    1       
CONSTANT:  CTL_VM      2       
CONSTANT:  CTL_VFS     3       
CONSTANT:  CTL_NET     4       
CONSTANT:  CTL_DEBUG   5       
CONSTANT:  CTL_HW      6       
CONSTANT:  CTL_MACHDEP 7       
CONSTANT:  CTL_USER    8       
CONSTANT:  CTL_MAXID   9       


CONSTANT:  KERN_OSTYPE      1  
CONSTANT:  KERN_OSRELEASE       2  
CONSTANT:  KERN_OSREV       3  
CONSTANT:  KERN_VERSION         4  
CONSTANT:  KERN_MAXVNODES       5  
CONSTANT:  KERN_MAXPROC         6  
CONSTANT:  KERN_MAXFILES        7  
CONSTANT:  KERN_ARGMAX      8  
CONSTANT:  KERN_SECURELVL       9  
CONSTANT:  KERN_HOSTNAME       10  
CONSTANT:  KERN_HOSTID     11  
CONSTANT:  KERN_CLOCKRATE      12  
CONSTANT:  KERN_VNODE      13  
CONSTANT:  KERN_PROC       14  
CONSTANT:  KERN_FILE       15  
CONSTANT:  KERN_PROF       16  
CONSTANT:  KERN_POSIX1     17  
CONSTANT:  KERN_NGROUPS        18  
CONSTANT:  KERN_JOB_CONTROL    19  
CONSTANT:  KERN_SAVED_IDS      20  
CONSTANT:  KERN_BOOTTIME       21  
CONSTANT:  KERN_NISDOMAINNAME  22  
ALIAS: KERN_DOMAINNAME     KERN_NISDOMAINNAME
CONSTANT:  KERN_MAXPARTITIONS  23  
CONSTANT:  KERN_KDEBUG         24  
CONSTANT:  KERN_UPDATEINTERVAL 25  
CONSTANT:  KERN_OSRELDATE      26  
CONSTANT:  KERN_NTP_PLL        27  
CONSTANT:  KERN_BOOTFILE       28  
CONSTANT:  KERN_MAXFILESPERPROC    29  
CONSTANT:  KERN_MAXPROCPERUID  30  
CONSTANT:  KERN_DUMPDEV        31  
CONSTANT:  KERN_IPC        32  
CONSTANT:  KERN_DUMMY      33  
CONSTANT:  KERN_PS_STRINGS 34  
CONSTANT:  KERN_USRSTACK32 35  
CONSTANT:  KERN_LOGSIGEXIT 36  
CONSTANT:  KERN_SYMFILE        37  
CONSTANT:  KERN_PROCARGS       38
CONSTANT:  KERN_NETBOOT        40  
CONSTANT:  KERN_PANICINFO      41  
CONSTANT:  KERN_SYSV       42  
CONSTANT:  KERN_AFFINITY       43  
CONSTANT:  KERN_TRANSLATE      44  
CONSTANT:  KERN_CLASSIC        KERN_TRANSLATE  
CONSTANT:  KERN_EXEC       45  
CONSTANT:  KERN_CLASSICHANDLER KERN_EXEC 
CONSTANT:  KERN_AIOMAX     46  
CONSTANT:  KERN_AIOPROCMAX     47  
CONSTANT:  KERN_AIOTHREADS     48  
CONSTANT:  KERN_PROCARGS2      49
CONSTANT:  KERN_COREFILE       50  
CONSTANT:  KERN_COREDUMP       51  
CONSTANT:  KERN_SUGID_COREDUMP 52  
CONSTANT:  KERN_PROCDELAYTERM  53  
CONSTANT:  KERN_SHREG_PRIVATIZABLE 54  
! CONSTANT: KERN_PROC_LOW_PRI_IO 55 ! deprecated
CONSTANT:  KERN_LOW_PRI_WINDOW 56  
CONSTANT:  KERN_LOW_PRI_DELAY  57  
CONSTANT:  KERN_POSIX      58  
CONSTANT:  KERN_USRSTACK64     59  
CONSTANT:  KERN_NX_PROTECTION  60  
CONSTANT:  KERN_TFP        61  
CONSTANT:  KERN_PROCNAME       62  
CONSTANT:  KERN_THALTSTACK     63  
CONSTANT:  KERN_SPECULATIVE_READS  64  
CONSTANT:  KERN_OSVERSION      65  
CONSTANT:  KERN_SAFEBOOT       66  
CONSTANT:  KERN_LCTX       67  
CONSTANT:  KERN_RAGEVNODE      68
CONSTANT:  KERN_TTY        69  
CONSTANT:  KERN_CHECKOPENEVT       70      
CONSTANT:  KERN_THREADNAME     71  
CONSTANT:  KERN_MAXID      72  

: KERN_COUNT_SYSCALLS ( -- n )
    KERN_OSTYPE 1000 + ;

CONSTANT:  KERN_RAGE_PROC      1
CONSTANT:  KERN_RAGE_THREAD    2
CONSTANT:  KERN_UNRAGE_PROC    3
CONSTANT:  KERN_UNRAGE_THREAD  4

CONSTANT:  KERN_OPENEVT_PROC     1
CONSTANT:  KERN_UNOPENEVT_PROC   2

CONSTANT:  KERN_TFP_POLICY         1

CONSTANT:  KERN_TFP_POLICY_DENY        0   
CONSTANT:  KERN_TFP_POLICY_DEFAULT     2   

CONSTANT:  KERN_KDEFLAGS       1
CONSTANT:  KERN_KDDFLAGS       2
CONSTANT:  KERN_KDENABLE       3
CONSTANT:  KERN_KDSETBUF       4
CONSTANT:  KERN_KDGETBUF       5
CONSTANT:  KERN_KDSETUP        6
CONSTANT:  KERN_KDREMOVE       7
CONSTANT:  KERN_KDSETREG       8
CONSTANT:  KERN_KDGETREG       9
CONSTANT:  KERN_KDREADTR       10
CONSTANT:  KERN_KDPIDTR        11
CONSTANT:  KERN_KDTHRMAP           12
CONSTANT:  KERN_KDPIDEX            14
CONSTANT:  KERN_KDSETRTCDEC        15
CONSTANT:  KERN_KDGETENTROPY       16

CONSTANT:  KERN_PANICINFO_MAXSIZE  1   
CONSTANT:  KERN_PANICINFO_IMAGE    2   

CONSTANT:  KERN_PROC_ALL       0   
CONSTANT:  KERN_PROC_PID       1   
CONSTANT:  KERN_PROC_PGRP      2   
CONSTANT:  KERN_PROC_SESSION   3   
CONSTANT:  KERN_PROC_TTY       4   
CONSTANT:  KERN_PROC_UID       5   
CONSTANT:  KERN_PROC_RUID      6   
CONSTANT:  KERN_PROC_LCID      7   

CONSTANT:  KERN_LCTX_ALL       0   
CONSTANT:  KERN_LCTX_LCID      1   

CONSTANT:  KIPC_MAXSOCKBUF     1   
CONSTANT:  KIPC_SOCKBUF_WASTE  2   
CONSTANT:  KIPC_SOMAXCONN      3   
CONSTANT:  KIPC_MAX_LINKHDR    4   
CONSTANT:  KIPC_MAX_PROTOHDR   5   
CONSTANT:  KIPC_MAX_HDR        6   
CONSTANT:  KIPC_MAX_DATALEN    7   
CONSTANT:  KIPC_MBSTAT     8   
CONSTANT:  KIPC_NMBCLUSTERS    9   
CONSTANT:  KIPC_SOQLIMITCOMPAT 10  

CONSTANT:  VM_METER    1       
CONSTANT:  VM_LOADAVG  2       

CONSTANT:  VM_MACHFACTOR   4       
CONSTANT:  VM_SWAPUSAGE    5       
CONSTANT:  VM_MAXID    6       

CONSTANT:  HW_MACHINE   1      
CONSTANT:  HW_MODEL     2      
CONSTANT:  HW_NCPU      3      
CONSTANT:  HW_BYTEORDER     4      
CONSTANT:  HW_PHYSMEM   5      
CONSTANT:  HW_USERMEM   6      
CONSTANT:  HW_PAGESIZE  7      
CONSTANT:  HW_DISKNAMES     8      
CONSTANT:  HW_DISKSTATS     9      
CONSTANT:  HW_EPOCH    10      
CONSTANT:  HW_FLOATINGPT   11      
CONSTANT:  HW_MACHINE_ARCH 12      
CONSTANT:  HW_VECTORUNIT   13      
CONSTANT:  HW_BUS_FREQ 14      
CONSTANT:  HW_CPU_FREQ 15      
CONSTANT:  HW_CACHELINE    16      
CONSTANT:  HW_L1ICACHESIZE 17      
CONSTANT:  HW_L1DCACHESIZE 18      
CONSTANT:  HW_L2SETTINGS   19      
CONSTANT:  HW_L2CACHESIZE  20      
CONSTANT:  HW_L3SETTINGS   21      
CONSTANT:  HW_L3CACHESIZE  22      
CONSTANT:  HW_TB_FREQ  23      
CONSTANT:  HW_MEMSIZE  24      
CONSTANT:  HW_AVAILCPU 25      
CONSTANT:  HW_MAXID    26      

CONSTANT:  USER_CS_PATH         1  
CONSTANT:  USER_BC_BASE_MAX     2  
CONSTANT:  USER_BC_DIM_MAX      3  
CONSTANT:  USER_BC_SCALE_MAX    4  
CONSTANT:  USER_BC_STRING_MAX   5  
CONSTANT:  USER_COLL_WEIGHTS_MAX    6  
CONSTANT:  USER_EXPR_NEST_MAX   7  
CONSTANT:  USER_LINE_MAX        8  
CONSTANT:  USER_RE_DUP_MAX      9  
CONSTANT:  USER_POSIX2_VERSION 10  
CONSTANT:  USER_POSIX2_C_BIND  11  
CONSTANT:  USER_POSIX2_C_DEV   12  
CONSTANT:  USER_POSIX2_CHAR_TERM   13  
CONSTANT:  USER_POSIX2_FORT_DEV    14  
CONSTANT:  USER_POSIX2_FORT_RUN    15  
CONSTANT:  USER_POSIX2_LOCALEDEF   16  
CONSTANT:  USER_POSIX2_SW_DEV  17  
CONSTANT:  USER_POSIX2_UPE     18  
CONSTANT:  USER_STREAM_MAX     19  
CONSTANT:  USER_TZNAME_MAX     20  
CONSTANT:  USER_MAXID      21  

CONSTANT:  CTL_DEBUG_NAME      0   
CONSTANT:  CTL_DEBUG_VALUE     1   
CONSTANT:  CTL_DEBUG_MAXID     20

CONSTANT: WMESGLEN 7
CONSTANT: WMESGLEN+1 8
CONSTANT: EPROC_CTTY 1
CONSTANT: EPROC_SLEADER 2
CONSTANT: COMAPT_MAXLOGNAME 12

CONSTANT: MAXCOMLEN 16

CONSTANT: MAXCOMLEN+1 17
TYPEDEF: ushort u_short
TYPEDEF: uint u_int
TYPEDEF: uchar u_char
TYPEDEF: uint32_t sigset_t
TYPEDEF: u_int64_t u_quad_t
TYPEDEF: int32_t segsz_t

STRUCT: run-queue-struct
    { __p_forw void* }
    { __p_back void* } ;

UNION-STRUCT: extern-proc-union
    { p_st1 run-queue-struct }
    { __p_starttime timeval } ;

STRUCT: itimerval
    { it_interval timeval }
    { it_value timeval } ;

! CLEAN ME UP
TYPEDEF: uint fixpt_t
TYPEDEF: void* sigacts
TYPEDEF: void* pgrp
TYPEDEF: void* user
TYPEDEF: void* vnode
TYPEDEF: void* proc
TYPEDEF: void* session
TYPEDEF: void* ucred

STRUCT: vmspace
    { dummy int32_t }
    { dummy2 caddr_t }
    { dummy3 int32_t[5] }
    { dummy4 caddr_t[3] } ;

STRUCT: extern_proc
    { p_un extern-proc-union }
    { p_vmspace vmspace* }
    { p_sigacts sigacts* }
    { p_flag int }
    { p_stat char }
    { p_pid pid_t }
    { p_oppid pid_t }
    { p_dupfd int }
    { user_stack caddr_t }
    { exit_thread void* }
    { p_debugger int }
    { sigwait boolean_t }
    { p_estcpu u_int }
    { p_cpticks int }
    { p_pctcpu fixpt_t }
    { p_wchan void* }
    { p_wmesg char* }
    { p_swtime u_int }
    { p_slptime u_int }
    { p_realtimer itimerval }
    { p_rtime timeval }
    { p_uticks u_quad_t }
    { p_sticks u_quad_t }
    { p_iticks u_quad_t }
    { p_traceflag int }
    { p_tracep vnode* }
    { p_siglist int }
    { p_textvp vnode* }
    { p_holdcnt int }
    { p_sigmask sigset_t }
    { p_ignore sigset_t }
    { p_catch sigset_t }
    { p_priority u_char }
    { p_usrpri u_char }
    { p_nice char }
    { p_comm char[MAXCOMLEN+1] }
    { p_pgrp pgrp* }
    { p_addr user* }
    { p_xstat u_short }
    { p_acflag u_short }
    { p_ru rusage* } ;

STRUCT: _pcred
    { pc_lock char[72] }
    { pc_ucred ucred* }
    { p_ruid uid_t }
    { p_svuid uid_t }
    { p_rgid gid_t }
    { p_svgid gid_t }
    { p_refcnt int } ;

CONSTANT: NGROUPS_MAX 16
ALIAS: NGROUPS NGROUPS_MAX

STRUCT: _ucred
    { cr_ref int32_t }
    { cr_uid uid_t }
    { cr_ngroups short }
    { cr_groups gid_t[NGROUPS] } ;

STRUCT: eproc
    { e_paddr proc* }
    { e_sess session* }
    { e_pcred _pcred }
    { e_ucred _ucred }
    { e_vm vmspace }
    { e_ppid pid_t }
    { e_pgid pid_t }
    { e_jobc short }
    { e_tdev dev_t }
    { e_tpgid pid_t }
    { e_tsess session* }
    { e_wmesg char[WMESGLEN] }
    { e_xsize segsz_t }
    { e_xrssize short }
    { e_xccount short }
    { e_xswrss short }
    { e_flag int32_t }
    { e_login char[COMAPT_MAXLOGNAME] }
    { e_lcid pid_t }
    { e_spare int32_t[3] } ;

STRUCT: kinfo_proc
    { kp_proc extern_proc }
    { kp_eproc eproc } ;

SPECIALIZED-ARRAY: kinfo_proc

: *value ( c-ptr c-type -- value )
    [ [ 0 ] dip heap-size <byte-array> ] keep alien-value ; inline

:: <value> ( value c-type -- c-ptr )
    c-type heap-size <byte-array> :> c-ptr
    value 0 c-ptr c-type set-alien-value
    c-ptr ; inline

: sysctl-enum-processes ( -- obj )
    int-array{ $ CTL_KERN $ KERN_PROC $ KERN_PROC_ALL 0 } ;

: get-buffer-size ( -- n )
    sysctl-enum-processes
    [ ]
    [ length 1 - f ]
    [ length size_t <value> f 0 ] tri
    [ my_sysctl io-error ] 3keep 2drop size_t *value ;

:: get-result ( len -- byte-array n )
    sysctl-enum-processes
    [ ]
    [ length 1 - len <byte-array> ] bi
    len size_t <value> f 0
    [ my_sysctl io-error ] 4 nkeep 2drop size_t *value ;

: list-processes ( -- seq )
    get-buffer-size get-result head kinfo_proc-array-cast ;
