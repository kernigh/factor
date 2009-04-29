! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays combinators constructors
db2.sqlite.lib db2.utils destructors db2.statements
kernel make math.parser sequences strings assocs db2.utils ;
IN: db2.fql

TUPLE: fql ;

GENERIC: expand-fql* ( object -- sequence/statement )
GENERIC: normalize-fql ( object -- sequence/statement )

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

TUPLE: select < fql names from where group-by order-by offset limit ;
CONSTRUCTOR: select ( names from -- obj ) ;
M: select normalize-fql ( select -- select )
    [ ??1array ] change-names
    [ ??1array ] change-from
    [ ??1array ] change-group-by
    [ ??1array ] change-order-by ;

TUPLE: and < fql sequence ;

TUPLE: or < fql sequence ;

: expand-fql ( object1 -- object2 ) normalize-fql expand-fql* ;

M: or expand-fql* ( obj -- string )
    [
        sequence>> "(" %
        [ " or " % ] [ expand-fql* % ] interleave
        ")" %
    ] "" make ;

M: and expand-fql* ( obj -- string )
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
    ] "" make >>sql ;

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
    ] "" make >>sql ;

M: delete expand-fql*
    [ statement new ] dip
    [
        {
            [ "delete from " % tables>> ", " join % ]
            [ where>> [ " where " % expand-fql* % ] when* ]
                [ order-by>> [ " order by " % ", " join % ] when* ]
            [ limit>> [ " limit " % # ] when* ]
        } cleave
    ] "" make >>sql ;

M: select expand-fql*
    [ statement new ] dip
    [
        {
            [ "select " % names>> ", " join % ]
            [ " from " % from>> ", " join % ]
            [ where>> [ " where " % expand-fql* % ] when* ]
            [ group-by>> [ " group by " % ", " join % ] when* ]
            [ order-by>> [ " order by " % ", " join % ] when* ]
            [ offset>> [ " offset " % # ] when* ]
            [ limit>> [ " limit " % # ] when* ]
        } cleave
    ] "" make >>sql ;
