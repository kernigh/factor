drop table boat;
drop table owner;
drop table boat_owner;

create table boat(id integer primary key, name varchar, year integer, model varchar);
create table owner(id integer primary key, name varchar);

create table boat_owner(id integer primary key, boat_id integer, owner_id integer);

insert into boat(name, year, model) values('HMS Raptor', 2011, 'Raptor2011');
insert into boat(name, year, model) values('HMS Raptor 2', 2015, 'Raptor2015');

insert into owner(name) values('erg');
insert into owner(name) values('mew');


insert into boat_owner(boat_id, owner_id) values((select id from boat where name = 'HMS Raptor'), (select id from owner where name = 'erg'));
insert into boat_owner(boat_id, owner_id) values((select id from boat where name = 'HMS Raptor'), (select id from owner where name = 'mew'));

insert into boat_owner(boat_id, owner_id) values((select id from boat where name = 'HMS Raptor 2'), (select id from owner where name = 'erg'));
insert into boat_owner(boat_id, owner_id) values((select id from boat where name = 'HMS Raptor 2'), (select id from owner where name = 'mew'));


select boat_id, owner_id from boat_owner;
