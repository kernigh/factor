! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alien.c-types alien.data arrays
calendar.format combinators db.binders db.connections db.errors
db.result-sets db.statements db.types db.utils destructors
io.encodings.utf8 kernel libc math namespaces
postgresql.db.connections postgresql.db.connections.private
postgresql.db.ffi postgresql.db.lib postgresql.db.statements
postgresql.db.types present sequences serialize
specialized-arrays urls strings ;
IN: postgresql.db.result-sets
SPECIALIZED-ARRAY: uint
SPECIALIZED-ARRAY: void*

TUPLE: postgresql-result-set < result-set ;

M: postgresql-result-set dispose
    [ handle>> PQclear ] [ f >>handle drop ] bi ;

M: postgresql-result-set #rows ( result-set -- n )
    handle>> PQntuples ;

M: postgresql-result-set #columns ( result-set -- n )
    handle>> PQnfields ;

: result>handle-n ( result-set -- handle n )
    [ handle>> ] [ n>> ] bi ; inline

M: postgresql-result-set advance-row ( result-set -- )
    [ 1 + ] change-n drop ;

M: postgresql-result-set more-rows? ( result-set -- ? )
    [ n>> ] [ max>> ] bi < ;

: type>oid ( symbol -- n )
    dup array? [ first ] when
    {
        { BLOB [ BYTEA-OID ] }
        { FACTOR-BLOB [ BYTEA-OID ] }
        [ drop 0 ]
    } case ;

: type>param-format ( symbol -- n )
    dup array? [ first ] when
    {
        { BLOB [ 1 ] }
        { FACTOR-BLOB [ 1 ] }
        [ drop 0 ]
    } case ;

: param-types ( statement -- seq )
    in>> [ type>oid ] uint-array{ } map-as ;

: default-param-value ( obj -- alien n )
    ?number>string dup [ utf8 malloc-string &free ] when 0 ;

: obj>value/type ( obj -- value type )
    {
        { [ dup string? ] [ VARCHAR ] }
        { [ dup array? ] [ first2 ] }
        { [ dup in-binder-low? ] [ [ value>> ] [ type>> ] bi ] }
        [ "postgresql obj>value/type: no binder found" throw ] 
    } cond ;

: param-values ( statement -- seq seq2 )
    in>>
    [
        obj>value/type
        {
            { FACTOR-BLOB [
                dup [ object>bytes malloc-byte-array/length ] [ 0 ] if
            ] }
            { BLOB [ dup [ malloc-byte-array/length ] [ 0 ] if ] }
            { DATE [ dup [ timestamp>ymd ] when default-param-value ] }
            { TIME [ dup [ timestamp>hms ] when default-param-value ] }
            { DATETIME [ dup [ timestamp>ymdhms ] when default-param-value ] }
            { TIMESTAMP [ dup [ timestamp>ymdhms ] when default-param-value ] }
            { URL [ dup [ present ] when default-param-value ] }
            [ drop default-param-value ]
        } case 2array
    ] map flip [
        f f
    ] [
        first2 [ >void*-array ] [ >uint-array ] bi*
    ] if-empty ;

: param-formats ( statement -- seq )
    in>> [ type>param-format ] uint-array{ } map-as ;

M: postgresql-db-connection statement>result-set ( statement -- result-set )
    dup
    [
        [ db-connection get handle>> ] dip
        {
            [ sql>> ]
            [ in>> length ]
            [ param-types ]
            [ param-values ]
            [ param-formats ]
        } cleave
        0 PQexecParams dup postgresql-result-ok? [
            [ postgresql-result-error-message parse-sql-error ] [ PQclear ] bi throw
        ] unless
    ] with-destructors
    \ postgresql-result-set new-result-set
    init-result-set ;

M: postgresql-result-set column
    [ [ handle>> ] [ n>> ] bi ] 2dip
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
        { BOOLEAN [ pq-get-boolean ] }
        { URL [ pq-get-string dup [ >url ] when ] }
        { FACTOR-BLOB [
            pq-get-blob
            dup [ bytes>object ] when ] }
        [ no-sql-type ]
    } case ;
