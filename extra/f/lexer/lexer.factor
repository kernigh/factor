! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors ascii classes combinators
combinators.short-circuit constructors continuations
destructors f.dictionary fry grouping io io.encodings.utf8
io.files io.streams.document io.streams.string
kernel lexer make math namespaces nested-comments sequences
splitting strings words arrays locals ;
IN: f.lexer

: loop>sequence ( quot exemplar -- seq )
    [ '[ [ @ [ [ , ] when* ] keep ] loop ] ] dip make ; inline

: loop>array ( quot -- seq )
    { } loop>sequence ; inline

TUPLE: lexer stream comment-nesting-level string-mode ;

: new-lexer ( lexer -- lexer )
    new
        0 >>comment-nesting-level ; inline

: <lexer> ( stream -- lexer )
    lexer new-lexer
        swap >>stream ; inline

ERROR: lexer-error error ;

: with-lexer ( lexer quot -- )
    [ [ <document-reader> ] change-stream ] dip
    '[
        _
        [ input-stream get stream>> dispose ]
        [ ] cleanup
    ] with-input-stream ; inline

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

TUPLE: lexed-string < lexed string delimiter ;

TUPLE: lexed-token < lexed string ;

: <lexed-string> ( token delimiter string -- lexed-string )
    [ lexed-string new-lexed ] 2dip
        [ >>delimiter ] dip
        >>string ; inline

TUPLE: line-comment < lexed text ;
TUPLE: nested-comment < lexed start comment finish ;

UNION: comment line-comment nested-comment ;

: <line-comment> ( text -- line-comment )
    line-comment new
        swap >>text ; inline

: <nested-comment> ( start comment finish -- nested-comment )
    nested-comment new
        swap >>finish
        swap >>comment
        swap >>start ; inline


: text ( token/f -- string/f ) dup token? [ text>> ] when ;

: lex-blanks ( -- )
    [ peek1 text blank? [ read1 ] [ f ] if ] loop>array drop ;

: lex-til-eol ( -- comment )
    [ peek1 text "\r\n" member? [ f ] [ read1 text ] if ] loop>array >string ;

: lex-nested-comment ( -- comments )
    input-stream get [ 1 + ] change-comment-nesting-level drop
    2 read
    [
        2 peek text {
            { "(*" [ lex-nested-comment ] }
            { "*)" [
                input-stream get
                [ 1 - ] change-comment-nesting-level drop
                f
            ] }
            [ drop read1 text ]
        } case
    ] loop>array
    2 read <nested-comment> ;

ERROR: bad-comment-nesting ;

: ensure-nesting ( -- )
    input-stream get comment-nesting-level>> 0 = [
        bad-comment-nesting
    ] unless ;

TUPLE: string-word name string delimiter ;

ERROR: bad-long-string ;
ERROR: bad-short-string ;

: read-long-string ( -- string )
    [
        3 peek text "\"\"\"" sequence= [
            3 read drop
            peek1 text { CHAR: \n CHAR: \r CHAR: \t f } member? [
                f
            ] [
                "\"\"\""
            ] if
        ] [
            peek1 text {
                { CHAR: \ [ 2 read [ text ] map >string ] }
                [ drop read1 [ text ] [ bad-long-string ] if* ]
            } case
        ] if
    ] loop>array >string ;

: read-short-string ( -- string )
    [
        peek1 text CHAR: " = [
            1 read drop
            f
        ] [
            peek1 text {
                { CHAR: \ [ 2 read text ] }
                [ drop read1 [ text 1string ] [ bad-short-string ] if* ]
            } case
        ] if
    ] loop>array concat ;

: read-string ( string -- string )
    2 peek text >string "\"\"" = [
        2 read drop
        "\"\"\"" read-long-string
    ] [
        "\"" read-short-string
    ] if <lexed-string> ;

: lex-string/token ( -- string/token/f )
    " \n\r\"" read-until [
        text>> CHAR: " = [
            read-string
        ] when
    ] [
        drop f
    ] if* ;

: lex-token ( -- token/string/comment/f )
    lex-blanks
    2 peek
    text {
        { [ dup "!" head? ] [ drop lex-til-eol rest <line-comment> ] }
        { [ dup "(*" head? ] [ drop lex-nested-comment ensure-nesting ] }
        { [ dup f = ] [ drop f ] }
        [ drop lex-string/token ]
    } cond ;

: lex-chunk ( -- token/f )
    " \n\r" input-stream get stream>> stream-read-until [
        drop f
    ] unless ;

: peek-token ( -- token/string/comment/f )
    peek1 text>> ;

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
