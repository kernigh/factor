! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors ascii classes combinators
combinators.short-circuit constructors continuations
destructors f.dictionary fry grouping io io.encodings.utf8
io.files io.streams.document io.streams.string
kernel lexer make math namespaces nested-comments sequences
splitting strings words arrays locals ;
QUALIFIED-WITH: io.streams.document io
IN: f.lexer

: loop>sequence ( quot exemplar -- seq )
    [ '[ [ @ [ [ , ] when* ] keep ] loop ] ] dip make ; inline

: loop>array ( quot -- seq )
    { } loop>sequence ; inline

TUPLE: lexer stream comment-nesting-level ;

: new-lexer ( lexer -- lexer )
    new
        0 >>comment-nesting-level ; inline

: <lexer> ( stream -- lexer )
    lexer new-lexer
        swap >>stream ; inline

ERROR: lexer-error error ;

: with-lexer ( lexer quot -- )
    [ drop \ lexer ] 2keep
    '[
        _ [ <document-reader> ] change-stream
        [
            _
            [ input-stream get stream>> dispose ]
            [ ] cleanup
        ] with-input-stream
    ] with-variable ; inline
        
TUPLE: string-lexer < lexer ;

: <string-lexer> ( string -- lexer )
    string-lexer new-lexer
        swap <string-reader> >>stream ; inline

: with-string-lexer ( string quot -- )
    [ <string-lexer> ] dip with-lexer ; inline

TUPLE: file-lexer < lexer path ;

: <file-lexer> ( path -- lexer )
    file-lexer new-lexer
        swap utf8 <file-reader> >>stream ; inline

: with-file-lexer ( path quot -- )
    [ <file-lexer> ] dip with-lexer ; inline

TUPLE: lexed tokens ;

: new-lexed ( tokens class -- parsed )
    new
        swap >>tokens ; inline

TUPLE: lexed-string < lexed name text ;

TUPLE: lexed-token < lexed string ;

: <lexed-string> ( tokens -- lexed-string )
    [ lexed-string new-lexed ] keep
        [ first >>name ]
        [ third >>text ] bi ; inline

TUPLE: line-comment < lexed ;
TUPLE: lua-string < lexed start text stop ;

: <lua-string> ( tokens text -- lua-string )
    lua-string new-lexed
        swap >>text ; inline

TUPLE: lua-comment < lexed start text stop ;

: <lua-comment> ( tokens text -- lua-comment )
    lua-comment new-lexed
        swap >>text ; inline

UNION: comment line-comment lua-comment ;

: <line-comment> ( sequence -- line-comment )
    line-comment new-lexed ; inline
    
GENERIC: first-token ( obj -- token/f )
GENERIC: last-token ( obj -- token/f )

M: io:token first-token ;
M: io:token last-token ;

M: sequence first-token [ f ] [ first first-token ] if-empty ;
M: sequence last-token [ f ] [ last last-token ] if-empty ;

M: lexed first-token tokens>> [ f ] [ first first-token ] if-empty ;
M: lexed last-token tokens>> [ f ] [ last last-token ] if-empty ;

: text ( token/f -- string/f ) dup token? [ text>> ] when ;

: lex-blanks ( -- )
    [ peek1 text blank? [ read1 ] [ f ] if ] loop>array drop ;

: lex-til-eol ( -- comment )
    ! [ peek1 text "\r\n" member? [ f ] [ read1 text ] if ] loop>array >string ;
    "\r\n" read-until drop ;

TUPLE: string-word name string delimiter ;

ERROR: bad-long-string ;
ERROR: bad-short-string ;

ERROR: stream-read-until-string-error needle string stream ;

