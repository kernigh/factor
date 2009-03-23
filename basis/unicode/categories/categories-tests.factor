! Copyright (C) 2008 Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: tools.test kernel unicode.categories character-classes sequences ;
IN: unicode.categories.tests

[ { f f f f t t f t t f t } ] [ CHAR: A { 
    whitespace? blank? line-separator? lowercase? uppercase?
    alphabetic? digit? printable? alphanumeric? control?
    character? 
} [ execute( char -- ? ) ] with map ] unit-test

[ { f f f f t t f t t f t } ] [ CHAR: A { 
    whitespace blank line-separator lowercase uppercase
    alphabetic digit printable alphanumeric control
    character 
} [ class-member? ] with map ] unit-test

[ t ] [ CHAR: \s whitespace? ] unit-test
[ t ] [ CHAR: \s blank? ] unit-test
[ f ] [ CHAR: \s line-separator? ] unit-test

[ t ] [ CHAR: \n whitespace? ] unit-test
[ f ] [ CHAR: \n blank? ] unit-test
[ t ] [ CHAR: \n line-separator? ] unit-test

[ t ] [ CHAR: a alphabetic? ] unit-test
[ f ] [ CHAR: a uppercase? ] unit-test
[ t ] [ CHAR: a lowercase? ] unit-test

[ t ] [ CHAR: a hex-digit? ] unit-test
[ t ] [ CHAR: 9 hex-digit? ] unit-test
[ f ] [ CHAR: g hex-digit? ] unit-test

[ f ] [ CHAR: a digit? ] unit-test
[ t ] [ CHAR: 9 digit? ] unit-test
[ f ] [ CHAR: g digit? ] unit-test
