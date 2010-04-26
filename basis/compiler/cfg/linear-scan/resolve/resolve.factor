! Copyright (C) 2009, 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs combinators
combinators.short-circuit fry kernel locals namespaces
make math sequences hashtables
cpu.architecture
compiler.cfg
compiler.cfg.rpo
compiler.cfg.liveness
compiler.cfg.registers
compiler.cfg.utilities
compiler.cfg.instructions
compiler.cfg.predecessors
compiler.cfg.parallel-copy
compiler.cfg.linear-scan.assignment
compiler.cfg.linear-scan.allocation.state ;
IN: compiler.cfg.linear-scan.resolve

TUPLE: location
{ reg read-only }
{ rep read-only }
{ reg-class read-only } ;

: <location> ( reg rep -- location )
    dup reg-class-of location boa ;

M: location equal?
    over location? [
        { [ [ reg>> ] bi@ = ] [ [ reg-class>> ] bi@ = ] } 2&&
    ] [ 2drop f ] if ;

M: location hashcode*
    reg>> hashcode* ;

SYMBOL: spill-temps

: spill-temp ( rep -- n )
    spill-temps get [ next-spill-slot ] cache ;

: add-mapping ( from to rep -- )
    '[ _ <location> ] bi@ 2array , ;

:: resolve-value-data-flow ( bb to vreg -- )
    vreg bb vreg-at-end
    vreg to vreg-at-start
    2dup = [ 2drop ] [ vreg rep-of add-mapping ] if ;

: compute-mappings ( bb to -- mappings )
    dup live-in dup assoc-empty? [ 3drop f ] [
        [ keys [ resolve-value-data-flow ] with with each ] { } make
    ] if ;

: memory->register ( from to -- )
    swap [ reg>> ] [ [ rep>> ] [ reg>> ] bi ] bi* _reload ;

: register->memory ( from to -- )
    [ [ reg>> ] [ rep>> ] bi ] [ reg>> ] bi* _spill ;

: temp->register ( from to -- )
    nip [ reg>> ] [ rep>> ] [ rep>> spill-temp ] tri _reload ;

: register->temp ( from to -- )
    drop [ [ reg>> ] [ rep>> ] bi ] [ rep>> spill-temp ] bi _spill ;

: register->register ( from to -- )
    swap [ reg>> ] [ [ reg>> ] [ rep>> ] bi ] bi* ##copy ;

SYMBOL: temp

: >insn ( from to -- )
    {
        { [ over temp eq? ] [ temp->register ] }
        { [ dup temp eq? ] [ register->temp ] }
        { [ over reg>> spill-slot? ] [ memory->register ] }
        { [ dup reg>> spill-slot? ] [ register->memory ] }
        [ register->register ]
    } cond ;

: mapping-instructions ( alist -- insns )
    [ swap ] H{ } assoc-map-as
    [ temp [ swap >insn ] parallel-mapping ] { } make ;

: perform-mappings ( bb to mappings -- )
    dup empty? [ 3drop ] [
        mapping-instructions insert-simple-basic-block
        cfg get cfg-changed drop
    ] if ;

: resolve-edge-data-flow ( bb to -- )
    2dup compute-mappings perform-mappings ;

: resolve-block-data-flow ( bb -- )
    dup successors>> [ resolve-edge-data-flow ] with each ;

: resolve-data-flow ( cfg -- )
    needs-predecessors

    H{ } clone spill-temps set
    [ resolve-block-data-flow ] each-basic-block ;
