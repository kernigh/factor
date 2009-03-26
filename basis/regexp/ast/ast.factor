! Copyright (C) 2008, 2009 Doug Coleman, Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel arrays accessors sequences math character-classes ;
IN: regexp.ast

TUPLE: negation term ;
C: <negation> negation

TUPLE: from-to n m ;
C: <from-to> from-to

TUPLE: at-least n ;
C: <at-least> at-least

TUPLE: tagged-epsilon tag ;
C: <tagged-epsilon> tagged-epsilon

CONSTANT: epsilon T{ tagged-epsilon { tag t } }

TUPLE: concatenation first second ;

: <concatenation> ( seq -- concatenation )
    [ epsilon ] [ unclip [ concatenation boa ] reduce ] if-empty ;

TUPLE: alternation first second ;

: <alternation> ( seq -- alternation )
    unclip [ alternation boa ] reduce ;

TUPLE: star term ;
C: <star> star

SINGLETONS: unix-lines dotall multiline case-insensitive reversed-regexp ;

: <maybe> ( term -- term' )
    f <concatenation> 2array <alternation> ;

: <plus> ( term -- term' )
    dup <star> 2array <concatenation> ;

: repetition ( n term -- term' )
    <array> <concatenation> ;

GENERIC: <times> ( term times -- term' )

M: at-least <times>
    n>> swap [ repetition ] [ <star> ] bi 2array <concatenation> ;

: to-times ( term n -- ast )
    dup zero?
    [ 2drop epsilon ]
    [ dupd 1- to-times 2array <concatenation> <maybe> ]
    if ;

M: from-to <times>
    [ n>> swap repetition ]
    [ [ m>> ] [ n>> ] bi - to-times ] 2bi
    2array <concatenation> ;

: char-class ( ranges ? -- term )
    [ <union> ] dip [ <not> ] when ;

TUPLE: lookahead term ;
C: <lookahead> lookahead

TUPLE: lookbehind term ;
C: <lookbehind> lookbehind

SINGLETONS: beginning-of-input ^ end-of-input $ end-of-file
^unix $unix word-break ;
