! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel sequences combinators fry
db2.types db2.binders math.ranges namespaces ;
IN: db2.result-sets

SYMBOL: sql-column-counter

TUPLE: result-set handle sql in out n max ;

GENERIC: #rows ( result-set -- n )
GENERIC: #columns ( result-set -- n )
GENERIC: advance-row ( result-set -- )
GENERIC: more-rows? ( result-set -- ? )
GENERIC# column 1 ( result-set column -- obj )
GENERIC# column-typed 2 ( result-set column type -- sql )

: init-result-set ( result-set -- result-set )
    dup #rows >>max
    0 >>n ;

: new-result-set ( query class -- result-set )
    new
        swap {
            [ handle>> >>handle ]
            [ sql>> >>sql ]
            [ in>> >>in ]
            [ out>> >>out ]
        } cleave ;

: sql-row ( result-set -- seq )
    dup #columns [ column ] with map ;

GENERIC: get-type ( obj -- type )

M: sql-type get-type ;
M: binder get-type type>> ;

: sql-row-typed ( result-set -- seq )
    [ #columns ] [ out>> ] [ ] tri
    '[ [ _ ] 2dip get-type column-typed ] 2map ;

: sql-row-typed-count ( result-set binder -- seq )
    [
        [ sql-column-counter [ inc ] [ get ] bi ] dip
        get-type column-typed
    ] with map ;

! : sql-row-typed-slice ( from to result-set -- seq )
    ! [ [a,b) ] dip [ out>> ] keep
    ! '[ [ _ ] 2dip get-type get-type ] 2map ;
