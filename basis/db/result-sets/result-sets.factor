! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators db.binders db.types fry kernel
math.ranges namespaces sequences ;
IN: db.result-sets

TUPLE: result-set handle sql in out n max ;

GENERIC: #rows ( result-set -- n )
GENERIC: #columns ( result-set -- n )
GENERIC: advance-row ( result-set -- )
GENERIC: more-rows? ( result-set -- ? )
GENERIC# column 1 ( result-set column -- obj )
GENERIC# column-typed 2 ( result-set column type -- sql )
GENERIC: get-type ( binder/word -- type )

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
    dup #columns iota [ column ] with map ;

: sql-row-typed ( result-set -- seq )
    [ #columns iota ] [ out>> ] [ ] tri
    '[ [ _ ] 2dip get-type column-typed ] 2map ;

M: sql-type get-type ;

M: out-binder get-type type>> ;

M: out-binder-low get-type type>> ;
