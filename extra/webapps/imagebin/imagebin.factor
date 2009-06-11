! Copyright (C) 2008 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel furnace.actions html.forms
http.server.dispatchers db db.tuples db.types urls
furnace.redirection multiline http namespaces
db.persistent ;
IN: webapps.imagebin

TUPLE: imagebin < dispatcher ;

TUPLE: image id path ;

PERSISTENT: image
    { "id" +db-assigned-key+ }
    { "path" { VARCHAR 256 } NOT-NULL } ;

: <uploaded-image-action> ( -- action )
    <page-action>
        { imagebin "uploaded-image" } >>template ;

SYMBOL: my-post-data
: <upload-image-action> ( -- action )
    <page-action>
        { imagebin "upload-image" } >>template
        [
            
            ! request get post-data>> my-post-data set-global
            ! image new
            !    "file" value
                ! insert-tuple
            "uploaded-image" <redirect>
        ] >>submit ;

: <imagebin> ( -- responder )
    imagebin new-dispatcher
        <upload-image-action> "" add-responder
        <upload-image-action> "upload-image" add-responder
        <uploaded-image-action> "uploaded-image" add-responder ;

