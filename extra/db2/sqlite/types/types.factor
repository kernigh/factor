! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays calendar.format combinators
db2.sqlite.ffi db2.sqlite.lib db2.sqlite.statements
db2.statements db2.types db2.utils fry kernel math present
sequences serialize urls db2.sqlite ;
IN: db2.sqlite.types

: (bind-sqlite-type) ( handle key value type -- )
    dup array? [ first ] when
    {
        { INTEGER [ sqlite-bind-int-by-name ] }
        { BIG-INTEGER [ sqlite-bind-int64-by-name ] }
        { SIGNED-BIG-INTEGER [ sqlite-bind-int64-by-name ] }
        { UNSIGNED-BIG-INTEGER [ sqlite-bind-uint64-by-name ] }
        { BOOLEAN [ sqlite-bind-boolean-by-name ] }
        { TEXT [ sqlite-bind-text-by-name ] }
        { VARCHAR [ sqlite-bind-text-by-name ] }
        { DOUBLE [ sqlite-bind-double-by-name ] }
        { REAL [ sqlite-bind-double-by-name ] }
        { DATE [ timestamp>ymd sqlite-bind-text-by-name ] }
        { TIME [ timestamp>hms sqlite-bind-text-by-name ] }
        { DATETIME [ timestamp>ymdhms sqlite-bind-text-by-name ] }
        { TIMESTAMP [ timestamp>ymdhms sqlite-bind-text-by-name ] }
        { BLOB [ sqlite-bind-blob-by-name ] }
        { FACTOR-BLOB [ object>bytes sqlite-bind-blob-by-name ] }
        { URL [ present sqlite-bind-text-by-name ] }
        { +db-assigned-key+ [ sqlite-bind-int-by-name ] }
        { +random-key+ [ sqlite-bind-int64-by-name ] }
        { NULL [ sqlite-bind-null-by-name ] }
        [ no-sql-type ]
    } case ;

: (bind-next-sqlite-type) ( handle key value type -- )
    {
        { INTEGER [ sqlite-bind-int ] }
        { BIG-INTEGER [ sqlite-bind-int64 ] }
        { SIGNED-BIG-INTEGER [ sqlite-bind-int64 ] }
        { UNSIGNED-BIG-INTEGER [ sqlite-bind-uint64 ] }
        { BOOLEAN [ sqlite-bind-boolean ] }
        { TEXT [ sqlite-bind-text ] }
        { VARCHAR [ sqlite-bind-text ] }
        { DOUBLE [ sqlite-bind-double ] }
        { REAL [ sqlite-bind-double ] }
        { DATE [ timestamp>ymd sqlite-bind-text ] }
        { TIME [ timestamp>hms sqlite-bind-text ] }
        { DATETIME [ timestamp>ymdhms sqlite-bind-text ] }
        { TIMESTAMP [ timestamp>ymdhms sqlite-bind-text ] }
        { BLOB [ sqlite-bind-blob ] }
        { FACTOR-BLOB [ object>bytes sqlite-bind-blob ] }
        { URL [ present sqlite-bind-text ] }
        { +db-assigned-key+ [ sqlite-bind-int ] }
        { +random-key+ [ sqlite-bind-int64 ] }
        { NULL [ drop sqlite-bind-null ] }
        [ no-sql-type ]
    } case ;

: bind-next-sqlite-type ( handle key value type -- )
    dup array? [ first ] when
    over [
        (bind-next-sqlite-type)
    ] [
        2drop sqlite-bind-null
    ] if ;

: bind-sqlite-type ( handle key value type -- )
    #! null and empty values need to be set by sqlite-bind-null-by-name
    over [
        NULL = [ 2drop NULL NULL ] when
    ] [
        drop NULL
    ] if* (bind-sqlite-type) ;

