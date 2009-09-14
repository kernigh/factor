! Copyright (C) 2008 Slava Pestov, Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators concurrency.combinators
db.connections db.pools db.postgresql db.sqlite
db.types fry io.files.temp kernel literals math multiline
namespaces random sequences system threads tools.test ;
IN: db.tester

: sqlite-test-db ( -- sqlite-db )
    "tuples-test.db" temp-file <sqlite-db> ;

! These words leak resources, but are useful for interactivel testing
: set-sqlite-db ( -- )
    sqlite-db db-open db-connection set ;

: test-sqlite-quot ( quot -- quot' )
    '[ sqlite-test-db _ with-db ] ; inline

: test-sqlite ( quot -- ) test-sqlite-quot call ; inline
: test-sqlite0 ( quot -- ) test-sqlite-quot call( -- ) ; inline

: postgresql-test-db ( -- postgresql-db )
    <postgresql-db>
        "localhost" >>host
        "postgres" >>username
        "thepasswordistrust" >>password
        "factor-test" >>database ;

: set-postgresql-db ( -- )
    postgresql-db db-open db-connection set ;

: test-postgresql-quot ( quot -- quot' )
    '[
        os windows? cpu x86.64? and [
            [ ] [ postgresql-test-db _ with-db ] unit-test
        ] unless
    ] ; inline

: test-postgresql ( quot -- ) test-postgresql-quot call ; inline
: test-postgresql0 ( quot -- ) test-postgresql-quot call( -- ) ; inline

: test-dbs ( quot -- )
    {
        [ test-sqlite0 ]
        [ test-postgresql0 ]
    } cleave ;

/*
TUPLE: test-1 id a b c ;

PERSISTENT: test-1
   { "id" +db-assigned-key+ }
   { "a" { VARCHAR 256 } NOT-NULL }
   { "b" { VARCHAR 256 } NOT-NULL }
   { "c" { VARCHAR 256 } NOT-NULL } ;

TUPLE: test-2 id x y z ;

PERSISTENT: test-2
   { "id" +db-assigned-key+ }
   { "x" { VARCHAR 256 } NOT-NULL }
   { "y" { VARCHAR 256 } NOT-NULL }
   { "z" { VARCHAR 256 } NOT-NULL } ;

: db-tester ( test-db -- )
    [
        [
            test-1 ensure-table
            test-2 ensure-table
        ] with-db
    ] [
        10 [
            drop
            10 [
                dup [
                    f 100 random 100 random 100 random test-1 boa
                    insert-tuple yield
                ] with-db
            ] times
        ] with parallel-each
    ] bi ;

: db-tester2 ( test-db -- )
    [
        [
            test-1 ensure-table
            test-2 ensure-table
        ] with-db
    ] [
        <db-pool> [
            10 [
                10 [
                    f 100 random 100 random 100 random test-1 boa
                    insert-tuple yield
                ] times
            ] parallel-each
        ] with-pooled-db
    ] bi ;
*/

