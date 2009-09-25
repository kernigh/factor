! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alarms calendar db db.orm db.orm.persistent
db.types fry http.server.filters kernel
math.intervals random system ;
IN: furnace.cache

TUPLE: server-state id expires ;

: new-server-state ( id class -- server-state )
    new swap >>id ; inline

PERSISTENT: server-state
    { "id" +random-key+ }
    { "expires" BIG-INTEGER NOT-NULL } ;

: get-state ( id class -- state )
    new-server-state select-tuple ;

: expire-state ( class -- )
    new
        -1/0. millis [a,b] >>expires
    delete-tuples ;

TUPLE: server-state-manager < filter-responder timeout ;

: new-server-state-manager ( responder class -- responder' )
    new
        swap >>responder
        20 minutes >>timeout ; inline

: touch-state ( state manager -- )
    timeout>> hence timestamp>millis >>expires drop ;
