! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors constructors db.connections db.sqlite.ffi
db.sqlite.lib db.statements kernel sequences vocabs.loader ;
IN: db.sqlite

TUPLE: sqlite-db path ;
CONSTRUCTOR: sqlite-db ( path -- sqlite-db ) ;

TUPLE: sqlite-db-connection < db-connection ;

: <sqlite-db-connection> ( handle -- db-connection )
    sqlite-db-connection new-db-connection ;

M: sqlite-db-connection dispose-statement
    handle>>
    [ [ sqlite3_reset drop ] [ sqlite-finalize ] bi ] when* ;

{
    "db.sqlite.connections"
    "db.sqlite.errors"
    "db.sqlite.ffi"
    "db.sqlite.lib"
    "db.sqlite.introspection"
    "db.sqlite.result-sets"
    "db.sqlite.statements"
    "db.sqlite.tuples"
    "db.sqlite.types"
} [ require ] each
