! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors ascii classes combinators.short-circuit
constructors continuations f.dictionary fry io
io.encodings.utf8 io.files kernel make math namespaces
sequences strings words nested-comments splitting grouping ;
IN: f.lexer

: loop>sequence ( quot exemplar -- seq )
    [ '[ [ @ [ [ , ] when* ] keep ] loop ] ] dip make ; inline

: loop>array ( quot -- seq )
    { } loop>sequence ; inline

: sequential? ( sequence -- ? )
    2 <clumps> [ first2 - -1 = not ] find drop not ;

: (start*-maximum) ( subseq seq n -- i/f )
    3dup 1 + start* [
        2dup - -1 = [
            nip (start*-maximum)
        ] [
            [ 3drop ] dip
        ] if
    ] [
        2nip
    ] if* ;

: start*-maximum ( subseq seq n -- i/f )
    3dup start* [
        nip (start*-maximum)
    ] [
        3drop f
    ] if* ;

ERROR: lexer-error error ;

CONSTRUCTOR: lexer-error ( error -- obj ) ;

TUPLE: lexer lines line# column# ;

: reset-lexer ( lexer -- lexer )
    0 >>line#
    0 >>column# ;

TUPLE: file-lexer < lexer path ;

CONSTRUCTOR: file-lexer ( path -- obj )
    dup path>> utf8 file-lines >>lines
    reset-lexer ;

TUPLE: string-lexer < lexer ;

: <string-lexer> ( string -- obj )
    string-lines
    string-lexer new
        swap >>lines
    reset-lexer ;

TUPLE: token line# start text ;

CONSTRUCTOR: token ( text -- obj )
    lexer get line#>> >>line#
    lexer get column#>> over text>> length - >>start ;

: advance-line ( lexer -- lexer )
    [ 1 + ] change-line#
    0 >>column# ;

: with-lexer ( lexer quot -- )
    [ \ lexer ] dip '[
        _ [ \ lexer-error boa rethrow ] recover
    ] with-variable ; inline

: with-file-lexer ( path quot -- )
    [ <file-lexer> ] dip with-lexer ; inline

: with-string-lexer ( string quot -- )
    [ <string-lexer> ] dip with-lexer ; inline

: last-line? ( lexer -- ? )
    [ line#>> ] [ lines>> length ] bi >= ;

: current-line ( lexer -- string )
    [ line#>> ] [ lines>> ] bi ?nth ;

: current-position ( lexer -- n string )
    [ column#>> ] [ current-line ] bi ;

: current-character ( lexer -- ch/f )
    current-position ?nth ;

: take-token ( n lexer -- string )
    [ current-position swapd subseq ]
    [ column#<< ] 2bi ;

: take-line ( lexer -- string )
    [ current-position swap tail ]
    [ dup current-line length >>column# drop ] bi ;
    
: line-done? ( lexer -- ? )
    current-position length >= ;

: lexer-done? ( lexer -- ? )
    { [ line-done? ] [ last-line? ] } 1&& ;

: ?next-line ( lexer -- lexer )
    dup line-done? [ advance-line ] when ;

: lex-til-eol ( -- token/f )
    lexer get
    [ take-line <token> ]
    [ advance-line drop ] bi ;

: advance-column ( n -- )
    [ lexer get ] dip '[ _ + ] change-column# drop ;

ERROR: token-not-found string ;

ERROR: string-trailing-token token ;

: lex-token ( -- comment/token/f )
    lexer get
    [ ?next-line current-position [ blank? ] find-from drop ] keep
    over [ take-token ] [ nip take-line ] if
    [ <token> ] [ f ] if*
    1 advance-column
    dup [ dup text>> empty? [ drop lex-token ] when ] when ;

: lex-til-string ( string -- token/f )
    dup '[
        [
            _
            lexer get line-done? [ "" , ] when
            lexer get ?next-line lexer-done? [ token-not-found ] when
            lexer get current-position swap start*-maximum [
                [ [ lexer get current-position ] dip swap subseq ]
                [ _ length + lexer get column#<< ] bi , f
            ] [
                lexer get take-line , t
            ] if*
        ] loop
    ] { } make "\n" join
    lexer get current-character [
        blank? [ lex-token text>> string-trailing-token ] unless
        1 advance-column
    ] when* ;

(*
: with-input-rewind ( quot -- )
    tell-input [ call ] dip
    swap [ seek-absolute seek-input ] [ drop ] if ; inline

ERROR: no-class-predicate class ;

: class-predicate ( class -- predicate )
    dup "predicate" word-prop [
        nip first
    ] [
        no-class-predicate
    ] if* ;

: try-token ( class -- )
    '[ token _ class-predicate execute( word -- ? ) ] with-input-rewind ;

: try-expect ( string -- )
    '[ _ token = not ] with-input-rewind ;

GENERIC: optional ( obj -- )

M: string optional try-expect ;
M: class optional try-token ;

ERROR: unexpected expected unexpected ;

: expect ( token -- )
    token 2dup text>> = [ 2drop ] [ unexpected ] if ;
*)
