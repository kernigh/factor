! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs combinators
combinators.short-circuit constructors db.binders
db.orm.persistent db.statements db.types db.utils destructors
fry kernel locals make math math.parser multiline namespaces
sequences sets splitting strings vectors ;
IN: db.orm.fql

: ??first2 ( obj -- obj1 obj2 )
    dup string? [
        VARCHAR
    ] [
        ?first2 [ VARCHAR ] unless*
    ] if ;

TUPLE: fql ;
TUPLE: fql-op < fql left right ;
TUPLE: aggregate-function < fql column ;

ERROR: in-binders-required fql ;

: ensure-in ( fql -- fql )
    dup in>> empty? [ in-binders-required ] when ;

: next-bind-index ( -- string )
    "?" ;


: new-op ( left right class -- fql-op )
    new
        swap >>right
        swap >>left ; inline

GENERIC: normalize-fql ( object -- sequence/statement )
M: object normalize-fql ( object -- fql ) ;
GENERIC: expand-fql* ( statement object -- sequence/statement )

: expand-fql ( object1 -- object2 )
    [ <statement> ] dip normalize-fql expand-fql* ;

TUPLE: insert < fql in ;

CONSTRUCTOR: insert ( in -- obj ) ;

M: insert normalize-fql ( insert -- insert )
    [ ??1array ] change-in ;

TUPLE: update < fql tables keys values where order-by limit ;

CONSTRUCTOR: update ( tables keys values where -- obj ) ;

M: update normalize-fql ( update -- update )
    [ ??1array ] change-tables
    [ ??1array ] change-keys
    [ ??1array ] change-values
    [ ??1array ] change-order-by ;

TUPLE: delete < fql tables where order-by limit ;

CONSTRUCTOR: delete ( tables keys values where -- obj ) ;

M: delete normalize-fql ( delete -- delete )
    [ ??1array ] change-tables
    [ ??1array ] change-order-by ;

TUPLE: select < fql in out ;
! columns from join where group-by
! having order-by offset limit ;

CONSTRUCTOR: select ( -- obj ) ;

M: select normalize-fql ( select -- select )
    [ ??1array ] change-in
    [ ??1array ] change-out ;
    ! [ ??1array ] change-columns
    ! [ ??1array ] change-join
    ! [ ??1array ] change-from
    ! [ ??1array ] change-where
    ! [ ??1array ] change-group-by
    ! [ ??1array ] change-order-by ;

TUPLE: and-sequence < fql sequence ;
CONSTRUCTOR: and-sequence ( sequence -- obj ) ;

TUPLE: or-sequence < fql sequence ;
CONSTRUCTOR: or-sequence ( sequence -- obj ) ;

TUPLE: op-is < fql-op ;
CONSTRUCTOR: op-is ( left right -- obj ) ;

TUPLE: op-eq < fql-op ;
CONSTRUCTOR: op-eq ( left right -- obj ) ;

TUPLE: op-not-eq < fql-op ;
CONSTRUCTOR: op-not-eq ( left right -- obj ) ;

TUPLE: op-lt < fql-op ;
CONSTRUCTOR: op-lt ( left right -- obj ) ;

TUPLE: op-lt-eq < fql-op ;
CONSTRUCTOR: op-lt-eq ( left right -- obj ) ;

TUPLE: op-gt < fql-op ;
CONSTRUCTOR: op-gt ( left right -- obj ) ;

TUPLE: op-gt-eq < fql-op ;
CONSTRUCTOR: op-gt-eq ( left right -- obj ) ;

TUPLE: fql-join < fql table table1 column1 table2 column2 ;

: new-join ( table table1 column1 table2 column2 class -- join )
    new
        swap >>column2
        swap >>table2
        swap >>column1
        swap >>table1
        swap >>table
        [ ??1array ] change-column1
        [ ??1array ] change-column2 ;

TUPLE: cross-join < fql-join ;

TUPLE: inner-join < fql-join ;

TUPLE: left-join < fql-join ;

TUPLE: right-join < fql-join ;

TUPLE: full-join < fql-join ;

: <cross-join> ( table table1 column1 table2 column2 -- cross-join )
    cross-join new-join ;

: <inner-join> ( table table1 column1 table2 column2 -- inner-join )
    inner-join new-join ;

: <left-join> ( table table1 column1 table2 column2 -- left-join )
    left-join new-join ;

: <right-join> ( table table1 column1 table2 column2  -- right-join )
    right-join new-join ;

: <full-join> ( table table1 column1 table2 column2 -- full-join )
    full-join new-join ;

