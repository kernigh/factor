! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs combinators db db.binders
db.connections db.statements db.types db.utils fry kernel
locals make orm.persistent sequences ;
IN: orm.queries

HOOK: create-table-sql db-connection ( tuple-class -- object )
HOOK: ensure-table-sql db-connection ( tuple-class -- object )
HOOK: drop-table-sql db-connection ( tuple-class -- object )

HOOK: insert-db-assigned-key-sql db-connection ( tuple -- object )
HOOK: insert-user-assigned-key-sql db-connection ( tuple -- object )
HOOK: insert-tuple-set-key db-connection ( tuple statement -- )
HOOK: update-tuple-sql db-connection ( tuple -- object )
HOOK: delete-tuple-sql db-connection ( tuple -- object )
HOOK: select-tuple-sql db-connection ( tuple -- object )

HOOK: n>bind-sequence db-connection ( n -- sequence ) 
HOOK: continue-bind-sequence db-connection ( previous n -- sequence )

: n>bind-string ( n -- string ) n>bind-sequence "," join ;
M: object n>bind-sequence "?" <repetition> ;
M: object continue-bind-sequence nip "?" <repetition> ;

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

: columns>in-binders ( columns tuple -- sequence )
    '[
        [ _ swap getter>> (( obj -- slot-value )) call-effect ]
        [ type>> ] bi
        <in-binder-low>
    ] { } map-as ;

! : where-primary-key ( statement persistent tuple -- statement )
    ! [ find-primary-key ] dip
    ! [ columns>in-binders add-in ]
    ! [ drop [ column-name>> ] map " WHERE " prepend add-sql ] 2bi ;

M:: object update-tuple-sql ( tuple -- statement )
    <statement> :> statement
    tuple >persistent :> persistent

    statement
        persistent table-name>> "UPDATE " " SET " surround add-sql
        persistent columns>> remove-primary-key :> columns:no-primary-key
        persistent find-primary-key :> columns:primary-key
        columns:no-primary-key length :> #columns
        columns:no-primary-key length :> #primary-key

        columns:no-primary-key [ column-name>> ] map
        #columns n>bind-sequence zip [ " = " glue ] { } assoc>map ", " join add-sql

        columns:no-primary-key tuple columns>in-binders add-in
        " WHERE " add-sql
        columns:primary-key tuple columns>in-binders add-in

        columns:primary-key [ column-name>> ] map
        #columns #primary-key continue-bind-sequence zip [ " = " glue ] { } assoc>map ", " join add-sql ;
