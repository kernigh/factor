! Copyright (C) 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: byte-arrays fry make io io.encodings.binary io.encodings.utf8 io.files
io.streams.byte-array peg peg.ebnf sequences kernel strings
math math.parser cpu.x86.assembler.private cpu.x86.assembler.operands
cpu.x86.assembler.operands.private parser lexer arrays
math.order combinators accessors assocs words effects
combinators.short-circuit ;
IN: cpu.x86.new-assembler.parser

: read-insns ( -- lines )
    "vocab:cpu/x86/new-assembler/insns.dat" utf8 file-lines ;

TUPLE: insn name operands opcode availability ;

C: <insn> insn

EBNF: parse-line

WhitespaceChar = (' ' | '\t')
Whitespace = WhitespaceChar+
MaybeWhitespace = WhitespaceChar*

Comment = MaybeWhitespace ';' .*

NameChar = !(WhitespaceChar | ',').
Name = NameChar+ => [[ >string ]]

Ignore = 'ignore' => [[ f ]]

Void = "void" => [[ { } ]]

CommaList = Name:x (',' Name:xs => [[ xs ]])*:xs => [[ xs x prefix ]]

Operands = Ignore | Void | CommaList

HexOpcodeByte = 'x' ([0-9a-fA-F]+:digits) => [[ digits >string hex> ]]
OctalOpcodeByte = ([0-7]+:digits) => [[ digits >string oct> ]]

OpcodeByte = '\\' (HexOpcodeByte | OctalOpcodeByte):value => [[ value ]]

OpcodeBytes = OpcodeByte+ => [[ >byte-array ]]

FancyOpcode = '[' (!(']').)+ ']'

Opcode = Ignore | FancyOpcode | OpcodeBytes

Availability = Ignore | CommaList

Instruction = MaybeWhitespace
    Name:name Whitespace
    Operands:operands Whitespace
    Opcode:opcode Whitespace
    Availability:availability
    MaybeWhitespace
    => [[ name operands opcode availability <insn> ]]

Line = (Comment | Instruction | MaybeWhitespace) !(.)

;EBNF

: mem-offs? ( obj -- ? )
    dup indirect? [
        {
            [ base>> not ]
            [ index>> not ]
            [ scale>> not ]
            [ displacement>> integer? ]
        } 1&&
    ] [ drop f ] if ;

: indirect-or? ( obj quot -- ? )
    over indirect? [ 2drop t ] [ call ] if ; inline

: operand-pred ( str -- quot )
    {
        { "fpu0" [ ST0 = ] }
        { "fpureg" [ register-80? ] }
        { "imm" [ integer? ] }
        { "imm16" [ integer? ] }
        { "imm32" [ integer? ] }
        { "imm64" [ integer? ] }
        { "imm8" [ integer? ] }
        { "mem" [ indirect? ] }
        { "mem128" [ indirect? ] }
        { "mem16" [ indirect? ] }
        { "mem256" [ indirect? ] }
        { "mem32" [ indirect? ] }
        { "mem64" [ indirect? ] }
        { "mem8" [ indirect? ] }
        { "mem80" [ indirect? ] }
        { "mem_offs" [ mem-offs? ] }
        { "reg16" [ register-16? ] }
        { "reg32" [ register-32? ] }
        { "reg32na" [ { [ register-32? ] [ EAX = not ] } 1&& ] }
        { "reg64" [ register-64? ] }
        { "reg8" [ register-8? ] }
        { "reg_al" [ AL = ] }
        { "reg_ax" [ AX = ] }
        { "reg_cl" [ CL = ] }
        { "reg_cx" [ CX = ] }
        { "reg_dx" [ DX = ] }
        { "reg_eax" [ EAX = ] }
        { "reg_ecx" [ ECX = ] }
        { "reg_edx" [ EDX = ] }
        { "reg_rax" [ RAX = ] }
        { "reg_rcx" [ RCX = ] }
        { "rm16" [ [ register-16? ] indirect-or? ] }
        { "rm32" [ [ register-32? ] indirect-or? ] }
        { "rm64" [ [ register-64? ] indirect-or? ] }
        { "rm8" [ [ register-8? ] indirect-or? ] }
        { "unity" [ 1 = ] }
        { "xmm0" [ XMM0 = ] }
        { "xmmreg" [ register-128? ] }
        { "xmmrm" [ [ register-128? ] indirect-or? ] }
    } at [ drop f ] or ;

