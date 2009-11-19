! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs classes classes.tuple
combinators db.query-objects db.types fry kernel make multiline
namespaces orm.persistent sequences shuffle db.utils ;
IN: orm

SYMBOL: table-counter

/*
: (tuple>relations) ( n tuple -- )
    [ ] [ >persistent columns>> ] bi [
        dup relation-category [
            2dup getter>> call( obj -- obj' ) dup IGNORE = [
                4drop
            ] [
                [ dup relation-class new ] unless*
                over relation-category [
                    swap [
                        [
B
                            [ class swap 2array ]
                            [ relation-class table-counter [ inc ] [ get ] bi 2array ] bi*
                        ] dip 3array ,
                    ] dip
                    [ table-counter get ] dip (tuple>relations)
                ] [
                    4drop
                ] if*
            ] if
        ] [
            3drop
        ] if
    ] with with each ;

: tuple>relations ( tuple -- seq )
    0 table-counter [
        [ 0 swap (tuple>relations) ] { } make
    ] with-variable ;
*/

: find-containing-classes ( class -- seq )
    [ inherited-persistent-table get-global ] dip
    '[
        nip columns>> [ type>> _ eq? ] any?
    ] assoc-filter ;

: column-contains-many? ( column -- ? )
    type>> dup array? [
        ?first2 [ tuple-class? ] [ sequence = ] bi* and
    ] [
        drop f
    ] if ;

: find-contains-many ( class -- seq )
    >persistent columns>> [ column-contains-many? ] filter ;

: find-one:one ( class -- seq )
    ;

: class>relations ( class -- relation )
    >persistent columns>> [ tuple-class? ] filter ;


: relation>join ( triple -- seq )
    
    ;

: relations>joins ( seq -- seq' )
    [ relation>join ] map concat ;

/*
: tuple>select-statement ( tuple -- select )
    [ select new ] dip
    {
        ! [ tuple>relations relations>joins 1array >>join ]
        ! [ ]
    } cleave ;
*/
