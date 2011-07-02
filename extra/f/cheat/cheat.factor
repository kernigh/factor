! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays classes.tuple classes.tuple.parser
combinators effects f.lexer f.parser2 f.vocabularies f.words fry
generalizations kernel make math.parser nested-comments
sequences strings words ;
QUALIFIED: parser
QUALIFIED: f.words
IN: f.cheat

<<
SYNTAX: TOKEN:
    parse-tuple-definition
    [ [ drop \ lexed ] dip define-tuple-class ]
    [
        [ 2drop name>> "<" ">" surround parser:create-in ]
        [ nip length swap '[ [ pop-parsed ] _ ndip _ boa ] ]
        [ 2drop [ all-slots rest [ name>> ] map ] [ name>> 1array ] bi <effect> ] 3tri define-inline
    ] 3bi ;
>>

TOKEN: number n ;

TOKEN: single-word name ;

TOKEN: main name ;

! TUPLE: identifier-stack-effect identifier stack-effect ;
! C: <identifier-stack-effect> identifier-stack-effect

! TUPLE: stack-effect in out ;
! C: <stack-effect> stack-effect

TUPLE: identifier-stack-effect identifier stack-effect ;
C: <identifier-stack-effect> identifier-stack-effect
TOKEN: stack-effect in out ;

TOKEN: fword name stack-effect body ;

TOKEN: local-fword name stack-effect body ;

TOKEN: fmethod type name stack-effect body ;

TOKEN: local-fmethod type name stack-effect body ;

TOKEN: macro name stack-effect body ;

TOKEN: local-macro name stack-effect body ;

TOKEN: hook name variable stack-effect ;

TOKEN: inline ;

TOKEN: recursive ;

TOKEN: flushable ;

TOKEN: foldable ;

TOKEN: begin-private ;

TOKEN: end-private ;

TOKEN: instance instance mixin ;

TOKEN: using vocabularies ;

TOKEN: unuse vocabulary ;

TOKEN: in vocabulary ;

TOKEN: predicate class superclass stack-effect body ;

TOKEN: mixin mixin ;

TOKEN: math name stack-effect ;

TOKEN: memo name stack-effect body ;

TOKEN: local-memo name stack-effect body ;

TOKEN: generic name stack-effect ;

TOKEN: generic# name arity stack-effect ;

TOKEN: constructor name class stack-effect ;

TOKEN: long-constructor name stack-effect body ;

TOKEN: symbols sequence ;

TOKEN: singletons sequence ;

TOKEN: error name slots ;

TOKEN: union class members ;

TOKEN: slot name ;

TOKEN: fhashtable object ;

TOKEN: farray object ;

TOKEN: fvector object ;

TOKEN: fquotation object ;

TOKEN: fbyte-array object ;

TOKEN: fhex object ;

TOKEN: literal object ;

TOKEN: qualified vocabulary ;

TOKEN: qualified-with vocabulary prefix ;

TOKEN: from vocabulary words ;

TOKEN: forget name ;

TOKEN: rename word vocabulary new-name ;

TOKEN: exclude vocabulary words ;

TOKEN: defer name ;

TOKEN: char ch ;

TOKEN: tuple name slots ;

TOKEN: boa-tuple name slots ;

TOKEN: assoc-tuple name slots ;

TOKEN: function-alias alias return name parameters ;

TOKEN: function return name parameters ;

TOKEN: struct name slots ;

TOKEN: gl-function return name obj parameters ;

TOKEN: callback return name parameters ;

TOKEN: typedef old new ;

TOKEN: ctype name ;

TOKEN: alias new old ;

TOKEN: library name ;

TOKEN: parse-time code ;

TOKEN: constant name value ;

TOKEN: syntax name body ;

TOKEN: functor-syntax name body ;

TOKEN: locals-assignment identifiers ;

TOKEN: literal-syntax word ;

TOKEN: literal-quotation objects ;

TOKEN: literal-array objects ;

TOKEN: let quotation ;

TOKEN: lambda bindings quotation ;

TOKEN: flags objects ;

TOKEN: postponed word ;

TOKEN: article objects ;

TOKEN: about name ;

TOKEN: call stack-effect ;

TOKEN: execute stack-effect ;

TOKEN: ebnf text ;
TOKEN: functor text ;
TOKEN: peg name stack-effect body ;

: add-parsing-word ( manifest vocab name quot -- manifest )
    <parsing-word> over add-word-to-vocabulary ;

: function-parameters ( -- seq )
    peek-token ";" = [
        token drop f
    ] [
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
        ] { } make
    ] if ;

DEFER: stack-effect

: stack-effect-part ( -- seq )
    new-parse
    [
        peek-token {
            { [ dup "--" = ] [ drop f ] }
            { [ dup ")" = ] [ drop f ] }
            { [ dup ":" tail? ] [ drop token stack-effect <identifier-stack-effect> drop t ] }
            [ drop token drop t ]
        } cond
    ] loop
    pop-parsed [ push-all-parsed ] keep
    [ text ] map ;

: (stack-effect) ( -- stack-effect )
    stack-effect-part
    "--" expect
    stack-effect-part
    ")" expect 
    <stack-effect> ;

: open-stack-effect ( -- stack-effect )
    new-parse (stack-effect) dup push-parsed ;

