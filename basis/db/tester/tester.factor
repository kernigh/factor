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

: test-sqlite ( quot -- )
    '[ sqlite-test-db _ with-db ] call ; inline

: test-sqlite0 ( quot -- )
    '[ sqlite-test-db _ with-db ] call( -- ) ;

: test-dbs ( quot -- )
    {
        [ test-sqlite0 ]
    } cleave ;

: postgresql-test-db ( -- postgresql-db )
    <postgresql-db>
        "localhost" >>host
        "postgres" >>username
        "thepasswordistrust" >>password
        "factor-test" >>database ;

: set-postgresql-db ( -- )
    postgresql-db db-open db-connection set ;

: test-postgresql ( quot -- )
    '[
        os windows? cpu x86.64? and [
            [ ] [ postgresql-test-db _ with-db ] unit-test
        ] unless
    ] call ; inline


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



TUPLE: user id name age ;
TUPLE: score id user score ;

PERSISTENT: user
    { "id" +db-assigned-key+ }
    { "name" VARCHAR }
    { "age" INTEGER } ;

PERSISTENT: score
    { "id" +db-assigned-key+ }
    { "user" user }
    { "score" INTEGER } ;

<<
: user1 ( -- obj ) T{ user f 1 "erg" 27 } clone ;
>>

: score1 ( -- obj )
    T{ score
        { id 1 }
        { user $[ user1 ] }
        { score 100 }
    } clone ;


TUPLE: thing-container id1 id2 name ;
TUPLE: thing id thing-container whatsit ;

PERSISTENT: thing-container
    { "id1" INTEGER PRIMARY-KEY }
    { "id2" INTEGER PRIMARY-KEY }
    { "name" VARCHAR } ;

PERSISTENT: thing
    { "id" +db-assigned-key+ }
    { "thing-container" thing-container }
    { "whatsit" VARCHAR } ;




TUPLE: author id name ;

TUPLE: comment id author text ts ;

TUPLE: thread id topic author ts comments ;

PERSISTENT: author
    { "id" +db-assigned-key+ }
    { "name" VARCHAR } ;

PERSISTENT: comment
    { "id" +db-assigned-key+ }
    { "author" author }
    { "text" VARCHAR }
    { "ts" TIMESTAMP } ;

PERSISTENT: thread
    { "id" +db-assigned-key+ }
    { "topic" VARCHAR }
    { "author" author }
    { "ts" TIMESTAMP }
    { "comments" { comment sequence } } ;

    ! 1 thread : many comments





TUPLE: examinee id name version ;

TUPLE: exam id name questions date-taken version ;

TUPLE: question id text version ;

TUPLE: answer id correct? text version ;


! TUPLE: exam-question id exam-id question-id version ;

TUPLE: answered-question id exam question correct? version ;

TUPLE: selected-answer answered-question-id answer-id version ;

*/
