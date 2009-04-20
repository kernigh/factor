! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db2 db2.persistent db2.sqlite db2.statements
db2.statements.private db2.tuples db2.types kernel make
sequences combinators ;
IN: db2.sqlite.tuples

M: sqlite-db-connection create-table-statement ( class -- statement )
    [ statement new ] dip lookup-persistent
    [
        "create table " %
        [ name>> % "(" % ]
        [
            columns>> [ ", " % ] [
                [ name>> % " " % ]
                [ type>> sql-type>string % ]
                [ modifiers>> [ " " % sql-modifiers>string % ] when* ] tri
            ] interleave
        ] bi
        ")" %
    ] "" make >>sql ;

M: sqlite-db-connection drop-table-statement ( class -- statement )
    name>> sanitize-sql-name "drop table " prepend ;

: start-tuple-statement ( tuple -- statement tuple persistent )
    [ statement new ] dip [ ] [ lookup-persistent ] bi ;

M: sqlite-db-connection
   insert-db-assigned-tuple-statement ( tuple -- statement )
B
    start-tuple-statement
    [
        {
            [ nip "insert into table " % name>> % ]
            [
                [
                    remove-user-assigned-id
                    [ "(" % [ ", " % ] [ name>> % ] interleave ")" % ]
                    [
                        "values(" % [ ", " % ] [ "?" % ] interleave ")" %
                    ] bi
                ]
                [ B [ accessor>> execute( obj1 -- obj2 ) push-out ] with each ] bi
            ]
        } 2cleave
    ] "" make >>sql ;

M: sqlite-db-connection
   insert-user-assigned-tuple-statement ( tuple -- statement )
    start-tuple-statement
    [
        {
            [ nip "insert into table " % name>> % ]
        } 2cleave
    ] "" make >>sql
    ;

M: sqlite-db-connection update-tuple-statement ( tuple -- statement )
    drop f f f <statement>
    ;

M: sqlite-db-connection delete-tuple-statement ( tuple -- statement )
    drop f f f <statement>
    ;

M: sqlite-db-connection select-tuple-statement ( tuple -- statement )
    drop f f f <statement>
    ;

M: sqlite-db-connection select-tuples-statement ( tuple -- statement )
    drop f f f <statement>
    ;
