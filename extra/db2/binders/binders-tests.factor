! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db2.binders db2.types kernel tools.test ;
IN: db2.binders.tests

[ VARCHAR "a" ] [ TV{ VARCHAR "a" } [ type>> ] [ value>> ] bi ] unit-test
