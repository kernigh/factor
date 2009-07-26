! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.postgresql.ffi db.postgresql.types
db.result-sets kernel math sequences ;
IN: db.postgresql.result-sets

TUPLE: postgresql-result-set < result-set ;

M: postgresql-result-set #rows ( result-set -- n )
    handle>> PQntuples ;

M: postgresql-result-set #columns ( result-set -- n )
    handle>> PQnfields ;

: result>handle-n ( result-set -- handle n )
    [ handle>> ] [ n>> ] bi ; inline

M: postgresql-result-set column ( result-set column -- object )
    [ result>handle-n ] dip pq-get-string ;

! M: postgresql-result-set column-typed ( result-set column -- object )
    ! dup pick out>> nth type>>
    ! [ result>handle-n ] 2dip postgresql-column-typed ;

M: postgresql-result-set advance-row ( result-set -- )
    [ 1+ ] change-n drop ;

M: postgresql-result-set more-rows? ( result-set -- ? )
    [ n>> ] [ max>> ] bi < ;
