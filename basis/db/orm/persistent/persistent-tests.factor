! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db.orm.examples db.orm.persistent kernel tools.test ;
IN: db.orm.persistent.tests

[ t ] [ user new db-assigned-key? ] unit-test
[ f ] [ user2 new db-assigned-key? ] unit-test
[ f ] [ user new user-assigned-key? ] unit-test
[ t ] [ user2 new user-assigned-key? ] unit-test
