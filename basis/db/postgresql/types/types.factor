! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alien.c-types alien.strings arrays
calendar.format combinators db.postgresql.ffi db.postgresql.lib
db.types destructors io.encodings.utf8 kernel math math.parser
sequences serialize strings urls ;
IN: db.postgresql.types

/*
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
*/
