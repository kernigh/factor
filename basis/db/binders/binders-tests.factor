! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.binders db.types kernel tools.test ;
IN: db.binders.tests

[ VARCHAR "a" ] [ SB{ VARCHAR "a" } [ type>> ] [ value>> ] bi ] unit-test
