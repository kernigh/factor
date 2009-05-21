! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays combinators constructors
db2.sqlite.lib db2.utils destructors db2.statements
kernel make math.parser sequences strings assocs
splitting ;
IN: db2.fql

TUPLE: fql ;

GENERIC: expand-fql* ( object -- sequence/statement )
GENERIC: normalize-fql ( object -- sequence/statement )

M: object normalize-fql ( object -- fql ) ;


TUPLE: insert < fql into names values ;
CONSTRUCTOR: insert ( into names values -- obj ) ;
M: insert normalize-fql ( insert -- insert )
    [ ??1array ] change-names ;

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

TUPLE: select < fql names out-columns from where group-by
having order-by offset limit ;
CONSTRUCTOR: select ( names from -- obj ) ;
M: select normalize-fql ( select -- select )
    [ ??1array ] change-names
    [ ??1array ] change-from
    [ ??1array ] change-group-by
    [ ??1array ] change-order-by ;

TUPLE: and-sequence < fql sequence ;

TUPLE: or-sequence < fql sequence ;

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
            [
                " set " % [ keys>> ] [ values>> ] bi 
                zip [ ", " % ] [ first2 [ % ] dip " = " % % ] interleave
            ]
            ! [ "  " % from>> ", " join % ]
            [ where>> [ " where " % expand-fql* % ] when* ]
            [ order-by>> [ " order by " % ", " join % ] when* ]
            [ limit>> [ " limit " % # ] when* ]
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
            [ "select " % names>> ", " join % ]
            [ out-columns>> >>out ]
            [ " from " % from>> ", " join % ]
            [ where>> [ " where " % expand-fql* % ] when* ]
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

TUPLE: avg < aggregate-function ;

TUPLE: sum < aggregate-function ;

TUPLE: count < aggregate-function ;

TUPLE: min < aggregate-function ;

TUPLE: max < aggregate-function ;

TUPLE: fql-first < aggregate-function ;

TUPLE: fql-last < aggregate-function ;
