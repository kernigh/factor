! Copyright (C) 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators db.tuples grouping io kernel make
mason.server mason.version.binary mason.version.common
mason.version.data mason.version.files mason.version.source
sequences ;
IN: mason.version

: check-releases ( builders -- )
    [ release-git-id>> ] map all-equal?
    [ "Some builders are out of date" throw ] unless ;

: make-release-directory ( version -- )
    "Creating release directory..." print flush
    [ "mkdir -p " % release-directory % "\n" % ] "" make
    execute-on-server ;

: do-release ( version -- )
    [
        builder new select-tuples
        {
            [ nip check-releases ]
            [ drop make-release-directory ]
            [ do-binary-release ]
            [
                first release-git-id>>
                [ do-source-release ]
                [ update-version ]
                2bi
            ]
            [ update-binary-releases ]
        } 2cleave
        "Done." print flush
    ] with-mason-db ;
