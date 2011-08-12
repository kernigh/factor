! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.connections sqlite.db.connections
sqlite.db.ffi sqlite.db.lib db.statements destructors kernel
namespaces ;
IN: sqlite.db.statements

M: sqlite-db-connection prepare-statement* ( statement -- statement )
    db-connection get handle>> over sql>> sqlite-prepare
    >>handle ;

M: sqlite-db-connection reset-statement
    [ handle>> sqlite3_reset drop ] keep ;

M: sqlite-db-connection dispose-statement
    handle>>
    [ [ sqlite3_reset drop ] [ sqlite-finalize ] bi ] when* ;

M: sqlite-db-connection next-bind-index "?" ;

M: sqlite-db-connection init-bind-index ;