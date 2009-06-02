! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors continuations db2 db2.persistent db2.tester
db2.tuples db2.types kernel tools.test db2.binders
db2.statements multiline db2.fql db2.persistent.tests urls
calendar literals sequences math math.ranges math.intervals ;
QUALIFIED-WITH: math.intervals I
QUALIFIED-WITH: math.ranges R
IN: db2.tuples.tests

: test-default-person ( -- )
    [ "drop table default_person" sql-command ] ignore-errors

    [ ] [ default-person create-table ] unit-test
    [ ] [ default-person drop-table ] unit-test
    [ ] [ default-person create-table ] unit-test
    [ ] [ person1 insert-tuple ] unit-test

    [ T{ default-person { id 1 } { name "omg" } } ]
    [ person1 select-tuple ] unit-test

    [ V{ T{ default-person { id 1 } { name "omg" } } } ]
    [ person1 select-tuples ] unit-test


    [ ]
    [ T{ default-person { id 1 } { name "foobar" } } update-tuple ] unit-test
    [ "foobar" ]
    [ T{ default-person { id 1 } } select-tuple name>> ] unit-test
    ;

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

TUPLE: pet-store id name pets ;
TUPLE: pet id pet-store-id name type ;

PERSISTENT: pet-store
    { "id" +db-assigned-key+ }
    { "name" VARCHAR } ;

PERSISTENT: pet
    { "id" +db-assigned-key+ }
    { "pet-store-id" INTEGER }
    { "name" VARCHAR }
    { "type" VARCHAR } ;

: test-pets ( -- )
    [ "drop table pet_store" sql-command ] ignore-errors
    [ "drop table pet" sql-command ] ignore-errors

    [ ] [ "create table pet_store(id integer primary key autoincrement, name varchar);" sql-command ] unit-test
    [ ] [ "create table pet(id integer primary key autoincrement, pet_store_id integer, name varchar, type varchar);" sql-command ] unit-test
    [ ] [ "insert into pet_store(id, name) values('1', 'petstore1');" sql-command ] unit-test
    [ ] [ "insert into pet_store(id, name) values('2', 'petstore2');" sql-command ] unit-test
    [ ] [ "insert into pet(id, pet_store_id, name, type) values('1', '1', 'fido', 'dog');" sql-command ] unit-test
    [ ] [ "insert into pet(id, pet_store_id, name, type) values('2', '1', 'fritz', 'dog');" sql-command ] unit-test
    [ ] [ "insert into pet(id, pet_store_id, name, type) values('3', '1', 'sir higgins', 'dog');" sql-command ] unit-test
    [ ] [ "insert into pet(id, pet_store_id, name, type) values('4', '2', 'button', 'cat');" sql-command ] unit-test
    [ ] [ "insert into pet(id, pet_store_id, name, type) values('5', '2', 'mittens', 'cat');" sql-command ] unit-test
    [ ] [ "insert into pet(id, pet_store_id, name, type) values('6', '2', 'fester', 'cat');" sql-command ] unit-test

    [
        V{
            T{ pet-store { id 1 } { name "petstore1" } }
            T{ pet
                { id 1 }
                { pet-store-id 1 }
                { name "fido" }
                { type "dog" }
            }
            T{ pet-store { id 1 } { name "petstore1" } }
            T{ pet
                { id 2 }
                { pet-store-id 1 }
                { name "fritz" }
                { type "dog" }
            }
            T{ pet-store { id 1 } { name "petstore1" } }
            T{ pet
                { id 3 }
                { pet-store-id 1 }
                { name "sir higgins" }
                { type "dog" }
            }
            T{ pet-store { id 2 } { name "petstore2" } }
            T{ pet
                { id 4 }
                { pet-store-id 2 }
                { name "button" }
                { type "cat" }
            }
            T{ pet-store { id 2 } { name "petstore2" } }
            T{ pet
                { id 5 }
                { pet-store-id 2 }
                { name "mittens" }
                { type "cat" }
            }
            T{ pet-store { id 2 } { name "petstore2" } }
            T{ pet
                { id 6 }
                { pet-store-id 2 }
                { name "fester" }
                { type "cat" }
            }
        }
    ] [
        <"
        select pet_store_1.id, pet_store_1.name,
               pet_1.id, pet_1.pet_store_id, pet_1.name, pet_1.type
        from pet_store pet_store_1
            inner join pet pet_1 on (pet_store_1.id = pet_1.pet_store_id);
        ">
        f
        {
            RT{ pet-store { "id" INTEGER } { "name" VARCHAR } }
            RT{ pet
                { "id" INTEGER } { "pet-store-id" INTEGER }
                { "name" VARCHAR } { "type" VARCHAR }
            }
        }
        <statement> sql-bind-typed-query
    ] unit-test

    [
        {
            T{ pet
                { id 1 }
                { pet-store-id 1 }
                { name "fido" }
                { type "dog" }
            }
            T{ pet
                { id 2 }
                { pet-store-id 1 }
                { name "fritz" }
                { type "dog" }
            }
            T{ pet
                { id 3 }
                { pet-store-id 1 }
                { name "sir higgins" }
                { type "dog" }
            }
            T{ pet
                { id 4 }
                { pet-store-id 2 }
                { name "button" }
                { type "cat" }
            }
            T{ pet
                { id 5 }
                { pet-store-id 2 }
                { name "mittens" }
                { type "cat" }
            }
            T{ pet
                { id 6 }
                { pet-store-id 2 }
                { name "fester" }
                { type "cat" }
            }
        }
    ]
    [
        select new
            { "id" "pet_store_id" "name" "type" } >>names
            "pet" >>from
        expand-fql
        {
            RT{ pet
                { "id" INTEGER } { "pet-store-id" INTEGER }
                { "name" VARCHAR } { "type" VARCHAR }
            }
        } >>out
        sql-bind-typed-query
    ] unit-test

    ;


