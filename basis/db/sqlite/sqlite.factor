! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: constructors sequences vocabs.loader ;
IN: db.sqlite

TUPLE: sqlite-db path ;

CONSTRUCTOR: sqlite-db ( path -- db ) ;

{
    "db.sqlite.connections"
    "db.sqlite.errors"
    "db.sqlite.ffi"
    "db.sqlite.lib"
    ! "db.sqlite.introspection"
    "db.sqlite.result-sets"
    "db.sqlite.statements"
    ! "db.sqlite.tuples"
    "db.sqlite.types"
    ! "db.sqlite.fql"
    ! "db.sqlite.orm"
} [ require ] each
