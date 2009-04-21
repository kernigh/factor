! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors constructors db2.connections db2.sqlite.ffi
db2.sqlite.lib db2.statements kernel ;
IN: db2.sqlite

TUPLE: sqlite-db path ;
CONSTRUCTOR: sqlite-db ( path -- sqlite-db ) ;

TUPLE: sqlite-db-connection < db-connection ;

: <sqlite-db-connection> ( handle -- db-connection )
    sqlite-db-connection new-db-connection ;

M: sqlite-db-connection dispose-statement
    handle>>
    [ [ sqlite3_reset drop ] [ sqlite-finalize ] bi ] when* ;
