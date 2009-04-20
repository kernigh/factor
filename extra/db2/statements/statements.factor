! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors continuations db2.connections db2.errors
db2.result-sets db2.utils destructors fry kernel sequences
strings vectors ;
IN: db2.statements

TUPLE: statement handle sql in out type ;

<PRIVATE

: obj>vector ( obj -- vector )
    V{ } clone or
    dup string? [ 1vector ] [ >vector ] if ;

: <statement> ( sql in out -- statement )
    statement new
        swap obj>vector >>out
        swap obj>vector >>in
        swap >>sql ;

PRIVATE>

HOOK: statement>result-set* db-connection ( statement -- result-set )
HOOK: execute-statement* db-connection ( statement type -- )
HOOK: prepare-statement* db-connection ( statement -- statement' )
HOOK: dispose-statement db-connection ( statement -- )
HOOK: bind-sequence db-connection ( statement -- )
HOOK: bind-typed-sequence db-connection ( statement -- )

M: statement dispose dispose-statement ;

: statement>result-set ( statement -- result-set )
    [ statement>result-set* ]
    [ dup sql-error? [ parse-sql-error ] when rethrow ] recover ;

M: object execute-statement* ( statement type -- )
    drop statement>result-set dispose ;

: execute-one-statement ( statement -- )
    dup type>> execute-statement* ;

: execute-statement ( statement -- )
    dup sequence?
    [ [ execute-one-statement ] each ]
    [ execute-one-statement ] if ;

: prepare-statement ( statement -- statement )
    dup handle>> [ prepare-statement* ] unless ;

: result-set-each ( statement quot: ( statement -- ) -- )
    over more-rows?
    [ [ call ] 2keep over advance-row result-set-each ]
    [ 2drop ] if ; inline recursive

: result-set-map ( statement quot -- sequence )
    accumulator [ result-set-each ] dip { } like ; inline

: statement>result-sequence ( statement -- sequence )
    statement>result-set [ [ sql-row ] result-set-map ] with-disposal ;

: statement>typed-result-sequence ( statement -- sequence )
    statement>result-set
    [ [ sql-row-typed ] result-set-map ] with-disposal ;

: push-in ( statement parameter -- statement )
    over in>> push ;

: push-out ( statement parameter -- statement )
    over out>> push ;
