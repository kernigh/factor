! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db2.persistent db2.tuples db2.types tools.test
db2.tester ;
IN: db2.tuples.tests

TUPLE: default-person id name birthdate email homepage ;

PERSISTENT: default-person {
    { "id" INTEGER { SERIAL PRIMARY-KEY } }
    { "name" VARCHAR }
    { "birthdate" TIMESTAMP }
    { "email" VARCHAR }
    { "homepage" URL }
}

: test-default-person ( -- )
    [ ] [ default-person create-table ] unit-test
    [ ] [ default-person drop-table ] unit-test
    ;


[ test-default-person ] test-dbs
