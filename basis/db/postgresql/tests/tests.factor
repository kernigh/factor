! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db db.statements db.statements.tests
tools.test ;
IN: db.postgresql.tests

: test-sql-bound-commands ( -- )
    create-computer-table
    
    [ ] [
        <statement>
            "insert into computer (name, os, version) values($1, $2, $3);" >>sql
            { "clubber" "windows" "7" } >>in
        sql-bind-command
    ] unit-test

    [ { { "windows" } } ] [
        <statement>
            "select os from computer where name = $1;" >>sql
            { "clubber" } >>in
        sql-bind-query
    ] unit-test ;


