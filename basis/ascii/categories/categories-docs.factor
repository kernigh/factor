USING: help.markup help.syntax ;
IN: ascii.categories

HELP: blank?
{ $values { "ch" "a character" } { "?" "a boolean" } }
{ $description "Tests for an ASCII linear whitespace character." } ;

HELP: lowercase?
{ $values { "ch" "a character" } { "?" "a boolean" } }
{ $description "Tests for a lowercase alphabet ASCII character." } ;

HELP: uppercase?
{ $values { "ch" "a character" } { "?" "a boolean" } }
{ $description "Tests for a uppercase alphabet ASCII character." } ;

HELP: digit?
{ $values { "ch" "a character" } { "?" "a boolean" } }
{ $description "Tests for an ASCII decimal digit character." } ;

HELP: alphabetic?
{ $values { "ch" "a character" } { "?" "a boolean" } }
{ $description "Tests for an ASCII alphabet character, both upper and lower case." } ;

HELP: alphanumeric?
{ $values { "ch" "a character" } { "?" "a boolean" } }
{ $description "Tests for an alphanumeric ASCII character." } ;

HELP: printable?
{ $values { "ch" "a character" } { "?" "a boolean" } }
{ $description "Tests for a printable ASCII character." } ;

HELP: control?
{ $values { "ch" "a character" } { "?" "a boolean" } }
{ $description "Tests for an ASCII control character." } ;

HELP: quotable?
{ $values { "ch" "a character" } { "?" "a boolean" } }
{ $description "Tests for characters which may appear in a Factor string literal without escaping." } ;

HELP: ascii-char?
{ $values { "ch" "a character" } { "?" "a boolean" } }
{ $description "Tests for whether a number is an ASCII character." } ;

ARTICLE: "ascii.categories" "ASCII character classes"
"The " { $vocab-link "ascii.categories" } " vocabulary provides POSIX character classes for characters in the legacy ASCII character set. Most applications should use " { $vocab-link "unicode.categories" } " instead."
{ $subsection blank? }
{ $subsection lowercase? }
{ $subsection uppercase? }
{ $subsection alphabetic? }
{ $subsection digit? }
{ $subsection printable? }
{ $subsection control? }
{ $subsection quotable? }
{ $subsection ascii-char? } ;
