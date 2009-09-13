! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: combinators db.orm db.orm.persistent
db.postgresql.connections.private db.statements db.types kernel
make multiline ;
IN: db.postgresql.orm

M: postgresql-connection select-id-statement
    [ <statement> ] dip
    {
        [ table-name "SELECT nextval FROM NEXTVAL('" "id_seq');" surround add-sql ]
        [ drop INTEGER <out-binder-low> >>out ]
    } cleave ;
