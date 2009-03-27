! Copyright (C) 2009 Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: character-classes character-classes.private tools.test
arrays kernel unicode.categories ;
IN: character-classes.tests

! Class algebra

[ f ] [ 1 2 <and> ] unit-test
[ T{ union f { 1 2 } } ] [ { 1 2 } <union> ] unit-test
[ 3 ] [ 1 2 <and> 3 <or> ] unit-test
[ CHAR: A ] [ CHAR: A uppercase <and> ] unit-test
[ CHAR: A ] [ uppercase CHAR: A <and> ] unit-test
[ t ] [ CHAR: A uppercase <or> uppercase = ] unit-test
[ t ] [ uppercase CHAR: A <or> uppercase = ] unit-test
[ t ] [ { t 1 } <union> ] unit-test
[ t ] [ { 1 t } <union> ] unit-test
[ f ] [ { f 1 } <intersection> ] unit-test
[ f ] [ { 1 f } <intersection> ] unit-test
[ 1 ] [ { f 1 } <union> ] unit-test
[ 1 ] [ { 1 f } <union> ] unit-test
[ 1 ] [ { t 1 } <intersection> ] unit-test
[ 1 ] [ { 1 t } <intersection> ] unit-test
[ 1 ] [ 1 <not> <not> ] unit-test
[ 1 ] [ { 1 1 } <intersection> ] unit-test
[ 1 ] [ { 1 1 } <union> ] unit-test
[ t ] [ { t t } <union> ] unit-test
[ t ] [ L dup <and> L = ] unit-test
[ T{ union { seq { 1 2 3 } } } ] [ { 1 2 } <union> { 2 3 } <union> 2array <union> ] unit-test
[ T{ union { seq { 2 3 } } } ] [ { 2 3 } <union> 1 <not> 2array <intersection> ] unit-test
[ f ] [ t <not> ] unit-test
[ t ] [ f <not> ] unit-test
[ f ] [ 1 <not> 1 t answer ] unit-test
[ t ] [ { 1 2 } <union> <not> 1 2 3array <union> ] unit-test
[ f ] [ { 1 2 } <intersection> <not> 1 2 3array <intersection> ] unit-test

! Making classes into nested conditionals

[ { 3 } ] [ { { 3 t } } table>condition ] unit-test
[ { alphabetic } ] [ { { 1 t } { 2 alphabetic } } table>questions ] unit-test
[ { { 1 t } { 2 t } } ] [ { { 1 t } { 2 alphabetic } } alphabetic t assoc-answer ] unit-test
[ { { 1 t } } ] [ { { 1 t } { 2 alphabetic } } alphabetic f assoc-answer ] unit-test
[ T{ condition f alphabetic { 1 2 } { 1 } } ] [ { { 1 t } { 2 alphabetic } } table>condition ] unit-test

SYMBOL: foo
SYMBOL: bar

[ T{ condition f hex-digit T{ condition f M { 1 3 2 } { 1 3 } } T{ condition f M { 1 2 } { 1 } } } ] [ { { 1 t } { 3 hex-digit } { 2 M } } table>condition ] unit-test

[ t ] [ L dup t answer ] unit-test
[ f ] [ L dup f answer ] unit-test
[ L ] [ L hex-digit t answer ] unit-test
[ L ] [ L hex-digit f answer ] unit-test
[ L ] [ L hex-digit <and> hex-digit t answer ] unit-test
[ hex-digit ] [ L hex-digit <and> L t answer ] unit-test
[ f ] [ L hex-digit <and> L f answer ] unit-test
[ f ] [ L hex-digit <and> hex-digit f answer ] unit-test
[ t ] [ L hex-digit <or> hex-digit t answer ] unit-test
[ L ] [ L hex-digit <or> hex-digit f answer ] unit-test
