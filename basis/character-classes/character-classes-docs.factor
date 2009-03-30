! Copyright (C) 2009 Daniel Ehrenberg
! See http://factorcode.org/license.txt for BSD license.
USING: help.markup help.syntax interval-sets math sequences ;
IN: character-classes

ABOUT: "character-classes"

ARTICLE: "character-classes" "Character classes"
"THe " { $vocab-link "character-classes" } " vocabulary implements an abstraction to represent sets of characters. These can be used to represent derived Unicode properties in a space-efficient way, for example. Dividing characters into character classes is essentially the zeroth step in parsing, coming before lexing, and it must be done extremely efficiently." $nl
{ $subsection { "character-classes" "use" } }
{ $subsection { "character-classes" "types" } }
{ $subsection { "character-classes" "construction" } }
{ $subsection { "character-classes" "syntax" } }
"The " { $vocab-link "unicode.categories" } " vocabulary defines category classes for certain Unicode properties." ;

ARTICLE: { "character-classes" "use" } "Using character classes"
"To test if a character is in a character class, use"
{ $subsection class-member? } ;

ARTICLE: { "character-classes" "types" } "Types of character classes"
{ $subsection { "character-classes" "integers" } }
{ $subsection { "character-classes" "intervals" } }
{ $subsection { "character-classes" "booleans" } }
{ $subsection union } 
{ $subsection quot-class }
{ $subsection not-class }
{ $subsection delay-class } ;

ARTICLE: { "character-classes" "integers" } "Integer character classes"
"Individual integers form character classes that are singletons, consisting just of that character. For example:"
{ $example "USING: prettyprint character-classes ; CHAR: A CHAR: A class-member? ." "t" }
{ $example "USING: prettyprint character-classes ; CHAR: B CHAR: A class-member? ." "f" } ;

ARTICLE: { "character-classes" "intervals" } "Interval set character classes"
{ $link "interval-sets" } " are a type of character class. They can be made with any of the interval set constructors, or with " { $link <range-class> } ". They represent the union of a number of closed intervals of positive integers." ;

ARTICLE: { "character-classes" "booleans" } "Boolean character classes"
"The classes " { $link t } " and " { $link f } " are used to represent the class of all characters and no characters, respectively. The algebraic simplifications done on character classes are specially aware of these values." ;

ARTICLE: { "character-classes" "construction" } "Constructing character classes"
"To construct character classes, use the following words:"
{ $subsection <range-class> }
{ $subsection <union> }
{ $subsection <or> }
{ $subsection <intersection> } 
{ $subsection <and> }
{ $subsection <quot-class> }
{ $subsection <delay-class> }
{ $see-also { $vocab-link "unicode.categories" } }
"Many of these constructors perform symbolic reduction on their inputs. In particular, " { $link quot-class } "es are coalesced by quotation, " { $link interval-set } " classes are combined into a single interval set, and there is a simple set of heuristics to reduce logical expressions." ;

ARTICLE: { "character-classes" "syntax" } "Syntax for defining character classes"
"There is a special construct of words which represent a Factor class of characters in the given character class. These words are called categories. These words themselves act as character classes, and work like " { $link delay-class } "."
{ $subsection POSTPONE: CATEGORY: }
{ $subsection define-category }
{ $subsection category-word } ;

HELP: <range-class>
{ $values { "from" integer } { "to" integer } { "range" interval-set } }
{ $description "Creates an interval set spanning the given range. This can be used as a character class." } ;

HELP: class-member?
{ $values { "char" integer } { "class" "a character class" } }
{ $description "Tests if the character is contained in the character class." } ;

HELP: <quot-class>
{ $values { "values" "sequence of outputs of the quotation" } { "quot" { $quotation "( char -- value )" } } }
{ $description "Creates a " { $link quot-class } " of characters whose output through the quotation is one of the given values." } ;

HELP: quot-class
{ $class-description "Quot-classes are a scheme for creating new character classes. They consist of two parts: a quotation and a set of values. To test if a character is in a quot-class, the quotation is run and its value is checked for membership in the values sequence." } ;

HELP: delay-class
{ $class-description "A delay class wraps a character class, providing the same " { $link class-member? } " behavior but not letting it participate in reductions. This is useful when the algebraic reductions of class algebra would be too expensive." } ;

HELP: <delay-class>
{ $values { "class" "a character class" } { "delay-class" delay-class } }
{ $class-description "Creates a " { $link delay-class } " out of a character class." } ;

HELP: not-class
{ $class-description "This character class represents the complement of another character class. The complemented class is in the " { $snippet "class" } " slot." } ;

HELP: union
{ $class-description "This represents the union of a number of character classes, contained in the " { $snippet "seq" } " slot. An instance can be created with the " { $link <union> } " word." } ;

HELP: <union>
{ $values { "seq" sequence } { "class" union } }
{ $description "Creates a character class which represents the disjunction (union) of a sequence of character classes" } ;

HELP: <or>
{ $values { "class1" "a character class" } { "class2" "a character class" } { "class" union } }
{ $description "Creates a character class which represents the disjunction (union) of two character classes." } ;

HELP: <intersection>
{ $values { "seq" sequence } { "class" "a character class" } }
{ $description "Creates a character class which represents the conjunction (intersection) of a sequence of character classes" } ;

HELP: <and>
{ $values { "class1" "a character class" } { "class2" "a character class" } { "class" "a character class" } }
{ $description "Creates a character class which represents the conjunction (intersection) of two character classes." } ;

HELP: CATEGORY:
{ $syntax "CATEGORY: name definition ;" }
{ $description "Defines a predicate class named " { $snippet "name" } " which consists of integer in the character class that " { $snippet "definition" } " specifies. The definition is just a Factor expression which evaluates to a character class. This evaluation will take place at parsetime." } ;

HELP: define-category
{ $values { "word" "a word which is a class" } { "definition" "a character class" } }
{ $description "Defines the word as a predicate class which consists of characters in the given character class." } ;
