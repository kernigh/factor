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


TUPLE: thing id whatsit ;
TUPLE: thing-container id1 id2 name thing ;

PERSISTENT: thing
    { "id" +db-assigned-key+ }
    { "whatsit" VARCHAR } ;

PERSISTENT: thing-container
    { "id1" INTEGER PRIMARY-KEY }
    { "id2" INTEGER PRIMARY-KEY }
    { "name" VARCHAR }
    { "thing" thing } ;




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





TUPLE: examinee id name version ;

TUPLE: exam id name questions date-taken version ;

TUPLE: question id text version ;

TUPLE: answer id correct? text version ;


! TUPLE: exam-question id exam-id question-id version ;

TUPLE: answered-question id exam question correct? version ;

TUPLE: selected-answer answered-question-id answer-id version ;


TUPLE: boat year model ;
TUPLE: owner name ;

TUPLE: boat-owner boat owner ;


/*

author new select-tuples
select a1.id, a1.name from author as a1;

reconstruct:
author new
    >>id
    >>name




comment new select-tuples
select c1.id, c1.text, c1.ts, a1.id, a1.name from comment as c1
 left join author as a1 on c1.author_id = a1.id;




thread new select-tuples
select t1.id, a1.id, a1.name, t1.text, t1.ts,
c1.id, a2.id, a2.name, c1.text, c1.ts
 from thread as t1
 left join comment as c1 on t1.id = c1.thread_id
 left join author as a1 on t1.author_id = a1.id
 left join author as a2 on c1.author_id = a2.id ;


reconstruct:
thread new
    >>id
        author new
            >>id
            >>name
    >>author
    >>text
    >>ts
        comment new
            >>id
                author new
                >>id >>name
            >>author
            >>text
            >>ts
    over comments>> push


thread new
    COUNT >>comments
select-tuples

select t1.id, a1.id, a1.name, t1.text, t1.ts, count(c1.id)
 from thread as t1
 left join author as a1 on t1.author_id = a1.id
 left join comment as c1 on t1.id = c1.thread_id
 group by t1.id;


reconstruct:
thread new
    >>id
        author new
            >>id
            >>name
    >>author
    >>text
    >>ts
    >>comments



thread new
    IGNORE >>comments
select-tuples


*/
