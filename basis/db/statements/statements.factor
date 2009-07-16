! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors continuations db.connections db.errors
db.result-sets db.utils destructors fry kernel sequences
strings vectors db.binders db.types namespaces math
combinators.short-circuit ;
IN: db.statements

TUPLE: statement handle sql in out type ;

TUPLE: parameter type value ;

TUPLE: tuple-parameter < parameter db-column ;

: <tuple-parameter> ( value db-column -- obj )
    tuple-parameter new
        swap >>db-column
        swap >>value ;

<PRIVATE

: obj>vector ( obj -- vector )
    dup { [ sequence? ] [ integer? not ] } 1&& [
        >vector
    ] [
        1vector
    ] if ;

PRIVATE>

: normalize-statement ( statement -- statement )  
    [ obj>vector ] change-out
    [ obj>vector ] change-in ;

: empty-statement ( -- statement )
    statement new
        V{ } clone >>in
        V{ } clone >>out ;

: <statement> ( sql in out -- statement )
    statement new
        swap >>out
        swap >>in
        swap >>sql
        normalize-statement ;

: <empty-statement> ( -- statement )
    f f f <statement> ;

: add-sql ( statement sql -- statement )
    '[ _ "" append-as ] change-sql ;

: add-in-param ( statement sql -- statement ) over in>> push ;
: add-in-params ( statement sql -- statement ) over in>> push-all ;
: add-out-param ( statement sql -- statement ) over out>> push ;
: add-out-params ( statement sql -- statement ) over out>> push-all ;

HOOK: statement>result-set db-connection ( statement -- result-set )
HOOK: execute-statement* db-connection ( statement type -- )
HOOK: prepare-statement* db-connection ( statement -- statement' )
HOOK: dispose-statement db-connection ( statement -- )
HOOK: bind-sequence db-connection ( statement -- )
HOOK: bind-typed-sequence db-connection ( statement -- )

M: statement dispose dispose-statement ;

: with-sql-error-handler ( quot -- )
    [ dup sql-error? [ parse-sql-error ] when rethrow ] recover ; inline

M: object execute-statement* ( statement type -- )
    drop statement>result-set dispose ;

: execute-one-statement ( statement -- )
    dup type>> execute-statement* ;

: execute-statement ( statement -- )
    dup sequence?
    [ [ execute-one-statement ] each ]
    [ execute-one-statement ] if ;

: prepare-statement ( statement -- statement )
    [ dup handle>> [ prepare-statement* ] unless ] with-sql-error-handler ;

: result-set-each ( statement quot: ( statement -- ) -- )
    over more-rows?
    [ [ call ] 2keep over advance-row result-set-each ]
    [ 2drop ] if ; inline recursive

: result-set-map ( statement quot -- sequence )
    accumulator [ result-set-each ] dip { } like ; inline

: statement>result-sequence ( statement -- sequence )
    statement>result-set [ [ sql-row ] result-set-map ] with-disposal ;

: return-tuple ( result-set -- seq )
    -1 sql-column-counter [
        dup out>> [
            [ nip class>> ]
            [ binders>> sql-row-typed-count ]
            [ nip binders>> [ setter>> ] map ] 2tri new-filled-tuple
        ] with map
    ] with-variable ;

: return-sequence ( result-set -- seq ) sql-row-typed ;

: return-tuples? ( result-set -- ? ) [ out-tuple-binder? ] all? ;

: statement>typed-result-sequence ( statement -- sequence )
    normalize-statement
    statement>result-set
    [
        dup out>> return-tuples? [
            [ return-tuple ] result-set-map
            dup {
                [ length 0 > ]
                [ first length 1 = ]
            } 1&& [ concat ] when
        ] [
            [ return-sequence ] result-set-map
        ] if
    ] with-disposal ;
