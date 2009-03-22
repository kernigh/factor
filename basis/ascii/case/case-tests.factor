! Copyright (C) 2007 Slava Pestov
! See http://factorcode.org/license.txt for BSD license.
USING: ascii.case tools.test ;
IN: ascii.case.tests

[ "HELLO HOW ARE YOU?" ] [ "hellO hOw arE YOU?" >upper ] unit-test
[ "i'm good thx bai" ] [ "I'm Good THX bai" >lower ] unit-test
