! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors classes.tuple constructors db.utils kernel
multiline parser quotations sequences ;
IN: db.binders

TUPLE: in-binder class renamed-table column type value ;
TUPLE: in-binder-low type value ;
CONSTRUCTOR: in-binder ( class renamed-table column type value -- obj ) ;
CONSTRUCTOR: in-binder-low ( type value -- obj ) ;

TUPLE: out-binder class renamed-table column type ;
TUPLE: out-binder-low type ;
CONSTRUCTOR: out-binder ( class renamed-table column type -- obj ) ;
CONSTRUCTOR: out-binder-low ( type -- obj ) ;

TUPLE: relation-binder
class1 renamed-table1 column1
class2 renamed-table2 column2
relation-type ;

CONSTRUCTOR: relation-binder ( class1 renamed-table1 column1 class2 renamed-table2 column2 relation-type -- obj ) ;
