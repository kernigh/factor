! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db db.connections db.types db.utils kernel
make orm.persistent sequences ;
IN: orm.queries

HOOK: create-table-sql db-connection ( tuple-class -- object )
HOOK: ensure-table-sql db-connection ( tuple-class -- object )
HOOK: drop-table-sql db-connection ( tuple-class -- object )

HOOK: insert-tuple-sql db-connection ( tuple -- object )
HOOK: insert-db-assigned-key-sql db-connection ( tuple -- object )
HOOK: insert-user-assigned-key-sql db-connection ( tuple -- object )
HOOK: update-tuple-sql db-connection ( tuple -- object )
HOOK: delete-tuple-sql db-connection ( tuple -- object )
HOOK: select-tuple-sql db-connection ( tuple -- object )

M: object create-table-sql
    >persistent dup table-name>>
    [
        [
            [ columns>> ] dip
            "CREATE TABLE " % %
            "(" % [ ", " % ] [
                [ column-name>> % " " % ]
                [ type>> sql-create-type>string % ]
                [ modifiers>> " " join % ] tri
            ] interleave
        ] [
            drop
            find-primary-key [
                ", " %
                "PRIMARY KEY(" %
                [ "," % ] [ column-name>> % ] interleave
                ")" %
            ] unless-empty
            ");" %
        ] 2bi
    ] "" make ;

M: object drop-table-sql
    >persistent table-name>>
    "DROP TABLE " ";" surround ;
