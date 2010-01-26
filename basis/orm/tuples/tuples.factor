! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs combinators db db.binders
db.query-objects db.types db.utils fry kernel mirrors
orm.persistent sequences ;
IN: orm.tuples

(*
TUPLE: foo a b ;

PERSISTENT: foo
{ "a" INTEGER +primary-key+ }
{ "b" VARCHAR } ;
[ [ "drop table foo" sql-command ] test-sqlite ] try
[ "create table foo (a integer primary key, b varchar)" sql-command ] test-sqlite
[ 1 "lol" foo boa insert-tuple ] test-sqlite
[ "select * from foo" sql-query . ] test-sqlite
[ "update foo set a=1, b='omg' where a=1" sql-command ] test-sqlite
[ "select * from foo" sql-query . ] test-sqlite

*)

! : create-table ( class -- ) ; "CREATE TABLE " ;

: drop-table ( class -- )
    >persistent table-name>>
    "DROP TABLE " ";" surround sql-command ;

: ensure-table ( class -- ) drop ;

: ensure-tables ( classes -- ) [ ensure-table ] each ;

: recreate-table ( class -- ) drop ;



: tuple>pairs ( tuple -- seq )
    [ >persistent columns>> ] [ <mirror> >alist ] bi
    [ first2 dup IGNORE = [ 3drop f ] [ nip 2array ] if ] 2map sift ;

: pair>binder ( pair binder-class -- binder )
    new swap {
        [ first persistent>> class>> >>class ]
        [
            first
            [ persistent>> table-name>> "0" ]
            [ column-name>> ] bi <table-ordinal-column> >>toc
        ]
        [ first type>> >>type ]
        [ second >>value ]
    } cleave ;

: tuple>binders ( tuple binder -- seq )
    [ tuple>pairs ] dip '[ _ pair>binder ] map ;

: insert-tuple ( tuple -- )
    [ <insert> ] dip
    in-binder tuple>binders >>in
    query-object>statement sql-bind-typed-command ;


: tuple>primary-key-binders ( tuple -- seq )
    [ find-primary-key ] keep '[
        dup slot-name>> _ get-slot-named
        2array equal-binder pair>binder
    ] map ;


: update-tuple ( tuple -- )
    [ <update> ] dip
    {
        [ equal-binder tuple>binders >>in ]
        [ tuple>primary-key-binders >>where ]
    } cleave
    query-object>statement sql-bind-typed-command ;


: delete-tuples ( tuple -- )
    [ <delete> ] dip
    {
        [ tuple>primary-key-binders >>where ]
    } cleave
    query-object>statement sql-bind-typed-command ;


: select-tuple ( query/tuple -- tuple/f ) ;
: select-tuples ( query/tuple -- tuples ) ;
: count-tuples ( query/tuple -- n ) ;
