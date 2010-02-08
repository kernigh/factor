! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db db.debug db.types debugger kernel orm.persistent
orm.tuples tools.test sequences nested-comments ;
IN: orm.tuples.tests

TUPLE: foo-1 a b ;

PERSISTENT: foo-1
{ "a" INTEGER +primary-key+ }
{ "b" VARCHAR } ;

: test-1 ( -- )
    [ "drop table foo_1" sql-command ] try

    [ ] [ "create table foo_1 (a integer primary key, b varchar)" sql-command ] unit-test

    [ ] [ 1 "lol" foo-1 boa insert-tuple ] unit-test

    [ { { "1" "lol" } } ] [ "select * from foo_1" sql-query ] unit-test

    [ ] [ 1 "omg" foo-1 boa update-tuple ] unit-test

    [ { { "1" "omg" } } ] [ "select * from foo_1" sql-query ] unit-test

    [ ] [ 1 f foo-1 boa delete-tuples ] unit-test

    [ { } ] [ "select * from foo_1" sql-query ] unit-test ;

[ test-1 ] test-sqlite
[ test-1 ] test-postgresql

TUPLE: foo-2 id a ;
PERSISTENT: foo-2
{ "id" INTEGER +primary-key+ }
{ "a" VARCHAR } ;

TUPLE: bar-2 id b ;
PERSISTENT: bar-2
{ "id" INTEGER +primary-key+ }
{ "b" { foo-2 sequence } } ;

: setup-test-2-sql ( -- )
    [ "drop table foo_2" sql-command ] try
    [ "drop table bar_2" sql-command ] try

    [ ] [ "create table foo_2(id integer primary key, a varchar, bar_2_id integer)" sql-command ] unit-test
    [ ] [ "create table bar_2(id integer primary key)" sql-command ] unit-test

    [ ] [ "insert into foo_2(id, a, bar_2_id) values(0, 'first', 0);" sql-command ] unit-test
    [ ] [ "insert into foo_2(id, a, bar_2_id) values(1, 'second', 0);" sql-command ] unit-test

    [ ] [ "insert into bar_2(id) values(0);" sql-command ] unit-test

    [
        {
            { "0" "0" "first" }
            { "0" "1" "second" }
        }
    ] [ "select bar_2.id, foo_2.id, foo_2.a from bar_2 left join foo_2 on foo_2.bar_2_id = bar_2.id where bar_2.id = 0" sql-query ] unit-test

    ;

: test-2 ( -- )
    setup-test-2-sql

    [ ]
    [ T{ bar-2 f 0 } select-tuples ] unit-test
    ;

[ setup-test-2-sql ] test-sqlite
[ setup-test-2-sql ] test-postgresql

[ test-2 ] test-sqlite
[ test-2 ] test-postgresql
