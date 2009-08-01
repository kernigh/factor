! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators db.types fry kernel math.ranges
multiline namespaces sequences ;
IN: db.result-sets

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

: new-result-set ( query handle class -- result-set )
    new
        swap >>handle
        swap {
            [ sql>> >>sql ]
            [ in>> >>in ]
            [ out>> >>out ]
        } cleave ;

: sql-row ( result-set -- seq )
    dup #columns [ column ] with map ;

GENERIC: get-type ( obj -- type )

M: sql-type get-type ;

/*
M: out-string-binder get-type drop VARCHAR ;
M: out-typed-binder get-type type>> ;
M: out-tuple-slot-binder get-type type>> ;
*/

: sql-row-typed ( result-set -- seq )
    [ #columns ] [ out>> ] [ ] tri
    '[ [ _ ] 2dip get-type column-typed ] 2map ;

: sql-row-typed-count ( result-set binder -- seq )
    [
        [ sql-column-counter [ inc ] [ get ] bi ] dip
        get-type column-typed
    ] with map ;
