! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs classes combinators.smart
constructors db.types db.utils fry kernel lexer math
namespaces parser sequences sets strings words combinators
quotations make multiline classes.tuple
combinators.short-circuit ;
IN: db.persistent

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

TUPLE: persistent class table-name
columns
relation-columns
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

GENERIC: db-assigned-id? ( object -- ? )

M: db-column db-assigned-id? ( db-column -- ? )
    modifiers>> AUTOINCREMENT swap member? ;

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

: get-tuple-slots ( seq tuple -- seq' )
    '[ slot-name>> _ get-slot-named ] map ;

: primary-key-values ( tuple -- seq )
    [ find-primary-key ] keep get-tuple-slots ;

: primary-key-set? ( tuple -- ? )
    primary-key-values [ ] any? ;

ERROR: bad-primary-key key ;

: >primary-key ( value tuple -- )
    [
        lookup-persistent find-primary-key
        dup length 1 = not [ bad-primary-key ] when
        first column-name>>
    ] keep set-slot-named ;

: remove-primary-key ( persistent -- seq )
    columns>> [ column-primary-key? not ] filter ;

M: persistent db-assigned-id? ( persistent -- ? )
    find-primary-key [ db-assigned-id? ] any? ;

: set-column-persistent-slots ( persistent -- persistent )
    dup [ [ clone swap >>persistent ] with map ] change-columns ;

: set-primary-key ( persistent -- persistent )
    dup find-primary-key >>primary-key ;

: set-relation-columns ( persistent -- persistent )
    dup columns>> [ type>> tuple-class? ] any? [
        dup columns>> [
            dup type>> tuple-class? [
                type>> find-primary-key
                [
                    clone
                    dup persistent>> table-name>>
                    '[ [ _ "_" ] dip 3append ] change-column-name
                    INTEGER >>type
                ] map
            ] [
                1array
            ] if
        ] map concat >>relation-columns
    ] when ;

: find-relation-columns ( tuple -- seq )
    lookup-persistent columns>> [ type>> tuple-class? ] filter ;

: find-relations ( tuple -- assoc )
    #! column/tuple pairs
    [ find-relation-columns ] keep
    '[ dup slot-name>> _ get-slot-named ] { } map>assoc ;

: unset-relations? ( assoc -- ? )
    [ nip primary-key-set? not ] assoc-any? ;

: find-unset-relations ( tuple -- seq )
    find-relations unset-relations? ;

: all-relations-primary-keys-set? ( tuple -- ? )
    find-relations [ nip primary-key-set? ] assoc-all? ;

GENERIC: db-relations? ( obj -- seq )

M: persistent db-relations? ( persistent -- seq )
    relation-columns>> ;

M: tuple-class db-relations? ( class -- seq )
    lookup-persistent relation-columns>> ;

M: tuple db-relations? ( class -- seq )
    class lookup-persistent relation-columns>> ;

: set-primary-key-names ( persistent -- persistent )
    dup find-primary-key [ column-name>> ] map >>primary-key-names ;

: special-primary-key? ( tuple -- ? )
    lookup-persistent primary-key>>
    [ type>> { +db-assigned-key+ +random-key+ } member? ] any? ;

: analyze-persistent ( persistent -- persistent )
    set-column-persistent-slots
    set-relation-columns
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

CONSTRUCTOR: persistent ( class table-name columns -- obj ) ;

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
