! Copyright (C) 2008, 2009 Doug Coleman, Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs grouping kernel locals math namespaces
sequences fry quotations math.order vectors
regexp.transition-tables words sets hashtables
regexp.ast ;
IN: regexp.nfa

SYMBOL: state

: next-state ( -- state )
    state [ get ] [ inc ] bi ;

SYMBOL: nfa-table

GENERIC: nfa-node ( node -- start-state end-state )

M: object nfa-node
    [ next-state next-state 2dup ] dip
    nfa-table get add-transition ;

: epsilon-transition ( source target -- )
    epsilon nfa-table get add-transition ;

M:: star nfa-node ( node -- start end )
    node term>> nfa-node :> s1 :> s0
    next-state :> s2
    next-state :> s3
    s1 s0 epsilon-transition
    s2 s0 epsilon-transition
    s2 s3 epsilon-transition
    s1 s3 epsilon-transition
    s2 s3 ;

M: concatenation nfa-node ( node -- start end )
    [ first>> ] [ second>> ] bi
    [ nfa-node ] bi@
    [ epsilon-transition ] dip ;

:: alternate-nodes ( s0 s1 s2 s3 -- start end )
    next-state :> s4
    next-state :> s5
    s4 s0 epsilon-transition
    s4 s2 epsilon-transition
    s1 s5 epsilon-transition
    s3 s5 epsilon-transition
    s4 s5 ;

M: alternation nfa-node ( node -- start end )
    [ first>> ] [ second>> ] bi
    [ nfa-node ] bi@
    alternate-nodes ;

: construct-nfa ( ast -- nfa-table )
    [
        0 state set
        <transition-table> nfa-table set
        nfa-node
        nfa-table get
            swap dup associate >>final-states
            swap >>start-state
    ] with-scope ;
