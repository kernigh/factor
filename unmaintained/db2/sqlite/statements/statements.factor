! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db2.connections db2.sqlite.connections
db2.sqlite.ffi db2.sqlite.lib db2.statements destructors kernel
namespaces db2.sqlite ;
IN: db2.sqlite.statements

M: sqlite-db-connection prepare-statement* ( statement -- statement )
    db-connection get handle>> over sql>> sqlite-prepare
    >>handle ;
