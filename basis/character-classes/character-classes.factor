! Copyright (C) 2009 Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel math math.order words combinators locals
combinators.short-circuit sequences classes.predicate
fry arrays assocs classes classes.parser parser
hints interval-sets generalizations quotations ;
QUALIFIED: sets
IN: character-classes

: <range-class> ( from to -- range )
    2array 1array <interval-set> ;

GENERIC: class-member? ( char class -- ? )

HINTS: class-member? { fixnum object } ;

M: object class-member? 2drop f ;

M: t class-member? ( obj class -- ? ) 2drop t ;

M: f class-member? 2drop f ;

M: integer class-member? ( obj class -- ? ) = ;

M: interval-set class-member? in? ;

: word-category ( word -- category )
    "character-class" word-prop ;

PREDICATE: category-word < word word-category ;

M: category-word class-member?
    word-category class-member? ;

TUPLE: delay-class { class read-only } ;
C: <delay-class> delay-class

M: delay-class class-member?
    class>> class-member? ;

TUPLE: quot-class { values sequence read-only } { quot quotation read-only } ;
C: <quot-class> quot-class

M: quot-class class-member?
    [ quot>> call( char -- value ) ] [ values>> ] bi member? ;

TUPLE: not-class { class read-only } ;

M: not-class class-member?
    class>> class-member? not ;

GENERIC: <not> ( class -- inverse )
M: object <not> not-class boa ;
M: not-class <not> class>> ;
M: t <not> drop f ;
M: f <not> drop t ;
M: interval-set <not> HEX: 10FFFF <interval-not> ;

TUPLE: union { seq read-only } ;

M: union class-member?
    seq>> [ class-member? ] with any? ;

<PRIVATE

PREDICATE: not-integer < not-class class>> integer? ;

PREDICATE: not-quot-class < not-class class>> quot-class? ;

PREDICATE: not-or < not-class class>> union? ;

DEFER: substitute

: flatten ( seq -- newseq )
    [ dup union? [ seq>> ] [ 1array ] if ] { } map-as concat ; inline

: seq>union ( seq -- instance )
    dup length {
        { 0 [ drop f ] }
        { 1 [ first ] }
        [ drop { } like union boa ]
    } case ;

: filter-integers ( partition -- partition' )
    [ integer? ] partition
    [ union boa '[ _ class-member? not ] filter ] keep append ;

: answer-not-ors ( partition -- partition' )
    [ not-or? ] partition
    [ '[ _ [ f substitute ] each ] map ] keep append ;

: tautology? ( seq -- ? )
    {
        [ t swap member? ]
        [ [ not-class? ] partition [ [ class>> ] map ] dip sets:intersects? ]
    } 1|| ;

: unify-intervals ( intervals sequence -- intervals sequence )
    swap [ { } ] [
        [ [ integer? not ] partition ] dip swap
        <interval-set> [ <interval-or> ] reduce 1array
    ] if-empty swap ;

: partition-quots ( quot-classes -- quot-class-sets )
    H{ } clone [
        '[ dup quot>> _ push-at ] each
    ] keep ;

: combine-quots ( quot quot-class-set connector -- quot-class )
    [ [ values>> ] map unclip ] dip reduce swap <quot-class> ; inline

: unify-quots ( quot-classes -- quot-classes' )
    partition-quots [ [ sets:union ] combine-quots ] { } assoc>map ;

: unify-not-quots ( quot-classes -- quot-classes' )
    [ class>> ] map partition-quots
    [ [ sets:intersect ] combine-quots ] { } assoc>map
    [ values>> empty? not ] filter
    [ <not> ] map ;

: consolidate ( seq -- seq' )
    [ interval-set? ] partition unify-intervals
    [ quot-class? ] partition [ unify-quots ] dip
    [ not-quot-class? ] partition [ unify-not-quots ] dip
    4 nappend ;

: make-union ( partition -- intersection )
    answer-not-ors
    f swap remove
    dup tautology?
    [ drop t ] [
        filter-integers sets:prune
        consolidate seq>union
    ] if ;

PRIVATE>

: <union> ( seq -- class )
    flatten sets:prune { } like
    [ not-integer? ] partition swap dup length {
        { 0 [ drop make-union ] }
        { 1 [
            first [ class>> '[ _ swap class-member? ] any? ] keep or
        ] }
        [ 3drop t ]
    } case ;

: <or> ( class1 class2 -- class )
    2array <union> ;

: <intersection> ( seq -- class )
    [ <not> ] map <union> <not> ;

: <and> ( a b -- class )
    2array <intersection> ;

: <minus> ( a b -- a-b )
    <not> <and> ;

: <sym-diff> ( a b -- a~b )
    [ <or> ] [ <and> ] 2bi <minus> ;

<PRIVATE

GENERIC# answer 2 ( class from to -- new-class )

M:: object answer ( class from to -- new-class )
    class from = to class ? ;

: replace-compound ( class from to -- seq )
    [ seq>> ] 2dip '[ _ _ answer ] map ;

M: union answer
    replace-compound <union> ;

M: not-class answer
    [ class>> ] 2dip answer <not> ;

PRIVATE>

GENERIC# substitute 1 ( class from to -- new-class )
M: object substitute answer ;
M: not-class substitute [ <not> ] bi@ answer ;

<PRIVATE

GENERIC: fully-evaluate ( class -- class' )
M: object fully-evaluate ;
M: category-word fully-evaluate word-category ;
M: delay-class fully-evaluate class>> fully-evaluate ;
M: not-class fully-evaluate class>> fully-evaluate <not> ;
M: union fully-evaluate seq>> [ fully-evaluate ] map <union> ;

PRIVATE>

: define-category ( word definition -- )
    fully-evaluate
    [ "character-class" set-word-prop ]
    [ '[ _ class-member? ] integer swap define-predicate-class ] 2bi ;

SYNTAX: CATEGORY:
    CREATE-CLASS parse-definition call( -- class ) define-category ;
