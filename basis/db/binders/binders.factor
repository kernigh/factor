! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors classes.tuple constructors db.types db.utils
kernel math math.parser multiline parser quotations sequences ;
IN: db.binders

TUPLE: table-ordinal table-name table-ordinal ;
TUPLE: table-ordinal-column < table-ordinal column-name ;
CONSTRUCTOR: table-ordinal
    ( table-name table-ordinal -- obj ) ;
CONSTRUCTOR: table-ordinal-column
    ( table-name table-ordinal column-name -- obj ) ;

SYNTAX: TO{
    \ } [ 2 ensure-length first2 <table-ordinal> ] parse-literal ;

SYNTAX: TOC{
    \ } [ 3 ensure-length first3 <table-ordinal-column> ] parse-literal ;

TUPLE: binder ;
TUPLE: high-binder < binder class toc type value ;

TUPLE: in-binder < high-binder ;
TUPLE: in-binder-low < binder value type ;
CONSTRUCTOR: in-binder ( -- obj ) ;
CONSTRUCTOR: in-binder-low ( value type -- obj ) ;

SYNTAX: TYPED{
    \ } [ first2 <in-binder-low> ] parse-literal ;

TUPLE: out-binder < high-binder ;
TUPLE: out-binder-low < binder type ;
CONSTRUCTOR: out-binder ( toc type -- obj ) ;
CONSTRUCTOR: out-binder-low ( type -- obj ) ;

TUPLE: and-binder binders ;
TUPLE: or-binder binders ;

TUPLE: join-binder < binder toc1 toc2 ;
CONSTRUCTOR: join-binder ( toc1 toc2 -- obj ) ;

TUPLE: count-function < out-binder ;
CONSTRUCTOR: count-function ( toc -- obj )
    INTEGER >>type ;

TUPLE: sum-function < out-binder ;
CONSTRUCTOR: sum-function ( toc -- obj )
    REAL >>type ;

TUPLE: average-function < out-binder ;
CONSTRUCTOR: average-function ( toc -- obj )
    REAL >>type ;

TUPLE: min-function < out-binder ;
CONSTRUCTOR: min-function ( toc -- obj )
    REAL >>type ;

TUPLE: max-function < out-binder ;
CONSTRUCTOR: max-function ( toc -- obj )
    REAL >>type ;

TUPLE: first-function < out-binder ;
CONSTRUCTOR: first-function ( toc -- obj )
    REAL >>type ;

TUPLE: last-function < out-binder ;
CONSTRUCTOR: last-function ( toc -- obj )
    REAL >>type ;

TUPLE: equal-binder < in-binder ;
CONSTRUCTOR: equal-binder ( -- obj ) ;
TUPLE: not-equal-binder < in-binder ;
CONSTRUCTOR: not-equal-binder ( -- obj ) ;
TUPLE: less-than-binder < in-binder ;
CONSTRUCTOR: less-than-binder ( -- obj ) ;
TUPLE: less-than-equal-binder < in-binder ;
CONSTRUCTOR: less-than-equal-binder ( -- obj ) ;
TUPLE: greater-than-binder < in-binder ;
CONSTRUCTOR: greater-than-binder ( -- obj ) ;
TUPLE: greater-than-equal-binder < in-binder ;
CONSTRUCTOR: greater-than-equal-binder ( -- obj ) ;

TUPLE: relation-binder
class1 toc1 column1
class2 toc2 column2
relation-type ;

CONSTRUCTOR: relation-binder ( class1 toc1 column1 class2 toc2 column2 relation-type -- obj ) ;
