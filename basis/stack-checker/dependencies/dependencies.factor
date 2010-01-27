! Copyright (C) 2009, 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: assocs classes.algebra classes.algebra.private fry kernel
math namespaces sequences words accessors classes ;
IN: stack-checker.dependencies

! Words that the current quotation depends on
SYMBOL: dependencies

SYMBOLS: inlined-dependency flushed-dependency called-dependency ;

: index>= ( obj1 obj2 seq -- ? )
    [ index ] curry bi@ >= ;

: dependency>= ( how1 how2 -- ? )
    { called-dependency flushed-dependency inlined-dependency }
    index>= ;

: strongest-dependency ( how1 how2 -- how )
    [ called-dependency or ] bi@ [ dependency>= ] most ;

: depends-on ( word how -- )
    over primitive? [ 2drop ] [
        dependencies get dup [
            swap '[ _ strongest-dependency ] change-at
        ] [ 3drop ] if
    ] if ;

! Generic words that the current quotation depends on
SYMBOL: generic-dependencies

: ?class-or ( class class/f -- class' )
    [ class-or ] when* ;

: depends-on-generic ( class generic -- )
    generic-dependencies get dup
    [ [ ?class-or ] change-at ] [ 3drop ] if ;

GENERIC: depends-on-class ( class -- )

M: anonymous-union depends-on-class
    members>> [ depends-on-class ] each ;

M: anonymous-intersection depends-on-class
    members>> [ depends-on-class ] each ;

M: anonymous-complement depends-on-class
    class>> depends-on-class ;

M: class depends-on-class
    inlined-dependency depends-on ;
