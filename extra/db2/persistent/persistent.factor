! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs classes combinators.smart
constructors db2.types db2.utils fry kernel lexer math
namespaces parser sequences sets strings words combinators
quotations make multiline classes.tuple ;
IN: db2.persistent

: sanitize-sql-name ( string -- string' )
    H{ { CHAR: - CHAR: _ } { CHAR: ? CHAR: p } } substitute ;

GENERIC: parse-table-name ( object -- class table )
GENERIC: parse-column-name ( object -- accessor column )
GENERIC: parse-column-type ( object -- string )
GENERIC: parse-column-modifiers ( object -- string )

ERROR: bad-table-name name ;

SYMBOL: raw-persistent-table
raw-persistent-table [ H{ } clone ] initialize

SYMBOL: inherited-persistent-table
inherited-persistent-table [ H{ } clone ] initialize

TUPLE: db-column persistent slot-name getter setter column-name type modifiers ;
: <db-column> ( slot-name column-name type modifiers -- obj )
    db-column new
        swap ??1array >>modifiers
        swap >>type
        swap >>column-name
        swap [ >>slot-name ]
             [ lookup-getter >>getter ]
             [ lookup-setter >>setter ] tri ;

TUPLE: persistent class table-name columns relations
primary-key primary-key-names ;

ERROR: not-persistent class ;

GENERIC: lookup-persistent ( obj -- persistent )

: ensure-persistent ( obj -- obj )
    dup lookup-persistent [ ] unless ;

: ?lookup-persistent ( class -- persistent/f )
    raw-persistent-table get ?at [ drop f ] unless ;

: tuple>persistent ( tuple -- persistent )
    class lookup-persistent ;

ERROR: duplicate-persistent-columns persistent ;

: check-columns ( persistent -- persistent )
    dup columns>>
    [ column-name>> ] map all-unique?
    [ duplicate-persistent-columns ] unless ;

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
    dup [ [ clone swap >>persistent ] with map ] change-columns ;

: set-primary-key ( persistent -- persistent )
    dup find-primary-key >>primary-key ;

: set-primary-key-names ( persistent -- persistent )
    dup find-primary-key [ column-name>> ] map >>primary-key-names ;

: analyze-persistent ( persistent -- persistent )
    set-column-persistent-slots
    set-primary-key 
    set-primary-key-names ;

M: tuple lookup-persistent class lookup-persistent ;

: superclass-persistent-columns ( class -- columns )
    superclasses [ ?lookup-persistent ] map sift
    [ columns>> ] map concat ;

: join-persistents ( class -- persistent )
    [ superclass-persistent-columns ] 
    [ ?lookup-persistent clone ] bi
    [ (>>columns) ] keep ;

M: class lookup-persistent ( class -- persistent )
    inherited-persistent-table get
    [
        join-persistents
        analyze-persistent
        check-columns
    ] cache ;

CONSTRUCTOR: persistent ( class table-name columns -- obj )
    H{ } clone >>relations ;

: check-sanitized-name ( string -- string )
    dup dup sanitize-sql-name = [ bad-table-name ] unless ;

: make-persistent ( class name columns -- )
    inherited-persistent-table get clear-assoc
    <persistent> dup class>> raw-persistent-table get set-at ;

: parse-column ( seq -- db-column )
    ?first3
    [ parse-column-name ]
    [ parse-column-type ]
    [ parse-column-modifiers ] tri* <db-column> ;

SYNTAX: PERSISTENT:
    scan-object parse-table-name check-sanitized-name
    \ ; parse-until
    [ parse-column ] map make-persistent ;

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
