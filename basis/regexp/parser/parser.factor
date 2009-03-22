! Copyright (C) 2008, 2009 Doug Coleman, Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: peg.ebnf kernel math.parser sequences assocs arrays fry math
combinators character-classes strings splitting peg locals accessors
regexp.ast unicode.case unicode.script.private unicode.categories
memoize interval-maps sets unicode.data combinators.short-circuit ;
IN: regexp.parser

: allowed-char? ( ch -- ? )
    ".()|[*+?$^" member? not ;

ERROR: bad-number ;

: ensure-number ( n -- n )
    [ bad-number ] unless* ;

:: at-error ( key assoc quot: ( key -- replacement ) -- value )
    key assoc at* [ drop key quot call ] unless ; inline

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

: parse-unicode-class ( name -- class )
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
        [ bad-class ]
    } cond ;

: unicode-class ( name -- class )
    dup parse-unicode-class [ ] [ bad-class ] ?if ;

: name>class ( name -- class )
    >string simple {
        { "lower" lowercase }
        { "upper" uppercase }
        { "alpha" alphabetic }
        { "ascii" ascii }
        { "digit" digit }
        { "alnum" alphanumeric }
        { "punct" punctuation }
        { "print" printable }
        { "blank" blank }
        { "cntrl" control }
        { "xdigit" hex-digit }
        { "space" whitespace }
    } [ unicode-class ] at-error ;

: lookup-escape ( char -- ast )
    {
        { CHAR: t [ CHAR: \t ] }
        { CHAR: n [ CHAR: \n ] }
        { CHAR: r [ CHAR: \r ] }
        { CHAR: f [ HEX: c ] }
        { CHAR: a [ HEX: 7 ] }
        { CHAR: e [ HEX: 1b ] }
        { CHAR: \\ [ CHAR: \\ ] }

        { CHAR: w [ word ] }
        { CHAR: W [ word <not-class> ] }
        { CHAR: s [ whitespace ] }
        { CHAR: S [ whitespace <not-class> ] }
        { CHAR: d [ digit ] }
        { CHAR: D [ digit <not-class> ] }

        { CHAR: z [ end-of-input <tagged-epsilon> ] }
        { CHAR: Z [ end-of-file <tagged-epsilon> ] }
        { CHAR: A [ beginning-of-input <tagged-epsilon> ] }
        { CHAR: b [ word-break <tagged-epsilon> ] }
        { CHAR: B [ word-break <not-class> <tagged-epsilon> ] }
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

: option>ch ( option -- string )
    options-assoc value-at ;

: parse-options ( on off -- options )
    [ [ ch>option ] { } map-as ] bi@ <options> ;

: string>options ( string -- options )
    "-" split1 parse-options ;
 
: options>string ( options -- string )
    [ on>> ] [ off>> ] bi
    [ [ option>ch ] map ] bi@
    [ "-" glue ] unless-empty
    "" like ;

! TODO: add syntax for various parenthized things,
!       add greedy and nongreedy forms of matching
! (once it's all implemented)

EBNF: parse-regexp

CharacterInBracket = !("}") Character

QuotedCharacter = !("\\E") .

Escape = "p{" CharacterInBracket*:s "}" => [[ s name>class ]]
       | "P{" CharacterInBracket*:s "}" => [[ s name>class <not-class> ]]
       | "Q" QuotedCharacter*:s "\\E" => [[ s <concatenation> ]]
       | "u" Character:a Character:b Character:c Character:d
            => [[ { a b c d } hex> ensure-number ]]
       | "x" Character:a Character:b
            => [[ { a b } hex> ensure-number ]]
       | "0" Character:a Character:b Character:c
            => [[ { a b c } oct> ensure-number ]]
       | . => [[ lookup-escape ]]

EscapeSequence = "\\" Escape:e => [[ e ]]

Character = EscapeSequence
          | "$" => [[ $ <tagged-epsilon> ]]
          | "^" => [[ ^ <tagged-epsilon> ]]
          | . ?[ allowed-char? ]?

AnyRangeCharacter = !("&&"|"||"|"--"|"~~") (EscapeSequence | .)

RangeCharacter = !("]") AnyRangeCharacter

Range = RangeCharacter:a "-" !("-") RangeCharacter:b => [[ a b <range-class> ]]
      | RangeCharacter

StartRange = AnyRangeCharacter:a "-" !("-") RangeCharacter:b => [[ a b <range-class> ]]
           | AnyRangeCharacter

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

Options = [idmsux]*

Parenthized = "?:" Alternation:a => [[ a ]]
            | "?" Options:on "-"? Options:off ":" Alternation:a
                => [[ a on off parse-options <with-options> ]]
            | "?#" [^)]* => [[ f ]]
            | "?~" Alternation:a => [[ a <negation> ]]
            | "?=" Alternation:a => [[ a <lookahead> <tagged-epsilon> ]]
            | "?!" Alternation:a => [[ a <lookahead> <not-class> <tagged-epsilon> ]]
            | "?<=" Alternation:a => [[ a <lookbehind> <tagged-epsilon> ]]
            | "?<!" Alternation:a => [[ a <lookbehind> <not-class> <tagged-epsilon> ]]
            | Alternation

Element = "(" Parenthized:p ")" => [[ p ]]
        | "[" CharClass:r "]" => [[ r ]]
        | ".":d => [[ dot ]]
        | Character

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

Concatenation = Repeated*:r => [[ r sift <concatenation> ]]

Alternation = Concatenation:c ("|" Concatenation)*:a
                => [[ a empty? [ c ] [ a values c prefix <alternation> ] if ]]

End = !(.)

Main = Alternation End
;EBNF
