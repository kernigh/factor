! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors f.lexer io io.encodings.utf8 io.files
io.streams.document sequences ;
QUALIFIED-WITH: io.streams.document io
IN: f.writer

GENERIC: write-parsed ( object -- )

M: lexed write-parsed
    tokens>> [ write-parsed ] each ;
    
M: io:token write-parsed
    write ;

M: integer write-parsed
    write1 ;

: write-src ( tree path -- )
    utf8 <file-writer> <document-writer> [
        [ dup nested-comment? [ B ] when write-parsed ] each nl
    ] with-output-stream ;
