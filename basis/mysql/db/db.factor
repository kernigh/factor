! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences vocabs.loader ;
IN: mysql.db

TUPLE: mysql-db host username password database port ;

: <mysql-db> ( -- db )
    f f f f 0 mysql-db boa ;

{
    "mysql.db.ffi"
    "mysql.db.lib"
    "mysql.db.connections"
    "mysql.db.statements"
    "mysql.db.result-sets"
} [ require ] each
