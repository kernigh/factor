! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs classes.mixin classes.parser
classes.singleton classes.tuple combinators db.binders
db.connections db.orm.fql db.orm.persistent db.types db.utils
fry kernel lexer locals mirrors multiline sequences db.statements
make classes shuffle namespaces math.parser ;
IN: db.orm


: filter-ignored-columns ( tuple -- columns' )
    [ lookup-persistent columns>> ] [ <mirror> ] bi
    '[ slot-name>> _ at IGNORE = not ] filter ;

: filter-functions ( tuple -- columns' )
    [ lookup-persistent columns>> ] [ <mirror> ] bi
    '[ slot-name>> _ at \ aggregate-function subclass? not ] filter ;

: filter-relations ( obj -- columns )
    lookup-persistent columns>> [ relation-category not ] filter ;


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

: actual-columns ( obj -- columns relation-columns )
    [ lookup-persistent columns>> ]
    [
        find-one:many-columns
        [ persistent>> class>> find-primary-key ] map concat
    ] bi ;

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

/*
: select-outs ( statement relations -- statement' )
    [
        first
        [ first2 [ name>> ] [ number>string ] bi* "_" glue ]
        [ nip first filter-relations ] 2bi
        [ column-name>> "." glue ] with map ", " join
    ] map ",\n " join add-sql ;
*/

: select-outs ( statement relations -- statement' )
    sort-relations [
        [ first2 [ name>> ] [ number>string ] bi* "_" glue ]
        [ nip first actual-columns ] 2bi
        [ [ column-name>> "." glue ] with map ]
        [ [ [ persistent>> table-name>> ] [ column-name>> ] bi "_" glue "." glue ] with map ]
        bi-curry* bi [ ", " join ] bi@ [ ", " glue ] unless-empty
    ] map ",\n " join add-sql ;

: renamed-table-name ( pair -- string )
    first2 [ table-name ] [ number>string ] bi* "_" glue ;

!TODO
: primary-keys ( pair -- seq )
    [ renamed-table-name ] [ find-primary-keys ] bi
    [ ] with map ;

: select-joins ( statement relations -- statement' )
    [
B
        first2
        [ [ first table-name ] bi@ " ON " glue ]
        [ nip renamed-table-name " AS " glue ] 2bi
        "\n LEFT JOIN " prepend
    ] map ", " join add-sql ;

! Needs tuple for filtering slots
: relations>select ( relations -- statement )
    [ statement new ] dip {
        [ drop "SELECT " add-sql ]
        [ select-outs ]
        [ drop "\n FROM " add-sql ]
        [ first first first table-name add-sql " AS " add-sql ]
        [ first first renamed-table-name add-sql ]
        [ select-joins ]
    } cleave ;


/*

SELECT thread2_0.id, thread2_0.topic, thread2_0.ts,
 author2_1.id, author2_1.name,
 thread2_0.id, thread2_0.topic, thread2_0.ts,
 comment2_3.id, comment2_3.text, comment2_3.ts,
 author2_4.id, author2_4.name
 FROM thread2 AS thread2_0
 LEFT JOIN thread2 ON author2 AS author2_1, 
 LEFT JOIN author2 ON address2 AS address2_2, 
 LEFT JOIN thread2 ON comment2 AS comment2_3, 
 LEFT JOIN comment2 ON author2 AS author2_4, 
 LEFT JOIN author2 ON address2 AS address2_5

SELECT thread2_0.id, thread2_0.topic, thread2_0.ts,
 author2_1.id, author2_1.name,
 address2_2.id, ..., address2_2.author_id
 comment2_3.id, comment2_3.text, comment2_3.ts, comment2_3.thread_id,
 author2_4.id, author2_4.name
 address2_5.id, ..., address2_5.author_id
 FROM thread2 AS thread2_0
 LEFT JOIN thread2 ON author2 AS author2_1, 
 LEFT JOIN author2 ON address2 AS address2_2, 
 LEFT JOIN thread2 ON comment2 AS comment2_3, 
 LEFT JOIN comment2 ON author2 AS author2_4, 
 LEFT JOIN author2 ON address2 AS address2_5


*/
