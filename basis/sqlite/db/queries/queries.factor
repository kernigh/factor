! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays db.connections db.queries db.statements
db.types kernel math namespaces sequences sqlite.db.connections ;
IN: sqlite.db.queries

M: sqlite-db-connection current-db-name 
    db-connection get db>> path>> ;

: sqlite-table-info ( string -- statement )
    [ <statement> ] dip
        sanitize-string
        "pragma table_info('" "');" surround >>sql ;
    

M: sqlite-db-connection table-exists-sql
    nip sqlite-table-info ;

TUPLE: sqlite-table-row cid name type notnull dflt_value pk ;

M: sqlite-db-connection table-rows-sql
    nip sqlite-table-info
        { INTEGER VARCHAR VARCHAR INTEGER VARCHAR INTEGER } >>out ;

M: sqlite-db-connection table-row-class sqlite-table-row ;
