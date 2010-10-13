! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators db.connections sqlite.db
sqlite.db.errors sqlite.db.lib kernel db.errors io.backend
destructors ;
IN: sqlite.db.connections

TUPLE: sqlite-db-connection < db-connection ;

: <sqlite-db-connection> ( handle -- db-connection )
    sqlite-db-connection new-db-connection ;

M: sqlite-db db>db-connection ( db -- db-connection )
    path>> normalize-path sqlite-open <sqlite-db-connection> ;

M: sqlite-db-connection dispose* ( db-connection -- )
    [ handle>> sqlite-close ] [ f >>handle drop ] bi ;

M: sqlite-db-connection parse-sql-error ( error -- error' )
    dup n>> {
        { 1 [ string>> parse-sqlite-sql-error ] }
        [ drop ]
    } case ;
