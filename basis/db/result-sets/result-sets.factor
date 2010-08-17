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
GENERIC# column 2 ( result-set column type -- sql )
GENERIC: get-type ( binder/word -- type )

: init-result-set ( result-set -- result-set )
    dup #rows >>max
    0 >>n ; inline

: new-result-set ( query handle class -- result-set )
    new
        swap >>handle
        swap {
            [ sql>> >>sql ]
            [ in>> >>in ]
            [ out>> >>out ]
        } cleave ; inline

ERROR: result-set-length-mismatch result-set #columns out-length ;

: validate-result-set ( result-set -- result-set )
    dup [ #columns ] [ out>> length ] bi 2dup = [
        2drop
    ] [
        result-set-length-mismatch
    ] if ;

: sql-row ( result-set -- seq )
    [ #columns iota ] [ out>> ] [ ] tri over empty? [
        nip
        '[ [ _ ] dip VARCHAR column ] map
    ] [
        validate-result-set
        '[ [ _ ] 2dip get-type column ] 2map
    ] if ;

M: sql-type get-type ;

M: out-binder get-type type>> ;

M: out-binder-low get-type type>> ;
