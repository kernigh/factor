! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors f.lexer f.parser2 io io.encodings.utf8
io.files io.streams.document kernel sequences ;
QUALIFIED-WITH: io.streams.document io
IN: f.writer

GENERIC: write-parsed ( object -- )

M: sequence write-parsed
    [ write-parsed ] each ;

M: lexed write-parsed
    tokens>> [ write-parsed ] each ;
    
M: io:token write-parsed write ;

: write-src ( tree path -- )
    utf8 <file-writer> <document-writer> [
        [ write-parsed ] each nl
    ] with-output-stream ;
