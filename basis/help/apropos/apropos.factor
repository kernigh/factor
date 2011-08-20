! Copyright (C) 2008, 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs fry help.markup help.topics io
kernel make math math.parser namespaces sequences sorting
summary tools.completion vocabs.hierarchy help.vocabs
vocabs words unicode.case help unicode.categories ;
IN: help.apropos

: $completions ( seq -- )
    dup [ word? ] all? [ words-table ] [
        dup [ vocab-spec? ] all? [
            $vocabs
        ] [
            [ <$pretty-link> 1array ] map $table
        ] if
    ] if ;

TUPLE: more-completions seq ;

CONSTANT: max-completions 5

M: more-completions valid-article? drop t ;

M: more-completions article-title
    seq>> length number>string " results" append ;

M: more-completions article-name
    seq>> length max-completions - number>string " more results" append ;

M: more-completions article-content
    seq>> [ second >lower ] sort-with keys \ $completions prefix ;

: (apropos) ( completions title -- element )
    [
        '[
            _ 1array \ $heading prefix ,
            [ max-completions short head keys \ $completions prefix , ]
            [ dup length max-completions > [ more-completions boa <$link> , ] [ drop ] if ]
            bi
        ] unless-empty
    ] { } make ;

: articles-matching ( str -- seq )
    articles get
    [ [ >link ] [ title>> ] bi* ] { } assoc-map-as
    completions ;

: $apropos ( str -- )
    first
    [ words-matching "Words" (apropos) ]
    [ vocabs-matching "Vocabularies" (apropos) ]
    [ articles-matching "Help articles" (apropos) ]
    tri 3array print-element ;

TUPLE: apropos-tuple search ;

C: <apropos> apropos-tuple

M: apropos-tuple valid-article? drop t ;

M: apropos-tuple article-title
    search>> "Search results for “" "”" surround ;

M: apropos-tuple article-name article-title ;

M: apropos-tuple article-content
    search>> 1array \ $apropos prefix ;

M: apropos-tuple >link ;

INSTANCE: apropos-tuple topic

: apropos ( str -- )
    [ blank? ] trim <apropos> print-topic ;
