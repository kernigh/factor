! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays combinators db db.binders db.orm
db.orm.fql db.orm.persistent db.postgresql.connections.private
db.statements db.types kernel make multiline sequences locals ;
IN: db.postgresql.orm

: select-id-statement ( tuple -- statement )
    [ <statement> ] dip
    {
        [ table-name "SELECT nextval FROM NEXTVAL('" "_id_seq');" surround add-sql ]
        [ drop INTEGER <out-binder-low> 1array >>out ]
    } cleave ;

M:: postgresql-db-connection insert-tuple* ( tuple -- )
    [
        tuple lookup-persistent db-assigned-key? [
            tuple dup select-id-statement sql-bind-typed-query
            first first set-primary-key drop
        ] when

        tuple dup lookup-persistent columns>>
        [ column>in-binder ] with map <insert> expand-fql ,
    ] { } make [ sql-bind-typed-command tuple ] keep run-after-setters ;
