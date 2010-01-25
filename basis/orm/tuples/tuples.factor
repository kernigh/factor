! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: ;
IN: orm.tuples

: insert-tuple ( tuple -- )
    ;

: create-table ( class -- ) ;
: ensure-table ( class -- ) ;
: ensure-tables ( classes -- ) ;
: recreate-table ( class -- ) ;

: drop-table ( class -- ) ;

: insert-tuple ( tuple -- ) ;

: update-tuple ( tuple -- ) ;

: delete-tuples ( tuple -- ) ;

: select-tuple ( query/tuple -- tuple/f ) ;
: select-tuples ( query/tuple -- tuples ) ;
: count-tuples ( query/tuple -- n ) ;
