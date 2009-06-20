! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs combinators db db.persistent
db.sqlite db.sqlite.connections db.sqlite.lib db.statements
db.tuples db.types kernel make sequences ;
IN: db.sqlite.tuples

M: sqlite-db-connection post-insert-tuple
    last-insert-id swap >primary-key ;
