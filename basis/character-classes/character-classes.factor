! Copyright (C) 2009 Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel math math.order words combinators locals
ascii combinators.short-circuit sequences classes.predicate
fry macros arrays assocs sets classes mirrors unicode.script
classes.parser parser ;
IN: character-classes

TUPLE: range-class from to ;
C: <range-class> range-class

GENERIC: class-member? ( obj class -- ? )

<PRIVATE

M: t class-member? ( obj class -- ? ) 2drop t ;

M: word class-member? "character-class" word-prop class-member? ;

M: integer class-member? ( obj class -- ? ) = ;

M: range-class class-member? ( obj class -- ? )
    [ from>> ] [ to>> ] bi between? ;

M: f class-member? 2drop f ;

PRIVATE>

TUPLE: not-class class ;

MIXIN: simple-class
INSTANCE: range-class simple-class

<PRIVATE

PREDICATE: not-integer < not-class class>> integer? ;

PREDICATE: not-simple < not-class class>> simple-class? ;

PRIVATE>

M: not-class class-member?
    class>> class-member? not ;

TUPLE: union seq ;

M: union class-member?
    seq>> [ class-member? ] with any? ;

TUPLE: intersection seq ;

M: intersection class-member?
    seq>> [ class-member? ] with all? ;

<PRIVATE

DEFER: substitute

: flatten ( seq class -- newseq )
    '[ dup _ instance? [ seq>> ] [ 1array ] if ] map concat ; inline

:: seq>instance ( seq empty class -- instance )
    seq length {
        { 0 [ empty ] }
        { 1 [ seq first ] }
        [ drop class new seq { } like >>seq ]
    } case ; inline

TUPLE: class-partition integers not-integers simples not-simples and or other ;

: partition-classes ( seq -- class-partition )
    prune
    [ integer? ] partition
    [ not-integer? ] partition
    [ simple-class? ] partition
    [ not-simple? ] partition
    [ intersection? ] partition
    [ union? ] partition
    class-partition boa ;

: class-partition>seq ( class-partition -- seq )
    make-mirror values concat ;

