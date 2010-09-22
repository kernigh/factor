! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alien.c-types classes classes.struct
combinators destructors fry io.backend.windows
io.encodings.string io.encodings.utf8 io.process.listing
kernel math sequences system windows.errors windows.kernel32
windows.types ;
IN: windows.snapshot

TUPLE: win32-snapshot < win32-handle flags process-id timestamp ;

TUPLE: win32-process-entry < process-entry ;

TUPLE: win32-module-entry process-id id module-base-address module-size handle module-name module-path ;

: do-snapshot ( flags process-id -- handle )
    CreateToolhelp32Snapshot dup invalid-handle? ;

: <win32-snapshot> ( flags process-id -- win32-snapshot )
    win32-snapshot new-disposable
        swap >>process-id
        swap >>flags
        nano-count >>timestamp
        dup [ flags>> ] [ process-id>> ] bi do-snapshot >>handle ;
    
: set-snapshot-entry-size ( entry -- entry )
    dup class heap-size >>dwSize ;

: snapshot-error ( n -- more? )
    TRUE = [
        t
    ] [
        GetLastError ERROR_NO_MORE_FILES = [
            f
        ] [
            win32-error-string throw
        ] if
    ] if ;
    
: TCHAR[]>string ( seq -- string )
    [ 0 = ] trim-tail utf8 decode ;
    
: MODULEENTRY32>module-entry ( MODULEENTRY32 -- module-entry )
    [ win32-module-entry new ] dip {
        [ th32ModuleID>> >>id ]
        [ th32ProcessID>> >>process-id ]
        [ modBaseAddr>> >>module-base-address ]
        [ modBaseSize>> >>module-size ]
        [ hModule>> >>handle ]
        [ szModule>> TCHAR[]>string >>module-name ]
        [ szExePath>> TCHAR[]>string >>module-path ]
    } cleave ;
        
: <MODULEENTRY32> ( -- obj )
    MODULEENTRY32 <struct> set-snapshot-entry-size ;
        
: first-module ( snapshot -- MODULEENTRY32/f )
    handle>> <MODULEENTRY32>
    [ Module32First snapshot-error ] keep
    swap [ drop f ] unless ;

: next-module ( snapshot -- MODULEENTRY32/f )
    handle>> <MODULEENTRY32>
    [ Module32Next snapshot-error ] keep
    swap [ drop f ] unless ;
    
: enumerate-snapshot-modules ( snapshot -- seq )
    [ first-module ]
    [ '[ _ next-module dup ] [ ] produce nip ] bi swap prefix sift ;

: snapshot>modules ( snapshot -- seq )
    enumerate-snapshot-modules [ MODULEENTRY32>module-entry ] map ;

GENERIC: loaded-modules ( obj -- seq )

M: integer loaded-modules ( id -- seq )
    [ TH32CS_SNAPMODULE ] dip <win32-snapshot> [ snapshot>modules ] with-disposal ;
    
M: process-entry loaded-modules id>> loaded-modules ;

: these-loaded-modules ( -- seq ) 0 loaded-modules ;

: <PROCESSENTRY32> ( -- obj )
    PROCESSENTRY32 <struct> set-snapshot-entry-size ;

: first-process ( snapshot -- PROCESSENTRY32/f )
    handle>> <PROCESSENTRY32>
    [ Process32First snapshot-error ] keep
    swap [ drop f ] unless ;

: next-process ( snapshot -- PROCESSENTRY32/f )
    handle>> <PROCESSENTRY32>
    [ Process32Next snapshot-error ] keep
    swap [ drop f ] unless ;

: PROCESSENTRY32>process-entry ( PROCESSENTRY32 -- process-entry )
    [ win32-process-entry new ] dip {
        [ th32ProcessID>> >>id ]
        [ th32ParentProcessID>> >>parent-id ]
    } cleave ;

: enumerate-snapshot-processes ( snapshot -- seq )
    [ first-process ]
    [ '[ _ next-process dup ] [ ] produce nip ] bi swap prefix sift ;
    
: snapshot>processes ( snapshot -- seq )
    enumerate-snapshot-processes [ PROCESSENTRY32>process-entry ] map ;
