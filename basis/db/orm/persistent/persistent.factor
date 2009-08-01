! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors annotations arrays assocs classes
classes.tuple combinators combinators.short-circuit
constructors db.types db.utils kernel math multiline namespaces
parser quotations sequences sets strings words ;
IN: db.orm.persistent

ERROR: bad-table-name obj ;
ERROR: bad-type-modifier obj ;
ERROR: not-persistent obj ;
ERROR: duplicate-persistent-columns obj ;

SYMBOL: raw-persistent-table
SYMBOL: inherited-persistent-table

raw-persistent-table [ H{ } clone ] initialize
inherited-persistent-table [ H{ } clone ] initialize

GENERIC: parse-table-name ( object -- class table )
GENERIC: parse-name ( object -- accessor column )
GENERIC: parse-column-type ( object -- string )
GENERIC: parse-column-modifiers ( object -- string )
GENERIC: lookup-persistent ( obj -- persistent )

: ?lookup-persistent ( class -- persistent/f )
    raw-persistent-table get ?at [ drop f ] unless ;

: lookup-persistent* ( class -- persistent/f )
    raw-persistent-table get ?at [ not-persistent ] unless ;

: check-sanitized-name ( string -- string )
    dup dup sanitize-sql-name = [ bad-table-name ] unless ;

TUPLE: persistent class table-name columns primary-key ;

CONSTRUCTOR: persistent ( class table-name columns -- obj ) ;

TUPLE: db-column persistent slot-name column-name type modifiers getter setter ;

: <db-column> ( slot-name column-name type modifiers -- obj )
    db-column new
        swap ??1array >>modifiers
        swap >>type
        swap >>column-name
        swap >>slot-name ;

: parse-column ( seq -- db-column )
    ?first3
    [ parse-name ]
    [ parse-column-type ]
    [ parse-column-modifiers ] tri* <db-column> ;

: superclass-persistent-columns ( class -- columns )
    superclasses [ ?lookup-persistent ] map sift
    [ columns>> ] map concat ;

: join-persistent-hierarchy ( class -- persistent )
    [ superclass-persistent-columns ]
    [ lookup-persistent* clone ] bi
    [ (>>columns) ] keep ;


: set-persistent-slots ( persistent -- )
    dup columns>> [ (>>persistent) ] with each ;


: set-setters ( persistent -- )
    columns>> [
        dup slot-name>>
        [ lookup-getter 1quotation >>getter ]
        [ lookup-setter 1quotation >>setter ] bi drop
    ] each ;


: column-primary-key? ( column -- ? )
    {
        [ type>> sql-primary-key? ]
        [ modifiers>> [ PRIMARY-KEY? ] any? ]
    } 1|| ;

GENERIC: find-primary-key ( obj -- seq )

M: persistent find-primary-key ( persistent -- seq )
    columns>> [ column-primary-key? ] filter ;

M: tuple-class find-primary-key ( class -- seq )
    lookup-persistent primary-key>> ;

M: tuple find-primary-key ( class -- seq )
    class find-primary-key ;

: set-primary-key ( persistent -- )
    dup find-primary-key >>primary-key drop ;


: process-persistent ( persistent -- persistent )
    {
        [ set-persistent-slots ]
        [ set-setters ]
        [ set-primary-key ]
        [ ]
    } cleave ;

: check-columns ( persistent -- persistent )
    dup columns>>
    [ column-name>> ] map all-unique?
    [ duplicate-persistent-columns ] unless ;

M: persistent lookup-persistent ;

M: tuple lookup-persistent class lookup-persistent ;

M: tuple-class lookup-persistent
    inherited-persistent-table get [
        join-persistent-hierarchy
        process-persistent
        check-columns
    ] cache ;

: ensure-persistent ( obj -- obj )
    dup lookup-persistent [ not-persistent ] unless ;

: ensure-type ( obj -- obj )
    dup tuple-class? [ ensure-persistent ] [ ensure-sql-type ] if ;

: ensure-type-modifier ( obj -- obj )
    dup { sequence } member? [ bad-type-modifier ] unless ;

: clear-persistent ( -- )
    inherited-persistent-table get clear-assoc ;

: save-persistent ( persistent -- )
    dup class>> raw-persistent-table get set-at ;

: make-persistent ( class name columns -- )
    clear-persistent <persistent> save-persistent ;

SYNTAX: PERSISTENT:
    scan-object parse-table-name check-sanitized-name
    \ ; parse-until
    [ parse-column ] map make-persistent ;

M: integer parse-table-name throw ;

M: sequence parse-table-name
    dup length {
        { 1 [ first parse-table-name ] }
        { 2 [ first2 ] }
        [ bad-table-name ]
    } case ;

M: tuple-class parse-table-name
    dup name>> sanitize-sql-name ;

M: sequence parse-name
    2 ensure-length first2
    [ ensure-string ] bi@ sanitize-sql-name ;

M: string parse-name
    dup 2array parse-name ;

M: word parse-column-type
    ensure-type ;

M: sequence parse-column-type
    2 ensure-length first2
    [ ensure-type ] [ ensure-type-modifier ] bi* 2array ;

M: word parse-column-modifiers ensure-sql-modifier ;

M: sequence parse-column-modifiers
    [ ensure-sql-modifier ] map ;







SINGLETONS: one:one one:many ;

ERROR: bad-relation-type obj ;
GENERIC: relation-type? ( obj -- ? )

M: sequence relation-type?
    dup length {
        { 1 [ first relation-type? ] }
        { 2 [ first relation-type? ] }
        [ drop bad-relation-type ]
    } case ;

M: tuple-class relation-type? drop t ;

M: word relation-type? drop f ;

: relation-columns ( obj -- columns )
    lookup-persistent
    columns>> [ type>> relation-type? ] filter ;

GENERIC: relation-type* ( obj -- obj' )

: relation-type ( column -- obj )
    type>> relation-type* ;

M: tuple-class relation-type* drop one:one ;

M: sequence relation-type*
    dup length {
        { 1 [ first relation-type* ] }
        { 2 [ first2 sequence = [ drop one:many ] [ bad-relation-type ] if ] }
        [ drop bad-relation-type ]
    } case ;
