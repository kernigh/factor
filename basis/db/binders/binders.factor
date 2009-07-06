! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.utils kernel parser quotations sequences
classes.tuple ;
IN: db.binders

TUPLE: binder table-name column-name slot-name type value getter setter ;

TUPLE: tuple-binder class binders ;

! TUPLE: sequence-binder binder ; ! ???

: set-binder-accessors ( binder -- binder )
    dup slot-name>>
        [ lookup-getter 1quotation >>getter ]
        [ lookup-setter 1quotation >>setter ] bi ;

: <simple-binder> ( type value -- binder )
    binder new
        swap >>value
        swap >>type ;

: <return-binder> ( slot-name type -- binder )
    binder new
        swap >>type
        swap >>slot-name
        set-binder-accessors ;

SYNTAX: SB{
    \ } [
        2 ensure-length first2 <simple-binder>
    ] parse-literal ;

ERROR: tuple-class-expected object ;

: ensure-class ( object -- tuple-class )
    dup tuple-class? [ tuple-class-expected ] unless ;

: <tuple-binder> ( class binders -- binder )
    tuple-binder new
        swap >>binders
        swap ensure-class >>class ;

SYNTAX: TB{
    \ } [
        unclip swap [ first2 <return-binder> ] map <tuple-binder>
    ] parse-literal ;
