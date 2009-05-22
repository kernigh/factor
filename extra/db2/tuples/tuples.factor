! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays byte-arrays classes combinators
combinators.short-circuit db2 db2.binders db2.connections
db2.errors db2.fql db2.persistent db2.statements db2.types
db2.utils fry kernel make math math.intervals sequences strings
assocs ;
FROM: db2.types => NULL ;
IN: db2.tuples

HOOK: create-table-statement db-connection ( class -- statement )
HOOK: drop-table-statement db-connection ( class -- statement )

HOOK: insert-tuple-statement db-connection ( tuple -- statement )
HOOK: update-tuple-statement db-connection ( tuple -- statement )
HOOK: delete-tuple-statement db-connection ( tuple -- statement )
HOOK: select-tuple-statement db-connection ( tuple -- statement )
HOOK: select-tuples-statement db-connection ( tuple -- statement )
HOOK: count-tuples-statement db-connection ( tuple -- statement )


GENERIC: where ( specs obj -- )

: binder, ( spec obj -- )
    [ type>> ] dip <simple-binder> , ;

: interval-comparison ( ? str -- str )
    "from" = " >" " <" ? swap [ "= " append ] when ;

: (infinite-interval?) ( interval -- ?1 ?2 )
    [ from>> ] [ to>> ] bi
    [ first fp-infinity? ] bi@ ;

: double-infinite-interval? ( obj -- ? )
    dup interval? [ (infinite-interval?) and ] [ drop f ] if ;

: infinite-interval? ( obj -- ? )
    dup interval? [ (infinite-interval?) or ] [ drop f ] if ;

: where-interval ( spec obj from/to -- )
    over first fp-infinity? [
        3drop
    ] [
        pick column-name>> ,
        [ first2 ] dip interval-comparison ,
        binder,
    ] if ;

: parens, ( quot -- ) "(" , call ")" , ; inline

M: interval where ( spec obj -- )
    [
        [ from>> "from" where-interval ]
        [ nip infinite-interval? [ " and " , ] unless ]
        [ to>> "to" where-interval ] 2tri
    ] parens, ;

M: sequence where ( spec obj -- )
    [
        [ " or " , ] [ dupd where ] interleave drop
    ] parens, ;

M: NULL where ( spec obj -- )
    drop column-name>> , " is NULL" , ;

: object-where ( spec obj -- )
    [ swap column-name>> "?" <op-eq> , ]
    [ drop binder, ] 2bi ;

M: byte-array where ( spec obj -- ) object-where ;
M: object where ( spec obj -- ) object-where ;
M: integer where ( spec obj -- ) object-where ;
M: string where ( spec obj -- ) object-where ;

: filter-slots ( tuple specs -- specs' )
    [
        slot-name>> swap get-slot-named
        dup double-infinite-interval? [ drop f ] when
    ] with filter ;

: many-where ( tuple seq -- )
    [
        [ nip column-name>> "?" <op-eq> ]
        [ nip type>> ]
        [ slot-name>> swap get-slot-named ]
        2tri <simple-binder> 2array
    ] with map % ;

: where-clause ( tuple specs -- )
    dupd filter-slots [ drop ] [ many-where ] if-empty ;


M: object create-table-statement ( class -- statement )
    [ statement new ] dip lookup-persistent
    [
        "create table " ,
        [ table-name>> , "(" , ]
        [
            columns>> [ ", " , ] [
                [ column-name>> , " " , ]
                [ type>> sql-type>string , ]
                [
                    modifiers>> [
                        { [ PRIMARY-KEY? ] [ AUTOINCREMENT? ] } 1|| not
                    ] filter
                    [ " " , sql-modifiers>string , ] when*
                ] tri
            ] interleave
        ] [ 
            find-primary-key [
                ", " ,
                "primary key(" ,
                [ "," , ] [ column-name>> , ] interleave
                ")" ,
            ] unless-empty
            ")" ,
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
        [
            [
                nip columns>> [ type>> ] map
            ] [
                columns>> [ getter>> ] map
                [ execute( obj -- obj' ) ] with map
            ] 2bi
            [ <simple-binder> ] 2map >>values
        ]
    } 2cleave expand-fql ;

M: object update-tuple-statement ( tuple -- statement )
    ;

M: object delete-tuple-statement ( tuple -- statement )
    ;

: (select-tuples-statement) ( tuple -- fql )
    [ \ select new ] dip
    dup lookup-persistent {
        [
            nip [ table-name>> ] [ columns>> ] bi
            [ column-name>> "." glue ] with map >>names
        ]
        [
            nip
            [ class>> ]
            [ columns>> [ slot-name>> ] map ]
            [ columns>> [ type>> ] map ] tri
            [ <return-binder> ] 2map <tuple-binder> >>names-out
        ]
        [ nip table-name>> >>from ]
        [
            columns>> [ where-clause ] { } make
            [ keys <and-sequence> >>where ] [ values >>where-in ] bi
        ]
    } 2cleave ;

M: object select-tuple-statement ( tuple -- statement )
    (select-tuples-statement) 1 >>limit expand-fql ;

: full-column-names ( persistent -- seq )
    [ table-name>> ] [ columns>> [ column-name>> ] map ] bi
    [ "." glue ] with map ;

M: object select-tuples-statement ( tuple -- statement )
    (select-tuples-statement) expand-fql ;

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
    select-tuple-statement sql-bind-typed-query first ;

: select-tuples ( tuple -- seq )
    select-tuples-statement sql-bind-typed-query ;

: count-tuples ( tuple -- n )
    count-tuples-statement sql-bind-typed-query ;
