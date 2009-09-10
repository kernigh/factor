! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays continuations db.connections db.errors
db.result-sets db.utils destructors fry kernel sequences ;
IN: db.statements

TUPLE: statement handle sql in out reconstructor type ;

TUPLE: parameter type value ;

TUPLE: tuple-parameter < parameter db-column ;

: <tuple-parameter> ( value db-column -- obj )
    tuple-parameter new
        swap >>db-column
        swap >>value ;

: normalize-statement ( statement -- statement )  
    [ obj>vector ] change-out
    [ obj>vector ] change-in ;

: <statement> ( -- statement )
    statement new
        V{ } clone >>out
        V{ } clone >>in ;

: add-sql ( statement sql -- statement )
    '[ _ "" append-as ] change-sql ;

: add-in-params ( statement sql -- statement ) over in>> push-all ;
: add-in-param ( statement sql -- statement ) 1array add-in-params ;
: add-out-params ( statement sql -- statement ) over out>> push-all ;
: add-out-param ( statement sql -- statement ) 1array add-out-params ;

HOOK: statement>result-set db-connection ( statement -- result-set )
HOOK: execute-statement* db-connection ( statement type -- )
HOOK: prepare-statement* db-connection ( statement -- statement' )
HOOK: dispose-statement db-connection ( statement -- )
HOOK: bind-sequence db-connection ( statement -- )
HOOK: bind-typed-sequence db-connection ( statement -- )

ERROR: no-database-in-scope ;

M: statement dispose dispose-statement ;
M: f dispose-statement no-database-in-scope ;

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

: statement>result-sequence-typed ( statement -- sequence )
    statement>result-set [ [ sql-row-typed ] result-set-map ] with-disposal ;
