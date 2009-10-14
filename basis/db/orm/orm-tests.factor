! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.errors db.orm db.orm.examples db.tester
kernel math sequences tools.test ;
IN: db.orm.tests

: test-orm-users ( -- )
    [ user drop-table ] ignore-table-exists
    [ ] [ user create-table ] unit-test
    [
        T{ user f 1 "erg" 28 }
    ] [ "erg" 28 <user> [ insert-tuple ] keep ] unit-test
    [ ] [ "mew" 6 <user> insert-tuple ] unit-test
    [
        {
            T{ user { id 1 } { name "erg" } { age 28 } }
            T{ user { id 2 } { name "mew" } { age 6 } }
        }
    ] [ user new select-tuples ] unit-test

    [
        T{ user { id 1 } { name "erg" } { age 29 } }
    ] [
        user new "erg" >>name select-tuple
        29 >>age update-tuple
        user new "erg" >>name select-tuple
    ] unit-test ;

: test-orm-lotto ( -- )
    [ lottery-ball drop-table ] ignore-table-exists
    [ ] [ lottery-ball create-table ] unit-test

    [ t ] [
        10 [ drop lottery-ball new [ insert-tuple ] keep n>> 0 > ] all?
    ] unit-test

    [ t ] [
        lottery-ball new select-tuples
        [ n>> 0 > ] all?
    ] unit-test
    ;

[ test-orm-users ] test-dbs
[ test-orm-lotto ] test-dbs