[ test-default-person ] test-dbs
! [ test-computer ] test-dbs
! [ test-pets ] test-dbs



TUPLE: test1 id timestamp ;

PERSISTENT: test1
    { "id" +db-assigned-key+ }
    { { "timestamp" "ts" } TIMESTAMP } ;

: test-test1 ( -- )
    [ test1 drop-table ] ignore-errors
    [ ] [ test1 create-table ] unit-test
    [ ] [ T{ test1 { timestamp $[ 2010 1 1 <date> ] } } insert-tuple ] unit-test
    [ ] [ T{ test1 { timestamp $[ 2010 1 2 <date> ] } } insert-tuple ] unit-test
    [ ] [ T{ test1 { timestamp $[ 2010 1 3 <date> ] } } insert-tuple ] unit-test
    [ ] [ T{ test1 { timestamp $[ 2010 1 4 <date> ] } } insert-tuple ] unit-test
    [ ] [ T{ test1 { timestamp $[ 2010 1 5 <date> ] } } insert-tuple ] unit-test
    [ 5 ] [ T{ test1 } select-tuples length ] unit-test
    [ 5 ] [ T{ test1 } count-tuples ] unit-test
    [ t ] [ T{ test1 } select-tuples [ timestamp>> ] all? ] unit-test
/*
    [ ] [
        T{ test1 { timestamp $[ 2010 1 2 <date> 2010 1 4 <date> R:[a,b] ] } }
        select-tuples
    ] unit-test
*/
    ;

[ test-test1 ] test-dbs


TUPLE: test2 id score ;

PERSISTENT: test2
    { "id" +db-assigned-key+ }
    { "score" INTEGER } ;

