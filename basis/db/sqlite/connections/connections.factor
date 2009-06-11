! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators db.connections db.sqlite
db.sqlite.errors db.sqlite.lib kernel db.errors io.backend ;
IN: db.sqlite.connections

M: sqlite-db db-open ( db -- db-connection )
    path>> normalize-path sqlite-open <sqlite-db-connection> ;

M: sqlite-db-connection db-close ( db-connection -- )
    handle>> sqlite-close ;

M: sqlite-db-connection parse-sql-error ( error -- error' )
    dup n>> {
        { 1 [ string>> parse-sqlite-sql-error ] }
        [ drop ]
    } case ;
