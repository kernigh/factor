! Copyright (C) 2008, 2009 Doug Coleman, Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: peg.ebnf kernel math.parser sequences assocs arrays fry math
combinators character-classes strings splitting peg locals accessors
regexp.ast unicode.case unicode.script.private unicode.categories
memoize interval-maps sets unicode.data combinators.short-circuit
vectors namespaces unicode.data.private ;
FROM: ascii.categories => ascii-char ;
IN: regexp.parser

SYMBOL: option-stack

: set-each ( keys value hashtable -- )
    '[ _ swap _ set-at ] each ;

: push-options ( options -- )
    option-stack [ ?push ] change ;

: pop-options ( -- )
    option-stack get pop* ;

: option? ( obj -- ? )
    option-stack get assoc-stack ;

: allowed-char? ( ch -- ? )
    ".()|[*+?$^" member? not ;

ERROR: bad-number ;

: ensure-number ( n -- n )
    [ bad-number ] unless* ;

ERROR: bad-class name ;

: simple ( str -- simple )
    ! Alternatively, first collation key level?
    >case-fold [ " \t_" member? not ] filter ;

: simple-table ( seq -- table )
    [ [ simple ] keep ] H{ } map>assoc ;

MEMO: simple-script-table ( -- table )
    script-table interval-values prune simple-table ;

MEMO: simple-category-table ( -- table )
    categories simple-table ;

MEMO: property-table ( -- table )
    properties keys simple-table ;

: unicode-class ( name -- class )
    {
        { [ dup { [ length 1 = ] [ first "clmnpsz" member? ] } 1&& ] [
            >upper first
            <category-range-class>
        ] }
        { [ dup >title categories member? ] [
            simple-category-table at <category-class>
        ] }
        { [ "script=" ?head ] [
            dup simple-script-table at
            [ <script-class> ]
            [ "script=" prepend bad-class ] ?if
        ] }
        { [ property-table ?at ] [ <property-class> <delay-class> ] }
        [ bad-class ]
    } cond ;

