! Copyright (C) 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: bootstrap.image.private cpu.x86.assembler
cpu.x86.assembler.operands kernel compiler.constants parser
sequences ;
IN: bootstrap.x86

: jit-pre-callback-stub ( -- )
    0 PUSH rc-absolute-cell rt-exception-handler jit-rel
    0 [] FS PUSH
    0 [] FS ESP MOV ;

: jit-post-callback-stub ( -- )
    0 [] FS POP
    ESP 4 ADD ;

<< "vocab:cpu/x86/32/bootstrap.factor" parse-file suffix! >>
call
