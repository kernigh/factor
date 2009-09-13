! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db.errors db.orm db.orm.examples kernel tools.test ;
IN: db.orm.tests

: test-orm-users ( -- )
    [ user drop-table ] ignore-table-exists
    [ ] [ user create-table ] unit-test
    [
        ! T{ user f 1 "erg" 28 }
    ] [ "erg" 28 <user> [ insert-tuple ] keep drop ] unit-test
    [ ] [ "mew" 6 <user> insert-tuple ] unit-test
    [
        {
            T{ user { id 1 } { name "erg" } { age 28 } }
            T{ user { id 2 } { name "mew" } { age 6 } }
        }
    ] [ user new select-tuples ] unit-test
    
    ;