: ?insensitive ( class -- class' )
    [ case-insensitive option? alphabetic ] dip ? ;

: name>class ( name -- class )
    >string simple {
        { "lower" [ lowercase ?insensitive ] }
        { "upper" [ uppercase ?insensitive ] }
        { "alpha" [ alphabetic ] }
        { "ascii" [ ascii-char ] }
        { "digit" [ digit ] }
        { "alnum" [ alphanumeric ] }
        { "punct" [ punctuation ] }
        { "print" [ printable ] }
        { "blank" [ blank ] }
        { "cntrl" [ control ] }
        { "xdigit" [ hex-digit ] }
        { "space" [ whitespace ] }
        { "defaultignorablecodepoint" [ default-ignorable ] }
        { "noncharactercodepoint"
            [ "Noncharacter_Code_Point" <property-class> ] }
        { "any" [ 0 HEX: 10FFFF <range-class> ] }
        [ unicode-class ]
    } case ;

: lookup-escape ( char -- ast )
    {
        { CHAR: t [ CHAR: \t ] }
        { CHAR: n [ CHAR: \n ] }
        { CHAR: r [ CHAR: \r ] }
        { CHAR: f [ HEX: c ] }
        { CHAR: a [ HEX: 7 ] }
        { CHAR: e [ HEX: 1b ] }
        { CHAR: \\ [ CHAR: \\ ] }

        { CHAR: w [ word-char ] }
        { CHAR: W [ word-char <not> ] }
        { CHAR: s [ whitespace ] }
        { CHAR: S [ whitespace <not> ] }
        { CHAR: d [ digit ] }
        { CHAR: D [ digit <not> ] }

        { CHAR: z [ end-of-input <tagged-epsilon> ] }
        { CHAR: Z [ end-of-file <tagged-epsilon> ] }
        { CHAR: A [ beginning-of-input <tagged-epsilon> ] }
        { CHAR: b [ word-break <tagged-epsilon> ] }
        { CHAR: B [ word-break <not> <tagged-epsilon> ] }
        [ ]
    } case ;

: options-assoc ( -- assoc )
    H{
        { CHAR: i case-insensitive }
        { CHAR: d unix-lines }
        { CHAR: m multiline }
        { CHAR: r reversed-regexp }
        { CHAR: s dotall }
    } ;

: ch>option ( ch -- singleton )
    options-assoc at ;

: parse-options ( on off -- options )
    [ [ ch>option ] { } map-as ] bi@ t f 
    H{ } clone [
         '[ _ set-each ] bi-curry@ bi*
    ] keep ;

: string>options ( string -- options )
    "-" split1 parse-options ;

: dot ( -- class )
    dotall option? [ t ] [
        unix-lines option?
        CHAR: \n line-separator ? <not>
    ] if ;

: cased-range? ( from to -- ? )
    {
        [ [ lowercase? ] bi@ and ]
        [ [ uppercase? ] bi@ and ]
    } 2|| ;

: make-range ( start end -- range-class )
    case-insensitive option? [
        2dup cased-range? [
            [ [ ch>lower ] bi@ <range-class> ]
            [ [ ch>upper ] bi@ <range-class> ] 2bi 
            <or>
        ] [ <range-class> ] if
    ] [ <range-class> ] if ;

: line-option ( multiline unix-lines default -- option )
    multiline option? [
        drop [ unix-lines option? ] 2dip swap ?
    ] [ 2nip ] if <tagged-epsilon> ;

: dollar ( -- condition )
    $ $unix end-of-input line-option ;

: carat ( -- condition )
    ^ ^unix beginning-of-input line-option ;

: modify ( elt -- elt' )
    case-insensitive option? [
        dup alphabetic? [
            [ ch>lower ] [ ch>upper ] bi <or>
        ] when
    ] when ;

: insensitive-map ( seq -- seq' )
    [ modify ] map ;

: make-concatenation ( seq -- concatenation )
    sift
    reversed-regexp option? [ reverse ] when
    <concatenation> ;

: push-reverse ( -- )
    H{ { reversed-regexp t } } push-options ;

EBNF: (parse-regexp)

CharacterInBracket = !("}") Character

QuotedCharacter = !("\\E") .

Escape = "p{" CharacterInBracket*:s "}" => [[ s name>class ]]
       | "P{" CharacterInBracket*:s "}" => [[ s name>class <not> ]]
       | "Q" QuotedCharacter*:s "\\E"
            => [[ s insensitive-map make-concatenation ]]
       | "u" Character:a Character:b Character:c Character:d
            => [[ { a b c d } hex> ensure-number ]]
       | "x" Character:a Character:b
            => [[ { a b } hex> ensure-number ]]
       | "0" Character:a Character:b Character:c
            => [[ { a b c } oct> ensure-number ]]
       | . => [[ lookup-escape ]]

EscapeSequence = "\\" Escape:e => [[ e ]]

Character = EscapeSequence
          | "$" => [[ dollar ]]
          | "^" => [[ carat ]]
          | . ?[ allowed-char? ]?

AnyRangeCharacter = !("&&"|"||"|"--"|"~~") (EscapeSequence | .)

RangeCharacter = !("]") AnyRangeCharacter

Range = RangeCharacter:a "-" !("-") RangeCharacter:b => [[ a b make-range ]]
      | RangeCharacter => [[ modify ]]

StartRange = AnyRangeCharacter:a "-" !("-") RangeCharacter:b => [[ a b make-range ]]
           | AnyRangeCharacter => [[ modify ]]

Ranges = StartRange:s Range*:r => [[ r s prefix ]]

BasicCharClass =  "^"?:n Ranges:e => [[ e n char-class ]]

CharClass = BasicCharClass:b "&&" CharClass:c
                => [[ b c <and> ]]
          | BasicCharClass:b "||" CharClass:c
                => [[ b c <or> ]]
          | BasicCharClass:b "~~" CharClass:c
                => [[ b c <sym-diff> ]]
          | BasicCharClass:b "--" CharClass:c
                => [[ b c <minus> ]]
          | BasicCharClass

Options = [idmsx-]*:opts ":"
    => [[ opts string>options dup push-options ]]

Lookbehind = "?<=" => [[ push-reverse ]]

NotLookbehind = "?<!" => [[ push-reverse ]]

Parenthized = "?:" Alternation:a => [[ a ]]
            | "?" Options Alternation:a
                => [[ a pop-options ]]
            | "?#" [^)]* => [[ f ]]
            | "?~" Alternation:a => [[ a <negation> ]]
            | "?=" Alternation:a => [[ a <lookahead> <tagged-epsilon> ]]
            | "?!" Alternation:a => [[ a <lookahead> <not> <tagged-epsilon> ]]
            | Lookbehind Alternation:a
                => [[ a <lookbehind> <tagged-epsilon> pop-options ]]
            | NotLookbehind Alternation:a
                => [[ a <lookbehind> <not> <tagged-epsilon> pop-options ]]
            | Alternation

Element = "(" Parenthized:p ")" => [[ p ]]
        | "[" CharClass:r "]" => [[ r <delay-class> ]]
        | ".":d => [[ dot ]]
        | Character => [[ modify ]]

Number = (!(","|"}").)* => [[ string>number ensure-number ]]

Times = "," Number:n "}" => [[ 0 n <from-to> ]]
      | Number:n ",}" => [[ n <at-least> ]]
      | Number:n "}" => [[ n n <from-to> ]]
      | "}" => [[ bad-number ]]
      | Number:n "," Number:m "}" => [[ n m <from-to> ]]

Repeated = Element:e "{" Times:t => [[ e t <times> ]]
         | Element:e "??" => [[ e <maybe> ]]
         | Element:e "*?" => [[ e <star> ]]
         | Element:e "+?" => [[ e <plus> ]]
         | Element:e "?" => [[ e <maybe> ]]
         | Element:e "*" => [[ e <star> ]]
         | Element:e "+" => [[ e <plus> ]]
         | Element

Concatenation = Repeated*:r => [[ r make-concatenation ]]

Alternation = Concatenation:c ("|" Concatenation)*:a
                => [[ a empty? [ c ] [ a values c prefix <alternation> ] if ]]

End = !(.)

Main = Alternation End
;EBNF

: parse-optioned-regexp ( string options -- ast )
    [
        string>options push-options
        (parse-regexp)
    ] with-scope ;

: parse-regexp ( string -- ast )
    "" parse-optioned-regexp ;
