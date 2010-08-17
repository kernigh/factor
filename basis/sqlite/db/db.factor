! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: constructors sequences vocabs.loader ;
IN: sqlite.db

TUPLE: sqlite-db path ;

CONSTRUCTOR: sqlite-db ( path -- db ) ;

{
    "sqlite.db.connections"
    "sqlite.db.errors"
    "sqlite.db.ffi"
    "sqlite.db.lib"
    ! "sqlite.db.introspection"
    "sqlite.db.result-sets"
    "sqlite.db.statements"
    ! "sqlite.db.tuples"
    "sqlite.db.types"
    ! "sqlite.db.fql"
    ! "sqlite.db.orm"
} [ require ] each