: stack-effect ( -- stack-effect )
    new-parse "(" expect (stack-effect) dup push-parsed ;

: optional-stack-effect ( -- stack-effect/f )
    peek-token "(" = [ stack-effect ] [ f ] if ;

: fake-syntax-vocabulary ( -- vocabulary )
    "syntax" <vocabulary>
        "syntax" "USING:" [
            ";" tokens-until dup [ use-vocabulary ] each <using>
        ] add-parsing-word
        "syntax" "USE:" [ parse-use 1array <using> ] add-parsing-word
        "syntax" "UNUSE:" [ parse-unuse <unuse> ] add-parsing-word
        "syntax" "IN:" [ parse-in <in> ] add-parsing-word

        "syntax" "HEX:" [ token <fhex> ] add-parsing-word
        "syntax" "H{" [ "}" parse-until <fhashtable> ] add-parsing-word
        "syntax" "B{" [ "}" parse-until <fbyte-array> ] add-parsing-word
        "syntax" "V{" [ "}" parse-until <fvector> ] add-parsing-word
        "syntax" "{" [ "}" parse-until <farray> ] add-parsing-word
        "syntax" "[" [ "]" parse-until <fquotation> ] add-parsing-word
        "syntax" "(" [ stack-effect ] add-parsing-word
        "syntax" "$" [ token <literal-syntax> ] add-parsing-word
        "syntax" "$[" [ "]" parse-until <literal-quotation> ] add-parsing-word
        "syntax" "${" [ "}" parse-until <literal-array> ] add-parsing-word
        "syntax" "flags{" [ "}" parse-until <flags> ] add-parsing-word
        "syntax" "POSTPONE:" [ chunk <postponed> ] add-parsing-word
        "syntax" "ARTICLE:" [ ";" parse-until <article> ] add-parsing-word
        "syntax" "ABOUT:" [ token <about> ] add-parsing-word

        "syntax" "[let" [ "]" parse-until <let> ] add-parsing-word
        "syntax" "[|" [ "|" tokens-until "]" parse-until <lambda> ] add-parsing-word

        "syntax" "C:" [ token token optional-stack-effect <constructor> ] add-parsing-word

        "syntax" ":>" [
            peek-token "(" = [
                "(" expect ")" tokens-until <locals-assignment>
            ] [
                peek-token 1array <locals-assignment>
            ] if
        ] add-parsing-word

        "syntax" "MIXIN:" [ identifier <mixin> ] add-parsing-word
        "syntax" "INSTANCE:" [ token token <instance> ] add-parsing-word

        "syntax" "MATH:" [ identifier stack-effect <math> ] add-parsing-word
        "syntax" "MEMO:" [ identifier stack-effect ";" parse-until <memo> ] add-parsing-word
        "syntax" "MEMO::" [ identifier stack-effect ";" parse-until <local-memo> ] add-parsing-word

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
        "syntax" "PREDICATE:" [ identifier "<" expect token optional-stack-effect ";" parse-until <predicate> ]
            add-parsing-word
        "syntax" "FORGET:" [ forget-identifier <forget> ] add-parsing-word

        "syntax" "SYMBOLS:" [ ";" identifiers-until <symbols> ] add-parsing-word
        "syntax" "SYMBOL:" [ identifier 1array <symbols> ] add-parsing-word

        "syntax" "SINGLETONS:" [ ";" identifiers-until <singletons> ] add-parsing-word
        "syntax" "SINGLETON:" [ identifier 1array <singletons> ] add-parsing-word

        "syntax" "UNION:" [ identifier ";" tokens-until <union> ] add-parsing-word
        "syntax" "SLOT:" [ identifier <slot> ] add-parsing-word

        "syntax" "ERROR:" [ identifier ";" tokens-until <error> ] add-parsing-word


        "syntax" "EBNF:" [ ";EBNF" chunks-until <ebnf> ] add-parsing-word
        "syntax" "FUNCTOR:" [ ";FUNCTOR" tokens-until <ebnf> ] add-parsing-word
        "syntax" "PEG:" [ identifier stack-effect ";" parse-until <peg> ] add-parsing-word
        "syntax" "call(" [ open-stack-effect <call> ] add-parsing-word
        "syntax" "execute(" [ open-stack-effect <execute> ] add-parsing-word
        "syntax" "inline" [ <inline> ] add-parsing-word
        "syntax" "recursive" [ <recursive> ] add-parsing-word
        "syntax" "flushable" [ <flushable> ] add-parsing-word
        "syntax" "foldable" [ <foldable> ] add-parsing-word
        "syntax" "<PRIVATE" [ private-on <begin-private> ] add-parsing-word
        "syntax" "PRIVATE>" [ private-off <end-private> ] add-parsing-word

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
                "}" parse-until <boa-tuple>
            ] [
                [
                    [
                        token dup "}" = [
                            drop f
                        ] [
                            "{" = [
                                "}" parse-until , t
                            ] [
                                "bad tuple" throw
                            ] if
                        ] if
                    ] loop
                ] { } make <assoc-tuple>
            ] if
        ] add-parsing-word

        "syntax" "CONSTRUCTOR:" [
            identifier stack-effect ";" parse-until <long-constructor>
        ] add-parsing-word
    ;

M: object preload-manifest ( manifest -- manifest )
    fake-syntax-vocabulary over add-vocabulary-to-manifest ;
