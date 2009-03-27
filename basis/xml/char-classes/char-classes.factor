! Copyright (C) 2005, 2009 Daniel Ehrenberg
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences math math.order character-classes
combinators hints combinators.short-circuit interval-sets multiline
math.parser splitting unicode.categories arrays values ;
IN: xml.char-classes

<PRIVATE

CATEGORY: 1.0name-start
    L HEX: 2BB HEX: 2C1 <range-class> <or>
    "\u000559\u0006E5\u0006E6_:" <union> <or> ;

CATEGORY: 1.0name-char
    { L M N } <union>
    "_-.\u000387:" <union> <or> ;

<<

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

>>

CATEGORY: 1.1name-start
    <" ":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] | [#xD8-#xF6] | [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFFF] ">
    parse-interval-set ;

CATEGORY: 1.1name-char
    <" "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040] ">
    parse-interval-set \ 1.1name-start <or> ;

CATEGORY: 1.0text
    <" #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF] ">
    parse-interval-set ;

CATEGORY: 1.1text
    <" [#x1-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF] ">
    parse-interval-set ;

PRIVATE>

: name-start? ( 1.0? char -- ? )
    swap [ 1.0name-start? ] [ 1.1name-start? ] if ;

: name-char? ( 1.0? char -- ? )
    swap [ 1.0name-char? ] [ 1.1name-char? ] if ;

: text? ( 1.0? char -- ? )
    swap [ 1.0text? ] [ 1.1text? ] if ;
