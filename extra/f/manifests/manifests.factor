! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs assocs.private checksums
checksums.crc32 combinators kernel math namespaces sequences ;
IN: f.manifests

GENERIC: preload-syntax-vocabularies ( manifest -- manifest )

TUPLE: manifest
    path
    factor-checksum
    syntax-checksum
    help-checksum
    tests-checksum
    syntax-vocabularies
    used
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
        V{ } clone >>used
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

ERROR: key-exists value key assoc ;

: set-at-unique ( value key assoc -- )
    2dup key? [ key-exists ] [ set-at ] if ;
    
: assoc-union-unique! ( assoc1 assoc2 -- assoc1 )
    over [ set-at-unique ] with-assoc assoc-each ;
    
: assoc-union-unique ( assoc1 assoc2 -- union )
    [ [ [ assoc-size ] bi@ + ] [ drop ] 2bi new-assoc ] 2keep
    [ assoc-union-unique! ] bi@ ;

: manifest>vocabularies ( manifest -- hashtable )
    used>> [ get-manifest identifiers>> ] map
    ;
    
ERROR: ambiguous-word words ;

: check-ambiguities ( sequence -- word/f )
    dup length {
        { 0 [ drop f ] }
        { 1 [ first ] }
        [ ambiguous-word ]
    } case ;

: search-vocabularies ( string vocabularies -- words )
    [ words>> at ] with map sift check-ambiguities ;

: search-syntax ( string manifest -- word/f )
    syntax-vocabularies>> search-vocabularies ;
    
: search-identifiers ( string manifest -- word/f )
    manifest>vocabularies search-vocabularies ;
