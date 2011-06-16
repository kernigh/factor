! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays f.vocabularies f.words kernel f.parser
f.lexer make sequences ;
IN: f.cheat

TUPLE: main name ;
C: <main> main

TUPLE: stack-effect in out ;
C: <stack-effect> stack-effect

TUPLE: fword name stack-effect body ;
C: <fword> fword

TUPLE: local-fword name stack-effect body ;
C: <local-fword> local-fword

TUPLE: fmethod type name stack-effect body ;
C: <fmethod> fmethod

TUPLE: local-fmethod type name stack-effect body ;
C: <local-fmethod> local-fmethod

TUPLE: macro name stack-effect body ;
C: <macro> macro

TUPLE: local-macro name stack-effect body ;
C: <local-macro> local-macro

TUPLE: hook name variable stack-effect ;
C: <hook> hook

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

TUPLE: function-alias alias return name parameters ;
C: <function-alias> function-alias

TUPLE: function return name parameters ;
C: <function> function

TUPLE: struct name slots ;
C: <struct> struct

TUPLE: gl-function return name obj parameters ;
C: <gl-function> gl-function

TUPLE: callback return name parameters ;
C: <callback> callback

TUPLE: typedef old new ;
C: <typedef> typedef

TUPLE: ctype name ;
C: <ctype> ctype

TUPLE: alias new old ;
C: <alias> alias

TUPLE: library name ;
C: <library> library

TUPLE: parse-time code ;
C: <parse-time> parse-time

TUPLE: constant name value ;
C: <constant> constant

TUPLE: syntax name body ;
C: <syntax> syntax

TUPLE: functor-syntax name body ;
C: <functor-syntax> functor-syntax

: add-parsing-word ( manifest vocab name quot -- manifest )
    <parsing-word> over add-word-to-vocabulary ;

: function-parameters ( -- seq )
    "(" expect
    [
        [
            peek-token ")" = [
                token drop
                ";" expect f
            ] [
                token token 2array , t
            ] if
        ] loop
    ] { } make ;

: stack-effect ( -- stack-effect )
    "(" expect "--" tokens-until ")" tokens-until <stack-effect> ;

: optional-stack-effect ( -- stack-effect/f )
    peek-token "(" = [ stack-effect ] [ f ] if ;

: fake-syntax-vocabulary ( -- vocabulary )
    "syntax" <vocabulary>
        "syntax" "!" [ token-til-eol <line-comment> ] add-parsing-word
        "syntax" "USING:" [
            ";" tokens-until dup [ add-search-vocabulary ] each <using>
        ] add-parsing-word
        "syntax" "USE:" [ parse-use 1array <using> ] add-parsing-word
        "syntax" "UNUSE:" [ parse-unuse <unuse> ] add-parsing-word
        "syntax" "IN:" [ parse-in <in> ] add-parsing-word

        "syntax" "HEX:" [ token <fhex> ] add-parsing-word
        "syntax" "{" [ "}" parse-until <farray> ] add-parsing-word
        "syntax" "}" (( -- )) [ ] <word> over add-word-to-vocabulary
        "syntax" "H{" [ "}" parse-until <fhashtable> ] add-parsing-word
        "syntax" "B{" [ "}" parse-until <fbyte-array> ] add-parsing-word
        "syntax" "V{" [ "}" parse-until <fvector> ] add-parsing-word
        ! "syntax" "[" [ "]" parse-until <fquotation> ] add-parsing-word
        "syntax" "[" (( -- )) [ \ ] parse-until ] <word> over add-word-to-vocabulary
        "syntax" "]" (( -- )) [ ] <word> over add-word-to-vocabulary
        "syntax" ";" (( -- )) [ ] <word> over add-word-to-vocabulary
        "syntax" "--" (( -- )) [ ] <word> over add-word-to-vocabulary
        "syntax" "(" [ stack-effect ] add-parsing-word

        "syntax" "C:" [ token token <constructor> ] add-parsing-word

        "syntax" "MIXIN:" [ identifier <mixin> ] add-parsing-word
        "syntax" "INSTANCE:" [ token token <instance> ] add-parsing-word

        "syntax" "MATH:" [ identifier stack-effect <math> ] add-parsing-word

        "syntax" "GENERIC:" [ identifier stack-effect <generic> ] add-parsing-word
        "syntax" "GENERIC#" [ identifier token stack-effect <generic#> ] add-parsing-word
        "syntax" ":" [ identifier stack-effect ";" parse-until <fword> ] add-parsing-word
        "syntax" "::" [ identifier stack-effect ";" parse-until <local-fword> ] add-parsing-word
        "syntax" "M:" [
            token token optional-stack-effect ";" parse-until <fmethod>
        ] add-parsing-word
        "syntax" "M::" [
            token token optional-stack-effect ";" parse-until <local-fmethod>
        ] add-parsing-word
        "syntax" "MACRO:" [ identifier stack-effect ";" parse-until <macro> ] add-parsing-word
        "syntax" "MACRO::" [ identifier stack-effect ";" parse-until <local-macro> ] add-parsing-word

        "syntax" "MAIN:" [ token <main> ] add-parsing-word
        "syntax" "PREDICATE:" [ identifier "<" expect token ";" parse-until <predicate> ]
            add-parsing-word

        "syntax" "SYMBOLS:" [ ";" identifiers-until <symbols> ] add-parsing-word
        "syntax" "SYMBOL:" [ identifier 1array <symbols> ] add-parsing-word

        "syntax" "SINGLETONS:" [ ";" identifiers-until <singletons> ] add-parsing-word
        "syntax" "SINGLETON:" [ identifier 1array <singletons> ] add-parsing-word

        "syntax" "UNION:" [ identifier ";" tokens-until <union> ] add-parsing-word
        "syntax" "SLOT:" [ identifier <slot> ] add-parsing-word

        "syntax" "ERROR:" [ identifier ";" tokens-until <error> ] add-parsing-word

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
        "syntax" "CONSTANT:" [ token parse <constant> ] add-parsing-word

        "syntax" "FUNCTION:" [
            token token function-parameters <function>
        ] add-parsing-word

        "syntax" "FUNCTION-ALIAS:" [
            token token token function-parameters <function-alias>
        ] add-parsing-word

        "syntax" "CALLBACK:" [
            token token function-parameters <callback>
        ] add-parsing-word

        "syntax" "GL-FUNCTION:" [
            token token parse function-parameters <gl-function>
        ] add-parsing-word

        "syntax" "<<" [ ">>" parse-until <parse-time> ] add-parsing-word

        "syntax" "TYPEDEF:" [ token token <typedef> ] add-parsing-word
        "syntax" "STRUCT:" [
            token ";" parse-until <struct>
        ] add-parsing-word

        "syntax" "SYNTAX:" [ chunk ";" parse-until <syntax> ] add-parsing-word
        "syntax" "FUNCTOR-SYNTAX:" [ chunk ";" parse-until <functor-syntax> ] add-parsing-word

        "syntax" "HOOK:" [ token token stack-effect <hook> ] add-parsing-word

        "syntax" "C-TYPE:" [ token <ctype> ] add-parsing-word
        "syntax" "LIBRARY:" [ token <library> ] add-parsing-word
        "syntax" "ALIAS:" [ token token <alias> ] add-parsing-word
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
