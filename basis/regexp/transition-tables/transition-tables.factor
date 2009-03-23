! Copyright (C) 2008 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs fry hashtables kernel sequences
vectors locals character-classes ;
IN: regexp.transition-tables

TUPLE: transition-table transitions start-state final-states ;

: <transition-table> ( -- transition-table )
    transition-table new
        H{ } clone >>transitions
        H{ } clone >>final-states ;

: maybe-initialize-key ( key hashtable -- )
    ! Why do we have to do this?
    2dup key? [ 2drop ] [ [ H{ } clone ] 2dip set-at ] if ;

:: (set-transition) ( from to obj hash -- )
    to condition? [ to hash maybe-initialize-key ] unless
    from hash at
    [ [ to obj ] dip set-at ]
    [ to obj associate from hash set-at ] if* ;

: set-transition ( from to obj transition-table -- )
    transitions>> (set-transition) ;

:: (add-transition) ( from to obj hash -- )
    to hash maybe-initialize-key
    from hash at
    [ [ to obj ] dip push-at ]
    [ to 1vector obj associate from hash set-at ] if* ;

: add-transition ( from to obj transition-table -- )
    transitions>> (add-transition) ;

: map-set ( assoc quot -- new-assoc )
    '[ drop @ dup ] assoc-map ; inline

: number-transitions ( transitions numbering -- new-transitions )
    dup '[
        [ _ at ]
        [ [ _ condition-at ] assoc-map ] bi*
    ] assoc-map ;

: transitions-at ( transition-table assoc -- transition-table )
    [ clone ] dip
    [ '[ _ condition-at ] change-start-state ]
    [ '[ [ _ at ] map-set ] change-final-states ]
    [ '[ _ number-transitions ] change-transitions ] tri ;

: expand-one-or ( union transition -- alist )
    [ seq>> ] dip '[ _ 2array ] map ;

: expand-or ( state-transitions -- new-transitions )
    >alist [
        first2 over union?
        [ expand-one-or ] [ 2array 1array ] if
    ] map concat >hashtable ;

: expand-ors ( transition-table -- transition-table )
    [ [ expand-or ] assoc-map ] change-transitions ;
