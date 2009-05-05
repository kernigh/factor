! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays kernel math math.parser strings sequences
words math.order vectors combinators.short-circuit ;
IN: db2.utils

: ?when ( object quot -- object' ) dupd when ; inline

: ?1array ( obj -- array )
    dup { [ array? ] [ vector? ] } 1|| [ 1array ] unless ; inline

: ??1array ( obj -- array/f ) [ ?1array ] ?when ; inline

: ?first ( sequence -- object/f ) 0 swap ?nth ;
: ?second ( sequence -- object/f ) 1 swap ?nth ;
: ?third ( sequence -- object/f ) 2 swap ?nth ;

: ?first2 ( sequence -- object1/f object2/f )
    [ ?first ] [ ?second ] bi ;

: ?first3 ( sequence -- object1/f object2/f object3/f )
    [ ?first ] [ ?second ] [ ?third ] tri ;

: assoc-with ( object sequence quot -- obj curry )
    swapd [ [ -rot ] dip  call ] 2curry ; inline

: ?number>string ( n/string -- string )
    dup number? [ number>string ] when ;

ERROR: no-accessor name ;

: lookup-accessor ( string -- accessor )
    dup "accessors" lookup [ nip ] [ no-accessor ] if* ;

: lookup-getter ( string -- accessor )
    ">>" append lookup-accessor ;

: lookup-setter ( string -- accessor )
    ">>" prepend lookup-accessor ;

ERROR: string-expected object ;

: ensure-string ( object -- string )
    dup string? [ string-expected ] unless ;

ERROR: length-expected-range seq from to ;
: ensure-length-range ( seq from to -- seq )
    3dup [ length ] 2dip between? [
        2drop
    ] [
        length-expected-range
    ] if ;

ERROR: length-expected seq length ;
: ensure-length ( seq length -- seq )
    2dup [ length ] dip = [
        drop
    ] [
        length-expected
    ] if ;

: new-filled-tuple ( class values setters -- tuple )
    [ new ] 2dip [ execute( tuple obj -- tuple ) ] 2each ;
