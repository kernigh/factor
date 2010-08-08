! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators db.connections db.errors
db.postgresql db.postgresql.errors db.postgresql.ffi
db.postgresql.lib kernel sequences splitting destructors ;
IN: db.postgresql.connections

<PRIVATE

TUPLE: postgresql-db-connection < db-connection ;

: <postgresql-db-connection> ( handle -- db-connection )
    \ postgresql-db-connection new-db-connection ;

PRIVATE>

M: postgresql-db db>db-connection ( db -- db-connection )
    {
        [ host>> ]
        [ port>> ]
        [ pgopts>> ]
        [ pgtty>> ]
        [ database>> ]
        [ username>> ]
        [ password>> ]
    } cleave connect-postgres <postgresql-db-connection> ;

M: postgresql-db-connection dispose* ( db-connection -- )
    [ handle>> PQfinish ] [ f >>handle drop ] bi ;

M: postgresql-db-connection parse-sql-error
    "\n" split dup length {
        { 1 [ first parse-postgresql-sql-error ] }
        { 3 [
                first3
                [ parse-postgresql-sql-error ] 2dip
                postgresql-location >>location
        ] }
    } case ;
