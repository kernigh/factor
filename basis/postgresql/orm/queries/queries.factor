! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays combinators combinators.smart
db.statements db.types kernel locals make math.parser
math.ranges nested-comments orm.persistent orm.queries
postgresql.db.connections.private sequences ;
IN: postgresql.orm.queries

M: postgresql-db-connection insert-db-assigned-key-sql
    [ <statement> ] dip >persistent {
        [ table-name>> "select add_" prepend add-sql "(" add-sql ]
        [
            [ find-primary-key first add-in ]
            [
                columns>>
                remove-primary-key
                [ [ ", " % ] [ column-name>> % ] interleave ] "" make add-sql
                ");" add-sql
            ] bi
        ]
    } cleave ;

(*
: bind-name% ( column -- )
    ;

M: postgresql-db-connection insert-user-assigned-key-sql
    [ <statement> ] dip >persistent {
        [ table-name>> "INSERT INTO " prepend add-sql "(" add-sql ]
        [
            [
                columns>>
                [
                    [
                        [ ", " % ] [ column-name>> % ] interleave 
                        ")" %
                    ] "" make add-sql
                ] [
                    " values(" %
                    [ ", " % ] [
                        dup type>> +random-key+ = [
                            [
                                bind-name%
                                slot-name>>
                                f
                                random-id-generator
                            ] [ type>> ] bi <generator-bind> 1,
                        ] [
                            bind%
                        ] if
                    ] interleave
                    ");" 0%
                ] bi
            ]
    } cleave ;
*)


: postgresql-create-table ( tuple-class -- string )
    >persistent dup table-name>>
    [
        [
            [ columns>> ] dip
            "CREATE TABLE " % %
            "(" % [ ", " % ] [
                [ column-name>> % " " % ]
                [ type>> sql-create-type>string % ]
                [ drop ] tri
                ! [ modifiers % ] bi
            ] interleave
        ] [
            drop
            find-primary-key [
                ", " %
                "PRIMARY KEY(" %
                [ "," % ] [ column-name>> % ] interleave
                ")" %
            ] unless-empty
            ");" %
        ] 2bi
    ] "" make ;

: trim-quotes ( string -- string' )
    [ CHAR: " = ] trim ;

:: postgresql-create-function ( tuple-class -- string )
    tuple-class >persistent :> persistent
    persistent table-name>> :> table-name
    table-name trim-quotes :> table-name-unquoted
    persistent columns>> :> columns
    columns remove-primary-key :> columns-minus-key

    [
        "CREATE FUNCTION add_" table-name-unquoted "("

        columns-minus-key [ type>> sql-type>string ] map ", " join

        ") returns bigint as 'insert into "

        table-name "(" columns-minus-key [ column-name>> ] map ", " join
        ") values("
        1 columns-minus-key length [a,b]
        [ number>string "$" prepend ] map ", " join

        "); select currval(''" table-name-unquoted "_"
        persistent find-primary-key first column-name>>
        "_seq'');' language sql;"
    ] "" append-outputs-as ;

: db-assigned-key? ( persistent -- ? )
     find-primary-key [ type>> +db-assigned-key+ = ] all? ;

M: postgresql-db-connection create-table-sql ( tuple-class -- seq )
    [ postgresql-create-table ]
    [ dup db-assigned-key? [ postgresql-create-function 2array ] [ drop ] if ] bi ;


:: postgresql-drop-table ( tuple-class -- string )
    tuple-class >persistent table-name>> :> table-name
    [
        "drop table " table-name ";"
    ] "" append-outputs-as ;

:: postgresql-drop-function ( tuple-class -- string )
    tuple-class >persistent :> persistent
    persistent table-name>> :> table-name
    table-name trim-quotes :> table-name-unquoted
    persistent columns>> :> columns
    columns remove-primary-key :> columns-minus-key
    [
        "drop function add_" table-name-unquoted
        "("
        columns-minus-key [ type>> sql-type>string ] map ", " join
        ");"
    ] "" append-outputs-as ;

M: postgresql-db-connection drop-table-sql ( tuple-class -- seq )
    [ postgresql-drop-table ]
    [ dup db-assigned-key? [ postgresql-drop-function 2array ] [ drop ] if ] bi ;
    
