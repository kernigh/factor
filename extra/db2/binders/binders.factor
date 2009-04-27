! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db2.utils kernel parser sequences ;
IN: db2.binders

TUPLE: binder class table-name slot-name value type getter setter ;

: set-binder-accessors ( binder -- binder )
    dup slot-name>>
    [ lookup-getter >>getter ] [ lookup-setter >>setter ] bi ;

: <simple-binder> ( type value -- binder )
    binder new
        swap >>value
        swap >>type ;

SYNTAX: TV{
    \ } [
        2 ensure-length first2 <simple-binder>
    ] parse-literal ;

: <return-binder> ( class type -- binder )
    binder new
        swap >>type
        swap >>class ;

SYNTAX: CT{
    \ } [
        2 ensure-length first2 <return-binder>
    ] parse-literal ;

