! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays db db.queries db.statements kernel
postgresql.db ;
IN: postgresql.db.queries

M: postgresql-db-connection current-db-name
    db-connection get db>> database>> ;
