! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays continuations db.connections db.errors
db.result-sets db.utils destructors fry kernel sequences math ;

IN: db.statements

TUPLE: statement handle sql in out reconstructor type
retries errors retry-quotation ;

: normalize-statement ( statement -- statement )
    [ obj>vector ] change-out
    [ obj>vector ] change-in ;

: <statement> ( -- statement )
    statement new
        V{ } clone >>out
        V{ } clone >>in
        V{ } clone >>errors ;

: add-sql ( statement sql -- statement )
    '[ _ "" append-as ] change-sql ;

: add-in-params ( statement sql -- statement ) over in>> push-all ;
: add-in-param ( statement sql -- statement ) 1array add-in-params ;
: add-out-params ( statement sql -- statement ) over out>> push-all ;
: add-out-param ( statement sql -- statement ) 1array add-out-params ;

! Statement types

SINGLETON: retryable
ERROR: retryable-failed statement ;

: execute-retry-quotation ( statement -- statement )
    dup retry-quotation>> call( statement -- statement ) ;
 
GENERIC: prepare-statement-type ( statement type -- )
HOOK: statement>result-set db-connection ( statement -- result-set )
HOOK: prepare-statement* db-connection ( statement -- statement' )
HOOK: dispose-statement db-connection ( statement -- )
HOOK: bind-sequence db-connection ( statement -- )
HOOK: bind-typed-sequence db-connection ( statement -- )

ERROR: no-database-in-scope ;

M: statement dispose dispose-statement ;
M: f dispose-statement no-database-in-scope ;

: with-sql-error-handler ( quot -- )
    [ dup sql-error? [ parse-sql-error ] when rethrow ] recover ; inline

M: object prepare-statement-type ( statement type -- )
    2drop ;

M: retryable prepare-statement-type ( statement type -- )
    drop
    dup retries>> 0 > [
        [ 1 - ] change-retries
        [ f prepare-statement-type ] [
            over errors>> push
            execute-retry-quotation
            retryable prepare-statement-type
        ] recover
    ] [
        retryable-failed
    ] if ; inline

: prepare-statement ( statement -- statement )
    [ dup type>> prepare-statement-type ] keep
    [ dup handle>> [ prepare-statement* ] unless ] with-sql-error-handler ;

: result-set-each ( statement quot: ( statement -- ) -- )
    over more-rows?
    [ [ call ] 2keep over advance-row result-set-each ]
    [ 2drop ] if ; inline recursive

: result-set-map ( statement quot -- sequence )
    accumulator [ result-set-each ] dip { } like ; inline

: statement>sequence ( statement word -- sequence )
    [ statement>result-set ] dip
    '[ [ _ execute ] result-set-map ] with-disposal ; inline

: statement>result-sequence ( statement -- sequence )
    \ sql-row statement>sequence ;

: statement>result-sequence-typed ( statement -- sequence )
    \ sql-row-typed statement>sequence ;
