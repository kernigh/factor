USING: tools.test compiler.units classes.mixin definitions
kernel ;
IN: compiler.tests.redefine25

MIXIN: empty-mixin

: empty-mixin-test ( a -- ? ) empty-mixin? ;

TUPLE: empty-mixin-member ;

[ f ] [ empty-mixin-member new empty-mixin? ] unit-test
[ f ] [ empty-mixin-member new empty-mixin-test ] unit-test

[ ] [
    [
        \ empty-mixin-member \ empty-mixin add-mixin-instance
    ] with-compilation-unit
] unit-test

[ t ] [ empty-mixin-member new empty-mixin? ] unit-test
[ t ] [ empty-mixin-member new empty-mixin-test ] unit-test

[ ] [
    [
        \ empty-mixin forget
        \ empty-mixin-member forget
    ] with-compilation-unit
] unit-test
