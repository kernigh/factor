! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs checksums checksums.crc32 combinators
kernel namespaces sequences ;
IN: f.manifests

GENERIC: preload-syntax-vocabularies ( manifest -- manifest )

TUPLE: manifest
    path
    factor-checksum
    syntax-checksum
    help-checksum
    tests-checksum
    syntax-vocabularies
    using
    in
    identifiers
    parsed
    parsing-word-stack
    just-parsed
    objects ;

: <manifest> ( path checksum -- obj )
    manifest new
        swap >>factor-checksum
        swap >>path
        HS{ } clone >>using
        H{ } clone >>identifiers
        V{ } clone >>parsed
        V{ } clone >>parsing-word-stack
        V{ } clone >>objects
        V{ } clone >>syntax-vocabularies
    preload-syntax-vocabularies ; inline
    
SYMBOL: manifests
manifests [ H{ } clone ] initialize

: get-manifest ( string -- manifest/f )
    manifests get-global at ;

: set-manifest ( manifest vocab -- )
    manifests get-global set-at ;

: manifest-uptodate? ( manifest -- ? )
    [ path>> crc32 checksum-file ] [ checksum>> ] bi = ;
    
: manifests>vocabularies ( manifests -- vocabularies )
    [ identifiers>> ] map
    ;
    
: add-vocabulary-to-syntax ( vocabulary manifest -- )
    syntax-vocabularies>> push ;
    
ERROR: ambiguous-word words ;

: (search-syntax) ( string vocabularies -- words )
    syntax-vocabularies>>
    [ words>> at ] with map sift ;

: search-syntax ( string manifest -- word/f )
    (search-syntax)
    dup length {
        { 0 [ drop f ] }
        { 1 [ first ] }
        [ ambiguous-word ]
    } case ;