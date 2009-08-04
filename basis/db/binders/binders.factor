! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors classes.tuple constructors db.utils kernel
multiline parser quotations sequences ;
IN: db.binders

TUPLE: in-binder table column type value ;
TUPLE: param-in-binder type value ;
TUPLE: out-typed-binder table column type ;

CONSTRUCTOR: in-binder ( table column type value -- obj ) ;
CONSTRUCTOR: param-in-binder ( type value -- obj ) ;
CONSTRUCTOR: out-typed-binder ( table column type -- obj ) ;
