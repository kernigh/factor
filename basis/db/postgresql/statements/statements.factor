! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.connections
db.postgresql.connections.private db.postgresql.ffi
db.postgresql.lib db.statements destructors kernel namespaces
sequences math.parser ;
IN: db.postgresql.statements

M: postgresql-db-connection prepare-statement*
    dup
    [ db-connection get handle>> "statementname-can'tbef?" ] dip
    [ sql>> ] [ in>> ] bi length f
    PQprepare postgresql-error >>handle ;

M: postgresql-db-connection dispose-statement
    dup handle>> PQclear
    f >>handle drop ;

M: postgresql-db-connection bind-sequence drop ;


SYMBOL: postgresql-bind-counter

M: postgresql-db-connection init-bind-index ( -- )
    1 postgresql-bind-counter set ;

M: postgresql-db-connection next-bind-index ( -- string )
    postgresql-bind-counter
    [ get number>string ] [ inc ] bi "$" prepend ;
