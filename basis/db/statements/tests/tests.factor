! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors continuations db db.errors db.statements
db.tester db.types kernel tools.test db.binders ;
USE: multiline
IN: db.statements.tests

{ 1 0 } [ [ drop ] result-set-each ] must-infer-as
{ 1 1 } [ [ ] result-set-map ] must-infer-as

: create-computer-table ( -- )
    [ "drop table computer;" sql-command ] ignore-errors

    [ "drop table computer;" sql-command ]
    [ [ sql-table-missing? ] [ table>> "computer" = ] bi and ] must-fail-with

    [ ] [
        "create table computer(name varchar, os varchar, version integer);"
        sql-command
    ] unit-test ;

: test-sql-command ( -- )
    create-computer-table
    
    [ ] [
        "insert into computer (name, os) values('rocky', 'mac');"
        sql-command
    ] unit-test

    [ ] [
        "insert into computer (name, os) values('vio', 'opp');"
        f f <statement> sql-bind-command
    ] unit-test
    
    [ { { "rocky" "mac" } { "vio" "opp" } } ]
    [
        "select name, os from computer;"
        f f <statement> sql-query
    ] unit-test

    [ "insert into" sql-command ]
    [ sql-syntax-error? ] must-fail-with

    [ "selectt" sql-query drop ]
    [ sql-syntax-error? ] must-fail-with

    [ ] [
        "insert into computer (name, os, version) values(?, ?, ?);"
        { "clubber" "windows" "7" }
        f <statement>
        sql-bind-command
    ] unit-test

    [ { { "windows" } } ] [
        "select os from computer where name = ?;"
        { "clubber" } f <statement> sql-bind-query
    ] unit-test

    [ { { "windows" 7 } } ] [
        "select os, version from computer where name = ?;"
        { TV{ VARCHAR "clubber" } }
        { VARCHAR INTEGER }
        <statement> sql-bind-typed-query
    ] unit-test

    [ { { "windows" 7 } } ] [
        "select os, version from computer where name = ?;"
        { TV{ VARCHAR "clubber" } }
        { VARCHAR INTEGER }
        <statement> sql-bind-typed-query
    ] unit-test

    [ ] [
        "insert into computer (name, os, version) values(?, ?, ?);"
        {
            TV{ VARCHAR "paulie" }
            TV{ VARCHAR "netbsd" }
            TV{ INTEGER 7 }
        } f <statement>
        sql-bind-typed-command
    ] unit-test

/*
    [ ] [
        insert new
            "computer" >>into
            { "name" "os" "version" } >>names
            { "shoes" "freebsd" 5 } >>values
        
    ] unit-test
*/

    [ "drop table default_person" sql-command ] ignore-errors

    [ ] [
        "create table default_person(id INTEGER SERIAL PRIMARY KEY, name TEXT, birthdate TIMESTAMP, email TEXT, homepage TEXT)" f f <statement> sql-bind-command
    ] unit-test ;

[ test-sql-command ] test-dbs
