! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db.connections ;
IN: db.introspection

HOOK: all-db-objects db-connection ( -- sequence )
HOOK: all-tables db-connection ( -- sequence )
HOOK: all-indices db-connection ( -- sequence )


