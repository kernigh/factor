! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db2 db2.connections db2.persistent sequences kernel
db2.errors fry ;
IN: db2.tuples

HOOK: create-table-statement db-connection ( class -- statement )
HOOK: drop-table-statement db-connection ( class -- statement )

HOOK: insert-tuple-statement db-connection ( tuple -- statement )
! HOOK: insert-tuple-set-key-statement db-connection ( tuple -- statement )
HOOK: update-tuple-statement db-connection ( tuple -- statement )
HOOK: delete-tuple-statement db-connection ( tuple -- statement )
HOOK: select-tuple-statement db-connection ( tuple -- statement )
HOOK: select-tuples-statement db-connection ( tuple -- statement )
HOOK: count-tuples-statement db-connection ( tuple -- statement )

: create-table ( class -- )
B
    create-table-statement sql-bind-command ;

: drop-table ( class -- )
    drop-table-statement sql-command ;

: ensure-table ( class -- )
    '[ [ _ create-table ] ignore-table-exists ] ignore-function-exists ;

: ensure-tables ( seq -- ) [ ensure-table ] each ;

: recreate-table ( class -- )
    [ drop-table ] [ create-table ] bi ;

: insert-tuple ( tuple -- )
    insert-tuple-statement sql-bind-typed-command ;

: update-tuple ( tuple -- )
    update-tuple-statement sql-bind-typed-command ;

: delete-tuple ( tuple -- )
    delete-tuple-statement sql-bind-typed-command ;

: select-tuple ( tuple -- tuple' )
    select-tuple-statement sql-bind-typed-query first ;

: select-tuples ( tuple -- seq )
    select-tuples-statement sql-bind-typed-query ;

: count-tuples ( tuple -- n )
    count-tuples-statement sql-bind-typed-query ;
