drop table author;
drop table thread;
drop table comment;

create table author(id integer primary key, name varchar);
create table thread(id integer primary key, author_id integer, text varchar, ts timestamp);
create table comment(id integer primary key, author_id integer, thread_id integer, text varchar, ts timestamp);



insert into author(name) values('erg');
insert into author(name) values('mew');

insert into thread(author_id, text) values((select id from author where name = 'erg'), 'how i shot web?');
insert into thread(author_id, text) values((select id from author where name = 'mew'), 'how is babby formed?');

insert into comment(author_id, thread_id, text) values((select id from author where name ='erg'), (select id from thread where text = 'how i shot web?'), 'web comment0');
insert into comment(author_id, thread_id, text) values((select id from author where name ='erg'), (select id from thread where text = 'how i shot web?'), 'web comment1');
insert into comment(author_id, thread_id, text) values((select id from author where name ='mew'), (select id from thread where text = 'how i shot web?'), 'web comment2');

insert into comment(author_id, thread_id, text) values((select id from author where name ='erg'), (select id from thread where text = 'how is babby formed?'), 'web comment0');
insert into comment(author_id, thread_id, text) values((select id from author where name ='erg'), (select id from thread where text = 'how is babby formed?'), 'web comment1');
insert into comment(author_id, thread_id, text) values((select id from author where name ='mew'), (select id from thread where text = 'how is babby formed?'), 'web comment2');


select a1.id, a1.name from author as a1;

-- Return a thread object
select c1.id, c1.text, c1.ts, a1.id, a1.name from comment as c1
 left join author as a1 on c1.author_id = a1.id;


select "All threads, comments";
select t1.id, a1.id, a1.name, t1.text, t1.ts,
c1.id, a2.id, a2.name, c1.text, c1.ts
 from thread as t1
 left join comment as c1 on t1.id = c1.thread_id
 left join author as a1 on t1.author_id = a1.id
 left join author as a2 on c1.author_id = a2.id ;


select "All threads, comment counts";
select t1.id, a1.id, a1.name, t1.text, t1.ts, count(c1.id)
 from thread as t1
 left join author as a1 on t1.author_id = a1.id
 left join comment as c1 on t1.id = c1.thread_id
 group by t1.id;

