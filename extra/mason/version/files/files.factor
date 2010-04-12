! Copyright (C) 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors fry kernel make mason.config mason.platform
mason.release.archive namespaces sequences ;
IN: mason.version.files

: release-directory ( version -- string )
    [
        upload-directory get % "/releases/" % %
    ] "" make ;

: remote ( string version -- string )
    release-directory swap "/" glue ;

: platform ( builder -- string )
    [ os>> ] [ cpu>> ] bi (platform) ;

: binary-package-name ( builder -- string )
    [
        upload-directory get % "/" %
        [ platform % "/" % ] [ last-release>> % ] bi
    ] "" make ;

: binary-release-name ( version builder -- string )
    [
        [ "factor-" % platform % "-" % % ]
        [ os>> extension % ]
        bi
    ] "" make ;

: remote-binary-release-name ( version builder -- string )
    [ binary-release-name ] [ drop ] 2bi remote ;

: source-release-name ( version -- string )
    "factor-src-" ".zip" surround ;

: remote-source-release-name ( version -- string )
    [ source-release-name ] keep remote ;
