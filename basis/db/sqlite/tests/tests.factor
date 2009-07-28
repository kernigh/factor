! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db db.statements db.statements.tests tools.test ;
IN: db.sqlite.tests

: test-sql-bound-commands ( -- )
    create-computer-table
    
    [ ] [
        "insert into computer (name, os, version) values(?, ?, ?);"
        { "clubber" "windows" "7" } f <statement> sql-bind-command
    ] unit-test

    [ { { "windows" } } ] [
        "select os from computer where name = ?;"
        { "clubber" } f <statement> sql-bind-query
    ] unit-test ;
