! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs combinators db db.binders
db.query-objects db.types db.utils fry kernel math math.parser
mirrors namespaces nested-comments orm.persistent sequences
sets ;
IN: orm.tuples

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

GENERIC# pair>binder* 1 ( binder pair -- binder )

: (pair>binder) ( binder pair -- binder )
    {
        [ first persistent>> class>> >>class ]
        [
            first
            [ persistent>> table-name>> "0" ]
            [ column-name>> ] bi <table-ordinal-column> >>toc
        ]
        [ first type>> >>type ]
    } cleave ;

M: in-binder pair>binder* ( binder-class pair -- binder )
    [ (pair>binder) ] [ second >>value ] bi ;

M: out-binder pair>binder* ( binder-class pair -- binder )
    (pair>binder) ;

: pair>binder ( pair binder-class -- binder ) new swap pair>binder* ;

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
    tuple>primary-key-binders >>where
    query-object>statement sql-bind-typed-command ;

SYMBOL: ordinal

: next-ordinal ( -- string )
    ordinal [ dup 1 + ] change number>string ;

: (select-tuples) ( tuple -- tuple )
    0 ordinal [
        [ <select> ] dip {
            [ out-binder tuple>binders >>out ]
            [ equal-binder tuple>binders >>in ]
            [
                tuple>pairs [ first persistent>> table-name>> ] map prune
                [ next-ordinal <table-ordinal> ] map >>from
            ]
        } cleave
    ] with-variable ;

: select-tuples ( tuple -- tuples )
    ;

: make-reconstructor ( tuple -- quot )
    ;

: reconstruct ( seq quot tuple -- seq' )
    2drop
    ;

: select-tuple ( tuple -- tuple/f )
    [ (select-tuples) 1 >>limit sql-query ]
    [ make-reconstructor ]
    [ ] tri reconstruct ;

: count-tuples ( tuple -- n )
    ;


(*

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

[ 1 f foo boa (select-tuples) query-object>statement ] test-sqlite
*)
