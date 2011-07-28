! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs f.words kernel nested-comments ;
IN: f.namespaces

TUPLE: namespace < identity-tuple name words ;

ERROR: symbol-redefined string namespace ;

: ensure-unique ( string namespace -- string namespace )
    2dup words>> key? [ symbol-redefined ] when ;

: <namespace> ( name -- namespace )
    namespace new
        swap >>name
        H{ } clone >>words ; inline
        
: add-word-to-namespace ( word namespace -- )
    2dup [ name>> ] dip ensure-unique 2drop
    [ [ ] [ name>> ] bi ] [ words>> ] bi* set-at ;

: add-parsing-word ( namespace name quot -- )
    <parsing-word> dup namespace>> add-word-to-namespace ;

: init-symbol ( object string namespace -- )
    ensure-unique
    words>> set-at ;

