! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db.introspection db.types kernel orm.persistent
orm.tuples sqlite.db.connections accessors sequences ;
IN: sqlite.db.introspection

TUPLE: sqlite-object type name tbl-name rootpage sql ;

PERSISTENT: { sqlite-object "sqlite_master" }
    { "type" TEXT }
    { "name" TEXT }
    { "tbl-name" TEXT }
    { "rootpage" INTEGER }
    { "sql" TEXT } ;

M: sqlite-db-connection all-db-objects
    sqlite-object new select-tuples ;

M: sqlite-db-connection all-tables
    all-db-objects [ type>> "table" = ] filter ;

M: sqlite-db-connection all-indices
    all-db-objects [ type>> "index" = ] filter ;

