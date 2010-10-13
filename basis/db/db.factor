! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors continuations db.statements destructors fry
kernel locals math sequences strings summary ;
IN: db

ERROR: no-in-types statement ;
ERROR: no-out-types statement ;

GENERIC: sql-command ( object -- )
GENERIC: sql-query ( object -- sequence )

M: string sql-command ( string -- )
    <statement>
        swap >>sql
    sql-command ;

M: string sql-query ( string -- sequence )
    <statement>
        swap >>sql
    sql-query ;

ERROR: retryable-failed statement ;

: execute-retry-quotation ( statement -- statement )
    dup retry-quotation>> call( statement -- statement ) ;

:: (run-retryable) ( statement quot: ( statement -- statement ) -- obj )
    statement retries>> 0 > [
        statement [ 1 - ] change-retries drop
        [
            statement quot call
        ] [
            statement errors>> push
            statement execute-retry-quotation reset-statement
            quot (run-retryable)
        ] recover
    ] [
        statement retryable-failed
    ] if ; inline recursive

: run-retryable ( statement quot -- )
    over retries>> [
        '[ _ (run-retryable) ] with-disposal
    ] [
        with-disposal
    ] if ; inline

M: statement sql-command ( statement -- )
    [
        prepare-statement
        [ bind-sequence ] [ statement>result-set ] bi
    ] run-retryable drop ; inline

M: statement sql-query ( statement -- sequence )
    [
        prepare-statement
        [ bind-sequence ] [ statement>result-sequence ] bi
    ] run-retryable ; inline

M: sequence sql-command [ sql-command ] each ;
M: sequence sql-query [ sql-query ] map ;
