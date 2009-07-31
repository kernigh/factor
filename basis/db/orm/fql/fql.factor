! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs combinators
combinators.short-circuit constructors db.binders db.orm.persistent
db.statements db.types db.utils destructors fry kernel locals
make math math.parser multiline namespaces sequences splitting
strings vectors ;
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

: new-op ( left right class -- fql-op )
    new
        swap >>right
        swap >>left ; inline

GENERIC: normalize-fql ( object -- sequence/statement )
M: object normalize-fql ( object -- fql ) ;
GENERIC: expand-fql* ( statement object -- sequence/statement )

: expand-fql ( object1 -- object2 )
    [ statement new ] dip normalize-fql expand-fql* ;


TUPLE: insert < fql table binders ;

CONSTRUCTOR: insert ( table binders -- obj ) ;

M: insert normalize-fql ( insert -- insert )
    [ ??1array ] change-binders ;

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

TUPLE: select < fql columns from join where group-by
having order-by offset limit ;

CONSTRUCTOR: select ( -- obj ) ;

M: select normalize-fql ( select -- select )
    [ ??1array ] change-columns
    [ ??1array ] change-join
    [ ??1array ] change-from
    [ ??1array ] change-where
    [ ??1array ] change-group-by
    [ ??1array ] change-order-by ;

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

TUPLE: fql-join < fql table column1 column2 ;

: new-join ( table column1 column2 class -- join )
    new
        swap >>column2
        swap >>column1
        swap >>table
        [ ??1array ] change-column1
        [ ??1array ] change-column2 ;

TUPLE: cross-join < fql-join ;

TUPLE: inner-join < fql-join ;

TUPLE: left-join < fql-join ;

TUPLE: right-join < fql-join ;

TUPLE: full-join < fql-join ;

: <cross-join> ( table column1 column2 -- cross-join )
    cross-join new-join ;

: <inner-join> ( table column1 column2 -- inner-join )
    inner-join new-join ;

: <left-join> ( table column1 column2 -- left-join )
    left-join new-join ;

: <right-join> ( table column1 column2  -- right-join )
    right-join new-join ;

: <full-join> ( table column1 column2 -- full-join )
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
    binders>> [
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
    {
        [ table>> "INSERT INTO " prepend add-sql ]
        [ expand-insert-names ]
    } cleave normalize-statement ;





GENERIC: param>binder* ( obj -- obj' type )

M: number param>binder*
    dup integer? [ INTEGER ] [ REAL ] if ;

M: sequence param>binder*
    ??first2 [ [ VARCHAR ] unless* ] dip ;

M: NULL param>binder* NULL ;
M: +db-assigned-key+ param>binder* INTEGER ;

: param>binder ( obj -- pair ) param>binder* <param-in-binder> ;

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

SYMBOL: tables

: dot-table-name ( string -- string' )
    "." split1 drop ;

: dot-column-name ( string -- string' )
    "." split1-last [ nip ] when* ;

GENERIC: expand-out ( obj -- names binders )

M: out-tuple-binder expand-out ( obj -- names binders )
    [
        [ table>> ] [ binders>> ] bi
        [ name>> "." glue ] with map
    ] keep 1array ;

    ! [ table>> ] [ binders>> ] bi
    ! [ [ first "." glue ] with map ] [ [ first3 <out-tuple-slot-binder> ] map ] bi ;


: select-out ( statement tuple -- statement )
    columns>> [ expand-out ] { } map>assoc
    [ keys concat ", " join add-sql ] [ values concat >>out ] bi ;

: expand-where ( statement obj -- statement )
    where>> [
        [ " WHERE " add-sql ] dip
        [ expand-op ] map
        [ keys " AND " join add-sql ] [ values concat add-in-params ] bi
    ] when* ;

M:: select expand-fql* ( statement obj -- statement )
    H{ } clone tables [
        statement obj
        {
            [ [ "SELECT " add-sql ] dip select-out ]
            [ [ " FROM " add-sql ] dip from>> ", " join add-sql ]
            [ join>> [ [ expand-fql* ] each ] when* ]
            [ expand-where ]
            [ group-by>> [ [ " GROUP BY " add-sql ] dip ", " join add-sql ] when* ]
            [ order-by>> [ [ " ORDER BY " add-sql ] dip ", " join add-sql ] when* ]
            [ offset>> [ [ " OFFSET " add-sql ] dip number>string add-sql ] when* ]
            [ limit>> [ [ " LIMIT " add-sql ] dip number>string add-sql ] when* ]
        } cleave normalize-statement
    ] with-variable ;
























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

: tuple-out>tuple-binder ( tuple-out -- tuple-binder )
    [ class>> ]
    [
        [ slots>> ] [ class>> ] bi
        '[
            _ lookup-persistent-slot
            [ slot-name>> ] [ type>> ] bi <return-binder>
        ] map
    ] bi <tuple-binder> ;

: expand-tuple-out ( statement tuple-out -- statement )
    [ tuple-out>slots ", " join add-sql ] [ tuple-out>tuple-binder add-out-param ] bi ;

M: tuples-out expand-fql*
    [ expand-tuple-out ] each ;

TUPLE: set-operator < fql all? selects ;

TUPLE: intersect < set-operator ;

TUPLE: union < set-operator ;

TUPLE: except < set-operator ;

TUPLE: between < fql from to ;

! Null-handling

TUPLE: coalesce < fql a b ; ! a if a not null, else b

TUPLE: nullif < fql a b ; ! if a == b, then null, else a

! Aggregate functions

: new-aggregate-function ( column class -- obj )
    new swap >>column ; inline

TUPLE: fql-avg < aggregate-function ;
: <fql-avg> ( column -- count ) fql-avg new-aggregate-function ;

TUPLE: fql-sum < aggregate-function ;
: <fql-sum> ( column -- count ) fql-sum new-aggregate-function ;

TUPLE: fql-count < aggregate-function ;
: <fql-count> ( column -- count ) fql-count new-aggregate-function ;

TUPLE: fql-min < aggregate-function ;
: <fql-min> ( column -- count ) fql-min new-aggregate-function ;

TUPLE: fql-max < aggregate-function ;
: <fql-max> ( column -- count ) fql-max new-aggregate-function ;

TUPLE: fql-first < aggregate-function ;
: <fql-first> ( column -- count ) fql-first new-aggregate-function ;

TUPLE: fql-last < aggregate-function ;
: <fql-last> ( column -- count ) fql-last new-aggregate-function ;

: expand-aggregate ( obj str -- str' binder )
    [ column>> ] dip "(" append ")" surround "Aggregate function here" throw
    INTEGER <return-binder> ;

M: fql-avg expand-op ( obj -- string binder )
    "avg" expand-aggregate ;

M: fql-sum expand-op ( obj -- string binder )
    "sum" expand-aggregate ;

M: fql-count expand-op ( obj -- string binder )
    "count" expand-aggregate ;

M: fql-min expand-op ( obj -- string binder )
    "min" expand-aggregate ;

M: fql-max expand-op ( obj -- string binder )
    "max" expand-aggregate ;

M: fql-first expand-op ( obj -- string binder )
    "first" expand-aggregate ;

M: fql-last expand-op ( obj -- string binder )
    "last" expand-aggregate ;
*/
