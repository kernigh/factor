! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db.orm.fql db.postgresql.connections.private kernel
math.parser namespaces sequences ;
IN: db.postgresql.fql

SYMBOL: postgresql-bind-counter

M: postgresql-db-connection init-bind-index ( -- )
    1 postgresql-bind-counter set ;

M: postgresql-db-connection next-bind-index ( -- string )
    postgresql-bind-counter
    [ get number>string ] [ inc ] bi "$" prepend ;
