! Copyright (C) 2004, 2010 Mackenzie Straight, Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alien alien.c-types alien.data alien.syntax
arrays assocs classes.struct combinators
combinators.short-circuit destructors io io.backend io.buffers
 io.ports io.streams.c io.streams.null
io.timeouts kernel libc literals locals math namespaces
sequences system threads vocabs.loader windows.errors
windows.handles windows.kernel32 ;
IN: io.backend.windows

HOOK: CreateFile-flags io-backend ( DWORD -- DWORD )
HOOK: FileArgs-overlapped io-backend ( port -- overlapped/f )
HOOK: add-completion io-backend ( port -- port )

TUPLE: win32-file < win32-handle ptr ;

: <win32-file> ( handle -- win32-file )
    win32-file new-win32-handle ;

M: win32-file dispose
    [ cancel-operation ] [ call-next-method ] bi ;
    
: opened-file ( handle -- win32-file )
    check-invalid-handle <win32-file> |dispose add-completion ;

CONSTANT: share-mode
    flags{
        FILE_SHARE_READ
        FILE_SHARE_WRITE
        FILE_SHARE_DELETE
    }
    
: default-security-attributes ( -- obj )
    SECURITY_ATTRIBUTES <struct>
    SECURITY_ATTRIBUTES heap-size >>nLength ;
    
! Global variable with assoc mapping overlapped to threads
SYMBOL: pending-overlapped

TUPLE: io-callback port thread ;

C: <io-callback> io-callback

: (make-overlapped) ( -- overlapped-ext )
    OVERLAPPED malloc-struct &free ;

: make-overlapped ( port -- overlapped-ext )
    [ (make-overlapped) ] dip
    handle>> ptr>> [ >>offset ] when* ;

M: winnt FileArgs-overlapped ( port -- overlapped )
    make-overlapped ;

: <completion-port> ( handle existing -- handle )
     f 1 CreateIoCompletionPort dup win32-error=0/f ;

SYMBOL: master-completion-port

: <master-completion-port> ( -- handle )
    INVALID_HANDLE_VALUE f <completion-port> ;

M: winnt add-completion ( win32-handle -- win32-handle )
    dup handle>> master-completion-port get-global <completion-port> drop ;

: eof? ( error -- ? )
    { [ ERROR_HANDLE_EOF = ] [ ERROR_BROKEN_PIPE = ] } 1|| ;

: twiddle-thumbs ( overlapped port -- bytes-transferred )
    [
        drop
        [ self ] dip >c-ptr pending-overlapped get-global set-at
        "I/O" suspend {
            { [ dup integer? ] [ ] }
            { [ dup array? ] [
                first dup eof?
                [ drop 0 ] [ n>win32-error-string throw ] if
            ] }
        } cond
    ] with-timeout ;

:: wait-for-overlapped ( nanos -- bytes-transferred overlapped error? )
    nanos [ 1,000,000 /i ] [ INFINITE ] if* :> timeout
    master-completion-port get-global
    { int void* pointer: OVERLAPPED }
    [ timeout GetQueuedCompletionStatus zero? ] with-out-parameters
    :> ( error? bytes key overlapped )
    bytes overlapped error? ;

: resume-callback ( result overlapped -- )
    >c-ptr pending-overlapped get-global delete-at* drop resume-with ;

: handle-overlapped ( nanos -- ? )
    wait-for-overlapped [
        [
            [ drop GetLastError 1array ] dip resume-callback t
        ] [ drop f ] if*
    ] [ resume-callback t ] if ;

M: win32-handle cancel-operation
    [ handle>> CancelIo win32-error=0/f ] unless-disposed ;

M: winnt io-multiplex ( nanos -- )
    handle-overlapped [ 0 io-multiplex ] when ;

M: winnt init-io ( -- )
    <master-completion-port> master-completion-port set-global
    H{ } clone pending-overlapped set-global ;

ERROR: invalid-file-size n ;

: handle>file-size ( handle -- n )
    0 <ulonglong> [ GetFileSizeEx win32-error=0/f ] keep *ulonglong ;

ERROR: seek-before-start n ;

: set-seek-ptr ( n handle -- )
    [ dup 0 < [ seek-before-start ] when ] dip ptr<< ;

M: winnt tell-handle ( handle -- n ) ptr>> ;

M: winnt seek-handle ( n seek-type handle -- )
    swap {
        { seek-absolute [ set-seek-ptr ] }
        { seek-relative [ [ ptr>> + ] keep set-seek-ptr ] }
        { seek-end [ [ handle>> handle>file-size + ] keep set-seek-ptr ] }
        [ bad-seek-type ]
    } case ;

: file-error? ( n -- eof? )
    zero? [
        GetLastError {
            { [ dup expected-io-error? ] [ drop f ] }
            { [ dup eof? ] [ drop t ] }
            [ n>win32-error-string throw ]
        } cond
    ] [ f ] if ;

: wait-for-file ( FileArgs n port -- n )
    swap file-error?
    [ 2drop 0 ] [ [ lpOverlapped>> ] dip twiddle-thumbs ] if ;

: update-file-ptr ( n port -- )
    handle>> dup ptr>> [ rot + >>ptr drop ] [ 2drop ] if* ;

: finish-write ( n port -- )
    [ update-file-ptr ] [ buffer>> buffer-consume ] 2bi ;

M: winnt (wait-to-write)
    [
        [ make-FileArgs dup setup-write WriteFile ]
        [ wait-for-file ]
        [ finish-write ]
        tri
    ] with-destructors ;

: finish-read ( n port -- )
    [ update-file-ptr ] [ buffer>> n>buffer ] 2bi ;

M: winnt (wait-to-read) ( port -- )
    [
        [ make-FileArgs dup setup-read ReadFile ]
        [ wait-for-file ]
        [ finish-read ]
        tri
    ] with-destructors ;

: console-app? ( -- ? ) GetConsoleWindow >boolean ;

M: winnt init-stdio
    console-app?
    [ init-c-stdio ]
    [ null-reader null-writer null-writer set-stdio ] if ;

"io.files.windows" require

winnt set-io-backend
