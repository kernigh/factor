! Copyright (C) 2008, 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs arrays layouts math math.order
math.parser combinators combinators.short-circuit fry make
sequences sequences.generalizations alien alien.private
alien.strings alien.c-types alien.libraries classes.struct
namespaces kernel strings libc locals quotations words
cpu.architecture compiler.utilities compiler.tree compiler.cfg
compiler.cfg.builder compiler.cfg.builder.alien.params
compiler.cfg.builder.alien.boxing compiler.cfg.builder.blocks
compiler.cfg.instructions compiler.cfg.stack-frame
compiler.cfg.stacks compiler.cfg.stacks.local
compiler.cfg.registers compiler.cfg.hats ;
FROM: compiler.errors => no-such-symbol no-such-library ;
IN: compiler.cfg.builder.alien

: unbox-parameters ( parameters -- vregs reps )
    [
        [ length iota <reversed> ] keep
        [ [ <ds-loc> peek-loc ] [ base-type ] bi* unbox-parameter ]
        2 2 mnmap [ concat ] bi@
    ]
    [ length neg inc-d ] bi ;

: prepare-struct-caller ( vregs reps return -- vregs' reps' return-vreg/f )
    dup large-struct? [
        heap-size cell f ^^local-allot [
            '[ _ prefix ]
            [ int-rep struct-return-on-stack? 2array prefix ] bi*
        ] keep
    ] [ drop f ] if ;

: caller-parameter ( vreg rep on-stack? -- insn )
    [ dup reg-class-of reg-class-full? ] dip or
    [ [ alloc-stack-param ] keep \ ##store-stack-param new-insn ]
    [ [ next-reg-param ] keep \ ##store-reg-param new-insn ]
    if ;

: (caller-parameters) ( vregs reps -- )
    ! Place ##store-stack-param instructions first. This ensures
    ! that no registers are used after the ##store-reg-param
    ! instructions.
    [ first2 caller-parameter ] 2map
    [ ##store-stack-param? ] partition [ % ] bi@ ;

: caller-parameters ( params -- stack-size )
    [ abi>> ] [ parameters>> ] [ return>> ] tri
    '[ 
        _ unbox-parameters
        _ prepare-struct-caller struct-return-area set
        (caller-parameters)
        stack-params get
        struct-return-area get
    ] with-param-regs
    struct-return-area set ;

: box-return* ( node -- )
    return>> [ ] [ base-type box-return ds-push ] if-void ;

GENERIC# dlsym-valid? 1 ( symbols dll -- ? )

M: string dlsym-valid? dlsym ;

M: array dlsym-valid? '[ _ dlsym ] any? ;

: check-dlsym ( symbols dll -- )
    dup dll-valid? [
        dupd dlsym-valid?
        [ drop ] [ cfg get word>> no-such-symbol ] if
    ] [ dll-path cfg get word>> no-such-library drop ] if ;

: decorated-symbol ( params -- symbols )
    [ function>> ] [ parameters>> [ stack-size ] map-sum number>string ] bi
    {
        [ drop ]
        [ "@" glue ]
        [ "@" glue "_" prepend ]
        [ "@" glue "@" prepend ]
    } 2cleave
    4array ;

: alien-invoke-dlsym ( params -- symbols dll )
    [ dup abi>> callee-cleanup? [ decorated-symbol ] [ function>> ] if ]
    [ library>> load-library ]
    bi 2dup check-dlsym ;

: emit-stack-frame ( stack-size params -- )
    [ [ return>> ] [ abi>> ] bi stack-cleanup ##cleanup ]
    [ drop ##stack-frame ]
    2bi ;

M: #alien-invoke emit-node
    params>>
    {
        [ caller-parameters ]
        [ ##prepare-var-args alien-invoke-dlsym <gc-map> ##alien-invoke ]
        [ emit-stack-frame ]
        [ box-return* ]
    } cleave ;

M: #alien-indirect emit-node ( node -- )
    params>>
    [
        ds-pop ^^unbox-any-c-ptr
        [ caller-parameters ] dip
        <gc-map> ##alien-indirect
    ]
    [ emit-stack-frame ]
    [ box-return* ]
    tri ;

M: #alien-assembly emit-node
    params>> {
        [ caller-parameters ]
        [ quot>> ##alien-assembly ]
        [ emit-stack-frame ]
        [ box-return* ]
    } cleave ;

: callee-parameter ( rep on-stack? -- dst insn )
    [ next-vreg dup ] 2dip
    [ dup reg-class-of reg-class-full? ] dip or
    [ [ alloc-stack-param ] keep \ ##load-stack-param new-insn ]
    [ [ next-reg-param ] keep \ ##load-reg-param new-insn ]
    if ;

: prepare-struct-callee ( c-type -- vreg )
    large-struct?
    [ int-rep struct-return-on-stack? callee-parameter , ] [ f ] if ;

: (callee-parameters) ( params -- vregs reps )
    [ flatten-parameter-type ] map
    [
        [ [ first2 callee-parameter ] 1 2 mnmap ] 1 2 mnmap
        concat [ ##load-reg-param? ] partition [ % ] bi@
    ]
    [ [ keys ] map ]
    bi ;

: box-parameters ( vregs reps params -- )
    ##begin-callback [ box-parameter ds-push ] 3each ;

: callee-parameters ( params -- stack-size )
    [ abi>> ] [ return>> ] [ parameters>> ] tri
    '[ 
        _ prepare-struct-callee struct-return-area set
        _ [ base-type ] map [ (callee-parameters) ] [ box-parameters ] bi
        stack-params get
        struct-return-area get
    ] with-param-regs
    struct-return-area set ;

: callback-stack-cleanup ( stack-size params -- )
    [ nip xt>> ] [ [ return>> ] [ abi>> ] bi stack-cleanup ] 2bi
    "stack-cleanup" set-word-prop ;

: needs-frame-pointer ( -- )
    cfg get t >>frame-pointer? drop ;

M: #alien-callback emit-node
    params>> dup xt>> dup
    [
        needs-frame-pointer

        begin-word

        {
            [ callee-parameters ]
            [
                [
                    make-kill-block
                    quot>> ##alien-callback
                ] emit-trivial-block
            ]
            [
                return>> [ ##end-callback ] [
                    [ ds-pop ] dip
                    ##end-callback
                    base-type unbox-return
                ] if-void
            ]
            [ callback-stack-cleanup ]
        } cleave

        end-word
    ] with-cfg-builder ;
