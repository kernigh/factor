! Copyright (C) 2008 Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: unicode.data tools.test ;
IN: unicode.data.tests

[ "Nd" ] [ CHAR: 3 category ] unit-test
[ "Lo" ] [ HEX: 3400 category ] unit-test
[ "Lo" ] [ HEX: 3450 category ] unit-test
[ "Lo" ] [ HEX: 4DB5 category ] unit-test
[ "Cs" ] [ HEX: DD00 category ] unit-test
