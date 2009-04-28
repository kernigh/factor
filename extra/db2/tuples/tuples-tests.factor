! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors continuations db2 db2.persistent db2.tester
db2.tuples db2.types kernel tools.test db2.binders
db2.statements ;
IN: db2.tuples.tests

TUPLE: default-person id name birthdate email homepage ;

PERSISTENT: default-person
    { "id" INTEGER { PRIMARY-KEY AUTOINCREMENT } }
    { "name" VARCHAR }
    { "birthdate" TIMESTAMP }
    { "email" VARCHAR }
    { "homepage" URL } ;

: person1 ( -- person )
    default-person new
        "omg" >>name ;

: test-default-person ( -- )
    [ "drop table default_person" sql-command ] ignore-errors

    [ ] [ default-person create-table ] unit-test
    [ ] [ default-person drop-table ] unit-test
    [ ] [ default-person create-table ] unit-test
    [ ] [ person1 insert-tuple ] unit-test

    [ T{ default-person { id 1 } { name "omg" } } ]
    [ person1 select-tuple ] unit-test

    [ { T{ default-person { id 1 } { name "omg" } } } ]
    [ person1 select-tuples ] unit-test

    [ ]
    [ T{ default-person { id 1 } { name "foobar" } } update-tuple ] unit-test
    ;

TUPLE: computer name os version ;

PERSISTENT: computer
    { "name" VARCHAR }
    { "os" VARCHAR }
    { "version" INTEGER } ;

: test-computer ( -- )
    [ "drop table computer;" sql-command ] ignore-errors

    [ ] [
        "create table computer(name varchar, os varchar, version integer);"
        sql-command
    ] unit-test

    [ ] [
        "insert into computer (name, os) values('rocky', 'mac');"
        sql-command
    ] unit-test

    [ ] [
        "insert into computer (name, os, version) values('bullwinkle', 'haiku', '1');"
        sql-command
    ] unit-test

    [
        V{
            T{ computer { os "mac" } }
        }
    ] [
        "select os, version from computer where name = ?;"
        { TV{ VARCHAR "rocky" } }
        { RT{ computer { "os" VARCHAR } { "version" INTEGER } } }
        <statement> sql-bind-typed-query
    ] unit-test

    [
        V{
            T{ computer { name "bullwinkle" } { os "haiku" } { version 1 } }
        }
    ] [
        "select name, os, version from computer where name = ?;"
        { TV{ VARCHAR "bullwinkle" } }
        { RT{ computer { "name" VARCHAR } { "os" VARCHAR } { "version" INTEGER } } }
        <statement> sql-bind-typed-query
    ] unit-test

! Passing in sql-types returns a typed array
    [
        {
            { "rocky" "mac" f }
        }
    ] [
        "select name, os, version from computer where name = ?;"
        { TV{ VARCHAR "rocky" } }
        { VARCHAR VARCHAR INTEGER }
        <statement> sql-bind-typed-query
    ] unit-test

! Passing in tuple-binders returns a typed tuple
    [
        V{
            T{ computer { name "rocky" } { os "mac" } { version f } }
        }
    ] [
        "select name, os, version from computer where name = ?;"
        { TV{ VARCHAR "rocky" } }
        {
            RT{ computer
                { "name" VARCHAR }
                { "os" VARCHAR }
                { "version" INTEGER }
            }
        }
        <statement> sql-bind-typed-query
    ] unit-test
    ;

[ test-default-person ] test-dbs
[ test-computer ] test-dbs
