! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs byte-arrays classes
classes.tuple combinators combinators.short-circuit db
db.binders db.connections db.errors db.fql db.persistent
db.statements db.types db.utils fry kernel make math
math.intervals math.ranges multiline random sequences
sequences.deep strings sets ;
FROM: db.types => NULL ;
FROM: db.fql => update ;
FROM: db.fql => delete ;
IN: db.tuples

HOOK: create-table-string db-connection ( class -- statement )
HOOK: drop-table-string db-connection ( class -- statement )
HOOK: insert-tuple-statement db-connection ( tuple -- statement )
HOOK: post-insert-tuple db-connection ( tuple -- )
HOOK: update-tuple-statement db-connection ( tuple -- statement )
HOOK: delete-tuple-statement db-connection ( tuple -- statement )
HOOK: select-tuple-statement db-connection ( tuple -- statement )
HOOK: select-tuples-statement db-connection ( tuple -- statement )
HOOK: count-tuples-statement db-connection ( tuple -- statement )

: modifiers, ( column -- )
    modifiers>> [
        sql-modifiers>string [ " " % % ] unless-empty
    ] unless-empty ;

: create-column, ( column -- )
    [ column-name>> % " " % ]
    [ type>> sql-type>string % ]
    [ dup sql-primary-key? [ drop ] [ modifiers, ] if ] tri ;

M: object create-table-string ( class -- statement )
    lookup-persistent
    [
        "create table " %
        [ table-name>> % "(" % ]
        [
            { [ relation-columns>> ] [ columns>> ] } 1||
            [ ", " % ] [ create-column, ] interleave
        ] [ 
            find-primary-key [
                ", primary key(" %
                [ "," % ] [ column-name>> % ] interleave ")" %
            ] unless-empty
            ")" %
        ] tri
    ] "" make ;

M: object drop-table-string ( class -- string )
    lookup-persistent table-name>> sanitize-sql-name
    "drop table " prepend ;

