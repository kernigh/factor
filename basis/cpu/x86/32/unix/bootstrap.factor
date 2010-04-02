! Copyright (C) 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel parser sequences ;
IN: bootstrap.x86

: jit-save-tib ( -- ) ;
: jit-restore-tib ( -- ) ;
: jit-update-tib ( -- ) ;

<< "vocab:cpu/x86/32/bootstrap.factor" parse-file suffix! >>
call
