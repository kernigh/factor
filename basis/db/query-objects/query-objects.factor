! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators constructors db.binders
db.statements db.utils kernel namespaces sequences sets ;
IN: db.query-objects

TUPLE: query ;

TUPLE: insert < query in ;
CONSTRUCTOR: insert ( -- insert ) ;

TUPLE: update < query in where ;
CONSTRUCTOR: update ( -- update ) ;

TUPLE: delete < query where ;
CONSTRUCTOR: delete ( -- delete ) ;

TUPLE: select < query in out offset limit ;
CONSTRUCTOR: select ( -- select ) ;


GENERIC: >table-name ( in -- string )
GENERIC: >column-name ( in -- string )
GENERIC: >qualified-column-name ( in -- string )

M: in-binder >table-name table-name>> ;
M: out-binder >table-name table-name>> ;

M: in-binder >column-name column-name>> ;
M: out-binder >column-name column-name>> ;
M: count-function >column-name column-name>> "COUNT(" ")" surround ;
M: sum-function >column-name column-name>> "SUM(" ")" surround ;
M: average-function >column-name column-name>> "AVG(" ")" surround ;
M: min-function >column-name column-name>> "MIN(" ")" surround ;
M: max-function >column-name column-name>> "MAX(" ")" surround ;
M: first-function >column-name column-name>> "FIRST(" ")" surround ;
M: last-function >column-name column-name>> "LAST(" ")" surround ;

M: in-binder >qualified-column-name
    { table-name>> column-name>> } slots "." glue ;

: >table-names ( in -- string )
    [ >table-name ] map prune ", " join ;

: >column-names ( in -- string )
    [ >column-name ] map ", " join ;

: >qualified-column-names ( in -- string )
    [ >qualified-column-name ] map ", " join ;

: >bind-indices ( in -- string )
    length [ next-bind-index ] replicate ", " join ;

GENERIC: query-object>statement* ( statement query-object -- statement )

M: insert query-object>statement*
    [ "INSERT INTO " add-sql ] dip {
        [ in>> first >table-name add-sql " (" add-sql ]
        [ in>> >column-names add-sql ") VALUES(" add-sql ]
        [ in>> >bind-indices add-sql ");" add-sql ]
        [ in>> >>in ]
    } cleave ;

: >column/bind-pairs ( seq -- string )
    [
        >column-name next-bind-index " = " glue
    ] map " and " join ;

: seq>where ( statement seq -- statement )
    [
        [ " WHERE " add-sql ] dip
        >column/bind-pairs add-sql
    ] unless-empty ;

M: select query-object>statement*
    [ "SELECT " add-sql ] dip {
        [ out>> >column-names add-sql " FROM " add-sql ]
        [ out>> >table-names add-sql ]
        [ in>> seq>where ";" add-sql ]
        [ out>> >>out ]
        [ in>> >>in ]
    } cleave ;

M: update query-object>statement*
    [ "UPDATE " add-sql ] dip {
        [ in>> >table-names add-sql " SET " add-sql ]
        [ in>> >column/bind-pairs add-sql ]
        [ where>> seq>where ";" add-sql ]
        [ { in>> where>> } slots append >>in ]
    } cleave ;

M: delete query-object>statement*
    [ "DELETE FROM " add-sql ] dip {
        [ where>> >table-names add-sql ]
        [ where>> seq>where ";" add-sql ]
        [ where>> >>in ]
    } cleave ;

: query-object>statement ( object1 -- object2 )
    [
        init-bind-index
        [ <statement> ] dip query-object>statement*
        ! normalize-fql expand-fql*
    ] with-scope ;