: operand-preds ( operands -- quot: ( operands -- ? ) )
    [ swap operand-pred '[ _ swap nth @ ] ] map-index '[ _ 1&& ] ;

: literal-bytes ( n -- quot )
    read '[ _ % drop ] ;

: add-literal-byte ( n -- quot )
    read1 '[ _ swap nth reg-code _ + , ] ;

: immediate-byte ( n -- quot )
    '[ _ swap nth , ] ;

: immediate-word ( n -- quot )
    '[ _ swap nth 2, ] ;

: immediate-byte/word ( n -- quot )
    ! XXX
    ;

: immediate-dword ( n -- quot )
    '[ _ swap nth 4, ] ;

: 8, ( n -- ) 8 n, ; inline

: immediate-qword ( n -- quot )
    '[ _ swap nth 8, ] ;

: immediate-word/dword ( n -- quot )
    ! XXX
    ;

: immediate-word/dword/qword ( n -- quot )
    ! XXX
    ;

: compute-mod-r/m ( a b -- quot )
    '[ [ _ swap nth ] [ _ swap nth ] bi addressing ] ;

<<

SYNTAX: 4{
    4 iota scan-object scan-object "}" expect
    '[ [ _ + ] [ _ curry ] bi 2array ] map append! ;

>>

: opcode-quot ( code -- quot: ( operands -- ) )
    {
        {
            [ dup OCT: 100 OCT: 144 between? ]
            [ [ -3 shift OCT: 7 bitand ] [ OCT: 7 bitand ] bi compute-mod-r/m ]
        }
        [
            {
                4{ OCT: 1 [ 1 + literal-bytes ] }
                ! 5, 6, 7
                4{ OCT: 10 [ add-literal-byte ] }
                4{ OCT: 14 [ immediate-byte ] }
                4{ OCT: 20 [ immediate-byte ] }
                4{ OCT: 24 [ immediate-byte ] }
                4{ OCT: 30 [ immediate-word ] }
                4{ OCT: 34 [ immediate-byte/word ] }
                4{ OCT: 40 [ immediate-dword ] }
                4{ OCT: 44 [ immediate-word/dword/qword ] }
                4{ OCT: 50 [ immediate-byte ] }
                4{ OCT: 54 [ immediate-qword ] }
                4{ OCT: 60 [ immediate-word ] }
                4{ OCT: 64 [ immediate-word/dword ] }
                4{ OCT: 70 [ immediate-dword ] }
                ! 74, 75, 76, 77
            } case
        ]
    } cond ;

: opcodes-quot ( opcode -- quot: ( operands -- ) )
    binary
    [ [ read1 dup { f 0 } member-eq? not ] [ opcode-quot ] produce nip ]
    with-byte-reader ;

: create-insn-word ( name arity/f -- word )
    [ number>string append ] when* "cpu.x86.new-assembler" create ;

: variants-quot ( variants -- quot )
    [ operands>> operand-preds [ ] 2array ] map '[ _ cond ] ;

: insn-effect ( variants -- effect )
    first operands>> length { "a" "b" "c" "d" "e" } swap head { } <effect> ;

: define-insn-word ( name arity/f variants -- )
    [ create-insn-word ] dip [ variants-quot ] [ insn-effect ] bi
    define-declared ;

: group-by-arity ( variants -- assoc )
    H{ } clone [ '[ dup operands>> length _ push-at ] each ] keep ;

: define-insn-words ( name variants -- )
    group-by-arity [ >alist ] [ assoc-size 1 = ] bi
    [ first second [ f ] dip define-insn-word ]
    [ [ first2 define-insn-word ] with each ]
    if ;

: group-by-name ( insns -- assoc )
    H{ } clone [ '[ dup name>> _ push-at ] each ] keep ;

: parse-insns ( lines -- insns )
    [ parse-line ] map
    [ insn? ] filter
    [ operands>> ] filter ;

: define-insns ( insns -- )
    group-by-name [ define-insn-words ] assoc-each ;
