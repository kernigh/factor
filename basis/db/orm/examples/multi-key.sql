create table foo(a integer, b integer, text varchar, primary key(a,b));
create table bar(c integer, a integer, b integer, text varchar, primary key(c));
insert into foo(a,b,text) values(1,2,'lol');
insert into bar(c,a,b,text) values(3,1,2,'omg');
select foo.text from bar
	left join foo on bar.a = foo.a and bar.b = foo.b;


