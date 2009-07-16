! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.binders db.types kernel tools.test ;
IN: db.binders.tests

! [ VARCHAR "a" ] [ SB{ "a" VARCHAR } [ type>> ] [ value>> ] bi ] unit-test
