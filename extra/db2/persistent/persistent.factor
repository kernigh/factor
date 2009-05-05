! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs classes combinators.smart
constructors db2.types db2.utils fry kernel lexer math
namespaces parser sequences sets strings words combinators
quotations make multiline classes.tuple ;
IN: db2.persistent

SYMBOL: persistent-table
persistent-table [ H{ } clone ] initialize

TUPLE: db-column persistent getter setter column-name type modifiers ;
: <db-column> ( slot-name column-name type modifiers -- obj )
    db-column new
        swap ??1array >>modifiers
        swap >>type
        swap >>column-name
        swap [ lookup-getter >>getter ] [ lookup-setter >>setter ] bi ;

TUPLE: persistent class table-name columns relations
accessor-quot column-names no-id-column-names
all-column-types all-column-setters
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

ERROR: not-persistent class ;

GENERIC: lookup-persistent ( obj -- persistent )

: ensure-persistent ( obj -- obj )
    dup lookup-persistent [ ] unless ;

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

M: sequence parse-column-name
    2 ensure-length
    first2 
    [ ensure-string ]
    [ ensure-string sanitize-sql-name ] bi* ;

M: string parse-column-name
    dup 2array parse-column-name ;

M: word parse-column-type
    dup tuple-class?
    [ ensure-persistent ]
    [ ensure-sql-type ] if ;

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

: ?lookup-persistent ( class -- persistent/f )
    persistent-table get ?at [ drop f ] unless ;

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
    modifiers>> AUTOINCREMENT swap member? ;

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


: set-column-persistent-slots ( persistent -- persistent )
    dup [ [ swap >>persistent ] with map ] change-columns ;

: set-primary-key ( persistent -- persistent )
    dup find-primary-key >>primary-key ;

: set-primary-key-names ( persistent -- persistent )
    dup find-primary-key [ column-name>> ] map >>primary-key-names ;

/*

: set-primary-key-quot ( persistent -- persistent )
    dup find-primary-key
    [ getter>> 1quotation ] { } map-as
    '[ [ _ cleave ] curry { } output>sequence ] >>primary-key-quot ;

: set-db-assigned-id? ( persistent -- persistent )
    dup db-assigned-id? >>db-assigned-id? ;

: set-all-column-names ( persistent -- persistent )
    dup [ column-name>> ] map >>column-names ;

: set-no-id-column-names ( persistent -- persistent )
    dup remove-db-assigned-id [ column-name>> ] map
    >>no-id-column-names ;

: set-column-types ( persistent -- persistent )
    dup remove-db-assigned-id [ type>> ] map
    >>column-types ;

: set-all-column-types ( persistent -- persistent )
    dup columns>> [ type>> ] map >>all-column-types ;

: set-all-column-setters ( persistent -- persistent )
    dup columns>> [ setter>> ] map >>all-column-setters ;

: set-insert-string ( persistent -- persistent )
    dup column-names>> ", " join >>insert-string ;

: set-update-string ( persistent -- persistent )
    dup column-names>>
    [ " = ?" append ] map ", " join >>update-string ;

: set-accessor-quot ( persistent -- persistent )
    dup remove-db-assigned-id [
        getter>> 1quotation
    ] { } map-as
    '[ [ _ cleave ] curry { } output>sequence ] >>accessor-quot ;
*/

: analyze-persistent ( persistent -- persistent )
    set-column-persistent-slots
    set-primary-key 
    set-primary-key-names
    ! set-primary-key-quot
    ! set-db-assigned-id?
    ! set-all-column-names
    ! set-no-id-column-names
    ! set-all-column-types
    ! set-all-column-setters
    ! set-column-types
    ! set-insert-string
    ! set-update-string
    ! set-accessor-quot ;
    ;

CONSTRUCTOR: persistent ( class table-name columns -- obj )
    H{ } clone >>relations
    analyze-persistent ;

: superclass-persistent-columns ( class -- columns )
    superclasses rest-slice but-last-slice
    [ ?lookup-persistent ] map sift
    [ columns>> ] map concat ;

: make-persistent ( class name columns -- )
    pick superclass-persistent-columns append
    <persistent> dup class>> persistent-table get set-at ;

SYNTAX: PERSISTENT:
    scan-object parse-table-name check-sanitized-name
    \ ; parse-until
    [ parse-column ] map make-persistent ;

: scan-relation ( -- class class )
    scan-word scan-word [ ensure-persistent ] bi@ ;

TUPLE: relation left right ;

: normalize-relation ( relation -- relation )
    [ lookup-persistent ] change-left
    [ lookup-persistent ] change-right ;

TUPLE: one-one < relation ;
CONSTRUCTOR: one-one ( left right -- relation )
    normalize-relation ;

TUPLE: one-many < relation ;
CONSTRUCTOR: one-many ( left right -- relation )
    normalize-relation ;

TUPLE: many-many < relation ;
CONSTRUCTOR: many-many ( left right -- relation )
    normalize-relation ;

ERROR: relation-already-defined relation ;

: lookup-relations ( class -- relations )
    lookup-persistent relations>> ;

: check-relation ( relation persistent persistent -- relation )
    [ class>> ] [ relations>> ] bi* key? [ relation-already-defined ] when ;

: check-left ( relation -- relation )
    dup [ left>> ] [ right>> ] bi check-relation ;

: check-right ( relation -- relation )
    dup [ right>> ] [ left>> ] bi check-relation ;

: check-relations ( relation -- relation )
    check-left check-right ;

: add-relation-left ( relation -- )
    [ left>> ] [ right>> class>> ] [ left>> relations>> ] tri set-at ;

: add-relation-right ( relation -- )
    [ right>> ] [ left>> class>> ] [ right>> relations>> ] tri set-at ;

: add-relations ( relation -- )
    [ add-relation-left ] [ add-relation-right ] bi ;

GENERIC: add-relation ( relation -- )

M: one-one add-relation ( relation -- )
    check-relations add-relations ;

M: one-many add-relation ( relation -- )
    check-left add-relation-left ;

M: many-many add-relation ( relation -- )
    check-relations add-relations ;

SYNTAX: HAS-ONE:
    scan-relation <one-one> add-relation ;

SYNTAX: HAS-MANY:
    scan-relation <one-many> add-relation ;

SYNTAX: MANY-MANY:
    scan-relation <many-many> add-relation ;
