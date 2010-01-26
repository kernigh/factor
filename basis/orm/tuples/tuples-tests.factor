! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db db.debug db.types debugger kernel orm.persistent
orm.tuples tools.test ;
IN: orm.tuples.tests

TUPLE: foo a b ;

PERSISTENT: foo
{ "a" INTEGER +primary-key+ }
{ "b" VARCHAR } ;

: test-foo ( -- )
    [ [ "drop table foo" sql-command ] test-sqlite ] try

    [ ] [ "create table foo (a integer primary key, b varchar)" sql-command ] unit-test

    [ ] [ 1 "lol" foo boa insert-tuple ] unit-test

    [ { { "1" "lol" } } ] [ "select * from foo" sql-query ] unit-test

    [ ] [ 1 "omg" foo boa update-tuple ] unit-test

    [ { { "1" "omg" } } ] [ "select * from foo" sql-query ] unit-test

    [ ] [ 1 f foo boa delete-tuples ] unit-test

    [ { } ] [ "select * from foo" sql-query ] unit-test ;

[ test-foo ] test-sqlite
