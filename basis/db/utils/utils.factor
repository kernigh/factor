! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alien.c-types arrays assocs classes
combinators.short-circuit kernel libc locals math math.order
math.parser sequences sequences.private slots slots.private
strings vectors words ;
IN: db.utils

SLOT: slot-name

: sanitize-sql-name ( string -- string' )
    H{ { CHAR: - CHAR: _ } { CHAR: ? CHAR: p } } substitute ;

: malloc-byte-array/length ( byte-array -- alien length )
    [ malloc-byte-array &free ] [ length ] bi ;

: obj>vector ( obj -- vector )
    dup { [ sequence? ] [ integer? not ] } 1&&
    [ >vector ] [ 1vector ] if ;

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

:: 2interleave ( seq1 seq2 between: ( -- ) quot: ( obj1 obj2 -- ) -- )
    { [ seq1 empty? ] [ seq2 empty? ] } 0|| [
        seq1 seq2 [ first-unsafe ] bi@ quot call
        seq1 seq2 [ rest-slice ] bi@
        2dup { [ nip empty? ] [ drop empty? ] } 2|| [
            2drop
        ] [
            between call
            between quot 2interleave
        ] if
    ] unless ; inline recursive

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
    [ new ] 2dip [ call( tuple obj -- tuple ) ] 2each ;

ERROR: no-slot name specs ;

: offset-of-slot ( string tuple -- n )
    class superclasses [ "slots" word-prop ] map concat
    2dup slot-named [ 2nip offset>> ] [ no-slot ] if* ;

: get-slot-named ( name tuple -- value )
    [ nip ] [ offset-of-slot ] 2bi slot ;

: set-slot-named ( value name tuple -- )
    [ nip ] [ offset-of-slot ] 2bi set-slot ;

: change-slot-named ( name tuple quot -- tuple )
    [ [ get-slot-named ] dip call( obj -- obj' ) ]
    [ drop [ set-slot-named ] keep ] 3bi ;

: filter-slots ( tuple specs -- specs' )
    [
        slot-name>> swap get-slot-named
        ! dup double-infinite-interval? [ drop f ] when
    ] with filter ;
