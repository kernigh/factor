! Copyright (C) 2007, 2009 Slava Pestov, Daniel Ehrenberg
! See http://factorcode.org/license.txt for BSD license.
USING: ascii.categories tools.test sequences math kernel ;

[ t ] [ CHAR: a lowercase? ] unit-test
[ f ] [ CHAR: A lowercase? ] unit-test
[ f ] [ CHAR: \s lowercase? ] unit-test
[ f ] [ CHAR: a uppercase? ] unit-test
[ t ] [ CHAR: A uppercase? ] unit-test
[ f ] [ CHAR: \s uppercase? ] unit-test
[ t ] [ CHAR: a alphabetic? ] unit-test
[ t ] [ CHAR: A alphabetic? ] unit-test
[ f ] [ CHAR: \s alphabetic? ] unit-test
[ t ] [ CHAR: 0 digit? ] unit-test
[ f ] [ CHAR: x digit? ] unit-test
[ t ] [ 23 ascii-char? ] unit-test
[ f ] [ 223 ascii-char? ] unit-test
[ t ] [ CHAR: \s blank? ] unit-test
[ f ] [ CHAR: \n blank? ] unit-test
[ f ] [ CHAR: a blank? ] unit-test
[ f ] [ CHAR: \s line-separator? ] unit-test
[ t ] [ CHAR: \n line-separator? ] unit-test
[ f ] [ CHAR: a line-separator? ] unit-test
[ t ] [ CHAR: \s whitespace? ] unit-test
[ t ] [ CHAR: \n whitespace? ] unit-test
[ f ] [ CHAR: a whitespace? ] unit-test
[ t ] [ CHAR: ! punctuation? ] unit-test
[ f ] [ CHAR: a punctuation? ] unit-test
[ t ] [ CHAR: 9 alphanumeric? ] unit-test
[ t ] [ CHAR: a alphanumeric? ] unit-test
[ f ] [ CHAR: \n alphanumeric? ] unit-test
[ t ] [ 10 control? ] unit-test
[ f ] [ 100 control? ] unit-test
[ t ] [ CHAR: a printable? ] unit-test
[ f ] [ 10 printable? ] unit-test

[ 4 ] [
    0 "There are Four Upper Case characters"
    [ uppercase? [ 1+ ] when ] each
] unit-test

[ t f ] [ CHAR: \s ascii-char? 400 ascii-char? ] unit-test