: sql-type-unsafe ( handle index type -- obj )
    {
        { +db-assigned-key+ [ sqlite3_column_int64  ] }
        { +random-key+ [ sqlite3-column-uint64 ] }
        { INTEGER [ sqlite3_column_int ] }
        { BIG-INTEGER [ sqlite3_column_int64 ] }
        { SIGNED-BIG-INTEGER [ sqlite3_column_int64 ] }
        { UNSIGNED-BIG-INTEGER [ sqlite3-column-uint64 ] }
        { BOOLEAN [ sqlite3_column_int 1 = ] }
        { DOUBLE [ sqlite3_column_double ] }
        { REAL [ sqlite3_column_double ] }
        { TEXT [ sqlite3_column_text ] }
        { VARCHAR [ sqlite3_column_text ] }
        { DATE [ sqlite3_column_text [ ymd>timestamp ] ?when ] }
        { TIME [ sqlite3_column_text [ hms>timestamp ] ?when ] }
        { TIMESTAMP [ sqlite3_column_text [ ymdhms>timestamp ] ?when ] }
        { DATETIME [ sqlite3_column_text [ ymdhms>timestamp ] ?when ] }
        { BLOB [ sqlite-column-blob ] }
        { URL [ sqlite3_column_text [ >url ] ?when ] }
        { FACTOR-BLOB [ sqlite-column-blob [ bytes>object ] ?when ] }
        [ no-sql-type ]
    } case ;

ERROR: sqlite-type-error handle index type n ;

: sqlite-type ( handle index type -- obj )
    dup array? [ first ] when
    2over sqlite-column-type {
        { SQLITE_INTEGER [ sql-type-unsafe ] }
        { SQLITE_FLOAT [ sql-type-unsafe ] }
        { SQLITE_TEXT [ sql-type-unsafe ] }
        { SQLITE_BLOB [ sql-type-unsafe ] }
        { SQLITE_NULL [ 3drop f ] }
        [ sqlite-type-error ]
    } case ;

M: sqlite-db-connection bind-sequence ( statement -- )
    [ in>> ] [ handle>> ] bi '[
        [ _ ] 2dip 1+ swap sqlite-bind-text
    ] each-index ;

M: sqlite-db-connection bind-typed-sequence ( statement -- )
    [ in>> ] [ handle>> ] bi '[
        [ _ ] 2dip 1+ swap [ value>> ] [ type>> ] bi bind-next-sqlite-type
    ] each-index ;

ERROR: no-fql-type type ;

: sqlite-type>fql-type ( string -- type )
    {
        { "varchar" [ VARCHAR ] }
        { "integer" [ INTEGER ] }
        [ no-fql-type ]
    } case ;

M: sqlite-db-connection sql-type>string
    dup array? [ first ] when
    {
        { INTEGER [ "INTEGER" ] }
        { BIG-INTEGER [ "INTEGER " ] }
        { SIGNED-BIG-INTEGER [ "BIGINT" ] }
        { UNSIGNED-BIG-INTEGER [ "BIGINT" ] }
        { DOUBLE [ "DOUBLE" ] }
        { REAL [ "DOUBLE" ] }
        { BOOLEAN [ "BOOLEAN" ] }
        { TEXT [ "TEXT" ] }
        { VARCHAR [ "TEXT" ] }
        { DATE [ "DATE" ] }
        { TIME [ "TIME" ] }
        { DATETIME [ "DATETIME" ] }
        { TIMESTAMP [ "TIMESTAMP" ] }
        { BLOB [ "BLOB" ] }
        { FACTOR-BLOB [ "BLOB" ] }
        { URL [ "TEXT" ] }
        { +db-assigned-key+ [ "INTEGER" ] }
        { +random-key+ [ "INTEGER" ] }
        [ no-sql-type ]
    } case ;

ERROR: no-sql-modifier modifier ;

: sqlite-modifier>string ( symbol -- string )
    {
        { NULL [ "NULL" ] }
        { NOT-NULL [ "NOT NULL" ] }
        { SERIAL [ "SERIAL" ] }
        { AUTOINCREMENT [ "AUTOINCREMENT" ] }
        ! { PRIMARY-KEY [ "PRIMARY KEY" ] }
        { PRIMARY-KEY [ "" ] }
        [ no-sql-modifier ]
    } case ;

M: sqlite-db-connection sql-modifiers>string
    [ sqlite-modifier>string ] map " " join ;
