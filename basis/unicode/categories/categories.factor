! Copyright (C) 2008 Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel character-classes sequences unicode.data classes.parser
unicode.script accessors ;
IN: character-classes.unicode

<<

    TUPLE: category-class category ;
    C: <category-class> category-class
    INSTANCE: category-class simple-class

    categories [
        [ create-class-in ]
        [ <category-class> ] bi
        define-category
    ] each

    TUPLE: script-class script ;
    C: <script-class> script-class
    INSTANCE: script-class simple-class

    TUPLE: property-class property ;
    C: <property> property-class
    INSTANCE: property-class simple-class

>>

<PRIVATE

: same? ( obj1 obj2 quot1: ( obj1 -- val1 ) quot2: ( obj2 -- val2 ) -- ? )
    bi* = ; inline

PRIVATE>

M: script-class class-member?
    [ script-of ] [ script>> ] same? ;

M: category-class class-member?
    [ category ] [ category>> ] same? ;

M: property-class class-member?
    property>> property? ;

: <category-range-class> ( letter -- categories )
    categories [ first = ] with filter
    [ <category-class> ] map <union> ;

CATEGORY: whitespace
    "White_Space" <property> ;
CATEGORY: line-separator 
    { Zp Zl CHAR: \r CHAR: \n HEX: c HEX: b HEX: 85 } <union> ;
CATEGORY: blank
    \ whitespace \ line-separator <minus> ;

CATEGORY: lowercase
    \ Ll "Other_Lowercase" <property> <or> ;
CATEGORY: uppercase
    \ Lu "Other_Uppercase" <property> <or> ;
CATEGORY: alphabetic
    { Lu Ll Lt Lm Lo } <union>
    "Other_Alphabetic" <property> <or> ;

CATEGORY: digit \ Nd ;
CATEGORY: hex-digit "Hex_Digit" <property> ;
CATEGORY: alphanumeric alphabetic digit <or> ;

CATEGORY: control \ Cc ;
CATEGORY: graphic
    { whitespace control Cn Cs } <union> <not> ;
CATEGORY: printable
    { graphic blank } <union> \ control <minus> ;
CATEGORY: character \ Cn <not> ;

CATEGORY: math
    \ Sm "Other_Math" <property> <or> ;
CATEGORY: punctuation
    { Pc Pd Ps Pe Pi Pf Po } <union> ;
