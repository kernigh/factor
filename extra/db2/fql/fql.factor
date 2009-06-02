! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays combinators constructors
db2.sqlite.lib db2.utils destructors db2.statements
kernel make math.parser sequences strings assocs
splitting ;
IN: db2.fql

TUPLE: fql ;
TUPLE: fql-op < fql left right ;

GENERIC: expand-fql* ( object -- sequence/statement )
GENERIC: normalize-fql ( object -- sequence/statement )

M: object normalize-fql ( object -- fql ) ;

TUPLE: insert < fql into names values ;
CONSTRUCTOR: insert ( into names values -- obj ) ;
M: insert normalize-fql ( insert -- insert )
    [ ??1array ] change-names ;

TUPLE: update < fql tables keys values where where-in order-by limit ;
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

TUPLE: select < fql names names-out from where where-in group-by
having order-by offset limit ;
CONSTRUCTOR: select ( names from -- obj ) ;
M: select normalize-fql ( select -- select )
    [ ??1array ] change-names
    [ ??1array ] change-from
    [ ??1array ] change-group-by
    [ ??1array ] change-order-by ;

TUPLE: and-sequence < fql sequence ;
CONSTRUCTOR: and-sequence ( sequence -- obj ) ;

TUPLE: or-sequence < fql sequence ;
CONSTRUCTOR: or-sequence ( sequence -- obj ) ;

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

TUPLE: fql-join < fql left-table left-column right-table right-column ;

: new-join ( left-table left-column right-table right-column class -- join )
    new
        swap >>right-column
        swap >>right-table
        swap >>left-column
        swap >>left-table ; inline

: make-join ( table1.column table2.column class -- join )
    [ [ "." split1 ] bi@ ] dip new-join ;

TUPLE: cross-join < fql-join ;

TUPLE: inner-join < fql-join ;

TUPLE: left-outer-join < fql-join ;

TUPLE: right-outer-join < fql-join ;

TUPLE: full-outer-join < fql-join ;

: <cross-join> ( table1.column table2.column -- cross-join )
    cross-join make-join ;

: <inner-join> ( table1.column table2.column -- inner-join )
    inner-join make-join ;

: <left-outer-join> ( table1.column table2.column -- left-outer-join )
    left-outer-join make-join ;

: <right-outer-join> ( table1.column table2.column -- right-outer-join )
    right-outer-join make-join ;

: <full-outer-join> ( table1.column table2.column -- full-outer-join )
    full-outer-join make-join ;

: table-join% ( join string -- )
    over left-table>> % % right-table>> % ;

: table-column-join% ( join -- )
    {
        [ " on (" % left-table>> % "." % ]
        [ left-column>> % " = " % ]
        [ right-table>> % "." % ]
        [ right-column>> % ")" % ]
    } cleave  ;

M: cross-join expand-fql* ( obj -- string )
    [
        [ " cross join " table-join% ]
        [ table-column-join% ] bi
    ] "" make ;

M: inner-join expand-fql* ( obj -- string )
    [
        [ " inner join " table-join% ]
        [ table-column-join% ] bi
    ] "" make ;

M: left-outer-join expand-fql* ( obj -- string )
    [
        [ " left outer join " table-join% ]
        [ table-column-join% ] bi
    ] "" make ;

M: right-outer-join expand-fql* ( obj -- string )
    [
        [ " right outer join " table-join% ]
        [ table-column-join% ] bi
    ] "" make ;

M: full-outer-join expand-fql* ( obj -- string )
    [
        [ " full outer join " table-join% ]
        [ table-column-join% ] bi
    ] "" make ;

: expand-fql ( object1 -- object2 )
    normalize-fql expand-fql* ;

M: or-sequence expand-fql* ( obj -- string )
    [
        sequence>> "(" %
        [ " or " % ] [ expand-fql* % ] interleave
        ")" %
    ] "" make ;

M: and-sequence expand-fql* ( obj -- string )
    [
        sequence>> "(" %
        [ " and " % ] [ expand-fql* % ] interleave
        ")" %
    ] "" make ;

: >op< ( op -- left right ) [ left>> ] [ right>> ] bi ;

M: op-eq expand-fql* >op< " = " glue ;
M: op-not-eq expand-fql* >op< " <> " glue ;
M: op-lt expand-fql* >op< " < " glue ;
M: op-lt-eq expand-fql* >op< " <= " glue ;
M: op-gt expand-fql* >op< " > " glue ;
M: op-gt-eq expand-fql* >op< " >= " glue ;

M: string expand-fql* ( string -- string ) ;

M: insert expand-fql*
    [ statement new ] dip
    [
        {
            [ "insert into " % into>> % ]
            [ " (" % names>> ", " join % ")" % ]
            [ " values (" % values>> length "?" <array> ", " join % ");" % ]
            [ values>> >>in ]
        } cleave
    ] "" make >>sql normalize-statement ;

M: update expand-fql*
    [ statement new ] dip
    [
        {

            [ "update " % tables>> ", " join % ]
            [ " set " % keys>> [ " = ? " append ] map ", " join % ]
            [ values>> >>in ]
            [ where>> [ " where " % expand-fql* % ] when* ]
            [ where-in>> over in>> push-all ]
        } cleave
    ] "" make >>sql normalize-statement ;

M: delete expand-fql*
    [ statement new ] dip
    [
        {
            [ "delete from " % tables>> ", " join % ]
            [ where>> [ " where " % expand-fql* % ] when* ]
                [ order-by>> [ " order by " % ", " join % ] when* ]
            [ limit>> [ " limit " % # ] when* ]
        } cleave
    ] "" make >>sql normalize-statement ;

M: select expand-fql*
    [ statement new ] dip
    [
        {
            [ "select " % names>> [ expand-fql* ] map ", " join % ]
            [ names-out>> >>out ]
            [ " from " % from>> ", " join % ]
            [ where>> [ " where " % expand-fql* % ] when* ]
            [ where-in>> >>in ]
            [ group-by>> [ " group by " % ", " join % ] when* ]
            [ order-by>> [ " order by " % ", " join % ] when* ]
            [ offset>> [ " offset " % # ] when* ]
            [ limit>> [ " limit " % # ] when* ]
        } cleave
    ] "" make >>sql normalize-statement ;

TUPLE: set-operator < fql all? selects ;

TUPLE: intersect < set-operator ;

TUPLE: union < set-operator ;

TUPLE: except < set-operator ;

TUPLE: between < fql from to ;

! Null-handling

TUPLE: coalesce < fql a b ; ! a if a not null, else b

TUPLE: nullif < fql a b ; ! if a == b, then null, else a

! Aggregate functions

TUPLE: aggregate-function < fql column ;
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

M: fql-avg expand-fql* ( obj -- string )
    column>> "avg(" ")" surround ;

M: fql-sum expand-fql* ( obj -- string )
    column>> "sum(" ")" surround ;

M: fql-count expand-fql* ( obj -- string )
    column>> "count(" ")" surround ;

M: fql-min expand-fql* ( obj -- string )
    column>> "min(" ")" surround ;

M: fql-max expand-fql* ( obj -- string )
    column>> "max(" ")" surround ;

M: fql-first expand-fql* ( obj -- string )
    column>> "first(" ")" surround ;

M: fql-last expand-fql* ( obj -- string )
    column>> "last(" ")" surround ;
