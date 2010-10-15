! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs combinators combinators.smart fry
kernel locals macros make math orm.persistent prettyprint
sequences sequences.private splitting.monotonic nested-comments ;
IN: reconstructors

(*
ERROR: no-setter ;

: out-binder>setter ( toc -- word )
    [ class>> >persistent columns>> ]
    [ toc>> column-name>> ] bi '[ column-name>> _ = ] find
    nip [ no-setter ] unless* setter>> ;

MACRO: query-object>reconstructor ( tuple -- quot )
    out>> [ [ class>> ] bi@ = ] monotonic-split
    [ [ first class>> ] [ [ out-binder>setter ] map ] bi ] { } map>assoc
    [
        [
            first2
            [ , \ new , ]
            [ reverse [ \ swap , , (( obj obj -- obj )) , \ call-effect , ] each ] bi*
        ] each
    ] [ ] make '[ [ _ input<sequence ] ] ;


MACRO:: row>tuples ( spec -- quot )
    0 :> i!
    spec [
        unclip :> ( setters tuple-class )
        [
            tuple-class , \ new ,
            setters [ i , \ pick , \ nth-unsafe , , i 1 + i! ] each
            \ , ,
        ] [ ] make
    ] map [ ] concat-as '[ _ { } make nip ] ;

MACRO: rows>tuples ( spec -- quot )
    '[ [ _ row>tuples ] map ] ;


(*
TUPLE: bag id beans ;
TUPLE: bean id color ;

{ { 0 0 "blue" } { 0 1 "red" } }
{ { bag >>id } { bean >>id >>color } } rows>tuples .

{
    { T{ bag { id 0 } } T{ bean { id 0 } { color "blue" } } }
    { T{ bag { id 0 } } T{ bean { id 1 } { color "red" } } }
}
*)
*)
