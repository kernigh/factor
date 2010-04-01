! Copyright (C) 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: bootstrap.image.private cpu.x86.assembler
cpu.x86.assembler.operands kernel layouts namespaces parser
sequences system vocabs ;
IN: bootstrap.x86

: jit-pre-callback-stub ( -- ) ;

: jit-post-callback-stub ( -- ) ;

<< "vocab:cpu/x86/32/bootstrap.factor" parse-file suffix! >>
call
