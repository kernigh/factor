! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays combinators db.binders db.orm
db.orm.persistent db.postgresql.connections.private
db.statements db.types kernel make multiline sequences ;
IN: db.postgresql.orm

M: postgresql-db-connection select-id-statement
    [ <statement> ] dip
    {
        [ table-name "SELECT nextval FROM NEXTVAL('" "id_seq');" surround add-sql ]
        [ drop INTEGER <out-binder-low> 1array >>out ]
    } cleave ;
