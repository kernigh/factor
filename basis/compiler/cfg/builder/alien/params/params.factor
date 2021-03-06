! Copyright (C) 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: cpu.architecture fry kernel layouts math math.order
namespaces sequences vectors assocs arrays locals ;
IN: compiler.cfg.builder.alien.params

SYMBOL: stack-params

GENERIC: alloc-stack-param ( reg -- n )

M: object alloc-stack-param ( rep -- n )
    stack-params get
    [ rep-size cell align stack-params +@ ] dip ;

M: float-rep alloc-stack-param ( rep -- n )
    stack-params get swap rep-size
    [ cell align stack-params +@ ] keep
    float-right-align-on-stack? [ + ] [ drop ] if ;

: ?dummy-stack-params ( rep -- )
    dummy-stack-params? [ alloc-stack-param drop ] [ drop ] if ;

: ?dummy-int-params ( rep -- )
    dummy-int-params? [
        rep-size cell /i 1 max
        [ int-regs get [ pop* ] unless-empty ] times
    ] [ drop ] if ;

: ?dummy-fp-params ( rep -- )
    drop dummy-fp-params? [ float-regs get [ pop* ] unless-empty ] when ;

GENERIC: next-reg-param ( odd-register? rep -- reg )

M: int-rep next-reg-param
    [ nip ?dummy-stack-params ]
    [ nip ?dummy-fp-params ]
    [ drop [
        int-regs get last even?
        [ int-regs get pop* ] when
    ] when ]
    2tri int-regs get pop ;

M: float-rep next-reg-param
    nip [ ?dummy-stack-params ] [ ?dummy-int-params ] bi
    float-regs get pop ;

M: double-rep next-reg-param
    nip [ ?dummy-stack-params ] [ ?dummy-int-params ] bi
    float-regs get pop ;

:: reg-class-full? ( reg-class odd-register? -- ? )
    reg-class get empty?
    reg-class get length 1 = odd-register? and
    dup [ reg-class get delete-all ] when or ;

: init-reg-class ( abi reg-class -- )
    [ swap param-regs at <reversed> >vector ] keep set ;

: init-regs ( regs -- )
    [ <reversed> >vector swap set ] assoc-each ;

: with-param-regs ( abi quot -- )
    '[ param-regs init-regs 0 stack-params set @ ] with-scope ; inline

SYMBOLS: stack-values reg-values ;

:: next-parameter ( vreg rep on-stack? odd-register? -- )
    vreg rep on-stack?
    [ dup dup reg-class-of odd-register? reg-class-full? ] dip or
    [ alloc-stack-param stack-values ] [ odd-register? swap next-reg-param reg-values ] if
    [ 3array ] dip get push ;

: next-return-reg ( rep -- reg ) reg-class-of get pop ;

: with-return-regs ( quot -- )
    '[ return-regs init-regs @ ] with-scope ; inline
