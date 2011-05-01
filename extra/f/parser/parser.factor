! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors ascii f.dictionary f.lexer fry kernel math
namespaces nested-comments sequences f.words f.manifest
math.parser sequences.deep vocabs.loader ;
IN: f.parser

TUPLE: comment text ;
C: <comment> comment

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

TUPLE: parsed tokens ;

TUPLE: parsed-number < parsed n ;

TUPLE: parsed-word < parsed word ;

TUPLE: parsed-parsing-word < parsed word object ;

: new-parsed ( tokens class -- parsed )
    new
        swap >>tokens ; inline

: <parsed-word> ( token word -- number )
    [ parsed-word new-parsed ] dip
        >>word ; inline

: <parsed-parsing-word> ( object token word -- number )
    [ parsed-parsing-word new-parsed ] dip
        >>word
        swap >>object ; inline

: <parsed-number> ( token n -- number )
    [ parsed-number new-parsed ] dip
        >>n ; inline

GENERIC: last-token ( obj -- token/f )

M: token last-token ;
M: sequence last-token [ f ] [ last last-token ] if-empty ;
M: parsed last-token tokens>> last-token ;

: get-last-parsed ( -- obj/f )
    parsing-context get
    parsing-depth get 0 > [ last ] when
    [ f ] [ last ] if-empty ;

ERROR: unknown-token token ;

: process-parsing-word ( token parsing-word -- )
    [
        parsing-depth inc
        new-parsing-context
        [ push-parsing ]
        [ definition>> call( -- obj ) ] bi*
        parsing-depth dec
        pop-parsing
    ] keep <parsed-parsing-word> push-parsing ;

: lookup-token ( token/f -- )
    dup text>> search [
        dup parsing-word? [
            process-parsing-word
        ] [
            <parsed-word> push-parsing
        ] if
    ] [
        dup text>> string>number [
            <parsed-number> push-parsing
        ] [
            push-parsing
        ] if*
    ] if* ;

: token ( -- token/f )
    lex-token [ [ push-parsing ] [ text>> ] bi ] [ f ] if* ;

: tokens-until ( string -- seq )
    new-parsing-context
    '[
        token [ _ = not ] [ f ] if*
    ] loop
    pop-parsing [ push-all-parsing ] [ but-last ] bi
    [ text>> ] map ;

: parse ( -- obj/f )
    lex-token [ lookup-token get-last-parsed ] [ f ] if* ;

: parse-again? ( string object -- ? )
    dup parsed-parsing-word? [
        2drop t
    ] [
        last-token text>> = not
    ] if ;

! A parsing word cannot trigger the end of a parse-until.
! Example: { { } } -- } cannot be a parsing word
: parse-until ( string -- seq )
    new-parsing-context
    '[ parse [ [ _ ] dip parse-again? ] [ t ] if* ] loop
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
    [ lexer get lexer-done? not ]
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

: parse-factor-file ( path -- tree )
    [ [ (parse-factor) ] with-parser ] with-file-lexer ;

: parse-factor ( string -- tree )
    [ [ (parse-factor) ] with-parser ] with-string-lexer ;

: tokens ( seq -- seq' )
    dup parsed? [
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
