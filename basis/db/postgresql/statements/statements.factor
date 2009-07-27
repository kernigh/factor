! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.connections
db.postgresql.connections.private db.postgresql.ffi
db.postgresql.lib db.statements destructors kernel namespaces
sequences ;
IN: db.postgresql.statements

TUPLE: postgresql-statement < statement ;

M: postgresql-db-connection prepare-statement* ( statement -- )
    [ db-connection get handle>> f ] dip
    [ ] [ sql>> ] [ in>> ] tri
    length f PQprepare postgresql-error
    >>handle ;

M: postgresql-db-connection dispose ( query -- )
    dup handle>> PQclear
    f >>handle drop ;
