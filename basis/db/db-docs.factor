! Copyright (C) 2008 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: classes db.connections help.markup help.syntax kernel ;
IN: db

HELP: db-connection
{ $description "The " { $snippet "db-connection" } " class is the superclass of all other database classes. It stores a " { $snippet "handle" } " to the database as well as insert, update, and delete queries. Stores the current database object as a dynamic variable." } ;

HELP: new-db-connection
{ $values { "class" class } { "obj" db-connection } }
{ $description "Creates a new database object from a given class with caches for prepared statements. Does not actually connect to the database." }
{ $notes "User-defined databases must call this constructor word instead of " { $link new } "." } ;
