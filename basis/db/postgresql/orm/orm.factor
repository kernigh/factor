! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: ;
IN: db.postgresql.orm

/*
: create-table-sql ( class -- statement )
    [
        dupd
        "create table " 0% 0%
        "(" 0% [ ", " 0% ] [
            dup column-name>> 0%
            " " 0%
            dup type>> lookup-create-type 0%
            modifiers 0%
        ] interleave

        ", " 0%
        find-primary-key
        "primary key(" 0%
        [ "," 0% ] [ column-name>> 0% ] interleave
        "));" 0%
    ] query-make ;

: create-function-sql ( class -- statement )
    [
        [ dup remove-id ] dip
        "create function add_" 0% dup 0%
        "(" 0%
        over [ "," 0% ]
        [
            type>> lookup-type 0%
        ] interleave
        ")" 0%
        " returns bigint as '" 0%

        "insert into " 0%
        dup 0%
        "(" 0%
        over [ ", " 0% ] [ column-name>> 0% ] interleave
        ") values(" 0%
        swap [ ", " 0% ] [ drop bind-name% ] interleave
        "); " 0%
        "select currval(''" 0% 0% "_" 0%
        find-primary-key first column-name>> 0%
        "_seq'');' language sql;" 0%
    ] query-make ;

M: postgresql-db-connection create-sql-statement ( class -- seq )
    [        [ create-table-sql , ] keep
        dup db-assigned? [ create-function-sql , ] [ drop ] if
    ] { } make ;

: drop-function-sql ( class -- statement )
    [
        "drop function add_" 0% 0%
        "(" 0%
        remove-id
        [ ", " 0% ] [ type>> lookup-type 0% ] interleave
        ");" 0%    ] query-make ;

: drop-table-sql ( table -- statement )
    [
        "drop table " 0% 0% drop
    ] query-make ;

M: postgresql-db-connection drop-sql-statement ( class -- seq )
    [
        [ drop-table-sql , ] keep
        dup db-assigned? [ drop-function-sql , ] [ drop ] if
    ] { } make ;

*/
