! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: alien alien.c-types alien.libraries alien.syntax
classes.struct combinators continuations fry kernel math system
unix unix.ffi unix.types ;
IN: unix.kvm

<< "kvm" {
    { [ os unix? ] [ "/usr/lib/libkvm.so" cdecl add-library ] }
    [ drop ]
} cond >>

LIBRARY: kvm

STRUCT: kvm_swap
    { ksw_devname char[32] }
    { ksw_used int }
    { ksw_total int }
    { ksw_flags int }
    { ksw_reserved1 int }
    { ksw_reserved2 int } ;

CONSTANT: SWIF_DEV_PREFIX HEX: 0002

TYPEDEF: void kvm_t
TYPEDEF: void kinfo_proc

STRUCT: nlist
    { name char* }
    { type uchar }
    { other char }
    { desc short }
    { value ulong } ;

FUNCTION: int       kvm_close ( kvm_t* k ) ;
FUNCTION: char**    kvm_getargv ( kvm_t* k, kinfo_proc* kp, int n ) ;
FUNCTION: int       kvm_getcptime ( kvm_t* k, long* n ) ;
FUNCTION: char**    kvm_getenvv ( kvm_t* k, kinfo_proc* kp, int n ) ;
FUNCTION: c-string  kvm_geterr ( kvm_t* k ) ;
FUNCTION: char*     kvm_getfiles ( kvm_t* k, int a, int b, int* c ) ;
FUNCTION: int       kvm_getloadavg ( kvm_t* k, double* d, int b ) ;
FUNCTION: int       kvm_getmaxcpu ( kvm_t* k ) ;
FUNCTION: void*     kvm_getpcpu ( kvm_t* k, int n) ;
FUNCTION: kinfo_proc* kvm_getprocs ( kvm_t* k, int a, int b, int* c ) ;
FUNCTION: int       kvm_getswapinfo ( kvm_t* k, kvm_swap* ks, int a, int b ) ;
FUNCTION: int       kvm_nlist ( kvm_t* k, nlist* n ) ;
FUNCTION: kvm_t*    kvm_open  ( char* str1, char* str2, char* str3, int n, char* str4 ) ;
FUNCTION: kvm_t*    kvm_openfiles  ( char* str1, char* str2, char* str3, int n, char* str4 ) ;
FUNCTION: ssize_t   kvm_read ( kvm_t* k, ulong a, void* p, size_t size ) ;
FUNCTION: ssize_t   kvm_uread  ( kvm_t* k, kinfo_proc* pk, ulong n, char* str, size_t n ) ;

ERROR: kvm-exception string ;

: throw-kvm-exception ( k -- )
    kvm_geterr kvm-exception ;

: kvm-error ( k n -- )
    0 < [ throw-kvm-exception ] [ drop ] if ;

: close-kvm ( k -- ) dup kvm_close kvm-error ;

: open-kvm ( -- k )
    f f f O_RDONLY f kvm_open dup [ ] unless ;

: with-kvm ( quot: ( k -- ) -- )
    [ open-kvm ] dip over '[
        [ _ @ ]
        [ _ close-kvm ]
        [ ] cleanup
    ] call ; inline

