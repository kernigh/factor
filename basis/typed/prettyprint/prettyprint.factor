USING: definitions kernel locals.definitions see see.private typed words
summary make accessors classes ;
IN: typed.prettyprint

PREDICATE: typed-lambda-word < lambda-word "typed-word" word-prop ;

M: typed-word get-definer drop \ TYPED: \ ; ;
M: typed-lambda-word get-definer drop \ TYPED:: \ ; ;

M: typed-word get-definition "typed-def" word-prop ;
M: typed-word declarations. "typed-word" word-prop declarations. ;

M: input-mismatch-error summary
    [
        "Typed word “" %
        dup word>> name>> %
        "” expected input value of type " %
        dup expected-type>> name>> %
        " but got " %
        dup value>> class name>> %
        drop
    ] "" make ;

M: output-mismatch-error summary
    [
        "Typed word “" %
        dup word>> name>> %
        "” expected to output value of type " %
        dup expected-type>> name>> %
        " but gave " %
        dup value>> class name>> %
        drop
    ] "" make ;
