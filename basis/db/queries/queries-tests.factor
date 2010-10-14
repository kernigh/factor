! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db db.debug db.queries debugger tools.test ;
IN: db.queries.tests

: test-table-exists ( -- )
    [ "drop table table_omg;" sql-command ] try
    [ f ] [ "table_omg" table-exists? ] unit-test
    [ ] [ "create table table_omg(id integer);" sql-command ] unit-test
    [ t ] [ "table_omg" table-exists? ] unit-test ;

[ test-table-exists ] test-dbs
