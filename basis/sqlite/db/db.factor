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
    "sqlite.db.result-sets"
    "sqlite.db.statements"
    "sqlite.db.types"
    "sqlite.db.queries"
    ! "sqlite.db.introspection"

    "sqlite.orm"
} [ require ] each
