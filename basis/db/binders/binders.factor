! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors classes.tuple constructors db.utils kernel
multiline parser quotations sequences ;
IN: db.binders

TUPLE: in-binder table column type value ;
TUPLE: param-in-binder type value ;

TUPLE: out-string-binder table column ;
TUPLE: out-typed-binder table column type ;
TUPLE: out-tuple-slot-binder name type setter ; ! 3-tuple
TUPLE: out-tuple-binder class table binders ;

CONSTRUCTOR: in-binder ( table column type value -- obj ) ;
CONSTRUCTOR: param-in-binder ( type value -- obj ) ;
! CONSTRUCTOR: out-string-binder ( table column -- obj ) ;
CONSTRUCTOR: out-tuple-slot-binder ( name type setter -- obj ) ;
CONSTRUCTOR: out-tuple-binder ( class table binders -- obj ) ;




/*
TUPLE: typed obj type ;

: <typed> ( obj type -- typed )
    typed new
        swap >>type
        swap >>obj ;

SYNTAX: TYPED{
    \ } [ 2 ensure-length first2 <typed> ] parse-literal ;

TUPLE: binder table-name column-name slot-name type value getter setter ;

TUPLE: tuple-binder class binders ;

TUPLE: tuple-out table class slots ;
TUPLE: tuples-out tuples ;

TUPLE: slot-binder slot binder ;

: <slot-binder> ( slot binder -- slot-binder )
    slot-binder new
        swap >>binder
        swap >>slot ;

! TUPLE: sequence-binder binder ; ! ???

: set-binder-accessors ( binder -- binder )
    dup slot-name>>
        [ lookup-getter 1quotation >>getter ]
        [ lookup-setter 1quotation >>setter ] bi ;

: <simple-binder> ( value type -- binder )
    binder new
        swap >>type
        swap >>value ;

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
*/