: repartition ( partition -- partition' )
    ! This could be made more efficient; only and and or are effected
    class-partition>seq partition-classes ;

: filter-not-integers ( partition -- partition' )
    dup
    [ simples>> ] [ not-simples>> ] [ or>> ] tri
    3append intersection boa
    '[ [ class>> _ class-member? ] filter ] change-not-integers ;

: answer-ors ( partition -- partition' )
    dup [ not-integers>> ] [ not-simples>> ] [ simples>> ] tri 3append
    '[ [ _ [ t substitute ] each ] map ] change-or ;

: contradiction? ( partition -- ? )
    {
        [ [ simples>> ] [ not-simples>> ] bi intersects? ]
        [ other>> f swap member? ]
    } 1|| ;

: make-intersection ( partition -- intersection )
    answer-ors repartition
    [ t swap remove ] change-other
    dup contradiction?
    [ drop f ]
    [ filter-not-integers class-partition>seq prune t intersection seq>instance ] if ;

: read-words ( seq -- seq' )
    [ dup word? [ dup "character-class" word-prop swap or ] when ] map ;

PRIVATE>

: <intersection> ( seq -- class )
    { } like read-words
    dup intersection flatten partition-classes
    dup integers>> length {
        { 0 [ nip make-intersection ] }
        { 1 [ integers>> first [ '[ _ swap class-member? ] all? ] keep and ] }
        [ 3drop f ]
    } case ;

: <and> ( a b -- class )
    2array <intersection> ;

<PRIVATE

: filter-integers ( partition -- partition' )
    dup
    [ simples>> ] [ not-simples>> ] [ and>> ] tri
    3append union boa
    '[ [ _ class-member? not ] filter ] change-integers ;

: answer-ands ( partition -- partition' )
    dup [ integers>> ] [ not-simples>> ] [ simples>> ] tri 3append
    '[ [ _ [ f substitute ] each ] map ] change-and ;

: tautology? ( partition -- ? )
    {
        [ [ simples>> ] [ not-simples>> ] bi intersects? ]
        [ other>> t swap member? ]
    } 1|| ;

: make-union ( partition -- intersection )
    answer-ands repartition
    [ f swap remove ] change-other
    dup tautology?
    [ drop t ]
    [ filter-integers class-partition>seq prune f union seq>instance ] if ;

PRIVATE>

: <union> ( seq -- class )
    { } like read-words
    dup union flatten partition-classes
    dup not-integers>> length {
        { 0 [ nip make-union ] }
        { 1 [
            not-integers>> first
            [ class>> '[ _ swap class-member? ] any? ] keep or
        ] }
        [ 3drop t ]
    } case ;

: <or> ( a b -- or-class )
    2array <union> ;

GENERIC: <not> ( class -- inverse )

M: object <not>
    not-class boa ;

M: not-class <not>
    class>> ;

M: intersection <not>
    seq>> [ <not> ] map <union> ;

M: union <not>
    seq>> [ <not> ] map <intersection> ;

M: t <not> drop f ;
M: f <not> drop t ;

: <minus> ( a b -- a-b )
    <not> <and> ;

: <sym-diff> ( a b -- a~b )
    [ <or> ] [ <and> ] 2bi <minus> ;

TUPLE: condition question yes no ;
C: <condition> condition

GENERIC# answer 2 ( class from to -- new-class )

<PRIVATE

M:: object answer ( class from to -- new-class )
    class from = to class ? ;

: replace-compound ( class from to -- seq )
    [ seq>> ] 2dip '[ _ _ answer ] map ;

M: intersection answer
    replace-compound <intersection> ;

M: union answer
    replace-compound <union> ;

M: not-class answer
    [ class>> ] 2dip answer <not> ;

GENERIC# substitute 1 ( class from to -- new-class )
M: object substitute answer ;
M: not-class substitute [ <not> ] bi@ answer ;

PRIVATE>

: assoc-answer ( table question answer -- new-table )
    '[ _ _ substitute ] assoc-map
    [ nip ] assoc-filter ;

: assoc-answers ( table questions answer -- new-table )
    '[ _ assoc-answer ] each ;

<PRIVATE

DEFER: make-condition

: (make-condition) ( table questions question -- condition )
    [ 2nip ]
    [ swap [ t assoc-answer ] dip make-condition ]
    [ swap [ f assoc-answer ] dip make-condition ] 3tri
    2dup = [ 2nip ] [ <condition> ] if ;

: make-condition ( table questions -- condition )
    [ keys ] [ unclip (make-condition) ] if-empty ;

GENERIC: class>questions ( class -- questions )
: compound-questions ( class -- questions ) seq>> [ class>questions ] gather ;
M: union class>questions compound-questions ;
M: intersection class>questions compound-questions ;
M: not-class class>questions class>> class>questions ;
M: object class>questions 1array ;

: table>questions ( table -- questions )
    values [ class>questions ] gather >array t swap remove ;

PRIVATE>

: table>condition ( table -- condition )
    ! input table is state => class
    >alist dup table>questions make-condition ;

: condition-map ( condition quot: ( obj -- obj' ) -- new-condition ) 
    over condition? [
        [ [ question>> ] [ yes>> ] [ no>> ] tri ] dip
        '[ _ condition-map ] bi@ <condition>
    ] [ call ] if ; inline recursive

: condition-states ( condition -- states )
    dup condition? [
        [ yes>> ] [ no>> ] bi
        [ condition-states ] bi@ append prune
    ] [ 1array ] if ;

: condition-at ( condition assoc -- new-condition )
    '[ _ at ] condition-map ;

: define-category ( word definition -- )
    [ "character-class" set-word-prop ]
    [ '[ _ class-member? ] integer swap define-predicate-class ] 2bi ;

: CATEGORY:
    CREATE-CLASS parse-definition call( -- class ) define-category ; parsing
