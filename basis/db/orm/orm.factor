! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors annotations arrays assocs classes
classes.mixin classes.parser classes.singleton classes.tuple
combinators db db.binders db.connections db.orm.fql
db.orm.persistent db.statements db.types db.utils fry kernel
lexer locals make math.order math.parser math.ranges mirrors
multiline namespaces sequences sets shuffle splitting.monotonic
constructors math db.errors ;
IN: db.orm

HOOK: create-sql-statement db-connection ( class -- obj )
HOOK: drop-sql-statement db-connection ( class -- obj )

: filter-ignored-columns ( tuple -- columns' )
    [ lookup-persistent columns>> ] [ <mirror> ] bi
    '[ slot-name>> _ at IGNORE = not ] filter ;

: filter-functions ( tuple -- columns' )
    [ lookup-persistent columns>> ] [ <mirror> ] bi
    '[ slot-name>> _ at \ aggregate-function subclass? not ] filter ;

: filter-relations ( obj -- columns )
    lookup-persistent columns>> [ relation-category not ] filter ;

: create-many:many-table ( class1 class2 -- statement )
    [ <statement> ] 2dip
    {
        [ 2drop "CREATE TABLE " add-sql ]
        [
            [ lookup-persistent table-name>> ] bi@ "_" glue
            "_join_table(id primary key serial, " append add-sql
        ]
        [ [ class>primary-key-create ] bi@ ", " glue add-sql ");" add-sql ]
    } 2cleave ;

: actual-columns ( obj -- columns relation-columns )
    [ lookup-persistent columns>> ]
    [
        find-one:many-columns
        [ persistent>> class>> find-primary-key ] map concat
    ] bi ;

M: object create-sql-statement
    [ <statement> ] dip
    {
        [ drop "CREATE TABLE " add-sql ]
        [ quoted-table-name add-sql "(" add-sql ]
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

: create-table ( class -- ) create-sql-statement sql-command ;

: recreate-table ( class -- )
    [
        '[ _ drop-sql-statement sql-command ] ignore-table-missing
    ] [
        create-table
    ] bi ;

: ensure-table ( class -- )
    '[ _ create-table ] ignore-table-exists ;

: ensure-tables ( classes -- ) [ ensure-table ] each ;

M: object drop-sql-statement
    quoted-table-name [ "DROP TABLE " ] dip ";" 3append
    <statement>
        swap >>sql ;

: drop-table ( class -- ) drop-sql-statement sql-command ;

: canonicalize-tuple ( tuple -- tuple' )
    tuple>array dup rest-slice [
        dup tuple? [ canonicalize-tuple ] [ IGNORE = IGNORE f ? ] if
    ] change-each >tuple ;

DEFER: select-columns

: columns>out-tuples ( columns1 columns2 -- seq )
    [ [ relation-class select-columns ] map concat ]
    [ prepend ] bi* ; inline

: select-columns ( tuple -- seq )
    lookup-persistent
    columns>> [ relation-category ] partition columns>out-tuples ;

SYMBOL: table-counter

: (tuple>relations) ( n tuple -- )
    [ ] [ lookup-persistent columns>> ] bi [
        dup relation-category [
            2dup getter>> call( obj -- obj' ) dup IGNORE = [
                4drop
            ] [
                [ dup relation-class new ] unless*
                over relation-category [
                    swap [
                        [
                            [ class swap 2array ]
                            [ relation-class table-counter [ inc ] [ get ] bi 2array ] bi*
                        ] dip 3array ,
                    ] dip
                    [ table-counter get ] dip (tuple>relations)
                ] [
                    4drop
                ] if*
            ] if
        ] [
            3drop
        ] if
    ] with with each ;

: tuple>relations ( tuple -- seq )
    0 table-counter [
        [ 0 swap (tuple>relations) ] { } make
    ] with-variable ;

: sort-relations ( relations -- seq )
    [ first2 ] { } map>assoc concat prune ;

: renamed-table-name ( pair -- string )
    first2 [ table-name ] [ number>string ] bi* "_" glue ;

: qualified-column-string ( persistent -- string )
    [ table-name>> ] [ columns>> ] bi
    [ column-name>> "." glue ] with map ", " join ;

: tuple-slots ( tuple persistent -- seq )
    columns>> [ getter>> call( obj -- obj ) ] with map ;

: n-parameters ( n -- string )
    [1,b] [ number>string "$" prepend ] map "," join ;

: column>binder ( column -- class table-name column-name type )
    {
        [ persistent>> class>> ]
        [ persistent>> table-name>> ]
        [ column-name>> ]
        [ type>> ]
    } cleave ;

: column>out-binder ( column -- binder )
    column>binder <out-binder> ;

: column>in-binder ( tuple column -- binder )
    {
        [ nip column>binder ]
        [ getter>> call( obj -- obj ) ]
    } 2cleave <in-binder> ;

HOOK: insert-tuple db-connection ( tuple -- )

: set-columns ( tuple -- seq )
    dup lookup-persistent columns>> [
        getter>> call( obj -- obj )
    ] with filter ;

: select-ins ( tuple -- seq )
    dup set-columns [ column>in-binder ] with map ;

: select-outs ( tuple -- seq )
    filter-ignored-columns [ column>out-binder ] map ;

TUPLE: column-wrapper n seq ;

CONSTRUCTOR: column-wrapper ( seq -- obj )
    0 >>n ;

: next-column ( obj -- n )
    [ [ n>> ] [ seq>> ] bi nth ] 
    [ [ 1 + ] change-n drop ] bi ;

: reconstruct-class ( seq -- )
    [
        first persistent>> class>> '[ drop _ new ] ,
    ] [
        [
            setter>> '[ next-column _ call( obj obj -- obj ) ]
        ] map '[ _ cleave ] ,
    ] bi ;

: columns>reconstructor ( seq -- quot )
    [
        [ [ persistent>> class>> ] compare ] monotonic-split
        unclip swap [
            reconstruct-class
        ] [
            [
                [ reconstruct-class ]
                [ setter>> '[ drop _ call( obj obj -- obj ) ] , ] bi
            ] each
        ] bi*
    ] [ ] make '[ <column-wrapper> _ cleave ] ;

: select-tuple-obj ( tuple -- select )
    [ <select> ] dip
    {
        [ select-ins >>in ]
        [ select-outs >>out ]
        [ filter-ignored-columns columns>reconstructor >>reconstructor ]
    } cleave ;

: do-select-tuple ( select -- seq )
    expand-fql
    [ sql-bind-typed-query ] [ reconstructor>> ] bi
    '[ _ call( obj -- obj ) ] map ;

: select-tuples ( tuple -- seq )
    select-tuple-obj do-select-tuple ;

: select-tuple ( tuple -- seq )
    select-tuple-obj 1 >>limit do-select-tuple ?first ;
