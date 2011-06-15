! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays f.vocabularies f.words f.manifest kernel f.parser
f.lexer make ;
IN: f.cheat

TUPLE: stack-effect in out ;
C: <stack-effect> stack-effect

TUPLE: fword name stack-effect body ;
C: <fword> fword

TUPLE: fmethod type name body ;
C: <fmethod> fmethod

TUPLE: inline ;
C: <inline> inline

TUPLE: recursive ;
C: <recursive> recursive

TUPLE: flushable ;
C: <flushable> flushable

TUPLE: foldable ;
C: <foldable> foldable

TUPLE: begin-private ;
C: <begin-private> begin-private

TUPLE: end-private ;
C: <end-private> end-private


TUPLE: instance instance mixin ;
C: <instance> instance

! TUPLE: comment text ;
! C: <comment> comment

TUPLE: using vocabularies ;
C: <using> using

TUPLE: unuse vocabulary ;
C: <unuse> unuse

TUPLE: in vocabulary ;
C: <in> in

TUPLE: predicate class superclass body ;
C: <predicate> predicate

TUPLE: mixin mixin ;
C: <mixin> mixin

TUPLE: math name stack-effect ;
C: <math> math

TUPLE: generic name stack-effect ;
C: <generic> generic

TUPLE: generic# name arity stack-effect ;
C: <generic#> generic#

TUPLE: constructor name class ;
C: <constructor> constructor

TUPLE: symbols sequence ;
C: <symbols> symbols

TUPLE: singletons sequence ;
C: <singletons> singletons

TUPLE: error name slots ;
C: <error> error

TUPLE: union class members ;
C: <union> union

TUPLE: slot name ;
C: <slot> slot

TUPLE: fhashtable object ;
C: <fhashtable> fhashtable

TUPLE: farray object ;
C: <farray> farray

TUPLE: fvector object ;
C: <fvector> fvector

TUPLE: fquotation object ;
C: <fquotation> fquotation

TUPLE: fbyte-array object ;
C: <fbyte-array> fbyte-array

TUPLE: fhex object ;
C: <fhex> fhex

TUPLE: literal object ;
C: <literal> literal

TUPLE: qualified vocabulary ;
C: <qualified> qualified

TUPLE: qualified-with vocabulary prefix ;
C: <qualified-with> qualified-with

TUPLE: from vocabulary words ;
C: <from> from

TUPLE: rename word vocabulary new-name ;
C: <rename> rename

TUPLE: exclude vocabulary words ;
C: <exclude> exclude

TUPLE: defer name ;
C: <defer> defer

TUPLE: char ch ;
C: <char> char

TUPLE: tuple name slots ;
C: <tuple> tuple

TUPLE: boa-tuple name slots ;
C: <boa-tuple> boa-tuple

TUPLE: assoc-tuple name slots ;
C: <assoc-tuple> assoc-tuple

: add-parsing-word ( manifest vocab name quot -- manifest )
    <parsing-word> over add-word-to-vocabulary ;

