! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db db.connections db.orm db.orm.fql
db.orm.persistent db.sqlite.connections db.sqlite.ffi
db.sqlite.lib kernel math namespaces sequences db.statements
locals ;
IN: db.sqlite.orm

M:: sqlite-db-connection insert-tuple* ( tuple -- )
    tuple dup lookup-persistent columns>> [ column>in-binder ] with map
    <insert> expand-fql
    [ sql-bind-typed-command tuple ] keep run-after-setters

    tuple lookup-persistent db-assigned-key? [
        tuple last-insert-id set-primary-key drop
    ] when ;
