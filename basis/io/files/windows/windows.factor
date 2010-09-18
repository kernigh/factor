! Copyright (C) 2008 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alien.c-types alien.data alien.strings
classes.struct combinators combinators.short-circuit
continuations destructors environment io.backend
io.backend.windows io.binary io.buffers io.encodings.utf16n
io.files io.files.private io.files.types io.pathnames io.ports
kernel literals make math math.bitwise sequences
specialized-arrays system tr
windows windows.errors windows.kernel32 windows.shell32
windows.time windows.types ;
SPECIALIZED-ARRAY: ushort
IN: io.files.windows

: open-file ( path access-mode create-mode flags -- handle )
    [
        [ share-mode default-security-attributes ] 2dip
        CreateFile-flags f CreateFile opened-file
    ] with-destructors ;

: open-r/w ( path -- win32-file )
    flags{ GENERIC_READ GENERIC_WRITE }
    OPEN_EXISTING 0 open-file ;

: open-read ( path -- win32-file )
    GENERIC_READ OPEN_EXISTING 0 open-file 0 >>ptr ;

: open-write ( path -- win32-file )
    GENERIC_WRITE CREATE_ALWAYS 0 open-file 0 >>ptr ;

: (open-append) ( path -- win32-file )
    GENERIC_WRITE OPEN_ALWAYS 0 open-file ;

: open-existing ( path -- win32-file )
    flags{ GENERIC_READ GENERIC_WRITE }
    share-mode
    f
    OPEN_EXISTING
    FILE_FLAG_BACKUP_SEMANTICS
    f CreateFileW dup win32-error=0/f <win32-file> ;

: maybe-create-file ( path -- win32-file ? )
    #! return true if file was just created
    flags{ GENERIC_READ GENERIC_WRITE }
    share-mode
    f
    OPEN_ALWAYS
    0 CreateFile-flags
    f CreateFileW dup win32-error=0/f <win32-file>
    GetLastError ERROR_ALREADY_EXISTS = not ;

: set-file-pointer ( handle length method -- )
    [ [ handle>> ] dip d>w/w <uint> ] dip SetFilePointer
    INVALID_SET_FILE_POINTER = [ "SetFilePointer failed" throw ] when ;

HOOK: open-append os ( path -- win32-file )

TUPLE: FileArgs
    hFile lpBuffer nNumberOfBytesToRead
    lpNumberOfBytesRet lpOverlapped ;

C: <FileArgs> FileArgs

: make-FileArgs ( port -- <FileArgs> )
    {
        [ handle>> check-disposed ]
        [ handle>> handle>> ]
        [ buffer>> ]
        [ buffer>> buffer-length ]
        [ drop DWORD <c-object> ]
        [ FileArgs-overlapped ]
    } cleave <FileArgs> ;

: setup-read ( <FileArgs> -- hFile lpBuffer nNumberOfBytesToRead lpNumberOfBytesRead lpOverlapped )
    {
        [ hFile>> ]
        [ lpBuffer>> buffer-end ]
        [ lpBuffer>> buffer-capacity ]
        [ lpNumberOfBytesRet>> ]
        [ lpOverlapped>> ]
    } cleave ;

: setup-write ( <FileArgs> -- hFile lpBuffer nNumberOfBytesToWrite lpNumberOfBytesWritten lpOverlapped )
    {
        [ hFile>> ]
        [ lpBuffer>> buffer@ ]
        [ lpBuffer>> buffer-length ]
        [ lpNumberOfBytesRet>> ]
        [ lpOverlapped>> ]
    } cleave ;

M: windows (file-reader) ( path -- stream )
    open-read <input-port> ;

M: windows (file-writer) ( path -- stream )
    open-write <output-port> ;

M: windows (file-appender) ( path -- stream )
    open-append <output-port> ;

SYMBOLS: +read-only+ +hidden+ +system+
+archive+ +device+ +normal+ +temporary+
+sparse-file+ +reparse-point+ +compressed+ +offline+
+not-content-indexed+ +encrypted+ ;

