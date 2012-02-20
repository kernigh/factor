! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs calendar fry kernel locals parser 
sequences vocabs words memoize ;
IN: calendar.holidays

SINGLETONS: all world commonwealth-of-nations ;

<<
SYNTAX: HOLIDAY:
    scan-new-word
    dup "holiday" word-prop [
        dup H{ } clone "holiday" set-word-prop
    ] unless
    parse-definition ( timestamp/n -- timestamp ) define-declared ;

SYNTAX: HOLIDAY-NAME:
    [let scan-word "holiday" word-prop :> holidays scan-word :> name scan-object :> value
    value name holidays set-at ] ;
>>

GENERIC: holidays ( timestamp singleton -- seq )

<PRIVATE

: region-holidays ( singleton -- seq )
    all-words swap '[ "holiday" word-prop _ swap key? ] filter ;

: all-holidays ( -- seq )
    all-words [ "holiday" word-prop ] filter ;

: matching-holidays ( timestamp seq -- seq' )
    [ [ execute( timestamp -- timestamp' ) ] [ drop ] 2bi same-day? ] with filter ;

M: object holidays
    region-holidays matching-holidays ;

PRIVATE>

M: all holidays
    drop
    all-holidays matching-holidays [ "holiday" word-prop >alist ] map concat ;

: holiday? ( timestamp/n singleton -- ? )
    [ holidays ] [ drop ] 2bi '[ _ same-day? ] any? ;

: holiday-name ( word singleton -- string/f )
    [ "holiday" word-prop ] dip swap at ;

: holiday-names ( timestamp/n singleton -- seq )
    [ holidays ] keep '[ _ holiday-name ] map ;

HOLIDAY: armistice-day november 11 >>day ;
HOLIDAY-NAME: armistice-day world "Armistice Day"
