! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays db2 db2.introspection db2.sqlite multiline
sequences kernel db2.statements fry ;
IN: db2.sqlite.introspection

M: sqlite-db-connection query-table-names*
    "SELECT type, name, tbl_name, rootpage, sql from sqlite_master"
    f f <statement> sql-query ;

M: sqlite-db-connection query-table-schema*
    1array [
        <"
        SELECT sql FROM 
           (SELECT * FROM sqlite_master UNION ALL
            SELECT * FROM sqlite_temp_master)
        WHERE type!='meta' and tbl_name = ?
        ORDER BY tbl_name, type DESC, name
        ">
    ] dip f <statement> sql-bind-query first ;

: parse-sqlite-type ( seq string -- seq )
    '[ first _ = ] filter [ second ] map ;

M: sqlite-db-connection parse-table-names
    "table" parse-sqlite-type ;

M: sqlite-db-connection parse-index-names
    "index" parse-sqlite-type ;
