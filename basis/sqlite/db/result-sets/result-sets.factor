! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.result-sets db.statements destructors
kernel sqlite.db.connections sqlite.db.lib sqlite.db.types
strings ;
IN: sqlite.db.result-sets

TUPLE: sqlite-result-set < result-set has-more? ;

M: sqlite-result-set dispose
    f >>handle drop ;

M: sqlite-db-connection statement>result-set
    dup handle>>
    sqlite-result-set new-result-set dup advance-row ;

M: sqlite-result-set advance-row ( result-set -- )
    dup handle>> sqlite-next >>has-more? drop ;

M: sqlite-result-set more-rows? ( result-set -- )
    has-more?>> ;

M: sqlite-result-set #columns ( result-set -- n )
    handle>> sqlite-#columns ;

M: sqlite-result-set column ( result-set n type -- obj )
    [ handle>> ] 2dip sqlite-type ;
