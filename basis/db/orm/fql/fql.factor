! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs combinators
combinators.short-circuit constructors db.binders
db.orm.persistent db.statements db.types db.utils destructors
fry kernel locals make math math.parser multiline namespaces
sequences sets splitting strings vectors db.connections
quoting ;
IN: db.orm.fql

HOOK: next-bind-index db-connection ( -- string )
HOOK: init-bind-index db-connection ( -- )

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

: new-op ( left right class -- fql-op )
    new
        swap >>right
        swap >>left ; inline

GENERIC: normalize-fql ( object -- sequence/statement )
M: object normalize-fql ( object -- fql ) ;
GENERIC: expand-fql* ( statement object -- sequence/statement )

: expand-fql ( object1 -- object2 )
    [
        init-bind-index
        [ <statement> ] dip normalize-fql expand-fql*
    ] with-scope ;

TUPLE: insert < fql in ;

CONSTRUCTOR: insert ( in -- obj ) ;

M: insert normalize-fql ( insert -- insert )
    [ ??1array ] change-in ;

TUPLE: select < fql in out relations reconstructor offset limit ;
! columns from join where group-by
! having order-by offset limit ;

CONSTRUCTOR: select ( -- obj ) ;

M: select normalize-fql ( select -- select )
    [ ??1array ] change-in
    [ ??1array ] change-out ;

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



: expand-insert-names ( statement insert -- statement )
    in>> [
        [ " (" add-sql ] dip
        [ column-name>> ] map ", " join add-sql
        ")" add-sql
    ] [
        [ " VALUES (" add-sql ] dip
        length [ next-bind-index ] replicate ", " join add-sql ")" add-sql
    ] bi ;

: primary-key-random? ( obj -- ? )
    
    ;

M: insert expand-fql*
    ensure-in
    {
        [ in>> >>in ]
        [ in>> first quoted-table-name "INSERT INTO " prepend add-sql ]
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

: in/out ( obj -- in out )
    { in>> out>> } slots ;

: table-columns ( obj -- columns )
    lookup-persistent columns>> ;

: column>out-binder ( column -- out-binder )
    persistent>> 
    ;

: 'table-name' ( binder -- string )
    table-name>> "\"" dup surround ;

: full-table-name ( binder -- string )
    [ class>> quoted-table-name ]
    [ 'table-name' ] bi " AS " glue ;

: binder>name ( binder -- string )
    [ 'table-name' ] [ column-name>> ] bi "." glue ;

: binder>names ( binder -- string )
    [ table-name>> ] [ class>> ] bi
    table-columns [ column-name>> "." glue ] with map ;

: binders>names ( seq -- string )
    [ binder>name ] map prune ", " join ;

: select-out ( statement select -- statement )
    out>> binders>names add-sql ;

: seq>tables ( statement seq -- tables )
    [ full-table-name ] map prune ", " join add-sql ;

: select-tables ( statement select -- statement )
    in/out append seq>tables ;

: delete-tables ( statement select -- statement )
    in>> [ 'table-name' ] map prune ", " join add-sql ;

: select-relations ( statement seq -- statement )
    [
        {
            [ drop " LEFT JOIN " add-sql ] dip
            [ table-name1>> double-quote add-sql "." add-sql ]
            [ column-name1>> add-sql " ON " add-sql ]
            [ table-name2>> double-quote add-sql "." add-sql ]
            [ column-name2>> add-sql ]
        } cleave
    ] each ;

: expand-where ( statement obj -- statement )
    [ " WHERE " add-sql ] dip
    in>> [
        binder>name " = " next-bind-index 3append
    ] map " and " join add-sql ;

: in>primary-key ( in -- column )
    [ column>> column-primary-key? ] filter ;

: in>columns ( in -- column )
    [ column>> column-primary-key? not ] filter ;

: write-qualified-binders ( statement seq -- statement )
    [
        binder>name " = " next-bind-index 3append
    ] map ", " join add-sql ;

: write-binders ( statement seq -- statement )
    [
        column-name>> " = " next-bind-index 3append
    ] map ", " join add-sql ;

: expand-where-primary-key ( statement obj -- statement )
    [ " WHERE " add-sql ] dip
    in>> in>primary-key
    write-binders ;

M: select expand-fql* ( statement obj -- statement )
    {
        [ in>> >>in ]
        [ out>> >>out ]
        [ reconstructor>> >>reconstructor ]
        [ [ "SELECT " add-sql ] dip select-out ]
        [ [ " FROM " add-sql ] dip select-tables ]
        [ relations>> select-relations ]
        [ dup in>> empty? [ drop ] [ expand-where ] if ]
        [ offset>> [ number>string " OFFSET " prepend add-sql ] when* ]
        [ limit>> [ number>string " LIMIT " prepend add-sql ] when* ]
    } cleave normalize-statement ;


TUPLE: delete < fql in ;

CONSTRUCTOR: delete ( -- obj ) ;

M: delete normalize-fql ( delete -- delete )
    [ ??1array ] change-in ;

M: delete expand-fql* ( statement obj -- statement' )
    {
        [ [ "DELETE FROM " add-sql ] dip delete-tables ]
        [ dup in>> empty? [ drop ] [ expand-where ] if ]
        [ in>> >>in ]
    } cleave ;


TUPLE: update < fql in ;

CONSTRUCTOR: update ( -- obj ) ;

M: update normalize-fql ( update -- update )
    [ ??1array ] change-in ;

M: update expand-fql* ( statement obj -- statement' )
    {
        [ [ "UPDATE " add-sql ] dip delete-tables ]
        [ [ " SET " add-sql ] dip in>> in>columns write-binders ]
        [ dup in>> empty? [ drop ] [ expand-where-primary-key ] if ]
        [ in>> [ in>columns ] [ in>primary-key ] bi append >>in ]
    } cleave ;

/*
    {
        [ in>> >>in ]
        [ out>> >>out ]
        [ reconstructor>> >>reconstructor ]
        [ [ "SELECT " add-sql ] dip select-out ]
        [ [ " FROM " add-sql ] dip select-tables ]
        [ relations>> select-relations ]
        [ dup in>> empty? [ drop ] [ expand-where ] if ]
        [ offset>> [ number>string " OFFSET " prepend add-sql ] when* ]
        [ limit>> [ number>string " LIMIT " prepend add-sql ] when* ]
    } cleave normalize-statement ;
*/

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

