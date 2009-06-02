! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs combinators db2 db2.persistent
db2.sqlite db2.sqlite.lib db2.statements db2.tuples db2.types
kernel make sequences ;
IN: db2.sqlite.tuples

M: sqlite-db-connection post-insert-tuple
    last-insert-id swap >primary-key ;
