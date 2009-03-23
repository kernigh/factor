! Copyright (C) 2005, 2009 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences strings hints ascii.categories math ;
IN: ascii.case

: ch>lower ( ch -- lower ) dup uppercase? [ HEX: 20 + ] when ; inline
: >lower ( str -- lower ) [ ch>lower ] map ;
: ch>upper ( ch -- upper ) dup lowercase? [ HEX: 20 - ] when ; inline
: >upper ( str -- upper ) [ ch>upper ] map ;

HINTS: >lower string ;
HINTS: >upper string ;
