! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.statements destructors kernel math multiline
sequences strings summary ;
IN: db

ERROR: no-in-types statement ;
ERROR: no-out-types statement ;

GENERIC: sql-command ( object -- )
GENERIC: sql-query ( object -- sequence )
GENERIC: sql-bind-command ( object -- )
GENERIC: sql-bind-query ( object -- sequence )
GENERIC: sql-bind-typed-command ( object -- )
GENERIC: sql-bind-typed-query ( object -- sequence )

M: string sql-command ( string -- )
    <statement>
        swap >>sql
    sql-command ;

M: string sql-query ( string -- sequence )
    <statement>
        swap >>sql
    sql-query ;

M: statement sql-command ( statement -- )
    [
        prepare-statement
        [ bind-sequence ] [ statement>result-set drop ] bi
    ] with-disposal ;

M: statement sql-query ( statement -- sequence )
    [
        prepare-statement
        [ bind-sequence ] [ statement>result-sequence ] bi
    ] with-disposal ;

M: statement sql-bind-typed-command ( statement -- )
    [
        prepare-statement
        [ bind-typed-sequence ] [ statement>result-set drop ] bi
    ] with-disposal ;

M: no-out-types summary
    drop "SQL types are required for the return values of this query" ;

M: statement sql-bind-typed-query ( statement -- sequence )
    [
        dup out>> empty? [ no-out-types ] when
        prepare-statement
        [ bind-typed-sequence ] [ statement>result-sequence-typed ] bi
    ] with-disposal ;

M: sequence sql-command [ sql-command ] each ;
M: sequence sql-query [ sql-query ] map ;
M: sequence sql-bind-typed-command [ sql-bind-typed-command ] each ;
M: sequence sql-bind-typed-query [ sql-bind-typed-query ] map ;

M: integer sql-command throw ;
M: integer sql-query throw ;
M: integer sql-bind-command throw ;
M: integer sql-bind-query throw ;
M: integer sql-bind-typed-command throw ;
M: integer sql-bind-typed-query throw ;
