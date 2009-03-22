! Copyright (C) 2005, 2009 Daniel Ehrenberg
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences unicode.categories.syntax math math.order
combinators hints combinators.short-circuit interval-maps multiline
math.parser splitting unicode.categories arrays values ;
IN: xml.char-classes

CATEGORY: 1.0name-start
    Ll Lu Lo Lt Nl | {
        [ HEX: 2BB HEX: 2C1 between? ]
        [ "\u000559\u0006E5\u0006E6_:" member? ]
    } 1|| ;

CATEGORY: 1.0name-char
    Ll Lu Lo Lt Nl Mc Me Mn Lm Nd |
    "_-.\u000387:" member? ;

: read-num ( string -- character )
    dup length 1 = [ first ] [ 2 tail hex> ] if ;

: parse-interval-set ( string -- interval-set )
    "|" split [
        [ blank? ] trim
        dup first {
            { CHAR: " [ second ] }
            { CHAR: # [ read-num ] }
            { CHAR: [ [ rest but-last "-" split1 [ read-num ] bi@ 2array ] }
        } case
    ] map <interval-set> ;

VALUE: 1.1name-start-map
<" ":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] | [#xD8-#xF6] | [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFFF] ">
parse-interval-set to: 1.1name-start-map

: 1.1name-start? ( ch -- ? )
    1.1name-start-map interval-key? ;

VALUE: 1.1name-char-map
<" "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040] ">
parse-interval-set to: 1.1name-char-map

: 1.1name-char? ( ch -- ? )
    { [ 1.1name-start? ] [ 1.1name-char-map interval-key? ] } 1|| ;

: name-start? ( 1.0? char -- ? )
    swap [ 1.0name-start? ] [ 1.1name-start? ] if ;

: name-char? ( 1.0? char -- ? )
    swap [ 1.0name-char? ] [ 1.1name-char? ] if ;

VALUE: 1.0text-map
<" #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF] ">
parse-interval-set to: 1.0text-map

VALUE: 1.1text-map
<" [#x1-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF] ">
parse-interval-set to: 1.1text-map

: text? ( 1.0? char -- ? )
    swap 1.0text-map 1.1text-map ? interval-key? ;

HINTS: text? { object fixnum } ;
