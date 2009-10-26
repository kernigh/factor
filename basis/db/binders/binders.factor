! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors classes.tuple constructors db.utils kernel
multiline parser quotations sequences ;
IN: db.binders

TUPLE: in-binder class table-name column-name type value column ;
TUPLE: in-binder-low type value ;
CONSTRUCTOR: in-binder ( class table-name column-name type value column -- obj ) ;
CONSTRUCTOR: in-binder-low ( type value -- obj ) ;

TUPLE: out-binder class table-name column-name type column ;
TUPLE: out-binder-low type ;
CONSTRUCTOR: out-binder ( class table-name column-name type column -- obj ) ;
CONSTRUCTOR: out-binder-low ( type -- obj ) ;

TUPLE: out-function function table column type ;

TUPLE: count-function < out-function ;
CONSTRUCTOR: count-function ( table column

TUPLE: relation-binder
class1 table-name1 column-name1 column1
class2 table-name2 column-name2 column2
relation-type ;

CONSTRUCTOR: relation-binder ( class1 table-name1 column-name1 column1 class2 table-name2 column-name2 column2 relation-type -- obj ) ;
