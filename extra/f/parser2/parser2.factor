! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs combinators f.lexer f.vocabularies fry
io kernel namespaces sequences strings vectors math splitting ;
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

! M: token last-token ;
M: object last-token ;
M: sequence last-token [ f ] [ last last-token ] if-empty ;
M: lexed last-token tokens>> last-token ;
M: integer last-token ;

TUPLE: manifest
    current-vocabulary
    search-vocabulary-names
    search-vocabularies
    in
    identifiers
    comments
    parsed
    parsing-word-stack
    just-parsed
    objects ;

: <manifest> ( -- obj )
    manifest new
        HS{ } clone >>search-vocabulary-names
        V{ } clone >>search-vocabularies
        H{ } clone >>identifiers
        V{ } clone >>comments
        V{ } clone >>parsed
        V{ } clone >>parsing-word-stack
        V{ } clone >>objects ;

: (search-manifest) ( string assocs -- words )
    [ words>> at ] with map sift ;

ERROR: ambiguous-word words ;
: search-manifest ( string manifest -- word/f )
    search-vocabularies>> (search-manifest)
    dup length {
        { 0 [ drop f ] }
        { 1 [ first ] }
        [ ambiguous-word ]
    } case ;

: search ( string -- word/f )
    manifest get search-manifest ;

: parse-stack ( -- obj )
    manifest get parsed>> ;

: current-parse-vector ( -- obj )
    parse-stack dup empty? [ last ] unless ;

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

: push-comment ( comment -- )
    manifest get comments>> push ;

: do-parsing-word ( word -- )
    definition>> call( -- obj ) push-parsed ;

: maybe-call-parsing-word ( string -- )
    dup text search [
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
    

: add-parse-tree ( comment/token -- )
    dup comment? [ push-comment ]
    [ pop-parsed drop manifest get objects>> push ] if ;

: stream-empty? ( stream -- ? ) stream-peek1 not >boolean ;

: (parse-factor) ( -- )
    [ input-stream get stream-empty? not ]
    [ parse [ add-parse-tree ] when* ] while ;

GENERIC: preload-manifest ( manifest -- manifest )

: with-parser ( quot -- manifest )
    [
        <manifest> preload-manifest
        manifest
    ] dip '[
        @
    ] with-output-variable ; inline

: parse-factor-quot ( -- quot )
    [ [ (parse-factor) ] with-parser ] ; inline

: parse-factor-file ( path -- tree )
    parse-factor-quot with-file-lexer ;

: parse-factor ( string -- tree )
    parse-factor-quot with-string-lexer ;


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

: add-search-vocabulary ( token -- )
    text manifest get search-vocabulary-names>> sets:adjoin ;

: remove-search-vocabulary ( token -- )
    text manifest get search-vocabulary-names>> sets:delete ;

: maybe-create-vocabulary ( string hashtable -- )
    2dup key? [
        2drop
    ] [
        [ H{ } clone ] 2dip set-at
    ] if ;

: add-vocabulary-to-manifest ( vocabulary manifest -- )
    [ [ name>> ] [ search-vocabulary-names>> ] bi* sets:adjoin ]
    [ [ ] [ search-vocabularies>> ] bi* push ] 2bi ;

: parse-use ( -- string )
    token
    dup add-search-vocabulary ;

: parse-unuse ( -- string )
    token
    dup remove-search-vocabulary ;

ERROR: expected expected got ;

: expect ( string -- )
    token 2dup = [ 2drop ] [ \ expected boa parsing-error ] if ;

: set-in ( string -- )
    text
    manifest get
    [ identifiers>> maybe-create-vocabulary ]
    [ in<< ] 2bi ;

: parse-in ( -- string )
    token dup set-in ;

GENERIC: using-vocabulary? ( obj -- ? )

M: string using-vocabulary? ( vocabulary -- ? )
    manifest get search-vocabulary-names>> sets:in? ;

M: vocabulary using-vocabulary? ( vocabulary -- ? )
    vocabulary-name using-vocabulary? ;

: use-vocabulary ( vocab -- )
    dup using-vocabulary? [
        vocabulary-name "Already using ``" "'' vocabulary" surround
        print
    ] [
        manifest get
        [ search-vocabs>> push ]
        [ search-vocab-names>> sets:conjoin ] 2bi
    ] if ;

: identifiers-until ( string -- seq )
    tokens-until
    dup [ add-identifier ] each ;


: ensure-in ( -- ) manifest get in>> [ no-IN:-form ] unless ;

: private-on ( -- )
    ensure-in
    manifest get in>>
    ".private" ?tail drop ".private" append set-in ;

: private-off ( -- )
    ensure-in
    manifest get in>> ".private" ?tail drop set-in ;
