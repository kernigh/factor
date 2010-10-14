! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays db.connections db.queries db.statements
db.types kernel namespaces sqlite.db.connections ;
IN: sqlite.db.queries

M: sqlite-db-connection current-db-name 
    db-connection get db>> path>> ;

M: sqlite-db-connection table-exists-sql
    [ <statement> ] dip
        sanitize-string
        "pragma table_info('" "');" surround >>sql ;

