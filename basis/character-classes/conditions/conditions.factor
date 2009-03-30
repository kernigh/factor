! Copyright (C) 2009 Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences assocs character-classes fry accessors
arrays ;
QUALIFIED: sets
IN: character-classes.conditions

TUPLE: condition question yes no ;
C: <condition> condition

: assoc-answer ( table question answer -- new-table )
    '[ _ _ substitute ] assoc-map
    [ nip ] assoc-filter ;

: assoc-answers ( table questions answer -- new-table )
    '[ _ assoc-answer ] each ;

<PRIVATE

DEFER: make-condition

: (make-condition) ( table questions question -- condition )
    [ 2nip ]
    [ swap [ t assoc-answer ] dip make-condition ]
    [ swap [ f assoc-answer ] dip make-condition ] 3tri
    2dup = [ 2nip ] [ <condition> ] if ;

: make-condition ( table questions -- condition )
    [ keys ] [ unclip (make-condition) ] if-empty ;

GENERIC: class>questions ( class -- questions )
M: union class>questions seq>> [ class>questions ] sets:gather ;
M: not-class class>questions class>> class>questions ;
M: object class>questions 1array ;

: table>questions ( table -- questions )
    values [ class>questions ] sets:gather >array { t f } sets:diff ;

PRIVATE>

: table>condition ( table -- condition )
    ! input table is state => class
    >alist dup table>questions make-condition ;

: condition-map ( condition quot: ( obj -- obj' ) -- new-condition ) 
    over condition? [
        [ [ question>> ] [ yes>> ] [ no>> ] tri ] dip
        '[ _ condition-map ] bi@ <condition>
    ] [ call ] if ; inline recursive

: condition-states ( condition -- states )
    dup condition? [
        [ yes>> ] [ no>> ] bi 2array
        [ condition-states ] sets:gather
    ] [ 1array ] if ;

: condition-at ( condition assoc -- new-condition )
    '[ _ at ] condition-map ;
