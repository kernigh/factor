! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs destructors fry io.backend.windows
io.process.listing kernel sequences system windows.advapi32
windows.errors windows.kernel32 windows.snapshot windows.types ;
FROM: sets => members ;
IN: io.process.listing.windows
    
M: windows all-running-processes ( -- seq )
    TH32CS_SNAPPROCESS 0 <win32-snapshot> [ snapshot>processes  ] with-disposal ;

M: windows process-group* ( process-entry/id -- seq )
    process-id-trees [ at ] dip
    '[
        [ id>> ] map [ _ at ] map concat
        [ [ id>> ] [ parent-id>> ] bi = not ] filter f like
    ] follow concat members ;

M: windows terminate-process* ( id -- )
    [
        [ PROCESS_ALL_ACCESS FALSE ] dip OpenProcess
        [ win32-error=0/f ] [ <win32-handle> &dispose drop ] [ ] tri
        1 TerminateProcess win32-error=0/f
    ] with-destructors ;
