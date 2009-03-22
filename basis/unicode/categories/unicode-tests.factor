! Copyright (C) 2008 Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: tools.test kernel character-classes.unicode words sequences ;
IN: character-classes.unicode.tests

[ { f f t t f t t f t } ] [ CHAR: A { 
    blank? lowercased? uppercased? alphabetic? digit? 
    printable? alphanumeric? control? character? 
} [ execute ] with map ] unit-test
