! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors ascii f.dictionary f.lexer fry kernel math
namespaces nested-comments sequences f.words f.manifest
math.parser sequences.deep vocabs.loader combinators
strings splitting arrays io io.streams.document ;
IN: f.parser

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

! M: token last-token ;
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
    lex-token [
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

: token ( -- token/f )
    next-token [ premature-eof ] unless* ;

: tokens-until ( string -- seq )
    new-parsing-context
    dup '[
        next-token [ _ = not ] [ _ token-expected ] if*
    ] loop
    pop-parsing [ push-all-parsing ] [ but-last ] bi ;

: parse ( -- obj/f )
    next-token [ lookup-token get-last-parsed ] [ f ] if* ;

: parse-again? ( string object -- ? )
    dup parsed-parsing-word? [
        2drop t
    ] [
        last-token = not
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

: (parse-factor) ( -- )
    [ input-stream get lexer-done? not ]
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

: call-parsing-word ( string -- obj )
    [ expect ]
    [ search definition>> call( -- obj ) ] bi ;

"f.cheat" require
