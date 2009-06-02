! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs byte-arrays classes combinators
combinators.short-circuit db2 db2.binders db2.connections
db2.errors db2.fql db2.persistent db2.statements db2.types
db2.utils fry kernel make math math.intervals math.ranges
multiline random sequences sequences.deep strings ;
FROM: db2.types => NULL ;
FROM: db2.fql => update ;
FROM: db2.fql => delete ;
IN: db2.tuples

ERROR: unimplemented ;

HOOK: create-table-statement db-connection ( class -- statement )
HOOK: drop-table-statement db-connection ( class -- statement )

HOOK: insert-tuple-statement db-connection ( tuple -- statement )
HOOK: post-insert-tuple db-connection ( tuple -- )
HOOK: update-tuple-statement db-connection ( tuple -- statement )
HOOK: delete-tuple-statement db-connection ( tuple -- statement )
HOOK: select-tuple-statement db-connection ( tuple -- statement )
HOOK: select-tuples-statement db-connection ( tuple -- statement )
HOOK: count-tuples-statement db-connection ( tuple -- statement )

GENERIC# where-object 1 ( obj spec -- )

: (where-object) ( obj spec -- )
    swap [
        drop slot-name>> "?" <op-eq>
    ] [
        [ type>> ] dip <simple-binder> 1array
    ] 2bi 2array , ;

M: object where-object (where-object) ;
M: integer where-object (where-object) ;
M: byte-array where-object (where-object) ;
M: string where-object (where-object) ;
M: interval where-object
    swap
    [
        from>> first2 [
            [ slot-name>> "?" <op-gt-eq> ] dip
        ] [
            [ slot-name>> "?" <op-gt> ] dip
        ] if
        REAL swap <simple-binder> 1array 2array ,
    ] [
        to>> first2 [
            [ slot-name>> "?" <op-lt-eq> ] dip
        ] [
            [ slot-name>> "?" <op-lt> ] dip
        ] if
        REAL swap <simple-binder> 1array 2array ,
    ] 2bi ;

M: sequence where-object
    swap [
        [
            drop slot-name>> "?" <op-eq>
        ] [
            [ type>> ] dip <simple-binder>
        ] 2bi 2array
    ] with map [ keys <or-sequence> ] [ values ] bi 2array , ;

: many-where ( tuple seq -- )
    [
        [ getter>> execute( obj -- obj ) ] keep where-object
    ] with each ;

: filter-slots ( tuple specs -- specs' )
    [ slot-name>> swap get-slot-named ] with filter ;

: where-clause ( tuple specs -- and-sequence binder-sequence )
    [ drop ] [ filter-slots ] 2bi
    [ drop f f ]
    [
        [ many-where ] { } make
        [ keys <and-sequence> ] [ values concat ] bi
    ] if-empty ;

: set-statement-where ( statement tuple specs -- statement )
    columns>> where-clause
    [ drop ] [ [ >>where ] [ >>where-in ] bi* ] if-empty ;

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
                    dup sql-primary-key? not
                    [ " " % modifiers>> sql-modifiers>string % ] [ drop ] if
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

: make-binder ( type obj -- binder )
    over {
        { +random-key+ [ drop 64 random-bits <simple-binder> ] }
        [ drop <simple-binder> ]
    } case ;

M: object insert-tuple-statement ( tuple -- statement )
    [ \ insert new ] dip
    dup lookup-persistent {
        [ nip table-name>> >>into ]
        [ nip columns>> [ column-name>> ] map >>names ]
        [
            [
                nip columns>> [ type>> ] map
            ] [
                columns>> [ getter>> ] map
                [ execute( obj -- obj' ) ] with map
            ] 2bi
            [ make-binder ] 2map >>values
        ]
    } 2cleave expand-fql ;

: qualified-names ( table-name columns -- string )
    [ column-name>> "." glue ] with map ;

: persistent>qualified-names ( persistent -- string )
    [ table-name>> ] [ columns>> ] bi qualified-names ;

: where-primary-key ( statement tuple specs -- statement )
    find-primary-key where-clause
    [ drop ] [ [ >>where ] [ >>where-in ] bi* ] if-empty ;

M: object update-tuple-statement ( tuple -- statement )
    [ \ update new ] dip
    dup lookup-persistent {
        [ nip table-name>> >>tables ]
        [
            nip
            remove-primary-key [ column-name>> ] map >>keys
        ]
        [
            [ nip remove-primary-key [ type>> ] map ]
            [
                remove-primary-key [ getter>> ] map
                [ execute( obj -- obj' ) ] with map
            ] 2bi

            [ <simple-binder> ] 2map >>values
        ]
        [ where-primary-key ]
    } 2cleave expand-fql ;

M: object delete-tuple-statement ( tuple -- statement )
    [ \ delete new ] dip
    dup lookup-persistent {
        [ nip table-name>> >>tables ]
        [ set-statement-where ]
    } 2cleave expand-fql ;

: (select-tuples-statement) ( tuple -- fql )
    [ \ select new ] dip
    dup lookup-persistent {
        [ nip persistent>qualified-names >>names ]
        [
            nip
            [ class>> ]
            [ columns>> [ slot-name>> ] map ]
            [ columns>> [ type>> ] map ] tri
            [ <return-binder> ] 2map <tuple-binder> >>names-out
        ]
        [ nip table-name>> >>from ]
        [ set-statement-where ]
    } 2cleave ;

M: object select-tuple-statement ( tuple -- statement )
    (select-tuples-statement) 1 >>limit expand-fql ;

: full-column-names ( persistent -- seq )
    [ table-name>> ] [ columns>> [ column-name>> ] map ] bi
    [ "." glue ] with map ;

M: object select-tuples-statement ( tuple -- statement )
    (select-tuples-statement) expand-fql ;

M: object count-tuples-statement ( tuple -- statement )
    [ \ select new ] dip
    dup lookup-persistent {
        [
            nip [ table-name>> ] [ columns>> ] bi
            first column-name>> "." glue <fql-count> >>names
            INTEGER f <simple-binder> >>names-out
        ]
        [ nip table-name>> >>from ]
        [ set-statement-where ]
    } 2cleave expand-fql ;

: create-table ( class -- )
    create-table-statement sql-bind-command ;

: drop-table ( class -- )
    drop-table-statement sql-command ;

: ensure-table ( class -- )
    '[ [ _ create-table ] ignore-table-exists ] ignore-function-exists ;

: ensure-tables ( seq -- ) [ ensure-table ] each ;

: recreate-table ( class -- )
    [ drop-table ] [ create-table ] bi ;

M: object post-insert-tuple drop ;

: insert-tuple ( tuple -- )
    dup class lookup-persistent find-primary-key
    [ type>> { +db-assigned-key+ +random-key+ } member? ] any?
    [
        [ insert-tuple-statement sql-bind-typed-command ]
        [ post-insert-tuple ] bi
    ] [
        insert-tuple-statement sql-bind-typed-command
    ] if ;

: update-tuple ( tuple -- )
    update-tuple-statement sql-bind-typed-command ;

: delete-tuples ( tuple -- )
    delete-tuple-statement sql-bind-typed-command ;

: select-tuple ( tuple -- tuple'/f )
    select-tuple-statement sql-bind-typed-query
    [ f ] [ first ] if-empty ;

: select-tuples ( tuple -- seq )
    select-tuples-statement sql-bind-typed-query ;

: count-tuples ( tuple -- n )
    count-tuples-statement sql-bind-typed-query first first ;
