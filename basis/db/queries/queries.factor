! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays ascii classes.tuple
combinators.short-circuit db db.connections db.statements
db.types db.utils fry kernel orm.tuples sequences strings ;
IN: db.queries

HOOK: current-db-name db-connection ( -- string )

ERROR: unsafe-sql-string string ;

HOOK: sanitize-string db-connection ( string -- string )

M: object sanitize-string
    dup [ { [ Letter? ] [ digit? ] [ "_" member? ] } 1|| ] all?
    [ unsafe-sql-string ] unless ;

<PRIVATE
GENERIC: >sql-name* ( object -- string )
M: tuple-class >sql-name* name>> sql-name-replace ;
M: string >sql-name* sql-name-replace ;
PRIVATE>

: >sql-name ( object -- string ) >sql-name* sanitize-string ;

HOOK: table-exists-sql db-connection ( database table -- ? )

: database-table-exists? ( database table -- ? )
    table-exists-sql sql-query ?first ?first >boolean ;

: table-exists? ( table -- ? )
    [ current-db-name ] dip database-table-exists? ;

CONSTANT: table-information-string
    """SELECT * FROM information_schema.tables
        WHERE
            table_catalog=$1 AND 
            table_name=$2 AND
            table_schema='public'"""

: table-information-statement ( database table -- statement )
    [ <statement> ] 2dip
        2array >>in
        { BOOLEAN } >>out
        table-information-string >>sql ;

M: object table-exists-sql
    table-information-statement
    [ "SELECT EXISTS(" ")" surround ] change-sql ;

HOOK: table-rows-sql db-connection ( database table -- ? )
HOOK: table-row-class db-connection ( -- class )

M: object table-rows-sql
    table-information-statement f >>out ;

: database-table-rows ( database table -- sequence )
    table-rows-sql sql-query
    table-row-class '[ _ slots>tuple ] map ;

: table-rows ( table -- sequence )
    [ current-db-name ] dip database-table-rows ;
