! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: continuations db.debug orm.examples orm.queries
tools.test ;
IN: orm.queries.tests

[ [ \ user drop-table ] test-dbs ] ignore-errors

[ \ user create-table ] test-dbs
[ \ user drop-table ] test-dbs
