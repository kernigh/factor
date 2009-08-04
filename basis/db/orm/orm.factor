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
            [ column>create-text ] map sift ", " join add-sql
        ] [
            class>one:many-relations [
                [ ", " ] dip [ add-sql ] bi@
            ] unless-empty
        ] [
            class>primary-key-create add-sql
            ");" add-sql
        ]
    } cleave ;

: drop-table ( class -- statement )
    table-name [ "DROP TABLE " ] dip ";" 3append
    statement new
        swap >>sql ;

: columns>out-tuple ( columns -- seq )
    [ first persistent>> [ class>> ] [ table-name>> ] bi ]
    [ [ type>> 3array ] with with map ] bi ;

: columns>out-tuples ( columns1 columns2 -- seq )
    [ [ type>> lookup-persistent columns>> columns>out-tuple ] map concat ]
    [ columns>out-tuple prepend ] bi* ; inline

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



: canonicalize-tuple ( tuple -- tuple' )
    tuple>array dup rest-slice [
        dup tuple? [ canonicalize-tuple ] [ IGNORE = IGNORE f ? ] if
    ] change-each >tuple ;

