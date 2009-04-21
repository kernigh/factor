! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs classes combinators.smart
constructors db2.types db2.utils fry kernel lexer math
namespaces parser sequences sets strings words combinators
quotations make ;
IN: db2.persistent

SYMBOL: persistent-table
persistent-table [ H{ } clone ] initialize

TUPLE: db-column accessor name type modifiers ;
CONSTRUCTOR: db-column ( accessor name type modifiers -- obj ) ;

TUPLE: persistent class name columns
accessor-quot column-names
column-types
insert-string update-string
primary-key primary-key-names primary-key-quot db-assigned-id? ;

: sanitize-sql-name ( string -- string' )
    H{ { CHAR: - CHAR: _ } { CHAR: ? CHAR: p } } substitute ;

GENERIC: parse-table-name ( object -- class table )
GENERIC: parse-column-name ( object -- accessor column )
GENERIC: parse-column-type ( object -- string )
GENERIC: parse-column-modifiers ( object -- string )

ERROR: bad-table-name name ;

: check-sanitized-name ( string -- string )
    dup dup sanitize-sql-name = [ bad-table-name ] unless ;

M: integer parse-table-name throw ;

M: sequence parse-table-name
    dup length 1 = [
        first parse-table-name
    ] [
        2 ensure-length
        first2
    ] if ;

M: class parse-table-name
    dup name>> sanitize-sql-name ;

: (parse-column-name) ( string object -- accessor string )
    [ lookup-accessor ]
    [ ensure-string sanitize-sql-name ] bi* ;

M: sequence parse-column-name
    2 ensure-length
    ?first2 (parse-column-name) ;

M: string parse-column-name
    dup (parse-column-name) sanitize-sql-name ;

M: word parse-column-type
    ensure-sql-type ;

M: sequence parse-column-type
    1 2 ensure-length-range
    ?first2
    [ ensure-sql-type ] [ ] bi*
    [ 2array ] when* ;

M: sequence parse-column-modifiers
    [ ensure-sql-modifier ] map ;

M: word parse-column-modifiers
    ensure-sql-modifier ;

: parse-column ( seq -- db-column )
    ?first3
    [ parse-column-name ]
    [ parse-column-type ]
    [ parse-column-modifiers ] tri* <db-column> ;

ERROR: not-persistent class ;

GENERIC: lookup-persistent ( obj -- persistent )

M: tuple lookup-persistent class lookup-persistent ;

M: class lookup-persistent ( class -- persistent )
    persistent-table get ?at [ not-persistent ] unless ;

: tuple>persistent ( tuple -- persistent )
    class lookup-persistent ;

: primary-key-modifiers ( -- seq )
    { PRIMARY-KEY } ;

GENERIC: db-assigned-id? ( object -- ? )
: user-assigned-id? ( db-column -- ? )
    db-assigned-id? not ;

M: db-column db-assigned-id? ( db-column -- ? )
    modifiers>> SERIAL swap member? ;

: primary-key? ( db-column -- ? )
    modifiers>> primary-key-modifiers intersect empty? not ;

: find-primary-key ( persistent -- seq )
    columns>> [ primary-key? ] filter ;

M: persistent db-assigned-id? ( persistent -- ? )
    find-primary-key [ db-assigned-id? ] any? ;

: remove-db-assigned-id ( persistent -- seq )
    columns>> [ db-assigned-id? not ] filter ;

: remove-user-assigned-id ( persistent -- seq )
    columns>> [ user-assigned-id? not ] filter ;


: set-primary-key ( persistent -- persistent )
    dup find-primary-key >>primary-key ;

: set-primary-key-names ( persistent -- persistent )
    dup find-primary-key [ name>> ] map >>primary-key-names ;

: set-primary-key-quot ( persistent -- persistent )
    dup find-primary-key
    [ accessor>> 1quotation ] { } map-as
    '[ [ _ cleave ] curry { } output>sequence ] >>primary-key-quot ;

: set-db-assigned-id? ( persistent -- persistent )
    dup db-assigned-id? >>db-assigned-id? ;

: set-column-names ( persistent -- persistent )
    dup remove-db-assigned-id [ name>> ] map
    >>column-names ;

: set-column-types ( persistent -- persistent )
    dup remove-db-assigned-id [ type>> ] map
    >>column-types ;

: set-insert-string ( persistent -- persistent )
    dup column-names>> ", " join >>insert-string ;

: set-update-string ( persistent -- persistent )
    dup column-names>>
    [ " = ?" append ] map ", " join >>update-string ;

: set-accessor-quot ( persistent -- persistent )
    dup remove-db-assigned-id [
        accessor>> 1quotation
    ] { } map-as
    '[ [ _ cleave ] curry { } output>sequence ] >>accessor-quot ;
    
: analyze-persistent ( persistent -- persistent )
    set-primary-key 
    set-primary-key-names
    set-primary-key-quot
    set-db-assigned-id?
    set-column-names
    set-column-types
    set-insert-string
    set-update-string
    set-accessor-quot ;

CONSTRUCTOR: persistent ( class name columns -- obj )
    analyze-persistent ;

: make-persistent ( class name columns -- )
    <persistent> dup class>> persistent-table get set-at ;

SYNTAX: PERSISTENT:
    scan-object parse-table-name check-sanitized-name
    scan-object [ parse-column ] map
    make-persistent ;