: fake-syntax-vocabulary ( -- vocabulary )
    "syntax" <vocabulary>
        "syntax" "!" [ token-til-eol <line-comment> ] add-parsing-word
        "syntax" "USING:" [ ";" tokens-until <using> ] add-parsing-word
        "syntax" "USE:" [ token 1array <using> ] add-parsing-word
        "syntax" "UNUSE:" [ token <unuse> ] add-parsing-word
        "syntax" "IN:" [ token <in> ] add-parsing-word

        "syntax" "HEX:" [ token <fhex> ] add-parsing-word
        "syntax" "{" [ "}" parse-until <farray> ] add-parsing-word
        "syntax" "}" (( -- )) [ ] <word> over add-word-to-vocabulary
        "syntax" "H{" [ "}" parse-until <fhashtable> ] add-parsing-word
        "syntax" "B{" [ "}" parse-until <fbyte-array> ] add-parsing-word
        "syntax" "V{" [ "}" parse-until <fvector> ] add-parsing-word
        "syntax" "[" (( -- )) [ \ ] parse-until <fquotation> ] <word> over add-word-to-vocabulary
        "syntax" "]" (( -- )) [ ] <word> over add-word-to-vocabulary
        "syntax" ";" (( -- )) [ ] <word> over add-word-to-vocabulary
        "syntax" "--" (( -- )) [ ] <word> over add-word-to-vocabulary
        "syntax" "(" [ "--" tokens-until ")" tokens-until <stack-effect> ] add-parsing-word

        "syntax" "C:" [ token token <constructor> ] add-parsing-word

        "syntax" "MIXIN:" [ token <mixin> ] add-parsing-word
        "syntax" "INSTANCE:" [ token token <instance> ] add-parsing-word

        "syntax" "MATH:" [ token "(" call-parsing-word <math> ] add-parsing-word

        "syntax" "GENERIC:" [ token "(" call-parsing-word <generic> ] add-parsing-word
        "syntax" "GENERIC#" [ token token "(" call-parsing-word <generic#> ] add-parsing-word
        "syntax" ":" [ token "(" call-parsing-word ";" parse-until <fword> ] add-parsing-word
        "syntax" "M:" [ token token ";" parse-until <fmethod> ] add-parsing-word

        "syntax" "PREDICATE:" [ token "<" expect token ";" parse-until <predicate> ]
            add-parsing-word

        "syntax" "SYMBOLS:" [ ";" tokens-until <symbols> ] add-parsing-word
        "syntax" "SYMBOL:" [ token 1array <symbols> ] add-parsing-word

        "syntax" "SINGLETONS:" [ ";" tokens-until <singletons> ] add-parsing-word
        "syntax" "SINGLETON:" [ token 1array <singletons> ] add-parsing-word

        "syntax" "UNION:" [ token ";" tokens-until <union> ] add-parsing-word
        "syntax" "SLOT:" [ token <slot> ] add-parsing-word

        "syntax" "ERROR:" [ token ";" tokens-until <error> ] add-parsing-word

        "syntax" "inline" [ <inline> ] add-parsing-word
        "syntax" "recursive" [ <recursive> ] add-parsing-word
        "syntax" "flushable" [ <flushable> ] add-parsing-word
        "syntax" "foldable" [ <foldable> ] add-parsing-word
        "syntax" "<PRIVATE" [ <begin-private> ] add-parsing-word
        "syntax" "PRIVATE>" [ <end-private> ] add-parsing-word

        "syntax" "\\" [ token <literal> ] add-parsing-word
        "syntax" "FROM:" [ token "=>" expect ";" tokens-until <from> ] add-parsing-word
        "syntax" "EXCLUDE:" [ token "=>" expect ";" tokens-until <exclude> ] add-parsing-word
        "syntax" "RENAME:" [ token token "=>" expect token <rename> ] add-parsing-word
        "syntax" "QUALIFIED:" [ token <qualified> ] add-parsing-word
        "syntax" "QUALIFIED-WITH:" [ token token <qualified-with> ] add-parsing-word

        "syntax" "DEFER:" [ token <defer> ] add-parsing-word
        "syntax" "CHAR:" [ chunk <char> ] add-parsing-word

        "syntax" "TUPLE:" [
            token 
            [
                [
                    token
                    dup ";" = [
                        drop f
                    ] [
                        dup "{" = [
                            drop "}" tokens-until ,
                        ] [
                            ,
                        ] if t
                    ] if
                ] loop
            ] { } make <tuple>
        ] add-parsing-word

        "syntax" "T{" [
            token
            peek-token "f" = [
                token drop
                ";" parse-until <boa-tuple>
            ] [
                [
                    [
                        token dup "}" = [
                            drop f
                        ] [
                            "{" = [
                                "}" tokens-until , t
                            ] [
                                "bad tuple" throw
                            ] if
                        ] if
                    ] loop
                ] { } make <assoc-tuple>
            ] if
        ] add-parsing-word
    ;

M: object preload-manifest ( manifest -- manifest )
    fake-syntax-vocabulary over add-vocabulary-to-manifest ;
