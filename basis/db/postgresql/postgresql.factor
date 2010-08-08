! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences vocabs.loader ;
IN: db.postgresql

TUPLE: postgresql-db
    host port pgopts pgtty database username password ;

: <postgresql-db> ( -- postgresql-db )
    postgresql-db new ;

{
    "db.postgresql.connections"
    ! "db.postgresql.errors"
    ! "db.postgresql.ffi"
    "db.postgresql.lib"
    ! "db.postgresql.introspection"
    "db.postgresql.result-sets"
    ! "db.postgresql.statements"
    ! "db.postgresql.tuples"
    "db.postgresql.types"
    ! "db.postgresql.fql"
    ! "db.postgresql.orm"
} [ require ] each
