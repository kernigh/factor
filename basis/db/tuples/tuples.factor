! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: multiline ;
IN: db.tuples

/*
: return-tuple ( result-set -- seq )
    -1 sql-column-counter [
        dup out>> [
            [ nip class>> ]
            [ binders>> sql-row-typed-count ]
            [ nip binders>> [ setter>> ] map ] 2tri new-filled-tuple
        ] with map
    ] with-variable ;

: return-sequence ( result-set -- seq ) sql-row-typed ;

: return-tuples? ( result-set -- ? ) [ out-tuple-binder? ] all? ;

: statement>typed-result-sequence ( statement -- sequence )
    normalize-statement
    statement>result-set
    [
        dup out>> return-tuples? [
            [ return-tuple ] result-set-map
            dup {
                [ length 0 > ]
                [ first length 1 = ]
            } 1&& [ concat ] when
        ] [
            [ return-sequence ] result-set-map
        ] if
    ] with-disposal ;
*/
