! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alien.c-types alien.strings arrays
calendar.format combinators db.postgresql.ffi db.postgresql.lib
db.types destructors io.encodings.utf8 kernel math math.parser
sequences serialize strings urls ;
IN: db.postgresql.types

: pq-get-is-null ( handle row column -- ? )
    PQgetisnull 1 = ;

: pq-get-string ( handle row column -- obj )
    3dup PQgetvalue utf8 alien>string
    dup empty? [ [ pq-get-is-null f ] dip ? ] [ [ 3drop ] dip ] if ;

: pq-get-number ( handle row column -- obj )
    pq-get-string dup [ string>number ] when ;

TUPLE: postgresql-malloc-destructor alien ;
C: <postgresql-malloc-destructor> postgresql-malloc-destructor

M: postgresql-malloc-destructor dispose ( obj -- )
    alien>> PQfreemem ;

: &postgresql-free ( alien -- alien )
    dup <postgresql-malloc-destructor> &dispose drop ; inline

: pq-get-blob ( handle row column -- obj/f )
    [ PQgetvalue ] 3keep 3dup PQgetlength
    dup 0 > [
        [ 3drop ] dip
        [
            memory>byte-array >string
            0 <uint>
            [
                PQunescapeBytea dup zero? [
                    postgresql-result-error-message throw
                ] [
                    &postgresql-free
                ] if
            ] keep
            *uint memory>byte-array
        ] with-destructors
    ] [
        drop pq-get-is-null nip [ f ] [ B{ } clone ] if
    ] if ;

: postgresql-column-typed ( handle row column type -- obj )
    dup array? [ first ] when
    {
        { +db-assigned-key+ [ pq-get-number ] }
        { +random-key+ [ pq-get-number ] }
        { INTEGER [ pq-get-number ] }
        { BIG-INTEGER [ pq-get-number ] }
        { DOUBLE [ pq-get-number ] }
        { TEXT [ pq-get-string ] }
        { VARCHAR [ pq-get-string ] }
        { DATE [ pq-get-string dup [ ymd>timestamp ] when ] }
        { TIME [ pq-get-string dup [ hms>timestamp ] when ] }
        { TIMESTAMP [ pq-get-string dup [ ymdhms>timestamp ] when ] }
        { DATETIME [ pq-get-string dup [ ymdhms>timestamp ] when ] }
        { BLOB [ pq-get-blob ] }
        { URL [ pq-get-string dup [ >url ] when ] }
        { FACTOR-BLOB [
            pq-get-blob
            dup [ bytes>object ] when ] }
        [ no-sql-type ]
    } case ;

