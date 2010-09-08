! Copyright (C) 2003, 2009 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays calendar combinators.short-circuit
concurrency.combinators concurrency.count-downs
concurrency.flags concurrency.semaphores continuations debugger
destructors fry io.sockets io.sockets.secure io.streams.duplex
io.timeouts kernel logging make math namespaces present
prettyprint sequences strings threads ;
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
listen-on
ready-counter
server-stopped ;

: local-server ( port -- addrspec ) "localhost" swap <inet> ;

: internet-server ( port -- addrspec ) f swap <inet> ;

: new-threaded-server ( encoding class -- threaded-server )
    new
        "server" >>name
        DEBUG >>log-level
        <secure-config> >>secure-config
        V{ } clone >>sockets
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

: accept-connection ( threaded-server -- )
    [ accept ] [ addr>> ] bi
    [ '[ _ _ _ handle-client ] ]
    [ drop threaded-server get name>> swap thread-name ] 2bi
    spawn drop ;

: accept-loop ( threaded-server -- )
    [
        threaded-server get semaphore>>
        [ [ accept-connection ] with-semaphore ]
        [ accept-connection ]
        if*
    ] [ accept-loop ] bi ;

: started-accept-loop ( server -- )
    threaded-server get
    [ sockets>> push ] [ ready-counter>> count-down ] bi ;

: start-accept-loop ( server -- )
    [ started-accept-loop ] [ [ accept-loop ] with-disposal ] bi ;

: make-server ( addrspec -- server )
    threaded-server get encoding>> <server> ;

\ start-accept-loop NOTICE add-error-logging

ERROR: no-ports-configured threaded-server ;

: check-ports-configured ( threaded-server -- threaded-server )
    dup listen-on>> empty? [ no-ports-configured ] when ;

: set-listening-ports ( threaded-server -- threaded-server )
    dup listen-on
    [ >>listen-on ] [ length <count-down> >>ready-counter ] bi ;

: init-server ( threaded-server -- threaded-server )
    set-listening-ports
    <flag> >>server-stopped
    dup semaphore>> [
        dup max-connections>> [
            <semaphore> >>semaphore
        ] when*
    ] unless ;

: ((start-server)) ( threaded-server -- )
    init-server
    check-ports-configured
    dup threaded-server [
        [ ] [ name>> ] bi
        [
            [
                listen-on>> [ make-server |dispose ] map
                [ '[ _ start-accept-loop ] in-thread ] parallel-each
            ] with-destructors
        ] with-logging
    ] with-variable ;

: (start-server) ( threaded-server -- )
    #! Only create a secure-context if we want to listen on
    #! a secure port, otherwise start-server won't work at
    #! all if SSL is not available.
    dup secure>> [
        dup secure-config>> [
            ((start-server))
        ] with-secure-context
    ] [
        ((start-server))
    ] if ;

PRIVATE>

: start-server ( threaded-server -- threaded-server )
    [ (start-server) ]
    [ ready-counter>> await ]
    [ ] tri ;

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

GENERIC: port ( addrspec -- n )

M: integer port ;

M: object port port>> ;

: secure-port ( -- n )
    threaded-server get dup [ secure>> port ] when ;

: insecure-port ( -- n )
    threaded-server get dup [ insecure>> port ] when ;
