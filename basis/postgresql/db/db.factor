! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences vocabs.loader ;
IN: postgresql.db

TUPLE: postgresql-db
    host port pgopts pgtty database username password ;

: <postgresql-db> ( -- postgresql-db )
    postgresql-db new ; inline

{
    "postgresql.db.connections"
    "postgresql.db.errors"
    "postgresql.db.ffi"
    "postgresql.db.lib"
    "postgresql.db.result-sets"
    "postgresql.db.statements"
    "postgresql.db.types"
    "postgresql.db.queries"
    ! "postgresql.db.introspection"

    "postgresql.orm"
} [ require ] each
