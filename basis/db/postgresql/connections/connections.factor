! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: ;
IN: db.postgresql.connections

<PRIVATE

TUPLE: postgresql-db-connection < db-connection ;
: <postgresql-db-connection> ( handle -- db-connection )
    postgresql-db-connection new-db-connection
        swap >>handle ;

PRIVATE>

