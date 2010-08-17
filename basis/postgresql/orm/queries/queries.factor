! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.types kernel make nested-comments
orm.persistent orm.queries postgresql.db.connections.private
sequences ;
IN: postgresql.orm.queries

(*
: postgresql-create-table ( tuple-class -- string )
    >persistent dup table-name>>
    [
        [
            [ columns>> ] dip
            "CREATE TABLE " % %
            "(" % [ ", " % ] [
                [ column-name>> % " " % ]
                [ type>> sql-create-type>string % ]
                [ drop ] tri
                ! [ modifiers % ] bi
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

M: postgresql-db-connection create-table-sql ( class -- seq )
    postgresql-create-table ;

*)
