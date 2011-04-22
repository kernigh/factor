! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors ascii f.dictionary f.lexer fry kernel math
namespaces nested-comments sequences f.words f.manifest
math.parser sequences.deep vocabs.loader ;
IN: f.parser

: with-output-variable ( obj symbol quot -- obj )
    over [ get ] curry compose with-variable ; inline

SYMBOL: parsing-context
SYMBOL: parsing-depth

: new-parsing-context ( -- )
    V{ } clone parsing-context get push ;

: >parsing-context ( token -- )
    parsing-context get parsing-depth get 0 <= [
        push
    ] [
        last push
    ] if ;

: >all-parsing-context ( token -- )
    parsing-context get parsing-depth get 0 <= [
        push-all
    ] [
        last push-all
    ] if ;

: parsing-context> ( -- seq )
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
        [ >parsing-context ]
        [ definition>> call( -- obj ) ] bi*
        parsing-depth dec
        parsing-context>
    ] keep <parsed-parsing-word> >parsing-context ;

: lookup-token ( token/f -- )
    dup text>> search [
        dup parsing-word? [
            process-parsing-word
        ] [
            <parsed-word> >parsing-context
        ] if
    ] [
        dup text>> string>number [
            <parsed-number> >parsing-context
        ] [
            >parsing-context
        ] if*
    ] if* ;

: token ( -- token/f )
    lex-token [ [ >parsing-context ] [ text>> ] bi ] [ f ] if* ;

: tokens-until ( string -- seq )
    new-parsing-context
    '[
        token [ _ = not ] [ f ] if*
    ] loop
    parsing-context> [ >all-parsing-context ] [ but-last ] bi
    [ text>> ] map ;

: parse ( -- obj/f )
    lex-token [ lookup-token get-last-parsed ] [ f ] if* ;

! A parsing word cannot trigger the end of a parse-until.
! Example: { { } } -- } cannot be a parsing word
: parse-until ( string -- seq )
    new-parsing-context
    '[
        parse [ dup parsed-parsing-word? [ drop t ] [ last-token text>> _ = not ] if ] [ f ] if*
    ] loop
    parsing-context> [ >all-parsing-context ] [ but-last ] bi ;

: token-til-eol ( -- string/f )
    lex-til-eol ;

<PRIVATE

: add-parse-tree ( token -- )
    \ manifest get objects>> push ;

: (parse-factor-file) ( -- )
    [ lexer get lexer-done? not ]
    [ parse [ add-parse-tree ] when* ] while ;

PRIVATE>

GENERIC: preload-manifest ( manifest -- manifest )
    
: parse-factor-file ( path -- tree )
    dup <manifest>
    preload-manifest
    \ manifest [
        [
            V{ } clone parsing-context set
            0 parsing-depth set
            (parse-factor-file)
        ] with-file-lexer
    ] with-output-variable ;

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