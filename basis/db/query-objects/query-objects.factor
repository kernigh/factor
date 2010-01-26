! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators constructors db.binders
db.statements db.utils kernel make math namespaces sequences
sequences.deep sets ;
IN: db.query-objects

TUPLE: query ;

TUPLE: insert < query { in sequence } ;
CONSTRUCTOR: insert ( -- insert ) ;

TUPLE: update < query { in sequence } { where sequence } ;
CONSTRUCTOR: update ( -- update ) ;

TUPLE: delete < query { where sequence } ;
CONSTRUCTOR: delete ( -- delete ) ;

TUPLE: select < query
    { in sequence }
    { out sequence }
    { from sequence }
    { join sequence }
    { offset integer }
    { limit integer } ;
CONSTRUCTOR: select ( -- select ) ;

GENERIC: >table-as ( obj -- string )
GENERIC: >table-name ( in -- string )
GENERIC: >column-name ( in -- string )
GENERIC: >qualified-column-name ( in -- string )

M: binder >table-as ( obj -- string )
    toc>> >table-as ;

M: table-ordinal >table-as ( obj -- string )
    { table-name>> table-name>> table-ordinal>> } slots
    append " AS " glue ;

M: in-binder >table-name toc>> table-name>> ;
M: out-binder >table-name toc>> table-name>> ;

M: in-binder >column-name toc>> column-name>> ;
M: out-binder >column-name toc>> column-name>> ;

M: count-function >column-name toc>> column-name>> "COUNT(" ")" surround ;
M: sum-function >column-name toc>> column-name>> "SUM(" ")" surround ;
M: average-function >column-name toc>> column-name>> "AVG(" ")" surround ;
M: min-function >column-name toc>> column-name>> "MIN(" ")" surround ;
M: max-function >column-name toc>> column-name>> "MAX(" ")" surround ;
M: first-function >column-name toc>> column-name>> "FIRST(" ")" surround ;
M: last-function >column-name toc>> column-name>> "LAST(" ")" surround ;

: >qualified-full-name ( obj -- string )
    toc>> { table-name>> table-ordinal>> column-name>> } slots
    [ append ] dip "." glue ;

M: in-binder >qualified-column-name >qualified-full-name ;
M: out-binder >qualified-column-name >qualified-full-name ;
M: and-binder >qualified-column-name
    binders>> [ >qualified-full-name ] map ", " join "(" ")" surround ;

M: count-function >qualified-column-name
    >qualified-full-name "COUNT(" ")" surround ;
M: sum-function >qualified-column-name
    >qualified-full-name "SUM(" ")" surround ;
M: average-function >qualified-column-name
    >qualified-full-name "AVG(" ")" surround ;
M: min-function >qualified-column-name
    >qualified-full-name "MIN(" ")" surround ;
M: max-function >qualified-column-name
    >qualified-full-name "MAX(" ")" surround ;
M: first-function >qualified-column-name
    >qualified-full-name "FIRST(" ")" surround ;
M: last-function >qualified-column-name
    >qualified-full-name "LAST(" ")" surround ;

GENERIC: binder-operator ( obj -- string )
M: equal-binder binder-operator drop " = " ;
M: not-equal-binder binder-operator drop " <> " ;
M: less-than-binder binder-operator drop " < " ;
M: less-than-equal-binder binder-operator drop " <= " ;
M: greater-than-binder binder-operator drop " > " ;
M: greater-than-equal-binder binder-operator drop " >= " ;

GENERIC: >bind-pair ( obj -- string )
: object-bind-pair ( obj -- string )
    [ >qualified-column-name next-bind-index ] [ binder-operator ] bi glue ;
: special-bind-pair ( obj join-string -- string )
    [ binders>> [ object-bind-pair ] map ] dip join "(" ")" surround ;
M: object >bind-pair object-bind-pair ;
M: and-binder >bind-pair " and " special-bind-pair ;
M: or-binder >bind-pair " or " special-bind-pair ;

: >column/bind-pairs ( seq -- string )
    [ >bind-pair ] map " and " join ;

: >table-names ( in -- string )
    [ >table-name ] map prune ", " join ;

: >column-names ( in -- string )
    [ >column-name ] map ", " join ;

: >qualified-column-names ( in -- string )
    [ >qualified-column-name ] map ", " join ;

: >bind-indices ( in -- string )
    length [ next-bind-index ] replicate ", " join ;

GENERIC: query-object>statement* ( statement query-object -- statement )

GENERIC: flatten-binder ( obj -- obj' )
M: in-binder flatten-binder ;
M: and-binder flatten-binder binders>> [ flatten-binder ] map ;
M: or-binder flatten-binder binders>> [ flatten-binder ] map ;

: flatten-in ( seq -- seq' )
    [
        [ flatten-binder , ] each
    ] { } make flatten ;

M: insert query-object>statement*
    [ "INSERT INTO " add-sql ] dip {
        [ in>> first >table-name add-sql " (" add-sql ]
        [ in>> >column-names add-sql ") VALUES(" add-sql ]
        [ in>> >bind-indices add-sql ");" add-sql ]
        [ in>> flatten-in >>in ]
    } cleave ;

: seq>where ( statement seq -- statement )
    [
        [ " WHERE " add-sql ] dip
        >column/bind-pairs add-sql
    ] unless-empty ;

: renamed-table-names ( seq -- string )
    [ >table-as ] map ", " join ;

: select-from ( select -- string )
    from>> renamed-table-names ;

GENERIC: >join-string ( join-binder -- string )

M: join-binder >join-string
    [ table-name2>> " LEFT JOIN " " ON " surround ]
    [ { table-name1>> column-name1>> } slots "." glue ]
    [ { table-name2>> column-name2>> } slots "." glue ]
    tri " = " glue append ;

: select-join ( select -- string )
    join>> [
        ""
    ] [
        [ >join-string ] map ", " join
    ] if-empty ;

M: select query-object>statement*
    [ "SELECT " add-sql ] dip {
        [ out>> >qualified-column-names add-sql " FROM " add-sql ]
        [ select-from add-sql ]
        [ select-join add-sql ]
        [ in>> seq>where ";" add-sql ]
        [ out>> >>out ]
        [ in>> flatten-in >>in ]
    } cleave ;

M: update query-object>statement*
    [ "UPDATE " add-sql ] dip {
        [ in>> renamed-table-names add-sql " SET " add-sql ]
        [ in>> >column/bind-pairs add-sql ]
        [ where>> seq>where ";" add-sql ]
        [ { in>> where>> } slots append flatten-in >>in ]
    } cleave ;

M: delete query-object>statement*
    [ "DELETE FROM " add-sql ] dip {
        [ where>> renamed-table-names add-sql ]
        [ where>> seq>where ";" add-sql ]
        [ where>> flatten-in >>in ]
    } cleave ;

: query-object>statement ( object1 -- object2 )
    [
        init-bind-index
        [ <statement> ] dip query-object>statement*
        ! normalize-fql
    ] with-scope ;
