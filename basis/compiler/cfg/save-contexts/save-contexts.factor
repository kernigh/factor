! Copyright (C) 2009, 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors locals
compiler.cfg.instructions compiler.cfg.registers
compiler.cfg.rpo cpu.architecture kernel sequences vectors ;
IN: compiler.cfg.save-contexts

! Insert context saves.

GENERIC: needs-save-context? ( insn -- ? )

M: ##unary-float-function needs-save-context? drop t ;
M: ##binary-float-function needs-save-context? drop t ;
M: gc-map-insn needs-save-context? drop t ;
M: insn needs-save-context? drop f ;

:: insert-save-context ( bb -- )
    bb instructions>> [ needs-save-context? ] find drop [
        [
            int-rep next-vreg-rep
            int-rep next-vreg-rep
            \ ##save-context new-insn
        ] dip bb [ insert-nth ] change-instructions drop
    ] when* ;

: insert-save-contexts ( cfg -- cfg' )
    dup [ insert-save-context ] each-basic-block ;
