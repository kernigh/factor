! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs checksums checksums.crc32 combinators
f.lexer f.vocabularies fry io kernel math namespaces sequences
splitting strings vectors vocabs.refresh.monitor vocabs.loader
vocabs io.files f.manifests ;
QUALIFIED: f.words
QUALIFIED: sets
IN: f.parser2


: with-output-variable ( obj symbol quot -- obj )
    over [ get ] curry compose with-variable ; inline

: (peek-token) ( -- token/string/f )
    read1 [
        dup comment? [ drop (peek-token) ] when
    ] [
        f
    ] if* ;

: peek-token ( -- token/string/f )
    [ (peek-token) text ] with-input-rewind ;

GENERIC: last-token ( obj -- token/f )

M: object last-token ;
M: sequence last-token [ f ] [ last last-token ] if-empty ;
M: lexed last-token tokens>> last-token ;
M: integer last-token ;

GENERIC: resolve ( object -- object' )

: parse-stack ( -- obj )
    manifest get parsed>> ;

: current-parse-vector ( -- obj )
    parse-stack dup empty? [
        dup last vector? [ last ] when
    ] unless ;

: push-parsed ( obj -- )
    current-parse-vector push ;

: push-all-parsed ( obj -- )
    current-parse-vector push-all ;

: new-parse ( -- )
    V{ } clone parse-stack push ;

: last-parsed ( -- obj )
    parse-stack last ;

: pop-parsed ( -- obj )
    parse-stack pop ;

: pop-all-parsed ( -- obj )
    parse-stack
    V{ } clone manifest get parsed<< ;

: push-comment ( comment -- )
    push-parsed ;

: do-parsing-word ( word -- )
    definition>> call( -- obj ) push-parsed ;

: maybe-call-parsing-word ( string -- )
    dup text manifest get search-syntax [
        dup f.words:parsing-word? [
            [
                [ manifest get parsing-word-stack>> push ]
                [ 1vector parse-stack push ] bi
            ]
            [ do-parsing-word ] bi*
            manifest get parsing-word-stack>> pop drop
        ] [
            drop push-parsed
        ] if
    ] [
        push-parsed
    ] if* ;

: just-parsed? ( -- ? )
    manifest get just-parsed>> ;

: just-parsed-on ( -- ) t manifest get just-parsed<< ;

: just-parsed-off ( -- ) f manifest get just-parsed<< ;

: read-token ( -- token/f )
    just-parsed-off
    read1 [
        dup comment? [
            push-comment read-token
        ] when
    ] [
        f
    ] if* ;

: parse ( -- obj/f )
    read-token [
        maybe-call-parsing-word
        last-parsed
    ] [
        f
    ] if* ;

TUPLE: parsing-error-tuple words word-names line# column# error ;

: parsing-error ( error -- * )
    parsing-error-tuple new
        swap >>error
        manifest get parsing-word-stack>>
            {
                [ >>words ]
                [ [ text ] map >>word-names ]
                [ first line#>> >>line# ]
                [ first column#>> >>column# ]
            } cleave
        throw ; inline

ERROR: token-expected expected ;

: parse-until ( string -- obj )
    new-parse
    dup '[
        parse [
            just-parsed? [
                just-parsed-off
                drop t
            ] [
                last-token text _ = [
                    [ just-parsed-on ] when
                ] keep not
            ] if
        ] [
            ! _ token-expected
            _ \ token-expected boa parsing-error
        ] if*
    ] loop
    pop-parsed [ push-all-parsed ] keep but-last ;

ERROR: premature-eof ;

: token ( -- string/f )
    read-token [
        [ push-parsed ] [ text ] bi
    ] [
        premature-eof
    ] if* ;

: tokens-until ( string -- sequence )
    new-parse
    dup '[
        read-token [ dup push-parsed text _ = not ] [ _ token-expected ] if*
    ] loop
    pop-parsed [ push-all-parsed ] keep
    but-last [ text ] map ;

: chunk ( -- token/f )
    lex-chunk [ premature-eof ] unless*
    dup push-parsed text ;

: chunks-until ( string -- seq )
    new-parse
    dup '[
        chunk [ _ = not ] [ _ token-expected ] if*
    ] loop
    pop-parsed [ push-all-parsed ] keep
    but-last [ text ] map ;
    
