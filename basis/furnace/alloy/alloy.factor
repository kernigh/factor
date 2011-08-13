! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: calendar db db.connections fry furnace.asides
furnace.auth.login.permits furnace.auth.providers furnace.cache
furnace.conversations furnace.db furnace.sessions kernel orm
orm.tuples sequences timers ;
IN: furnace.alloy

CONSTANT: state-classes { session aside conversation permit }

: init-furnace-tables ( -- )
    state-classes ensure-tables
    user ensure-table ;

: <alloy> ( responder db -- responder' )
    [ [ init-furnace-tables ] with-db ] keep
    [
        <asides>
        <conversations>
        <sessions>
    ] dip
    <db-persistence> ;

: start-expiring ( db -- )
    '[
        _ [ state-classes [ expire-state ] each ] with-db
    ] 5 minutes every drop ;
