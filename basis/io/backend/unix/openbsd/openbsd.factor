! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: io.backend io.backend.unix io.backend.unix.multiplexers
io.backend.unix.multiplexers.kqueue init namespaces system ;
IN: io.backend.unix.openbsd

M: openbsd init-io ( -- )
    <kqueue-mx> mx set-global ;

openbsd set-io-backend

[ start-signal-pipe-thread ] "io.backend.unix:signal-pipe-thread" add-startup-hook
