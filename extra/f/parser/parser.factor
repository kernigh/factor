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


: with-output-variable ( obj symbol quot -- obj )
    over [ get ] curry compose with-variable ; inline

SYMBOL: parsing-context
SYMBOL: parsing-depth

: new-parsing-context ( -- )
    V{ } clone parsing-context get push ;

: current-parsing-context ( -- seq )
    parsing-context get
    parsing-depth get 0 > [ last ] when ;

: push-parsing ( token -- )
    current-parsing-context push ;

: push-all-parsing ( token -- )
    current-parsing-context push-all ;

: pop-parsing ( -- seq )
    parsing-context get pop ;

: pop-last-parsed ( -- obj/f )
    parsing-context get
    parsing-depth get 0 > [
        last
    ] when
    [ f ] [ pop ] if-empty ;

: get-last-parsed ( -- obj/f )
    parsing-context get
    parsing-depth get 0 > [ last ] when
    [ f ] [ last ] if-empty ;

TUPLE: parsed-number < lexed n ;

: <parsed-number> ( n -- number )
    [ pop-last-parsed parsed-number new-lexed ] dip
        >>n ; inline

TUPLE: parsed-word < lexed word ;

: <parsed-word> ( word -- number )
    [ pop-last-parsed parsed-word new-lexed ] dip
        >>word ; inline

TUPLE: parsed-parsing-word < lexed word object ;

: <parsed-parsing-word> ( object -- number )
    [ pop-last-parsed parsed-parsing-word new-lexed ] dip
        >>object ; inline

GENERIC: last-token ( obj -- token/f )

M: token last-token ;
M: sequence last-token [ f ] [ last last-token ] if-empty ;
M: lexed last-token tokens>> last-token ;
M: integer last-token ;

ERROR: unknown-token token ;

: process-parsing-word ( parsing-word -- )
    pop-last-parsed
    new-parsing-context
    parsing-depth inc
    push-parsing
    definition>> call( -- obj )
    parsing-depth dec
    <parsed-parsing-word> push-parsing ;

: lookup-token ( string -- )
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
            ! unknown token
            drop
        ] if*
    ] if* ;

: next-token ( -- obj/f )
    read1 [
        dup comment? [
            manifest get comments>> push next-token
        ] [
            dup push-parsing text
        ] if
    ] [
        f
    ] if* ;

ERROR: premature-eof ;
ERROR: token-expected expected ;

: token ( -- token/string/f )
    next-token [ premature-eof ] unless* ;

: chunk ( -- token/f )
    lex-chunk [ premature-eof ] unless* ;

: tokens-until ( string -- seq )
    new-parsing-context
    dup '[
        next-token [ _ = not ] [ _ token-expected ] if*
    ] loop
    pop-parsing [ push-all-parsing ] [ but-last ] bi ;

: parse ( -- obj/f )
    next-token
    [ dup lexed-string? [ drop ] [ lookup-token ] if get-last-parsed ]
    [ f ] if* ;

: parse-again? ( string object -- ? )
    dup parsed-parsing-word? [
        2drop t
    ] [
        last-token dup token? [ text ] when = not
    ] if ;

! A parsing word cannot trigger the end of a parse-until.
! Example: { { } } -- } cannot be a parsing word
: parse-until ( string -- seq )
    new-parsing-context
    '[ parse [ [ _ ] dip parse-again? ] [ f ] if* ] loop
    pop-parsing [ push-all-parsing ] [ but-last ] bi ;

: token-til-eol ( -- string/f )
    lex-til-eol ;

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
        0 parsing-depth set @
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

: call-parsing-word ( string -- obj )
    [ expect ]
    [ search definition>> call( -- obj ) ] bi ;

GENERIC: using-vocabulary? ( obj -- ? )

! M: string using-vocabulary? ( vocabulary -- ? ) manifest get search-vocabulary-names>> in? ;

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
        ! [ [ load-vocab ] dip search-vocabs>> push ]
        ! [ [ vocabulary-name ] dip search-vocab-names>> conjoin ] 2bi
    ] if ;

: identifiers-until ( string -- seq )
    tokens-until
    dup [ add-identifier ] each ;

"f.cheat" require
