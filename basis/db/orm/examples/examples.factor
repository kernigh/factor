! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db.orm.persistent db.types kernel literals multiline
sequences ;
IN: db.orm.examples

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


TUPLE: thing-container id1 id2 name thing ;
TUPLE: thing id whatsit ;

PERSISTENT: thing-container
    { "id1" INTEGER PRIMARY-KEY }
    { "id2" INTEGER PRIMARY-KEY }
    { "name" VARCHAR }
    { "thing" thing } ;

PERSISTENT: thing
    { "id" +db-assigned-key+ }
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



/*

author new select-tuples

comment new select-tuples

thread new select-tuples


thread new
    COUNT >>comments
select-tuples


thread new
    IGNORE >>comments
select-tuples


*/
