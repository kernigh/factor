! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays ascii assocs combinators f.dictionary
f.lexer f.vocabularies f.words fry io
io.streams.document kernel math math.parser namespaces
nested-comments sequences sequences.deep splitting strings
vocabs.loader vectors ;
QUALIFIED: sets
IN: f.parser

TUPLE: manifest
    current-vocabulary
    search-vocabulary-names
    search-vocabularies
    in
    identifiers
    comments
    parse-stack
    just-parsed
    objects ;
    ! qualified-vocabularies

: <manifest> ( -- obj )
    manifest new
        HS{ } clone >>search-vocabulary-names
        V{ } clone >>search-vocabularies
        H{ } clone >>identifiers
        ! V{ } clone >>qualified-vocabs
        V{ } clone >>comments
        V{ } clone >>parse-stack
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

GENERIC: last-token ( obj -- token/f )

M: token last-token ;
M: sequence last-token [ f ] [ last last-token ] if-empty ;
M: lexed last-token tokens>> last-token ;
M: integer last-token ;

: with-output-variable ( obj symbol quot -- obj )
    over [ get ] curry compose with-variable ; inline

: new-parse-vector ( -- )
    V{ } clone manifest get parse-stack>> push ;

: current-parse-vector ( -- seq )
    manifest get parse-stack>> dup empty? [
        dup last vector? [ last ] when 
    ] unless ;

: push-parsing ( token -- )
    current-parse-vector push ;

: push-all-parsing ( token -- )
    current-parse-vector push-all ;

: pop-parsing ( -- seq )
    manifest get parse-stack>> pop ;

: pop-last-token ( -- obj/f )
    manifest get parse-stack>>
    dup last vector? [
        last pop
    ] [
        pop
    ] if ;

: pop-last-parsed ( -- obj/f )
    manifest get parse-stack>>
    dup last vector? [
        last pop
    ] [
        pop
    ] if ;

: token>new-parse-vector ( -- )
    pop-last-token
    new-parse-vector
    push-parsing ;

ERROR: unknown-token token ;

: process-parsing-word ( parsing-word -- )
    token>new-parse-vector
    definition>> call( -- obj )
    push-parsing ;

GENERIC: process-token ( obj -- )

M: object process-token ( obj -- ) drop ;

: read-token ( -- obj/f )
    f manifest get just-parsed<<
    read1 [
        dup comment? [
            manifest get comments>> push read-token
        ] [
            dup push-parsing text
        ] if
    ] [
        f
    ] if* ;

: (peek-token) ( -- token/string/f )
    read1 [
        dup comment? [ drop (peek-token) ] when
    ] [
        f
    ] if* ;

: peek-token ( -- token/string/f )
    [ (peek-token) text ] with-input-rewind ;

ERROR: premature-eof ;
ERROR: token-expected expected ;

: token ( -- token/string/f )
    read-token [ premature-eof ] unless* ;

: chunk ( -- token/f )
    lex-chunk [ premature-eof ] unless*
    dup push-parsing text ;

: tokens-until ( string -- seq )
    new-parse-vector
    dup '[
        read-token [ _ = not ] [ _ token-expected ] if*
    ] loop
    pop-parsing [ push-all-parsing ] [ but-last ] bi
    [ text ] map ;

: parse ( -- obj/f )
    new-parse-vector
    read-token
    [ process-token pop-parsing first ] [ f ] if* ;

: parse-until ( string -- seq )
    new-parse-vector
    dup '[
        parse [
            dup push-parsing
            manifest get just-parsed>> [
                f manifest get just-parsed<<
                drop t
            ] [
                last-token text _ =
                [ [ t manifest get just-parsed<< ] when ]
                [ not ] bi
            ] if
        ] [ _ token-expected ] if*
    ] loop

    pop-parsing [ push-all-parsing ] [ but-last ] bi ;

<PRIVATE

: add-parse-tree ( comment/token -- )
    manifest get
    over comment? [ comments>> ] [ objects>> ] if push ;

: stream-empty? ( stream -- ? ) stream-peek1 not >boolean ;

: (parse-factor) ( -- )
    [ input-stream get stream-empty? not ]
    [ parse [ add-parse-tree ] when* ] while ;

PRIVATE>

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










: tokens ( seq -- seq' )
    dup lexed? [
        tokens>> tokens
    ] [
        dup sequence? [
            [ tokens ] map
        ] [
            dup token? [ tokens ] unless
        ] if
    ] if ;

: tree>tokens ( tree -- tokens )
    objects>> [ tokens ] map flatten ;

ERROR: expected expected got ;

: expect ( string -- )
    token 2dup = [ 2drop ] [ expected ] if ;

: optional ( string -- )
    peek-token = [ token drop ] when ;

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

: add-identifier ( token -- )
    check-identifier-exists
    check-in-exists
    dup current-vocabulary set-at ;

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

"f.cheat" require
