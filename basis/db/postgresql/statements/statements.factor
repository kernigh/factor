! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.connections
db.postgresql.connections.private db.postgresql.ffi
db.postgresql.lib db.statements destructors kernel namespaces
sequences ;
IN: db.postgresql.statements

M: postgresql-db-connection prepare-statement*
    dup
    [ db-connection get handle>> f ] dip
    [ sql>> ] [ in>> ] bi length f
    PQprepare postgresql-error >>handle ;

M: postgresql-db-connection dispose ( query -- )
    [ handle>> PQfinish ]
    [ f >>handle drop ] bi ;

M: postgresql-db-connection dispose-statement
    dup handle>> PQclear
    f >>handle drop ;
