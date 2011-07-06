! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors f.cheat f.lexer f.parser2 io.streams.document
kernel sequences math.parser combinators ;
QUALIFIED-WITH: io.streams.document io
IN: f.resolver

ERROR: undefined-token token ;

TUPLE: resolved-word token word ;
C: <resolved-word> resolved-word

TUPLE: resolved-number token n ;
C: <resolved-number> resolved-number

M: lexed resolve ;

M: fword resolve
    [ [ resolve ] map ] change-body ;

M: io:token resolve
    dup text {
        { [ dup string>number ] [ <resolved-number> ] }
        { [ dup search ] [ <resolved-word> ] }
        [ undefined-token ]
    } cond ;
    
