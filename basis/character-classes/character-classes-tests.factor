! Copyright (C) 2009 Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: character-classes tools.test arrays kernel ;
IN: character-classes.tests

! Class algebra

[ f ] [ 1 2 <and> ] unit-test
[ T{ union f { 1 2 } } ] [ { 1 2 } <union> ] unit-test
[ 3 ] [ 1 2 <and> 3 <or> ] unit-test
[ CHAR: A ] [ CHAR: A LETTER-class <primitive-class> 2array <intersection> ] unit-test
[ CHAR: A ] [ LETTER-class <primitive-class> CHAR: A 2array <intersection> ] unit-test
[ T{ primitive-class { class LETTER-class } } ] [ CHAR: A LETTER-class <primitive-class> 2array <union> ] unit-test
[ T{ primitive-class { class LETTER-class } } ] [ LETTER-class <primitive-class> CHAR: A 2array <union> ] unit-test
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
[ T{ primitive-class { class letter-class } } ] [ letter-class <primitive-class> dup 2array <intersection> ] unit-test
[ T{ primitive-class { class letter-class } } ] [ letter-class <primitive-class> dup 2array <union> ] unit-test
[ T{ union { seq { 1 2 3 } } } ] [ { 1 2 } <union> { 2 3 } <union> 2array <union> ] unit-test
[ T{ union { seq { 2 3 } } } ] [ { 2 3 } <union> 1 <not> 2array <intersection> ] unit-test
[ f ] [ t <not> ] unit-test
[ t ] [ f <not> ] unit-test
[ f ] [ 1 <not> 1 t answer ] unit-test
[ t ] [ { 1 2 } <union> <not> 1 2 3array <union> ] unit-test
[ f ] [ { 1 2 } <intersection> <not> 1 2 3array <intersection> ] unit-test

! Making classes into nested conditionals

[ V{ 1 2 3 4 } ] [ T{ intersection f { 1 T{ not-class f 2 } T{ union f { 3 4 } } 2 } } class>questions ] unit-test
[ { 3 } ] [ { { 3 t } } table>condition ] unit-test
[ { T{ primitive-class } } ] [ { { 1 t } { 2 T{ primitive-class } } } table>questions ] unit-test
[ { { 1 t } { 2 t } } ] [ { { 1 t } { 2 T{ primitive-class } } } T{ primitive-class } t assoc-answer ] unit-test
[ { { 1 t } } ] [ { { 1 t } { 2 T{ primitive-class } } } T{ primitive-class } f assoc-answer ] unit-test
[ T{ condition f T{ primitive-class } { 1 2 } { 1 } } ] [ { { 1 t } { 2 T{ primitive-class } } } table>condition ] unit-test

SYMBOL: foo
SYMBOL: bar

[ T{ condition f T{ primitive-class f bar } T{ condition f T{ primitive-class f foo } { 1 3 2 } { 1 3 } } T{ condition f T{ primitive-class f foo } { 1 2 } { 1 } } } ] [ { { 1 t } { 3 T{ primitive-class f bar } } { 2 T{ primitive-class f foo } } } table>condition ] unit-test

[ t ] [ foo <primitive-class> dup t answer ] unit-test
[ f ] [ foo <primitive-class> dup f answer ] unit-test
[ T{ primitive-class f foo } ] [ foo <primitive-class> bar <primitive-class> t answer ] unit-test
[ T{ primitive-class f foo } ] [ foo <primitive-class> bar <primitive-class> f answer ] unit-test
[ T{ primitive-class f foo } ] [ foo <primitive-class> bar <primitive-class> 2array <intersection> bar <primitive-class> t answer ] unit-test
[ T{ primitive-class f bar } ] [ foo <primitive-class> bar <primitive-class> 2array <intersection> foo <primitive-class> t answer ] unit-test
[ f ] [ foo <primitive-class> bar <primitive-class> 2array <intersection> foo <primitive-class> f answer ] unit-test
[ f ] [ foo <primitive-class> bar <primitive-class> 2array <intersection> bar <primitive-class> f answer ] unit-test
[ t ] [ foo <primitive-class> bar <primitive-class> 2array <union> bar <primitive-class> t answer ] unit-test
[ T{ primitive-class f foo } ] [ foo <primitive-class> bar <primitive-class> 2array <union> bar <primitive-class> f answer ] unit-test
