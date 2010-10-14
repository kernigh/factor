! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays ascii combinators.short-circuit db
db.connections db.statements db.types db.utils kernel sequences ;
IN: db.queries

HOOK: current-db-name db-connection ( -- string )

ERROR: unsafe-sql-string string ;

HOOK: sanitize-string db-connection ( string -- string )

M: object sanitize-string
    dup [ { [ Letter? ] [ digit? ] [ "_" member? ] } 1|| ] all?
    [ unsafe-sql-string ] unless ;

HOOK: table-exists-sql db-connection ( database table -- ? )

: database-table-exists? ( database table -- ? )
    table-exists-sql sql-query ?first ?first >boolean ;

: table-exists? ( table -- ? )
    [ current-db-name ] dip database-table-exists? ;

M: object table-exists-sql
    [ <statement> ] 2dip
        2array >>in
        { BOOLEAN } >>out
        """SELECT EXISTS(
            SELECT * FROM information_schema.tables
            WHERE
                table_catalog=$1 AND 
                table_name=$2 AND
                table_schema='public')"""
        >>sql ;

