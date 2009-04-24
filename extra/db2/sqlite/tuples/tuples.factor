! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db2 db2.persistent db2.sqlite db2.statements
db2.tuples db2.types kernel make sequences combinators assocs
arrays ;
USE: multiline
IN: db2.sqlite.tuples

M: sqlite-db-connection create-table-statement ( class -- statement )
    [ statement new ] dip lookup-persistent
    [
        "create table " %
        [ table-name>> % "(" % ]
        [
            columns>> [ ", " % ] [
                [ column-name>> % " " % ]
                [ type>> sql-type>string % ]
                [ modifiers>> [ " " % sql-modifiers>string % ] when* ] tri
            ] interleave
        ] bi
        ")" %
    ] "" make >>sql ;

M: sqlite-db-connection drop-table-statement ( class -- statement )
    lookup-persistent table-name>> sanitize-sql-name "drop table " prepend ;

: start-tuple-statement ( tuple -- statement tuple persistent )
    [ <empty-statement> ] dip [ ] [ lookup-persistent ] bi ;

: types-slots ( tuple persistent -- types slots )
    [ nip column-types>> ]
    [ accessor-quot>> call( tuple -- seq ) ] 2bi ;

: types/slots ( tuple persistent -- sequence )
    types-slots zip ;

: types/slots/names ( tuple persistent -- types/slots/names )
    [ types-slots ]
    [ nip column-names>> ] 2bi 3array flip ;

M: sqlite-db-connection insert-tuple-statement ( tuple -- statement )
    start-tuple-statement
    [
        {
            [ nip "insert into " % table-name>> % "(" % ]
            [ nip insert-string>> % ")" % ]
            [
                nip
                " values(" %
                column-names>> length iota
                [ ", " % ] [ drop "?" % ] interleave ")" %
            ]
            [
                types/slots over in>> push-all
            ] 
        } 2cleave
    ] "" make >>sql ;

M: sqlite-db-connection update-tuple-statement ( tuple -- statement )
    start-tuple-statement
    [
        {
            [ nip "update " % table-name>> % " set " % ]
            [ nip update-string>> % " where " % ]
            [ nip primary-key-names>> [ " = ?" append ] map ", " join % ]
            [ primary-key-quot>> call( tuple -- seq ) over in>> push-all ] 
        } 2cleave
    ] "" make >>sql ;

M: sqlite-db-connection delete-tuple-statement ( tuple -- statement )
    "unimplemented" throw ;

M: sqlite-db-connection select-tuple-statement ( tuple -- statement )
    "unimplemented" throw ;

M: sqlite-db-connection select-tuples-statement ( tuple -- statement )
    start-tuple-statement
    [
        {
            [ nip "select " % column-names>> ", " join % ]
            [ nip " from " % table-name>> % ]
            [
                " where " % types/slots/names
                [ second ] filter
                [ [ third " = ?" append ] map ", " join % ]
                [ [ 2 head ] map over in>> push-all ] bi
            ]
            [ nip all-column-types>> over out>> push-all ]
        } 2cleave
    ] "" make >>sql ;