: win32-file-attribute ( n symbol attr -- )
    rot mask? [ , ] [ drop ] if ;

: win32-file-attributes ( n -- seq )
    [
        {
            [ +read-only+ FILE_ATTRIBUTE_READONLY win32-file-attribute ]
            [ +hidden+ FILE_ATTRIBUTE_HIDDEN win32-file-attribute ]
            [ +system+ FILE_ATTRIBUTE_SYSTEM win32-file-attribute ]
            [ +directory+ FILE_ATTRIBUTE_DIRECTORY win32-file-attribute ]
            [ +archive+ FILE_ATTRIBUTE_ARCHIVE win32-file-attribute ]
            [ +device+ FILE_ATTRIBUTE_DEVICE win32-file-attribute ]
            [ +normal+ FILE_ATTRIBUTE_NORMAL win32-file-attribute ]
            [ +temporary+ FILE_ATTRIBUTE_TEMPORARY win32-file-attribute ]
            [ +sparse-file+ FILE_ATTRIBUTE_SPARSE_FILE win32-file-attribute ]
            [ +reparse-point+ FILE_ATTRIBUTE_REPARSE_POINT win32-file-attribute ]
            [ +compressed+ FILE_ATTRIBUTE_COMPRESSED win32-file-attribute ]
            [ +offline+ FILE_ATTRIBUTE_OFFLINE win32-file-attribute ]
            [ +not-content-indexed+ FILE_ATTRIBUTE_NOT_CONTENT_INDEXED win32-file-attribute ]
            [ +encrypted+ FILE_ATTRIBUTE_ENCRYPTED win32-file-attribute ]
        } cleave
    ] { } make ;

: win32-file-type ( n -- symbol )
    FILE_ATTRIBUTE_DIRECTORY mask? +directory+ +regular-file+ ? ;

: (set-file-times) ( handle timestamp/f timestamp/f timestamp/f -- )
    [ timestamp>FILETIME ] tri@
    SetFileTime win32-error=0/f ;

M: winnt cwd
    MAX_UNICODE_PATH dup <ushort-array>
    [ GetCurrentDirectory win32-error=0/f ] keep
    utf16n alien>string ;

M: winnt cd
    SetCurrentDirectory win32-error=0/f ;

CONSTANT: unicode-prefix "\\\\?\\"

M: winnt root-directory? ( path -- ? )
    {
        { [ dup empty? ] [ drop f ] }
        { [ dup [ path-separator? ] all? ] [ drop t ] }
        { [ dup trim-tail-separators { [ length 2 = ]
          [ second CHAR: : = ] } 1&& ] [ drop t ] }
        { [ dup unicode-prefix head? ]
          [ trim-tail-separators length unicode-prefix length 2 + = ] }
        [ drop f ]
    } cond ;

: prepend-prefix ( string -- string' )
    dup unicode-prefix head? [
        unicode-prefix prepend
    ] unless ;

TR: normalize-separators "/" "\\" ;

M: winnt normalize-path ( string -- string' )
    absolute-path
    normalize-separators
    prepend-prefix ;

M: winnt CreateFile-flags ( DWORD -- DWORD )
    FILE_FLAG_OVERLAPPED bitor ;

<PRIVATE

: windows-file-size ( path -- size )
    normalize-path 0 WIN32_FILE_ATTRIBUTE_DATA <struct>
    [ GetFileAttributesEx win32-error=0/f ] keep
    [ nFileSizeLow>> ] [ nFileSizeHigh>> ] bi >64bit ;

PRIVATE>

M: winnt open-append
    [ dup windows-file-size ] [ drop 0 ] recover
    [ (open-append) ] dip >>ptr ;

M: winnt home
    {
        [ "HOMEDRIVE" os-env "HOMEPATH" os-env append-path ]
        [ "USERPROFILE" os-env ]
        [ my-documents ]
    } 0|| ;