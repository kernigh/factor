! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences vocabs.loader ;
IN: postgresql.db

TUPLE: postgresql-db
    host port pgopts pgtty database username password ;

: <postgresql-db> ( -- postgresql-db )
    postgresql-db new ;

{
    "postgresql.db.connections"
    ! "postgresql.db.errors"
    ! "postgresql.db.ffi"
    "postgresql.db.lib"
    ! "postgresql.db.introspection"
    "postgresql.db.result-sets"
    ! "postgresql.db.statements"
    ! "postgresql.db.tuples"
    "postgresql.db.types"
    ! "postgresql.db.fql"
    ! "postgresql.db.orm"
} [ require ] each
