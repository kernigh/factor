! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db2 db2.connections db2.persistent sequences kernel
db2.errors fry classes db2.utils accessors db2.fql combinators
db2.statements db2.types make db2.binders combinators.short-circuit ;
IN: db2.tuples

HOOK: create-table-statement db-connection ( class -- statement )
HOOK: drop-table-statement db-connection ( class -- statement )

HOOK: insert-tuple-statement db-connection ( tuple -- statement )
HOOK: update-tuple-statement db-connection ( tuple -- statement )
HOOK: delete-tuple-statement db-connection ( tuple -- statement )
HOOK: select-tuple-statement db-connection ( tuple -- statement )
HOOK: select-tuples-statement db-connection ( tuple -- statement )
HOOK: count-tuples-statement db-connection ( tuple -- statement )

M: object create-table-statement ( class -- statement )
    [ statement new ] dip lookup-persistent
    [
        "create table " %
        [ table-name>> % "(" % ]
        [
            columns>> [ ", " % ] [
                [ column-name>> % " " % ]
                [ type>> sql-type>string % ]
                [
                    modifiers>> [
                        { [ PRIMARY-KEY? ] [ AUTOINCREMENT? ] } 1|| not
                    ] filter
                    [ " " % sql-modifiers>string % ] when*
                ] tri
            ] interleave
        ] [ 
            find-primary-key [
                ", " %
                "primary key(" %
                [ "," % ] [ column-name>> % ] interleave
                ")" %
            ] unless-empty
            ")" %
        ] tri
    ] "" make >>sql ;

M: object drop-table-statement ( class -- statement )
    lookup-persistent table-name>> sanitize-sql-name
    "drop table " prepend ;

M: object insert-tuple-statement ( tuple -- statement )
    [ \ insert new ] dip
    dup lookup-persistent {
        [ nip table-name>> >>into ]
        [ nip columns>> [ column-name>> ] map >>names ]
        ! [ slot-values >>values ]
        [
            [
                nip columns>> [ type>> ] map
            ] [
                columns>> [ getter>> ] map
                [ execute( obj -- obj' ) ] with map
            ] 2bi [ <simple-binder> ] 2map >>values
        ]
    } 2cleave expand-fql ;

M: object update-tuple-statement ( tuple -- statement )
    ;

M: object delete-tuple-statement ( tuple -- statement )
    ;

M: object select-tuple-statement ( tuple -- statement )
    ;

M: object select-tuples-statement ( tuple -- statement )
    ;

M: object count-tuples-statement ( tuple -- statement )
    ;

: create-table ( class -- )
    create-table-statement sql-bind-command ;

: drop-table ( class -- )
    drop-table-statement sql-command ;

: ensure-table ( class -- )
    '[ [ _ create-table ] ignore-table-exists ] ignore-function-exists ;

: ensure-tables ( seq -- ) [ ensure-table ] each ;

: recreate-table ( class -- )
    [ drop-table ] [ create-table ] bi ;

: insert-tuple ( tuple -- )
    insert-tuple-statement sql-bind-typed-command ;

: update-tuple ( tuple -- )
    update-tuple-statement sql-bind-typed-command ;

: delete-tuple ( tuple -- )
    delete-tuple-statement sql-bind-typed-command ;

: select-tuple ( tuple -- tuple' )
    [ class ]
    [ select-tuple-statement sql-bind-typed-query first ]
    [ lookup-persistent all-column-setters>> new-filled-tuple ] tri ;

: select-tuples ( tuple -- seq )
    [ select-tuples-statement sql-bind-typed-query ]
    [ class ]
    [ lookup-persistent all-column-setters>> ] tri
    '[ [ _ ] dip _ new-filled-tuple ] map ;

: count-tuples ( tuple -- n )
    count-tuples-statement sql-bind-typed-query ;
