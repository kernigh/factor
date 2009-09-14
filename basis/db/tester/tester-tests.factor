! Copyright (C) 2008 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.orm db.orm.examples db.tester kernel
multiline sequences tools.test ;
IN: db.tester.tests

[ ] [ sqlite-test-db db-tester ] unit-test
[ ] [ sqlite-test-db db-tester2 ] unit-test
[ ] [ postgresql-test-db db-tester ] unit-test
[ ] [ postgresql-test-db db-tester2 ] unit-test

: author-erg ( -- author ) \ author new "erg" >>name ;
: author-mew ( -- author ) \ author new "mew" >>name ;
: thread-erg ( -- thread )
    \ thread new
        author-erg >>author
        "erg's thread" >>topic ;

: thread-mew ( -- thread )
    \ thread new
        author-mew >>author
        "mew's thread" >>topic ;

: comment-erg-erg1 ( -- comment ) \ comment new thread-erg >>thread author-erg >>author "responding to my own thread" >>text ;
: comment-erg-erg2 ( -- comment ) \ comment new thread-erg >>thread author-erg >>author "responding to my own thread again" >>text ;
: comment-erg-mew1 ( -- comment ) \ comment new thread-erg >>thread author-mew >>author "i can has erg's thread?" >>text ;
: comment-erg-mew2 ( -- comment ) \ comment new thread-erg >>thread author-mew >>author "pl0x?" >>text ;

: insert-authors ( -- )
    [ ] [ author-erg insert-tuple ] unit-test
    [ ] [ author-mew insert-tuple ] unit-test ;

: insert-threads ( -- )
    [ ] [ thread-erg insert-tuple ] unit-test
    [ ] [ thread-mew insert-tuple ] unit-test ;

: insert-comments ( -- )
    [ ] [ comment-erg-erg1 insert-tuple ] unit-test
    [ ] [ comment-erg-erg2 insert-tuple ] unit-test
    [ ] [ comment-erg-mew1 insert-tuple ] unit-test
    [ ] [ comment-erg-mew2 insert-tuple ] unit-test ;

: test-comments ( -- )
    [ ] [ { author thread comment } [ recreate-table ] each ] unit-test

    ! Authors
    insert-authors

    [ T{ author f 1 "erg" } ] [ \ author new "erg" >>name select-tuple ] unit-test
    [ T{ author f 2 "mew" } ] [ \ author new "mew" >>name select-tuple ] unit-test

    [
        {
            T{ author f 1 "erg" }
            T{ author f 2 "mew" }
        }
    ] [ \ author new select-tuples ] unit-test


    ! Threads
    insert-threads

    [
        {
            T{ thread { id 1 } { author T{ author f 1 "erg" } } { topic "erg's thread" } }
            T{ thread { id 2 } { author T{ author f 2 "mew" } } { topic "mew's thread" } }
        }
    ] [ \ thread new select-tuples ] unit-test


/*
    ! Comments
    insert-comments

    [
    ] [
        \ comment new select-tuples
    ] unit-test
*/
    
    ;

[ ] [ [ test-comments ] test-dbs ] unit-test
