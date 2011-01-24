! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs combinators combinators.smart fry
kernel locals macros make math orm.persistent prettyprint
sequences sequences.private splitting.monotonic nested-comments
grouping ;
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
*)


(*
TUPLE: bag id beans ;
TUPLE: bean id color ;

{ { 0 0 "blue" } { 0 1 "red" } }
{ { bag >>id } { bean >>id >>color } } rows>tuples .

{
    { T{ bag { id 0 } } T{ bean { id 0 } { color "blue" } } }
    { T{ bag { id 0 } } T{ bean { id 1 } { color "red" } } }
}


TUPLE: foo-1 a b ;

{ 1 "Asdf" }
{ { foo-1 >>a >>b } }

T{ foo-1 { a 1 } { b "Asdf" } }

*)

: split-by-length ( seq lengths -- seq' )
    0 [ + ] accumulate swap suffix 2 <clumps>
    [ first2 rot subseq ] with map ;

: fill-new-tuple ( seq spec -- tuple )
    unclip new [
        '[ [ _ ] 2dip execute( a obj -- obj ) drop ] 2each
    ] keep ;

: row>tuples ( seq spec -- seq' )
    [ [ length 1 - ] map split-by-length ] keep
    [ fill-new-tuple ] 2map ;

: rows>tuples ( seq spec -- seq' )
    '[ _ row>tuples ] map concat ;