: test-test2 ( -- )
    [ test2 drop-table ] ignore-errors
    [ ] [ test2 create-table ] unit-test
    [ ] [ T{ test2 { score 0 } } insert-tuple ] unit-test
    [ ] [ T{ test2 { score 10 } } insert-tuple ] unit-test
    [ ] [ T{ test2 { score 20 } } insert-tuple ] unit-test
    [ ] [ T{ test2 { score 40 } } insert-tuple ] unit-test
    [ ] [ T{ test2 { score 50 } } insert-tuple ] unit-test
    [ ] [ T{ test2 { score 80 } } insert-tuple ] unit-test
    [ ] [ T{ test2 { score 90 } } insert-tuple ] unit-test
    [ ] [ T{ test2 { score 100 } } insert-tuple ] unit-test
    [ ] [ T{ test2 { score f } } insert-tuple ] unit-test
    [ 9 ] [ T{ test2 } select-tuples length ] unit-test
    [ f ] [ T{ test2 } select-tuples [ score>> integer? ] all? ] unit-test
    [ 1 ] [
        T{ test2 { score $[ 45 55 R:[a,b] ] } } select-tuples length
    ] unit-test
    [ 1 ] [
        T{ test2 { score $[ 45 55 I:[a,b] ] } } select-tuples length
    ] unit-test

    ! Double infinite interval should select any where the score is a number
    [ 8 ] [
        T{ test2 { score $[ -1/0. 1/0. I:[a,b] ] } } select-tuples length
    ] unit-test

    [
        T{ statement
            { sql
                "select id, score from test2 where (score = ? or score = ? or score = ?)"
            }
            { in V{
                    T{ binder { type INTEGER } { value 49 } }
                    T{ binder { type INTEGER } { value 50 } }
                    T{ binder { type INTEGER } { value 51 } }
                }
            }
            { out V{ } }
        }
    ] [
       T{ select
           { names { "id" "score" } }
           { from "test2" }
           { where
               T{ or-sequence
                { sequence
                    {
                       T{ op-eq { left "score" } { right "?" } }
                       T{ op-eq { left "score" } { right "?" } }
                       T{ op-eq { left "score" } { right "?" } }
                    }
                }
              }
           }
           { where-in
                {
                    T{ binder { type INTEGER } { value 49 } }
                    T{ binder { type INTEGER } { value 50 } }
                    T{ binder { type INTEGER } { value 51 } }
                }
           }
       } expand-fql
    ] unit-test

    ;

[ test-test2 ] test-dbs


TUPLE: test3 id ;

PERSISTENT: test3
    { "id" +random-key+ } ;

: test-test3 ( -- )
    [ test3 drop-table ] ignore-errors
    [ ] [ test3 create-table ] unit-test
    [ ] [ test3 ensure-table ] unit-test
    [ ] [ test3 ensure-table ] unit-test
    [ ] [ T{ test3 } insert-tuple ] unit-test
    [ t ] [ T{ test3 } select-tuple >boolean ] unit-test
    [ t ] [ T{ test3 } select-tuple id>> 1 = not ] unit-test
    [ ] [ T{ test3 } delete-tuples ] unit-test
    [ f ] [ T{ test3 } select-tuple ] unit-test
    ;

[ test-test3 ] test-dbs


TUPLE: test4 id ;

PERSISTENT: test4
    { "id" +db-assigned-key+ } ;

: test-test4 ( --  )
    [ test4 drop-table ] ignore-errors
    [ ] [ test4 create-table ] unit-test
    [ t ] [ T{ test4 } [ insert-tuple ] keep id>> integer? ] unit-test ;

[ test-test4 ] test-dbs


TUPLE: test5 pk1 pk2 ;

PERSISTENT: test5
    { "pk1" INTEGER PRIMARY-KEY }
    { "pk2" INTEGER PRIMARY-KEY } ;

: test-test5 ( --  )
    [ test5 drop-table ] ignore-errors
    [ ] [ test5 create-table ] unit-test
    [ ] [ T{ test5 f 1 2 } insert-tuple ] unit-test
    [ T{ test5 f 1 2 } ] [ T{ test5 f 1 2 } select-tuple ] unit-test ;
    
[ test-test5 ] test-dbs

TUPLE: test6 url ;

PERSISTENT: test6
    { "url" URL } ;

: test-test6 ( --  )
    [ test6 drop-table ] ignore-errors
    [ ] [ test6 create-table ] unit-test
    [ ] [ T{ test6 f "http://factorcode.org" } insert-tuple ] unit-test
    [ URL" http://factorcode.org" ]
    [ T{ test6 f "http://factorcode.org" } select-tuple url>> ] unit-test ;

[ test-test6 ] test-dbs
