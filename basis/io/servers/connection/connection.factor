! Copyright (C) 2003, 2009 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays calendar combinators.short-circuit
concurrency.combinators concurrency.count-downs
concurrency.flags concurrency.semaphores continuations debugger
destructors fry io.sockets io.sockets.secure io.streams.duplex
io.timeouts kernel logging make math namespaces present
prettyprint sequences strings threads random ;
IN: io.servers.connection

TUPLE: threaded-server
name
log-level
secure
insecure
secure-config
sockets
max-connections
semaphore
timeout
encoding
handler
server-stopped ;

: local-server ( port -- addrspec ) "localhost" swap <inet> ;

: internet-server ( port -- addrspec ) f swap <inet> ;

: new-threaded-server ( encoding class -- threaded-server )
    new
        "server" >>name
        DEBUG >>log-level
        <secure-config> >>secure-config
        1 minutes >>timeout
        [ "No handler quotation" throw ] >>handler
        swap >>encoding ;

: <threaded-server> ( encoding -- threaded-server )
    threaded-server new-threaded-server ;

GENERIC: handle-client* ( threaded-server -- )

<PRIVATE

GENERIC: (>insecure) ( obj -- obj )

M: inet (>insecure) ;
M: local (>insecure) ;
M: integer (>insecure) internet-server ;
M: string (>insecure) internet-server ;
M: array (>insecure) [ (>insecure) ] map ;
M: f (>insecure) ;

: >insecure ( obj -- seq )
    (>insecure) dup sequence? [ 1array ] unless ;

: >secure ( addrspec -- addrspec' )
    >insecure
    [ dup { [ secure? ] [ not ] } 1|| [ <secure> ] unless ] map ;

: listen-on ( threaded-server -- addrspecs )
    [ secure>> >secure ] [ insecure>> >insecure ] bi append
    [ resolve-host ] map concat ;

: accepted-connection ( remote local -- )
    [
        [ "remote: " % present % ", " % ]
        [ "local: " % present % ]
        bi*
    ] "" make
    \ accepted-connection NOTICE log-message ;

: log-connection ( remote local -- )
    [ accepted-connection ]
    [ [ remote-address set ] [ local-address set ] bi* ]
    2bi ;

M: threaded-server handle-client* handler>> call( -- ) ;

: handle-client ( client remote local -- )
    '[
        _ _ log-connection
        threaded-server get
        [ timeout>> timeouts ] [ handle-client* ] bi
    ] with-stream ;

\ handle-client NOTICE add-error-logging

: thread-name ( server-name addrspec -- string )
    unparse-short " connection from " glue ;

: (accept-connection) ( server -- )
    [ accept ] [ addr>> ] bi
    [ '[ _ _ _ handle-client ] ]
    [ drop threaded-server get name>> swap thread-name ] 2bi
    spawn drop ;

: accept-connection ( server -- )
    threaded-server get semaphore>>
    [ [ (accept-connection) ] with-semaphore ]
    [ (accept-connection) ]
    if* ;

: accept-loop ( server -- )
    [ accept-connection ] [ accept-loop ] bi ;

: start-accept-loop ( server -- ) accept-loop ;

\ start-accept-loop NOTICE add-error-logging

: make-server ( addrspec -- server )
    threaded-server get encoding>> <server> ;

: init-server ( threaded-server -- threaded-server )
    <flag> >>server-stopped
    dup semaphore>> [
        dup max-connections>> [
            <semaphore> >>semaphore
        ] when*
    ] unless ;

ERROR: no-ports-configured threaded-server ;

: set-sockets ( threaded-server -- threaded-server )
    dup listen-on [
        no-ports-configured
    ] [
        [ [ make-server |dispose ] map >>sockets ] with-destructors
    ] if-empty ;

: (start-server) ( threaded-server -- )
    init-server
    dup threaded-server [
        [ ] [ name>> ] bi
        [
            set-sockets sockets>>
            [ '[ _ [ start-accept-loop ] with-disposal ] in-thread ] each
        ] with-logging
    ] with-variable ;

PRIVATE>

: start-server ( threaded-server -- threaded-server )
    #! Only create a secure-context if we want to listen on
    #! a secure port, otherwise start-server won't work at
    #! all if SSL is not available.
    dup dup secure>> [
        dup secure-config>> [
            (start-server)
        ] with-secure-context
    ] [
        (start-server)
    ] if ;

: stop-server ( threaded-server -- )
    [ [ f ] change-sockets drop dispose-each ]
    [ server-stopped>> raise-flag ] bi ;

: stop-this-server ( -- )
    threaded-server get stop-server ;

: this-port ( -- n )
    threaded-server get sockets>> first addr>> port>> ;

: wait-for-server ( threaded-server -- )
    server-stopped>> wait-for-flag ;

: with-threaded-server ( threaded-server quot -- )
    over
    '[
        [ _ start-server threaded-server _ with-variable ]
        [ _ stop-server ]
        [ ] cleanup
    ] call ; inline

: random-port ( obj -- n/f )
    dup sequence? [ random ] when ;

: secure-port ( -- n/f )
    threaded-server get secure>> random-port ;

: insecure-port ( -- n/f )
    threaded-server get insecure>> random-port ;
