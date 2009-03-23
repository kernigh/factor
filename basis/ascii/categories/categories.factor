! Copyright (C) 2009 Daniel Ehrenberg
! See http://factorcode.org/license.txt for BSD license.
USING: character-classes ;
IN: ascii.categories

CATEGORY: ascii
    0 127 <range-class> ;

CATEGORY: blank
    " \t" <union> ;

CATEGORY: line-separator
    "\n\r" <union> ;

CATEGORY: whitespace
    { blank line-separator } <union> ;

CATEGORY: lowercase
    CHAR: a CHAR: z <range-class> ;

CATEGORY: uppercase
    CHAR: A CHAR: Z <range-class> ;

CATEGORY: alphabetic
    { lowercase uppercase } <union> ;

CATEGORY: digit
    CHAR: 0 CHAR: 9 <range-class> ;

CATEGORY: printable
    CHAR: \s CHAR: ~ <range-class> ;

CATEGORY: control
    0 HEX: 1F <range-class> HEX: 7F <or> ;

CATEGORY: quotable
    \ printable "\"\\" <union> <minus> ;

CATEGORY: alphanumeric
    \ alphabetic \ digit <or> ;

CATEGORY: punctuation
    "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~" <union> ;