:: table-join ( statement join string -- statement )
    statement
    [
        string %
        join table>> %
        join [ column1>> ] [ column2>> ] bi
        [
            " AND " %
        ] [
            " ON " % [ % ] dip " = " % %
        ] 2interleave
    ] "" make add-sql ;

M: cross-join expand-fql*
    " CROSS JOIN " table-join ;

M: inner-join expand-fql* ( obj -- statement )
    " INNER JOIN " table-join ;

M: left-join expand-fql* ( obj -- statement )
    " LEFT JOIN " table-join ;

M: right-join expand-fql* ( obj -- statement )
    " RIGHT JOIN " table-join ;

M: full-join expand-fql* ( obj -- statement )
    " FULL JOIN " table-join ;





: expand-insert-names ( statement insert -- statement )
    in>> [
        [ " (" add-sql ] dip
        [ column>> ] map ", " join add-sql
        ")" add-sql
    ] [
        [ " VALUES (" add-sql ] dip
        [ length "?" <array> ", " join add-sql ]
        [ add-in-params ] bi
        ")" add-sql
    ] bi ;

M: insert expand-fql*
    ensure-in
    {
        [ in>> first table-name "INSERT INTO " prepend add-sql ]
        [ expand-insert-names ]
    } cleave normalize-statement ;





/*
GENERIC: param>binder* ( obj -- obj' type )

M: number param>binder*
    dup integer? [ INTEGER ] [ REAL ] if ;

M: sequence param>binder*
    ??first2 [ [ VARCHAR ] unless* ] dip ;

M: NULL param>binder* NULL ;
M: +db-assigned-key+ param>binder* INTEGER ;

: vector/array? ( obj -- ? ) { [ vector? ] [ array? ] } 1|| ;

: >op< ( op string -- strings/binders )
    [ [ left>> ] dip "?" 3append ]
    [ drop right>> param>binder 1array ] 2bi 2array ;

GENERIC: expand-op ( obj -- string/binders )

M: op-is expand-op " is " >op< ;
M: op-eq expand-op " = " >op< ;
M: op-not-eq expand-op " <> " >op< ;
M: op-lt expand-op " < " >op< ;
M: op-lt-eq expand-op " <= " >op< ;
M: op-gt expand-op " > " >op< ;
M: op-gt-eq expand-op " >= " >op< ;

M: or-sequence expand-op ( obj -- strings/binders )
    sequence>> [ expand-op ] map
    [ keys " OR " join "(" ")" surround ]
    [ values concat ] bi 2array ;

M: and-sequence expand-op ( obj -- strings/binders )
    sequence>> [ expand-op ] map
    [ keys " AND " join "(" ")" surround ]
    [ values concat ] bi 2array ;
*/

SYMBOL: tables

