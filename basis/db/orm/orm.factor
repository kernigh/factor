! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs classes.mixin classes.parser
classes.singleton classes.tuple combinators db.binders
db.connections db.orm.fql db.orm.persistent db.types db.utils
fry kernel lexer locals mirrors multiline sequences db.statements ;
IN: db.orm


: filter-ignored-columns ( tuple -- columns' )
    [ lookup-persistent columns>> ] [ <mirror> ] bi
    '[ slot-name>> _ at IGNORE = not ] filter ;

: filter-functions ( tuple -- columns' )
    [ lookup-persistent columns>> ] [ <mirror> ] bi
    '[ slot-name>> _ at \ aggregate-function subclass? not ] filter ;

TUPLE: renamed-table table renamed ;


: create-many:many-table ( class1 class2 -- statement )
    [ statement new ] 2dip
    {
        [ 2drop "CREATE TABLE " add-sql ]
        [
            [ lookup-persistent table-name>> ] bi@ "_" glue
            "_join_table(id primary key serial, " append add-sql
        ]
        [ [ class>primary-key-create ] bi@ ", " glue add-sql ");" add-sql ]
    } 2cleave ;

: create-table ( class -- statement )
    [ statement new ] dip
    {
        [ drop "CREATE TABLE " add-sql ]
        [ table-name add-sql "(" add-sql ]
        [
            lookup-persistent columns>>
            [ column>create-text ] map sift ", " join add-sql ");" add-sql
        ]
    } cleave ;

: drop-table ( class -- statement )
    table-name [ "DROP TABLE " ] dip ";" 3append
    statement new
        swap >>sql ;


: columns>out-tuple ( columns -- out-tuple )
    [ first persistent>> [ class>> ] [ table-name>> ] bi ]
    [
        [
            [ column-name>> ]
            [ type>> ]
            [ setter>> ] tri <out-tuple-slot-binder>
        ] map
    ] bi <out-tuple-binder> ;

: columns>out-tuples ( columns column -- seq )
    [ [ type>> lookup-persistent columns>> columns>out-tuple ] map ]
    [ columns>out-tuple prefix ] bi* ; inline

: select-columns ( tuple -- seq )
    lookup-persistent
    columns>> [ type>> tuple-class? ] partition columns>out-tuples ;

: select-tuples-plain ( tuple -- fql )
    [ select new ] dip {
        [ select-columns >>columns ]
        [ lookup-persistent table-name>> >>from ]
    } cleave ;

: select-tuples-relations ( tuple -- fql )
    [ select new ] dip {
        [ select-columns >>columns ]
    } cleave ;

:: select-tuples ( tuple -- seq )
    tuple lookup-persistent :> persistent
    persistent relation-columns :> relations
    
    f
    ;






/*
    relations [
        tuple select-tuples-plain
    ] [
        drop f
        ! select-tuples-relations
    ] if-empty ;
*/
