! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.result-sets destructors kernel
mysql.db.connections mysql.db.ffi mysql.db.lib ;
IN: mysql.db.result-sets

TUPLE: mysql-result-set < result-set ;

M: mysql-result-set #rows ( result-set -- n )
    handle>> [ mysql-#rows ] [ 0 ] if* ;

M: mysql-result-set #columns ( result-set -- n )
    handle>> [ mysql-#columns ] [ 0 ] if* ;

! M: mysql-result-set row-column ( result-set n -- obj )
    ! [ handle>> ] dip mysql-column ;

! M: mysql-result-set row-column-typed ( result-set n -- obj )
    ! [ handle>> ] dip mysql-column-typed ;

M: mysql-result-set advance-row ( result-set -- )
    handle>> [ mysql-next drop ] when* ;

M: mysql-result-set more-rows? ( result-set -- ? )
    handle>> [ current_row>> ] [ f ] if* ;

M: mysql-result-set dispose ( result-set -- )
    [ handle>> [ mysql_free_result ] when* ]
    [
        0 >>n
        0 >>max
        f >>handle drop
    ] bi ;

M: mysql-db-connection statement>result-set
    dup handle>> mysql_stmt_execute
    [ dup handle>> ] dip mysql-stmt-check-result ;

