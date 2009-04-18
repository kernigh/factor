! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db2 db2.sqlite db2.statements db2.tuples
kernel sequences db2.persistent ;
IN: db2.sqlite.tuples

M: sqlite-db-connection create-table-statement ( class -- statement )
    lookup-persistent B
    ! drop f f f <statement>
    ;

M: sqlite-db-connection drop-table-statement ( class -- statement )
    name>> sanitize-sql-name "drop table " prepend ;

M: sqlite-db-connection insert-tuple-statement ( tuple -- statement )
    drop f f f <statement>
    ;

M: sqlite-db-connection update-tuple-statement ( tuple -- statement )
    drop f f f <statement>
    ;

M: sqlite-db-connection delete-tuple-statement ( tuple -- statement )
    drop f f f <statement>
    ;

M: sqlite-db-connection select-tuple-statement ( tuple -- statement )
    drop f f f <statement>
    ;

M: sqlite-db-connection select-tuples-statement ( tuple -- statement )
    drop f f f <statement>
    ;
