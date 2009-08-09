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



TUPLE: author2 id name addresses ;

TUPLE: address2 name street1 street2 street3 city state country zip1 zip2 ;

TUPLE: comment2 id author text ts ;

TUPLE: thread2 id topic author ts comments ;

DEFER-PERSISTENT: address2

PERSISTENT: author2
    { "id" +db-assigned-key+ }
    { "name" VARCHAR }
    { "addresses" { address2 sequence } } ;

PERSISTENT: address2
    { "id" +db-assigned-key+ }
    { "street1" VARCHAR }
    { "street2" VARCHAR }
    { "street3" VARCHAR }
    { "city" VARCHAR }
    { "state" VARCHAR }
    { "country" VARCHAR }
    { "zip1" INTEGER }
    { "zip2" INTEGER } ;

PERSISTENT: comment2
    { "id" +db-assigned-key+ }
    { "author" author2 }
    { "text" VARCHAR }
    { "ts" TIMESTAMP } ;

PERSISTENT: thread2
    { "id" +db-assigned-key+ }
    { "topic" VARCHAR }
    { "author" author2 }
    { "ts" TIMESTAMP }
    { "comments" { comment2 sequence } } ;





TUPLE: vehicle id year model owners ;
TUPLE: boat < vehicle ;
TUPLE: car < vehicle ;
TUPLE: owner id name boats cars ;

DEFER-PERSISTENT: owner

PERSISTENT: vehicle
    { "id" +db-assigned-key+ }
    { "year" INTEGER }
    { "model" VARCHAR }
    { "owners" { owner sequence } } ;

PERSISTENT: boat ;
PERSISTENT: car ;

PERSISTENT: owner
    { "id" +db-assigned-key+ }
    { "name" VARCHAR }
    { "boats" { boat sequence } }
    { "cars" { car sequence } } ;



TUPLE: company id departments ;
TUPLE: department id employees ;
TUPLE: employee id name ;
TUPLE: supervisor id employee department ;
TUPLE: product id name ;
TUPLE: task id decription ;
TUPLE: product-task id product task ;
TUPLE: employee-product-task id employee product-task ;

DEFER-PERSISTENT: department
DEFER-PERSISTENT: employee
DEFER-PERSISTENT: supervisor
DEFER-PERSISTENT: product
DEFER-PERSISTENT: employee-product-task

PERSISTENT: company
    { "id" +db-assigned-key+ }
    { "departments" { department sequence } } ;

PERSISTENT: department
    { "id" +db-assigned-key+ }
    { "employees" { employee sequence } } ;

PERSISTENT: employee
    { "id" +db-assigned-key+ }
    { "name" VARCHAR } ;

PERSISTENT: supervisor
    { "id" +db-assigned-key+ }
    { "employee" employee }
    { "department" department } ;

PERSISTENT: product
    { "id" +db-assigned-key+ }
    { "name" VARCHAR } ;

PERSISTENT: task
    { "id" +db-assigned-key+ }
    { "description" VARCHAR } ;

PERSISTENT: product-task
    { "id" +db-assigned-key+ }
    { "product" product }
    { "task" task } ;

PERSISTENT: employee-product-task
    { "id" +db-assigned-key+ }
    { "employee" employee }
    { "product-task" product-task } ;





TUPLE: compound1 a b text ;
TUPLE: compound2 c compound1 text ;

PERSISTENT: compound1
    { "a" INTEGER PRIMARY-KEY }
    { "b" INTEGER PRIMARY-KEY }
    { "text" VARCHAR } ;

PERSISTENT: compound2
    { "c" INTEGER PRIMARY-KEY }
    { "compound1" compound1 }
    { "text" VARCHAR } ;

/*


create table foo(a integer, b integer, text varchar, primary key(a,b));
create table bar(c integer, a integer, b integer, text varchar, primary key(c));
insert into foo(a,b,text) values(1,2,'lol');
insert into bar(c,a,b,text) values(3,1,2,'omg');
select foo.text from bar
    left join foo on bar.a = foo.a and bar.b = foo.b;

*/










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
select
t1.id,
    a1.id,
    a1.name,
t1.text,
t1.ts,
    c1.id,
        a2.id,
        a2.name,
    c1.text,
    c1.ts
 from thread as t1
 left join author as a1 on t1.author_id = a1.id
 left join comment as c1 on t1.id = c1.thread_id
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







TUPLE: examinee id name version ;

TUPLE: exam id name questions date-taken version ;

TUPLE: question id text version ;

TUPLE: answer id correct? text version ;


! TUPLE: exam-question id exam-id question-id version ;

TUPLE: answered-question id exam question correct? version ;

TUPLE: selected-answer answered-question-id answer-id version ;

*/
