! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors annotations arrays assocs classes
classes.tuple combinators combinators.short-circuit
constructors db.types db.utils kernel math multiline namespaces
parser quotations sequences sets strings words make
fry lexer db.binders ;
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
GENERIC: lookup-raw-persistent ( obj -- obj' )
GENERIC: lookup-persistent ( obj -- persistent )

SYMBOL: deferred-persistent

: ?lookup-persistent ( class -- persistent/f )
    raw-persistent-table get ?at [ drop f ] unless ;

: lookup-persistent* ( class -- persistent/f )
    raw-persistent-table get ?at [ not-persistent ] unless ;

: check-sanitized-name ( string -- string )
    dup dup sanitize-sql-name = [ bad-table-name ] unless ;

TUPLE: persistent class table-name columns primary-key incomplete? ;

CONSTRUCTOR: persistent ( class table-name columns -- obj ) ;

TUPLE: db-column persistent
slot-name column-name type modifiers getter setter ;

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


: compute-persistent-slots ( persistent -- )
    dup columns>> [ (>>persistent) ] with each ;


: compute-setters ( persistent -- )
    columns>> [
        dup slot-name>>
        [ lookup-getter 1quotation >>getter ]
        [ lookup-setter 1quotation >>setter ] bi drop
    ] each ;

: column-primary-key? ( column -- ? )
    {
        [ type>> sql-primary-key? ]
        [ modifiers>> [ +primary-key+? ] any? ]
    } 1|| ;

GENERIC: table-name* ( column -- string )

M: sequence table-name* first table-name* ;

M: db-column table-name* persistent>> table-name>> ;

M: tuple-class table-name* lookup-persistent table-name>> ;

M: tuple table-name* lookup-persistent table-name>> ;

M: in-binder table-name* table-name>> ;

M: out-binder table-name* table-name>> ;

: table-name ( obj -- string )
    table-name* ;

: quoted-table-name ( obj -- string )
    table-name* "\"" dup surround ;

GENERIC: find-primary-key ( obj -- seq )

M: persistent find-primary-key ( persistent -- seq )
    columns>> [ column-primary-key? ] filter ;

M: tuple-class find-primary-key ( class -- seq )
    lookup-persistent primary-key>> ;

M: tuple find-primary-key ( class -- seq )
    class find-primary-key ;

: db-assigned-key? ( class -- ? )
    find-primary-key [ type>> +db-assigned-key+? ] all? ;

: user-assigned-key? ( class -- ? )
    find-primary-key [ modifiers>> +primary-key+ swap member? ] all? ;

: compute-primary-key ( persistent -- )
    dup find-primary-key >>primary-key drop ;

: primary-key-slots ( obj -- seq )
    lookup-persistent
    find-primary-key [ [ table-name ] [ slot-name>> ] bi "." glue ] map ;

: process-persistent ( persistent -- persistent )
    {
        [ compute-persistent-slots ]
        [ compute-setters ]
        [ compute-primary-key ]
        [ ]
    } cleave ;

: check-columns ( persistent -- persistent )
    dup columns>>
    [ column-name>> ] map all-unique?
    [ duplicate-persistent-columns ] unless ;

M: persistent lookup-raw-persistent ;
M: tuple lookup-raw-persistent class lookup-raw-persistent ;
M: tuple-class lookup-raw-persistent raw-persistent-table get at ;

M: persistent lookup-persistent ;

M: tuple lookup-persistent class lookup-persistent ;

M: tuple-class lookup-persistent
    inherited-persistent-table get [
        join-persistent-hierarchy
        process-persistent
        check-columns
    ] cache ;

: ensure-persistent ( obj -- obj )
    dup lookup-raw-persistent [ not-persistent ] unless ;

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

SYNTAX: DEFER-PERSISTENT:
    \ deferred-persistent scan-object
    raw-persistent-table get ?at [
        2drop
    ] [
        raw-persistent-table get set-at
    ] if ;

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






SYMBOL: table-names

SINGLETONS: one:one one:many many:one many:many ;

ERROR: bad-relation-category obj ;
ERROR: bad-relation-class obj ;


GENERIC: relation-category? ( obj -- ? )

M: sequence relation-category?
    dup length {
        { 1 [ first relation-category? ] }
        { 2 [ first relation-category? ] }
        [ drop bad-relation-category ]
    } case ;

M: db-column relation-category? type>> relation-category? ;

M: tuple-class relation-category? drop t ;

M: word relation-category? drop f ;

: relation-columns ( obj -- columns )
    lookup-persistent
    columns>> [ type>> relation-category? ] filter ;



GENERIC: relation-category ( obj -- obj' )

M: db-column relation-category
    type>> relation-category ;

M: object relation-category drop f ;
M: tuple-class relation-category drop one:one ;

M: sequence relation-category
    dup length {
        { 1 [ first relation-category ] }
        { 2 [ first2 sequence = [ drop one:many ] [ bad-relation-category ] if ] }
        [ drop bad-relation-category ]
    } case ;



GENERIC: relation-class* ( obj -- obj' )

: relation-class ( column -- obj )
    type>> relation-class* ;

M: tuple-class relation-class* ;

M: sequence relation-class*
    dup length {
        { 0 [ bad-relation-class ] }
        [ drop first ]
    } case ;

M: object relation-class* drop f ;


: query-shape ( class -- seq )
    lookup-persistent columns>> [ dup relation-category ] { } map>assoc ;

: filter-persistent ( quot -- seq )
    [ raw-persistent-table get values ] dip filter ; inline

: map-persistent ( quot -- seq )
    [ raw-persistent-table get values ] dip { } map-as ; inline

: each-persistent ( quot -- )
    [ raw-persistent-table get values ] dip each ; inline

: find-many:many-relations ( class -- seq )
    sequence 2array
    '[
        columns>> [ type>> _ = ] filter empty? not
    ] filter-persistent ;

GENERIC: select-columns* ( obj -- )

M: persistent select-columns*
    columns>> [ select-columns* ] each ;

M: db-column select-columns*
    dup type>> {
        { [ dup tuple-class? ] [ nip lookup-persistent select-columns* ] }
        [ drop , ]
    } cond ;

: select-columns ( obj -- seq )
    [ select-columns* ] { } make ;



GENERIC: select-reconstructor* ( obj -- )

M: persistent select-reconstructor*
    columns>> [ select-reconstructor* ] each ;

M: db-column select-reconstructor*
    dup relation-category {
        { one:one [
            [ type>> lookup-persistent select-reconstructor* ]
            [ setter>> , ] bi
        ] }
        { one:many [
            [ relation-class lookup-persistent select-reconstructor* ]
            [ getter>> '[ over _ push ] , ] bi
        ] }
        [ drop "next value" , setter>> , ]
    } case ;

: select-reconstructor ( obj -- seq )
    [ select-reconstructor* ] [ ] make ;

: ((column>create-text)) ( db-column -- )
    {
        [ type>> sql-create-type>string % ]
        [ modifiers>> [ " " % sql-modifiers>string % ] when* ]
    } cleave ;

: (column>create-text) ( db-column -- string )
    [
        [ slot-name>> % " " % ] [ ((column>create-text)) ] bi
    ] "" make ;

: (columns>create-text) ( seq -- seq )
    [ (column>create-text) ] map sift ;

: columns>create-text ( seq -- string )
    (columns>create-text) ", " join ;

: class>foreign-key-create ( class -- string )
    [ table-name ] [ find-primary-key (columns>create-text) ] bi
    [ "_" glue ] with map ", " join ;

: class>primary-key-create ( class -- string )
    find-primary-key [
        f
    ] [
        [ column-name>> ] map "," join
        ", primary key(" ")" surround
    ] if-empty ;

: column>create-text ( db-column -- string )
    dup relation-category {
        { one:one [ relation-class class>foreign-key-create ] }
        { one:many [ drop f ] }
        { many:one [ relation-class class>foreign-key-create ] }
        { many:many [ drop f ] }
        { f [ (column>create-text) ] }
        [ bad-relation-category ]
    } case ;

: find-one:many-columns ( obj -- seq ) lookup-persistent class>> '[
    columns>> [ [ relation-class _ = ] [ relation-category one:many =
    ] bi and ] filter ] map-persistent concat ;

: class>one:many-relations ( class -- string )
    find-one:many-columns
    [ persistent>> class>> class>foreign-key-create ] map ", " join ;

: set-primary-key ( tuple obj -- tuple' )
    over find-primary-key 1 ensure-length
    first setter>> call( tuple obj -- tuple ) ;

/*
: select-joins ( obj -- seq )
    query-shape
    [ nip ] assoc-filter
    [
        {
            [ first relation-class table-name ]
            [ first relation-class table-name ]
            [ first persistent>> primary-key-slots ]
            [ first relation-class table-name ]
            [ first relation-class primary-key-slots ]
        } cleave <left-join>
    ] map ;
*/
