! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db db.statements db.statements.tests
tools.test ;
IN: db.sqlite.tests

: test-sql-bound-commands ( -- )
    create-computer-table
    
    [ ] [
        <statement>
            "insert into computer (name, os, version) values(?, ?, ?);" >>sql
            { "clubber" "windows" "7" } >>in
        sql-bind-command
    ] unit-test

    [ { { "windows" } } ] [
        <statement>
            "select os from computer where name = ?;" >>sql
            { "clubber" } >>in
        sql-bind-query
    ] unit-test ;
