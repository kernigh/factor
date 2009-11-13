! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors classes.tuple constructors db.utils kernel
multiline parser quotations sequences db.types ;
IN: db.binders

TUPLE: binder ;

TUPLE: in-binder < binder class table-name column-name type value column ;
TUPLE: in-binder-low < binder type value ;
CONSTRUCTOR: in-binder ( class table-name column-name type value column -- obj ) ;
CONSTRUCTOR: in-binder-low ( type value -- obj ) ;

TUPLE: out-binder < binder class table-name column-name type column ;
TUPLE: out-binder-low < binder type ;
CONSTRUCTOR: out-binder ( class table-name column-name type column -- obj ) ;
CONSTRUCTOR: out-binder-low ( type -- obj ) ;


TUPLE: join-binder < binder table-name1 column-name1 table-name2 column-name2 ;
CONSTRUCTOR: join-binder ( table-name1 column-name1 table-name2 column-name2 -- obj ) ;

TUPLE: count-function < out-binder ;
CONSTRUCTOR: count-function ( table-name column-name -- obj )
    INTEGER >>type ;

TUPLE: sum-function < out-binder ;
CONSTRUCTOR: sum-function ( table-name column-name -- obj )
    REAL >>type ;

TUPLE: average-function < out-binder ;
CONSTRUCTOR: average-function ( table-name column-name -- obj )
    REAL >>type ;

TUPLE: min-function < out-binder ;
CONSTRUCTOR: min-function ( table-name column-name -- obj )
    REAL >>type ;

TUPLE: max-function < out-binder ;
CONSTRUCTOR: max-function ( table-name column-name -- obj )
    REAL >>type ;

TUPLE: first-function < out-binder ;
CONSTRUCTOR: first-function ( table-name column-name -- obj )
    REAL >>type ;

TUPLE: last-function < out-binder ;
CONSTRUCTOR: last-function ( table-name column-name -- obj )
    REAL >>type ;


TUPLE: relation-binder
class1 table-name1 column-name1 column1
class2 table-name2 column-name2 column2
relation-type ;

CONSTRUCTOR: relation-binder ( class1 table-name1 column-name1 column1 class2 table-name2 column-name2 column2 relation-type -- obj ) ;