: add-parse-tree ( -- )
    pop-all-parsed manifest get objects>> push-all ;

: stream-empty? ( stream -- ? ) stream-peek1 not >boolean ;

: with-manifest ( quot -- manifest )
    [ manifest ] dip '[ @ ] with-output-variable ; inline

: parse-factor-stream ( manifest -- tree )
    [
        [ input-stream get stream-empty? not ]
        [ parse [ add-parse-tree ] when ] while
        ! manifest get [ [ resolve ] map ] change-objects drop
    ] with-manifest ;

: should-parse? ( path -- ? )
    [ crc32 checksum-file ]
    [ path>vocab get-manifest factor-checksum>> ] bi = not ;

: parse-factor-file ( path -- tree )
    dup dup crc32 checksum-file <manifest>
    '[ _ parse-factor-stream ] with-file-lexer ;

: parse-factor ( string -- tree )
    f dup crc32 checksum-bytes <manifest>
    '[ _ parse-factor-stream ] with-string-lexer ;

: current-vocabulary ( -- string )
    manifest get [ in>> ] [ identifiers>> ] bi at ;

: current-vocabulary-name ( -- string )
    manifest get in>> ;

ERROR: identifier-redefined vocabulary word ;

: check-identifier-exists ( string -- string )
    dup
    text current-vocabulary key? [
        [ current-vocabulary-name ] dip identifier-redefined
    ] when ;

ERROR: no-IN:-form ;

: check-in-exists ( -- )
    manifest get in>> [ no-IN:-form ] unless ;

: remove-identifier ( string -- )
    check-in-exists
    current-vocabulary delete-at ;

: add-identifier ( string -- )
    check-identifier-exists
    check-in-exists
    dup current-vocabulary set-at ;

: forget-identifier ( -- string )
    token dup remove-identifier ;

: identifier ( -- string )
    token
    dup add-identifier ;

ERROR: expected expected got ;

: expect ( string -- )
    token 2dup = [ 2drop ] [ \ expected boa parsing-error ] if ;

: maybe-create-vocabulary ( string hashtable -- )
    2dup key? [
        2drop
    ] [
        [ H{ } clone ] 2dip set-at
    ] if ;

: set-in ( string -- )
    text
    manifest get
    [ identifiers>> maybe-create-vocabulary ]
    [ in<< ] 2bi ;

: parse-in ( -- string )
    token dup set-in ;

GENERIC: using-vocabulary? ( obj -- ? )

M: string using-vocabulary? ( vocabulary -- ? )
    manifest get using>> sets:in? ;

M: vocabulary using-vocabulary? ( vocabulary -- ? )
    vocabulary-name using-vocabulary? ;

: add-search-vocabulary ( token manifest -- )
    using>> sets:adjoin ;

: remove-search-vocabulary ( token manifest -- )
    using>> sets:delete ;
    
: use-vocabulary ( vocab -- )
    dup using-vocabulary? [
        vocabulary-name "Already using ``" "'' vocabulary" surround
        print
    ] [
        manifest get add-search-vocabulary
    ] if ;

: parse-use ( -- string )
    token [ manifest get add-search-vocabulary ] [ ] bi ;

: parse-unuse ( -- string )
    token [ manifest get remove-search-vocabulary ] [ ] bi ;

: body ( -- seq )
    ";" parse-until ;

: identifiers-until ( string -- seq )
    tokens-until
    dup [ add-identifier ] each ;

: ensure-in ( -- ) manifest get in>> [ no-IN:-form ] unless ;

: trim-private ( string -- string )
    ".private" ?tail drop ;
    
: append-private ( string -- string' )
    trim-private ".private" append ;

: private-on ( -- )
    ensure-in
    manifest get in>>
    append-private set-in ;

: private-off ( -- )
    ensure-in
    manifest get in>> trim-private set-in ;

"f.cheat" require


USE: nested-comments

        (*
        dup get-manifest [
            manifest get add-search-vocabulary
        ] [
            dup vocab-source-path [
                [ parse-factor-file ] keep set-manifest
            ] when*
            drop
        ] if
        *)