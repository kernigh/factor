! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators db.statements db.types kernel make
nested-comments orm.persistent orm.queries
postgresql.db.connections.private sequences ;
IN: postgresql.orm.queries

M: postgresql-db-connection <insert-db-assigned-key-sql>
    [ <statement> ] dip >persistent {
        [ table-name>> "select add_" prepend add-sql "(" add-sql ]
        [
            [ find-primary-key first add-in ]
            [
                columns>>
                remove-primary-key
                [ [ ", " % ] [ column-name>> % ] interleave ] "" make add-sql
                ");" add-sql
            ] bi
        ]
    } cleave ;

: bind-name% ( column -- )
    ;

M: postgresql-db-connection <insert-user-assigned-key-sql>
    [ <statement> ] dip >persistent {
        [ table-name>> "INSERT INTO " prepend add-sql "(" add-sql ]
        [
            [
                columns>>
                [
                    [
                        [ ", " % ] [ column-name>> % ] interleave 
                        ")" %
                    ] "" make add-sql
                ] [
                    " values(" %
                    [ ", " % ] [
                        dup type>> +random-key+ = [
                            [
                                bind-name%
                                slot-name>>
                                f
                                random-id-generator
                            ] [ type>> ] bi <generator-bind> 1,
                        ] [
                            bind%
                        ] if
                    ] interleave
                    ");" 0%
                ] bi
            ]
    } cleave ;


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