: remove-db-assigned-key ( columns -- columns' )
    [ +db-assigned-key+? not ] filter ;

: maybe-remove-primary-key ( columns -- columns' )
    remove-db-assigned-key ;

: insert-binders ( tuple persistent -- binders )
    persistent-columns maybe-remove-primary-key [
        {
            [ nip persistent>> table-name>> ]
            [ nip column-name>> ]
            [ nip type>> ]
            [ getter>> call( obj -- obj ) ]
        } 2cleave <in-binder>
    ] with map ;

M: object insert-tuple-statement ( tuple -- statement )
    [ \ insert new ] dip
    dup lookup-persistent {
        [ nip table-name>> >>table ]
        [ insert-binders >>binders ]
    } 2cleave ;

M: object post-insert-tuple drop ;




GENERIC: where-object ( spec obj -- )

: name/type ( obj -- name type )
    [ slot-name>> ] [ type>> ] bi ;

: make-op ( spec obj op-class -- op )
    [ [ name/type ] dip 2array ] dip new-op ;

: (where-object) ( spec obj -- ) \ op-eq make-op , ;

M: object where-object (where-object) ;
M: integer where-object (where-object) ;
M: byte-array where-object (where-object) ;
M: string where-object (where-object) ;

/*
M: interval where-object
    [
        from>> first2 [ \ op-gt-eq make-op ] [ \ op-gt make-op ] if
        REAL <simple-binder> 1array 2array ,
    ] [
        to>> first2 [ \ op-lt-eq make-op ] [ \ op-lt make-op ] if
        REAL <simple-binder> 1array 2array ,
    ] 2bi ;
*/

M: sequence where-object
    [ \ op-eq make-op ] with map <or-sequence> , ;

: many-where ( tuple seq -- )
    [
        [ getter>> call( obj -- obj ) ] keep swap where-object
    ] with each ;

: filter-slots ( tuple specs -- specs' )
    [ slot-name>> swap get-slot-named ] with filter ;

: where-clause ( tuple specs -- where-sequence )
    [ drop ] [ filter-slots ] 2bi
    [ drop f ] [
        [ many-where ] { } make <and-sequence> 
    ] if-empty ;

: set-statement-where ( statement tuple specs -- statement )
    columns>> where-clause >>where ;

: column>out-tuple ( tuple columns -- out-tuple )
    [
        nip first persistent>> [ class>> ] [ table-name>> ] bi
    ] [
        [
            [ nip column-name>> ]
            [ nip type>> ]
            [ nip setter>> ] 2tri 3array
        ] with map
    ] 2bi <out-tuple-binder> ;

: columns>out-tuples ( tuple columns column -- seq )
    [ [ type>> lookup-persistent columns>> column>out-tuple ] with map ]
    [ column>out-tuple prefix ] bi-curry* bi ; inline

: select-columns ( tuple persistent -- seq )
    columns>> [ type>> tuple-class? ] partition columns>out-tuples ;

: column>join ( db-column -- joins )
    [ type>> lookup-persistent table-name>> ]
    [ [ persistent>> table-name>> ] [ column-name>> ] bi "." glue ]
    [
        type>> lookup-persistent [ table-name>> ] [ find-primary-key ] bi
        tuck
        [ [ column-name>> "_" glue ] with map ]
        [ [ column-name>> "." glue ] with map ] 2bi*
    ] tri <left-join> ;

: select-joins ( persistent -- seq )
    columns>> [ type>> tuple-class? ] filter
    [ column>join ] map ;

: select-tuples-no-relations ( tuple -- statement )
    [ \ select new ] dip dup lookup-persistent {
        [ select-columns >>columns ]
        [ nip table-name>> >>from ]
        [ set-statement-where ]
    } 2cleave ;

: select-tuples-relations ( tuple -- statement )
    [ \ select new ] dip dup lookup-persistent {
        [ select-columns >>columns ]
        [ nip table-name>> >>from ]
        [ nip select-joins >>join ]
        [ set-statement-where ]
    } 2cleave ;


M: object select-tuples-statement ( tuple -- statement )
    dup db-relations? [
        select-tuples-relations
    ] [
        select-tuples-no-relations
    ] if ;

M: object select-tuple-statement ( tuple -- statement )
    select-tuples-statement 1 >>limit expand-fql ;



/*
: make-binder ( obj type -- binder )
    [
        {
            { +random-key+ [ drop 64 random-bits ] }
            [ drop ]
        } case
    ] keep <simple-binder> ;


: where-primary-key ( statement tuple specs -- statement )
    find-primary-key where-clause
    [ >>where ] unless-empty ;

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
                [ call( obj -- obj' ) ] with map
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

M: object count-tuples-statement ( tuple -- statement )
    [ \ select new ] dip
    dup lookup-persistent {
        [
            nip [ table-name>> ] [ columns>> ] bi
            first column-name>> "." glue <fql-count> >>names
            f INTEGER <simple-binder> >>names-out
        ]
        [ nip table-name>> >>from ]
        [ set-statement-where ]
    } 2cleave expand-fql ;

: count-tuples ( tuple -- n )
    count-tuples-statement sql-bind-typed-query first first ;
*/

: create-table ( class -- ) create-table-string sql-command ;

: drop-table ( class -- ) drop-table-string sql-command ;

: ensure-table ( class -- )
    '[ [ _ create-table ] ignore-table-exists ] ignore-function-exists ;

: ensure-tables ( seq -- ) [ ensure-table ] each ;

: recreate-table ( class -- )
    [ drop-table ] [ create-table ] bi ;


: select-tuple ( tuple -- tuple'/f )
    select-tuple-statement expand-fql sql-bind-typed-query
    [ f ] [ first ] if-empty ;

: select-tuples ( tuple -- seq )
    select-tuples-statement expand-fql sql-bind-typed-query ;

: select-relations ( tuple -- tuple' )
    [ find-relations ] [
        '[
            drop
            slot-name>> _ [ select-tuple ] change-slot-named drop
        ] assoc-each
    ] [ ] tri ;

: insert-tuple ( tuple -- )
    dup db-relations? [
        select-relations
    ] when

    [ insert-tuple-statement expand-fql sql-bind-typed-command ]
    [ dup special-primary-key? [ post-insert-tuple ] [ drop ] if ] bi ;

/*
: update-tuple ( tuple -- )
    update-tuple-statement sql-bind-typed-command ;

: delete-tuples ( tuple -- )
    delete-tuple-statement sql-bind-typed-command ;
*/
