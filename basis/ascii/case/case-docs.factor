USING: help.markup help.syntax ;
IN: ascii.case

HELP: ch>lower
{ $values { "ch" "a character" } { "lower" "a character" } }
{ $description "Converts an ASCII character to lower case." } ;

HELP: ch>upper
{ $values { "ch" "a character" } { "upper" "a character" } }
{ $description "Converts an ASCII character to upper case." } ;

HELP: >lower
{ $values { "str" "a string" } { "lower" "a string" } }
{ $description "Converts an ASCII string to lower case." } ;

HELP: >upper
{ $values { "str" "a string" } { "upper" "a string" } }
{ $description "Converts an ASCII string to upper case." } ;

ARTICLE: "ascii.case" "ASCII case conversion"
"The " { $vocab-link "ascii.case" } " vocabulary implements case conversion within the legacy ASCII character set. Most applications should use " { $vocab-link "unicode.case" } " instead."
$nl
{ $subsection ch>lower }
{ $subsection ch>upper }
{ $subsection >lower }
{ $subsection >upper } ;

ABOUT: "ascii.case"
