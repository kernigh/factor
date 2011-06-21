! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays ascii assocs combinators f.dictionary
f.lexer f.vocabularies f.words fry io
io.streams.document kernel math math.parser namespaces
nested-comments sequences sequences.deep splitting strings
vocabs.loader ;
QUALIFIED: sets
IN: f.parser

TUPLE: manifest
    current-vocabulary
    search-vocabulary-names
    search-vocabularies
    in
    identifiers
    comments
    objects ;
    ! qualified-vocabularies

: <manifest> ( -- obj )
    \ manifest new
        HS{ } clone >>search-vocabulary-names
        V{ } clone >>search-vocabularies
        H{ } clone >>identifiers
        ! V{ } clone >>qualified-vocabs
        V{ } clone >>comments
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

SYMBOL: parsing-context
SYMBOL: just-parsed

: new-parsing-context ( -- )
    V{ } clone parsing-context get push ;

: current-parsing-context ( -- seq )
    parsing-context get dup empty? [ last ] unless ;

: push-parsing ( token -- )
    current-parsing-context push ;

: push-all-parsing ( token -- )
    current-parsing-context push-all ;

: pop-parsing ( -- seq )
    parsing-context get pop ;

: pop-last-token ( -- obj/f )
    parsing-context get last pop ;

: token>new-parsing-context ( -- )
    pop-last-token
    new-parsing-context
    push-parsing ;

TUPLE: parsed-number < lexed n ;

: <parsed-number> ( n -- number )
    [ pop-parsing parsed-number new-lexed ] dip
        >>n ; inline

TUPLE: parsed-word < lexed word ;

: <parsed-word> ( word -- number )
    [ pop-parsing parsed-word new-lexed ] dip
        >>word ; inline

TUPLE: parsed-parsing-word < lexed word object ;

: <parsed-parsing-word> ( object -- number )
    [ pop-parsing parsed-parsing-word new-lexed ] dip
        >>object ; inline

ERROR: unknown-token token ;

: process-parsing-word ( parsing-word -- )
    token>new-parsing-context
    definition>> call( -- obj )
    pop-parsing push-all-parsing
    <parsed-parsing-word> push-parsing ;

GENERIC: process-token ( obj -- )

M: object process-token ( obj -- ) drop ;

M: string process-token ( string -- )
    dup search [
        nip
        dup parsing-word? [
            process-parsing-word
        ] [
            <parsed-word> push-parsing
        ] if
    ] [
        dup string>number [
            nip <parsed-number> push-parsing
        ] [
            drop
        ] if*
    ] if* ;

: read-token ( -- obj/f )
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
    new-parsing-context
    dup '[
        read-token [ _ = not ] [ _ token-expected ] if*
    ] loop
    pop-parsing [ push-all-parsing ] [ but-last ] bi ;

: parse ( -- obj/f )
    new-parsing-context
    read-token
    [ process-token current-parsing-context ] [ f ] if* ;

: parse-until ( string -- seq )
    new-parsing-context
    dup '[
        parse [
            just-parsed get [
                just-parsed off
                drop t
            ] [
                last-token text _ =
                [
                    [
                        just-parsed on
                        pop-parsing push-all-parsing
                    ] when
                ] [ not ] bi
            ] if
        ] [ _ token-expected ] if*
    ] loop
    pop-parsing [ push-all-parsing ] [ but-last ] bi ;

<PRIVATE

: parsed-comment? ( obj -- ? )
    dup parsed-parsing-word? [ object>> comment? ] [ drop f ] if ;

: add-parse-tree ( comment/token -- )
    \ manifest get
    over parsed-comment? [ comments>> ] [ objects>> ] if push ;

: stream-empty? ( stream -- ? ) stream-peek1 not >boolean ;

: (parse-factor) ( -- )
    [ input-stream get stream-empty? not ]
    [ parse [ add-parse-tree ] when* ] while ;

PRIVATE>

GENERIC: preload-manifest ( manifest -- manifest )
    
: with-parser ( quot -- manifest )
    [
        <manifest> preload-manifest
        \ manifest
    ] dip '[
        V{ } clone parsing-context set
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

: add-identifier ( token -- )
    check-identifier-exists
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
