! Copyright (C) 2007 Slava Pestov
! See http://factorcode.org/license.txt for BSD license.
USING: ascii.categories tools.test sequences math kernel ;

[ t ] [ CHAR: a lowercase? ] unit-test
[ f ] [ CHAR: A lowercase? ] unit-test
[ f ] [ CHAR: a uppercase? ] unit-test
[ t ] [ CHAR: A uppercase? ] unit-test
[ t ] [ CHAR: 0 digit? ] unit-test
[ f ] [ CHAR: x digit? ] unit-test

[ 4 ] [
    0 "There are Four Upper Case characters"
    [ uppercase? [ 1+ ] when ] each
] unit-test

[ t f ] [ CHAR: \s ascii? 400 ascii? ] unit-test
