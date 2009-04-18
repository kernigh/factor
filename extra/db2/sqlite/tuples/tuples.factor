! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db2.sqlite db2.statements db2.tuples kernel ;
IN: db2.sqlite.tuples

M: sqlite-db create-table-statement ( class -- statement )
    ;

M: sqlite-db drop-table-statement ( class -- statement )
    [ "drop table ?" ] dip name>> f <statement> ;

M: sqlite-db insert-tuple-statement ( tuple -- statement )
    ;

M: sqlite-db update-tuple-statement ( tuple -- statement )
    ;

M: sqlite-db delete-tuple-statement ( tuple -- statement )
    ;

M: sqlite-db select-tuple-statement ( tuple -- statement )
    ;

M: sqlite-db select-tuples-statement ( tuple -- statement )
    ;