:: stream-read-until-string ( needle stream -- string' )
    [
        0 :> i!
        needle length :> len
        [
            stream stream-read1 :> ch
            ch [ needle building get >string stream stream-read-until-string-error ] unless
            
            i needle nth ch = [ i 1 + i! ] [ 0 i! ] if
            ch ,
            len i = not
        ] loop
    ] "" make ;
    
: read-until-string ( needle -- string' )
    input-stream get stream-read-until-string ;

: read-long-string ( -- string end )
    tell-input
    [
        [
            3 peek text "\"\"\"" sequence= [
                3 read text
                [ peek1 text CHAR: " = [ read1 text ] [ f ] if ] loop>array
                append 3 cut* tell-input [ 3 - ] change-column# swap tell/string>token
                [ % ] [ , ] bi*
                f
            ] [
                peek1 text {
                    { CHAR: \ [ 2 read text % ] }
                    [ drop read1 [ text , ] [ bad-long-string ] if* ]
                } case
                t
            ] if
        ] loop
    ] { } make unclip-last [ >string tell/string>token ] dip ;

: read-short-string ( -- string end )
    tell-input
    [
        [
            peek1 text CHAR: " = [
                1 read ,
                f
            ] [
                peek1 text {
                    { CHAR: \ [ 2 read text % ] }
                    [ drop read1 dup [ bad-short-string ] unless text , ]
                } case
                t
            ] if
        ] loop
    ] { } make unclip-last [ >string tell/string>token ] dip ;

: read-string ( string delimiter -- lexed-string )
    2 peek text >string "\"\"" = [
        2 read drop
        [ drop "\"\"\"" ] change-text
        read-long-string
    ] [
        [ 1string ] change-text
        read-short-string
    ] if 4array <lexed-string> ;

: lex-string/token ( -- string/token/f )
    " \n\r\"" read-until [
        dup text>> CHAR: " = [
            read-string
        ] [
            drop
        ] if
    ] [
        drop f
    ] if* ;

ERROR: bad-separator string ;    
ERROR: lua-string-error string ;
: lex-lua-string ( -- string )
    1 read
    " [\r\n" read-until text>> CHAR: [ = [
        text>> dup [ CHAR: = = ] all? [ bad-separator ] unless
        [ '[ _ "[" 3append ] change-text ]
        [ length CHAR: = <string> "]" "]" surround ] bi
        
        [ input-stream get stream>> stream-read-until-string ] keep length cut*
        3array [ second ] keep
        <lua-string>
     ] [
        [ text>> ] bi@ append lua-string-error
    ] if ;

ERROR: lua-comment-error string ;
: lex-lua-comment ( -- string )
    1 read
    " (\r\n" read-until text>> CHAR: ( = [
        text>> dup [ CHAR: * = ] all? [ bad-separator ] unless
        [ '[ _ "(" 3append ] change-text ]
        [ length CHAR: * <string> ")" ")" surround ] bi
        
        [ input-stream get stream>> stream-read-until-string ] keep length cut*
        3array [ second ] keep
        <lua-comment>
     ] [
        [ text>> ] bi@ append lua-comment-error
    ] if ;
    
: lex-token ( -- token/string/comment/f )
    lex-blanks
    2 peek
    text {
        { [ dup "!" head? ] [ drop 1 read lex-til-eol 2array <line-comment> ] }
        { [ dup "#!" head? ] [ drop 2 read lex-til-eol 2array <line-comment> ] }
        { [ dup "[=" head? ] [ drop lex-lua-string ] }
        { [ dup "(*" head? ] [ drop lex-lua-comment ] }
        { [ dup f = ] [ drop f ] }
        [ drop lex-string/token ]
    } cond ;

: lex-chunk ( -- token/f )
    " \n\r" input-stream get stream>> stream-read-until [
        drop f
    ] unless ;

M: lexer dispose stream>> dispose ;

M: lexer stream-read1
    stream>> [
        lex-token
    ] with-input-stream* ;

M: lexer stream-read
    stream>> [
        [ lex-token ] replicate
    ] with-input-stream* sift f like ;

:: lexer-stream-read-until ( seps -- sep/f )
    lex-token [
        dup text>> seps member? [
            , seps lexer-stream-read-until
        ] unless
    ] [
        f
    ] if* ;

M: lexer stream-read-until
    stream>> swap '[
        [ _ lexer-stream-read-until ] { } make f like swap
    ] with-input-stream* ;

M: lexer stream-peek1
    stream>> [
        [ lex-token ] with-input-rewind
    ] with-input-stream* ;

M: lexer stream-peek
    stream>> [
        '[
            [ lex-token ] replicate
        ] with-input-rewind
    ] with-input-stream* sift f like ;

M: lexer stream-seek
    stream>> stream-seek ;

M: lexer stream-tell
    stream>> stream-tell ;