: dot-table-name ( string -- string' )
    "." split1 drop ;

: dot-column-name ( string -- string' )
    "." split1-last [ nip ] when* ;

GENERIC: expand-out ( obj -- names binders )

    ! columns>> [ expand-out ] { } map>assoc
    ! [ keys concat ", " join add-sql ] [ values concat >>out ] bi ;

! : binder>name ( binder -- string ) [ class>> table-name ] [ column>> ] bi "." glue ;

! : binders>names ( seq -- string ) [ binder>name ] map ", " join ;

: in/out ( obj -- in out )
    { in>> out>> } slots ;

: table-columns ( obj -- columns )
    lookup-persistent columns>> ;

: column>out-binder ( column -- out-binder )
    persistent>> 
    ;

: full-table-name ( binder -- string )
    [ class>> table-name ] [ renamed-table>> ] bi " AS " glue ;

: binder>name ( binder -- string )
    [ renamed-table>> ] [ column>> ] bi "." glue ;

: binder>names ( binder -- string )
    [ renamed-table>> ] [ class>> ] bi
    table-columns [ column-name>> "." glue ] with map ;

: binders>names ( seq -- string )
    [ binder>name ] map prune ", " join ;

: select-out ( statement select -- statement )
    out>> binders>names add-sql ;

: select-tables ( statement select -- statement )
    in/out append [ full-table-name ] map prune ", " join add-sql ;

: expand-where ( statement obj -- statement )
    [ " WHERE " add-sql ] dip
    in>> [
        binder>name " = " next-bind-index 3append
    ] map ", " join add-sql ;

    ! where>> [
        ! [ " WHERE " add-sql ] dip
        ! [ expand-op ] map
        ! [ keys " AND " join add-sql ] [ values concat add-in-params ] bi
    ! ] when* ;

M: select expand-fql* ( statement obj -- statement )
    {
        [ in>> >>in ]
        [ out>> >>out ]
        [ [ "SELECT " add-sql ] dip select-out ]
        [ [ " FROM " add-sql ] dip select-tables ]
        [ dup in>> empty? [ drop ] [ expand-where ] if ]
    } cleave normalize-statement ;


            ! [ [ "SELECT " add-sql ] dip select-out ]
            ! [ [ " FROM " add-sql ] dip from>> ", " join add-sql ]
            ! [ join>> [ [ expand-fql* ] each ] when* ]
            ! [ expand-where ]
            ! [ group-by>> [ [ " GROUP BY " add-sql ] dip ", " join add-sql ] when* ]
            ! [ order-by>> [ [ " ORDER BY " add-sql ] dip ", " join add-sql ] when* ]
            ! [ offset>> [ [ " OFFSET " add-sql ] dip number>string add-sql ] when* ]
            ! [ limit>> [ [ " LIMIT " add-sql ] dip number>string add-sql ] when* ]



! Aggregate functions

: new-aggregate-function ( column class -- obj )
    new swap >>column ; inline

TUPLE: fql-avg < aggregate-function ;
: <fql-avg> ( column -- avg ) fql-avg new-aggregate-function ;

TUPLE: fql-sum < aggregate-function ;
: <fql-sum> ( column -- sum ) fql-sum new-aggregate-function ;

TUPLE: fql-count < aggregate-function ;
: <fql-count> ( column -- count ) fql-count new-aggregate-function ;

TUPLE: fql-min < aggregate-function ;
: <fql-min> ( column -- min ) fql-min new-aggregate-function ;

TUPLE: fql-max < aggregate-function ;
: <fql-max> ( column -- max ) fql-max new-aggregate-function ;

TUPLE: fql-first < aggregate-function ;
: <fql-first> ( column -- first ) fql-first new-aggregate-function ;

TUPLE: fql-last < aggregate-function ;
: <fql-last> ( column -- last ) fql-last new-aggregate-function ;

/*
: expand-aggregate ( obj str type -- string/binder )
    [ [ column>> ] dip "(" append ")" surround ] dip
    [ f f ] dip <out-typed-binder> 2array ;

M: fql-avg expand-op ( obj -- string/binder )
    "avg" REAL expand-aggregate ;

M: fql-sum expand-op ( obj -- string/binder )
    "sum" REAL expand-aggregate ;

M: fql-count expand-op ( obj -- string/binder )
    "count" INTEGER expand-aggregate ;

M: fql-min expand-op ( obj -- string/binder )
    "min" REAL expand-aggregate ;

M: fql-max expand-op ( obj -- string/binder )
    "max" REAL expand-aggregate ;

M: fql-first expand-op ( obj -- string/binder )
    "first" REAL expand-aggregate ;

M: fql-last expand-op ( obj -- string/binder )
    "last" REAL expand-aggregate ;
*/





















/*




M: string expand-fql* ( string -- string ) add-sql ;

M: update expand-fql*
    {
        [ [ "update " add-sql ] dip tables>> ", " join add-sql ]
        [ [ " set " add-sql ] dip keys>> [ " = ?" append ] map ", " join add-sql ]
        [ values>> >>in ]
        [ expand-where ]
        [ order-by>> [ [ " order by " add-sql ] dip ", " join add-sql ] when* ]
        [ limit>> [ [ " limit " add-sql ] dip number>string add-sql ] when* ]
    } cleave normalize-statement ;

M: delete expand-fql*
    {
        [ [ "delete from " add-sql ] dip tables>> ", " join add-sql ]
        [ expand-where ]
        [ order-by>> [ [ " order by " add-sql ] dip ", " join add-sql ] when* ]
        [ limit>> [ [ " limit " add-sql ] dip number>string add-sql ] when* ]
    } cleave normalize-statement ;

: where>inputs ( seq -- seq' )
    [
        dup fql-op?
        [ right>> ??first2 swap <simple-binder> ] when
    ] map sift ;

: tuple-out>slots ( tuple-out -- string-seq )
    [ slots>> ] [ table>> ] bi
    '[ [ _ ] dip "." glue ] map ;

: lookup-persistent-slot ( string class -- slot )
    lookup-persistent columns>> [ slot-name>> = ] with find nip ;

TUPLE: set-operator < fql all? selects ;

TUPLE: intersect < set-operator ;

TUPLE: union < set-operator ;

TUPLE: except < set-operator ;

TUPLE: between < fql from to ;

! Null-handling

TUPLE: coalesce < fql a b ; ! a if a not null, else b

TUPLE: nullif < fql a b ; ! if a == b, then null, else a

*/
