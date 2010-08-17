! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db db.connections db.utils kernel
orm.persistent sequences ;
IN: orm.queries

HOOK: create-table-sql db-connection ( tuple-class -- sql )
HOOK: drop-table-sql db-connection ( tuple-class -- sql )

: create-table ( tuple-class -- )
    create-table-sql sql-command ;

: drop-table ( tuple-class -- )
    drop-table-sql sql-command ;

! M: object create-table-sql
    ! >persistent table-name>> "CREATE TABLE " ";" surround ;

M: object drop-table-sql
    >persistent table-name>>
    "DROP TABLE " ";" surround ;
