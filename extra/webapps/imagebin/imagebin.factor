! Copyright (C) 2008 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators constructors db.orm
db.orm.persistent db.types furnace.actions furnace.alloy
furnace.redirection html.forms http.server
http.server.dispatchers http.server.static io.directories
io.encodings.utf8 io.files io.files.temp io.files.unique
io.pathnames kernel math math.parser namespaces sequences
sorting validators db.sqlite db.connections ;
IN: webapps.imagebin

TUPLE: imagebin < dispatcher path ;

: <uploaded-image-action> ( -- action )
    <page-action>
        { imagebin "uploaded-image" } >>template ;

M: imagebin call-responder*
    [ imagebin set ] [ call-next-method ] bi ;

TUPLE: imagebin-file path original-name ;

CONSTRUCTOR: imagebin-file ( path original-name -- obj ) ;

PERSISTENT: imagebin-file
    { "path" VARCHAR +primary-key+ }
    { "original-name" VARCHAR } ;

: move-image ( mime-file -- )
    [ temporary-path>> imagebin get path>> move-file-unique file-name ]
    [ filename>> ] bi
    <imagebin-file> insert-tuple ;
    
: <download-image-action> ( -- action )
    <page-action>
        { imagebin "download-image" } >>template
        [ { { "id" [ v-number ] } } validate-params ] >>validate
        [
            imagebin get path>> "id" value append-path <static>
            <redirect>
        ] >>submit ;

: <list-images> ( -- action )
    <page-action>
        [
            imagebin-file new select-tuples "images" set-value
        ] >>init
        { imagebin "list-images" } >>template ;

: <default-imagebin-action> ( -- action )
    <page-action>
        { imagebin "imagebin" } >>template
        [
            "file1" param [ move-image ] when*
            "file2" param [ move-image ] when*
            "file3" param [ move-image ] when*
            "uploaded-image" <redirect>
        ] >>submit ;

: imagebin-db ( -- db ) "resource:imagebin.db" temp-file <sqlite-db> ;

: <imagebin> ( image-directory -- responder )
    imagebin new-dispatcher
        swap [ make-directories ] [ >>path ] bi
        <default-imagebin-action> "" add-responder
        <download-image-action> "download-image" add-responder
        <uploaded-image-action> "uploaded-image" add-responder
        imagebin-db <alloy> ;

: run-imagebin ( -- )
    imagebin-db [ { imagebin-file } ensure-tables ] with-db
    "resource:images" <imagebin> main-responder set-global ;

MAIN: run-imagebin
