! Copyright (C) 2008 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: alien.strings fry io.encodings.utf16n kernel
splitting windows windows.kernel32 windows.types system
environment alien.data sequences windows.errors
io.streams.memory io.encodings io specialized-arrays ;
SPECIALIZED-ARRAY: TCHAR
IN: environment.windows

M: windows os-env ( key -- value )
    MAX_UNICODE_PATH TCHAR <c-array>
    [ dup length GetEnvironmentVariable ] keep over 0 = [
        2drop f
    ] [
        nip utf16n alien>string
    ] if ;

M: windows set-os-env ( value key -- )
    swap SetEnvironmentVariable win32-error=0/f ;

M: windows unset-os-env ( key -- )
    f SetEnvironmentVariable 0 = [
        GetLastError ERROR_ENVVAR_NOT_FOUND =
        [ win32-error ] unless
    ] when ;

M: windows (os-envs) ( -- seq )
    GetEnvironmentStrings [
        <memory-stream> [
            utf16n decode-input
            [ "\0" read-until drop dup empty? not ] [ ] produce nip
        ] with-input-stream*
    ] [ FreeEnvironmentStrings win32-error=0/f ] bi ;
