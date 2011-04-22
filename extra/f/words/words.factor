! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel ;
IN: f.words

TUPLE: word < identity-tuple
    vocabulary name stack-effect definition ;

: new-word ( vocabulary name stack-effect definition class -- word )
    new
        swap >>definition
        swap >>stack-effect
        swap >>name
        swap >>vocabulary ; inline

: <word> ( vocabulary name stack-effect definition -- word )
    \ word new-word ; inline

TUPLE: parsing-word < word ;

: <parsing-word> ( vocabulary name definition -- parsing-word )
    [ (( -- obj )) ] dip \ parsing-word new-word ; inline
