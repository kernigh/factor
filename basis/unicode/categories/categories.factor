! Copyright (C) 2008 Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel character-classes sequences unicode.data classes.parser
unicode.script accessors arrays sets unicode.data.private assocs
strings ;
IN: unicode.categories

<<

: <category-class> ( string -- class )
    categories index
    [ 1array [ category# ] <quot-class> ]
    [ "Bad category class" throw ] if* ;

categories [
    [ create-class-in ]
    [ <category-class> ] bi
    define-category
] each

: <script-class> ( script -- class )
    1array [ script-of ] <quot-class> ;

: <category-range-class> ( letter -- categories )
    categories [ first = ] with filter
    [ <category-class> ] map <union> ;

categories [ first ] map prune [
    [ 1string create-class-in ]
    [ <category-range-class> ] bi
    define-category
] each

: <property-class> ( string -- class )
    properties at ;

>>

CATEGORY: whitespace
    "White_Space" <property-class> ;
CATEGORY: line-separator 
    { Zp Zl CHAR: \r CHAR: \n HEX: c HEX: b HEX: 85 } <union> ;
CATEGORY: blank
    \ whitespace \ line-separator <minus> ;

CATEGORY: lowercase
    \ Ll "Other_Lowercase" <property-class> <or> ;
CATEGORY: uppercase
    \ Lu "Other_Uppercase" <property-class> <or> ;
CATEGORY: alphabetic
    \ L "Other_Alphabetic" <property-class> <or> ;

CATEGORY: digit \ Nd ;
CATEGORY: hex-digit
    "Hex_Digit" <property-class> ;
CATEGORY: alphanumeric
    { alphabetic digit } <union> ;

CATEGORY: control \ Cc ;
CATEGORY: graphic
    { whitespace control Cn Cs } <union> <not> ;
CATEGORY: printable
    { graphic blank } <union> \ control <minus> ;
CATEGORY: character
    \ Cn <not> ;

CATEGORY: math
    \ Sm "Other_Math" <property-class> <or> ;
CATEGORY: punctuation \ P ;

CATEGORY: word-char
    { alphabetic Mn Mc Me Nl Pc } <union> ;

CATEGORY: default-ignorable
    "Other_Default_Ignorable_Code_Point" <property-class>
    "Variation_Selector" <property-class> <or>
    \ Cf <or>

    \ whitespace
    HEX: FFF9 HEX: FFFB <range-class> <or>
    HEX: 0600 HEX: 0603 <range-class> <or>
    HEX: 060D <or> HEX: 070F <or> <minus> ;
