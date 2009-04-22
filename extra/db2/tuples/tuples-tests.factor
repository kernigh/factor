! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors continuations db2 db2.persistent db2.tester
db2.tuples db2.types kernel tools.test ;
IN: db2.tuples.tests

TUPLE: default-person id name birthdate email homepage ;

PERSISTENT: default-person {
    { "id" INTEGER { PRIMARY-KEY AUTOINCREMENT } }
    { "name" VARCHAR }
    { "birthdate" TIMESTAMP }
    { "email" VARCHAR }
    { "homepage" URL }
}

: person1 ( -- person )
    default-person new
        "noobar" >>name ;

: test-default-person ( -- )
    [ "drop table default_person" sql-command ] ignore-errors

    [ ] [ default-person create-table ] unit-test
    [ ] [ default-person drop-table ] unit-test
    [ ] [ default-person create-table ] unit-test
    [ ] [ person1 insert-tuple ] unit-test

    [ T{ default-person { id 1 } { name "noobar" } } ]
    [ person1 select-tuples ] unit-test

    ! [ ]
    ! [ T{ default-person { id 1 } { name "foobar" } } update-tuple ] unit-test
    ;

[ test-default-person ] test-dbs
