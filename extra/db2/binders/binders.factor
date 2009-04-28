! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db2.utils kernel parser sequences ;
IN: db2.binders

TUPLE: binder table-name slot-name type value getter setter ;

TUPLE: tuple-binder class binders ;

: set-binder-accessors ( binder -- binder )
    dup slot-name>>
    [ lookup-getter >>getter ] [ lookup-setter >>setter ] bi ;

: <simple-binder> ( type value -- binder )
    binder new
        swap >>value
        swap >>type ;

: <return-binder> ( slot-name type -- binder )
    binder new
        swap >>type
        swap >>slot-name
        set-binder-accessors ;

SYNTAX: TV{
    \ } [
        2 ensure-length first2 <simple-binder>
    ] parse-literal ;

: <tuple-binder> ( binders class -- binder )
    tuple-binder new
        swap >>class
        swap >>binders ;

SYNTAX: RT{
    \ } [
        unclip [ [ first2 <return-binder> ] map ] dip <tuple-binder>
    ] parse-literal ;
