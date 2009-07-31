! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors classes.tuple combinators db.binders
db.orm.fql db.orm.persistent kernel locals sequences ;
IN: db.orm

: columns>out-tuple ( columns -- out-tuple )
B
    [ first persistent>> [ class>> ] [ table-name>> ] bi ]
    [
        [
            [ column-name>> ]
            [ type>> ]
            [ setter>> ] tri <out-tuple-slot-binder>
        ] map
    ] bi <out-tuple-binder> ;

: columns>out-tuples ( columns column -- seq )
    [ [ type>> lookup-persistent columns>> columns>out-tuple ] map ]
    [ columns>out-tuple prefix ] bi* ; inline

: select-columns ( tuple -- seq )
B
    lookup-persistent
    columns>> [ type>> tuple-class? ] partition columns>out-tuples ;

: select-tuples-plain ( tuple -- fql )
B
    [ select new ] dip {
        [ select-columns >>columns ]
        [ lookup-persistent table-name>> >>from ]
    } cleave ;

/*
: select-tuples-relations ( tuple -- fql )
    [ select new ] dip {
    } 2cleave ;
*/

:: select-tuples ( tuple -- seq )
    tuple lookup-persistent :> persistent
    persistent relation-columns :> relations
    relations [
        tuple select-tuples-plain
    ] [
        drop f
        ! select-tuples-relations
    ] if-empty ;
