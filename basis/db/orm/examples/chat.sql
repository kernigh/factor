--.read /Users/erg/factor/basis/db/examples/chat.sql

drop table ircer;
drop table spoken;

create table ircer (id integer primary key, name varchar);
create table spoken (id integer primary key, ircer_id integer, line varchar, ts timestamp);

insert into ircer(name) values('erg');
insert into ircer(name) values('mew');

insert into spoken (ircer_id, line, ts) values((select id from ircer where name = 'erg'), 'hi everybody!', datetime('now'));
insert into spoken (ircer_id, line, ts) values((select id from ircer where name = 'mew'), 'meow erg', datetime('now'));
insert into spoken (ircer_id, line, ts) values((select id from ircer where name = 'mew'), 'meow meow meow', datetime('now'));


select '';
select 'Ircers:';
select * from ircer;

select '';
select 'Spokens:';
select * from spoken;

--select all messages
select '';
select 'Selecting all messages';
select ircer.name, spoken.line, spoken.ts from spoken
 left join ircer on spoken.ircer_id = ircer.id;

--select all messages by a user
select '';
select 'Selecting erg messages';
select ircer.name, spoken.line, spoken.ts from spoken
 left join ircer on spoken.ircer_id = ircer.id
 where ircer.name ='erg';

select '';
select 'Selecting mew messages';
select ircer.name, spoken.line, spoken.ts from spoken
  left join ircer on spoken.ircer_id = ircer.id
  where ircer.name ='mew'
  order by ts;;
