! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs combinators f.vocabularies kernel
namespaces sequences sets io ;
IN: f.manifest

TUPLE: manifest
    path
    current-vocabulary
    search-vocabulary-names
    search-vocabularies
    objects ;
    ! qualified-vocabularies

: <manifest> ( path -- obj )
    \ manifest new
        swap >>path
        H{ } clone >>search-vocabulary-names
        V{ } clone >>search-vocabularies
        ! V{ } clone >>qualified-vocabs
        V{ } clone >>objects ;

: (search-manifest) ( string assocs -- words )
    [ words>> at ] with map sift ;

ERROR: ambiguous-word words ;
: search-manifest ( string manifest -- word/f )
    search-vocabularies>> (search-manifest)
    dup length {
        { 0 [ drop f ] }
        { 1 [ first ] }
        [ ambiguous-word ]
    } case ;

: search ( string -- word/f )
    manifest get search-manifest ;

: using-vocabulary? ( vocabulary -- ? )
    vocabulary-name manifest get search-vocabulary-names>> key? ;

: use-vocabulary ( vocab -- )
    dup using-vocabulary? [
        vocabulary-name "Already using ``" "'' vocabulary" surround
        print
    ] [
        manifest get
        [ search-vocabs>> push ]
        [ search-vocab-names>> conjoin ] 2bi
        ! [ [ load-vocab ] dip search-vocabs>> push ]
        ! [ [ vocabulary-name ] dip search-vocab-names>> conjoin ] 2bi
    ] if ;

! : add-search-vocabulary ( 

: add-vocabulary-to-manifest ( vocabulary manifest -- )
    [ [ [ words>> ] [ name>> ] bi ] [ search-vocabulary-names>> ] bi* set-at ]
    [ [ ] [ search-vocabularies>> ] bi* push ] 2bi ;
