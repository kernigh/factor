! Copyright (C) 2009 Daniel Ehrenberg
! See http://factorcode.org/license.txt for BSD license.
USING: sequences strings kernel io.encodings.string
math.order math io io.encodings.utf8 io.streams.string
combinators.short-circuit math.parser arrays
ascii.categories ascii.case character-classes ;
IN: quoted-printable

! This implements RFC 2045 section 6.7

<PRIVATE

: assure-small ( ch -- ch )
    dup 256 <
    [ "Cannot quote a character greater than 255" throw ] unless ;

CATEGORY: qprintable
    printable CHAR: = <minus> CHAR: \t <or> ;

: char>quoted ( ch -- str )
    dup qprintable? [ 1string ] [
        assure-small >hex >upper
        2 CHAR: 0 pad-head 
        CHAR: = prefix
    ] if ;

: take-some ( seqs -- seqs seq )
    0 over [ length + dup 76 >= ] find drop nip
    [ 1- cut-slice swap ] [ f swap ] if* concat ;

: divide-lines ( strings -- strings )
    [ dup ] [ take-some ] produce nip ;

PRIVATE>

: >quoted ( byte-array -- string )
    [ char>quoted ] { } map-as concat "" like ;

: >quoted-lines ( byte-array -- string )
    [ char>quoted ] { } map-as
    divide-lines "=\r\n" join ;

<PRIVATE

: read-char ( byte -- ch )
    dup CHAR: = = [
       drop read1 dup CHAR: \n =
       [ drop read1 read-char ]
       [ read1 2array hex> ] if
    ] when ;

: read-quoted ( -- bytes )
    [ read1 dup ] [ read-char ] B{ } produce-as nip ;

PRIVATE>

: quoted> ( string -- byte-array )
    ! Input should already be normalized to make \r\n into \n
    [ read-quoted ] with-string-reader ;
