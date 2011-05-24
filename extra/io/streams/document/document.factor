! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors destructors io kernel math sequences splitting
fry ;
IN: io.streams.document

! Readers
TUPLE: document-reader stream line# column# previous-character ;

TUPLE: token text line# column# ;

: <token> ( stream string -- token )
    swap
    [ token new ] 2dip
        [ >>text ] dip
        [ line#>> >>line# ]
        [ column#>> >>column# ] bi ; inline

: next-line ( stream -- )
    [ 1 + ] change-line#
    0 >>column# drop ;

: update-line-read1 ( stream character -- )
    >>previous-character next-line ;

: update-column ( stream character -- )
    >>previous-character [ 1 + ] change-column# drop ;

: update-line-read ( stream string -- )
    string-lines
    [ length 1 - '[ _ + ] change-line# drop ]
    [ last length '[ _ + ] change-column# drop ] 2bi ;

: update-stream-read1 ( stream character -- )
    over previous-character>> CHAR: \r = [
        update-line-read1
    ] [
        dup CHAR: \n = [
            update-line-read1
        ] [
            update-column
        ] if
    ] if ;

: update-stream-read ( stream string -- )
    over previous-character>> CHAR: \r = [
        [ last update-line-read1 ]
        [ update-line-read ] 2bi
    ] [
        update-line-read
    ] if ;

M: document-reader stream-element-type drop +character+ ;

M: document-reader stream-read1
    dup stream>> stream-read1 [
        [ <token> ]
        [ update-stream-read1 ]
        2bi
    ] [
        drop f
    ] if* ;

M: document-reader stream-peek1
    dup stream>> stream-peek1
    [ <token> ] [ drop f ] if* ;

M: document-reader stream-read
    [ nip ] [ stream>> stream-read ] 2bi [
        [ <token> ]
        [ update-stream-read ]
        2bi
    ] [
        drop f
    ] if* ;

M: document-reader stream-read-until
    [ nip ] [ stream>> stream-read-until ] 2bi
    over [
        pick previous-character>> CHAR: \r = [
            pick next-line
        ] when
        [
            [ nip >>previous-character drop ]
            [ drop <token> ]
            [ drop update-line-read ] 3tri
        ] 3keep
        nip
        [
            <token>
        ] [
            CHAR: \n = [ next-line ] [ [ 1 + ] change-column# drop ] if
        ] 2bi
    ] [
        3drop f f
    ] if ;

M: document-reader stream-peek
    [ nip ] [ stream>> stream-peek ] 2bi
    [ <token> ] [ drop f ] if* ;

M: document-reader stream-tell stream>> stream-tell ;
M: document-reader stream-seek stream>> stream-seek ;

M: document-reader dispose stream>> dispose ;

: <document-reader> ( stream -- stream' )
    document-reader new
        swap >>stream
        0 >>line#
        0 >>column# ; inline

: with-document-reader ( stream quot -- )
    [ <document-reader> ] dip with-input-stream ; inline
