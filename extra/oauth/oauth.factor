! Copyright (C) 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs base64 calendar checksums.hmac
checksums.sha fry http http.client kernel locals make
namespaces present random sequences sorting urls urls.encoding ;
IN: oauth

! Based on http://github.com/skypher/cl-oauth/blob/master/src/core/consumer.lisp

TUPLE: token key secret user-data ;

TUPLE: request-token < token consumer callback-uri verification-code authorized? ;

: <request-token> ( consumer-token callback-uri key secret user-data -- token )
    request-token new
        swap >>user-data
        swap >>secret
        swap >>key
        swap >>callback-uri
        swap >>consumer ;

TUPLE: request-token-params
consumer-token
user-parameters
timestamp
{ callback-uri initial: "oob" } ;

: <request-token-params> ( -- params )
    request-token-params new
        now timestamp>unix-time >>timestamp ;

:: signature-base-string ( uri request-method params -- string )
    [
        request-method % "&" %
        uri present url-encode % "&" %
        params assoc>query url-encode %
    ] "" make ;

: hmac-key ( consumer-secret token-secret -- key )
    [ url-encode ] [ "" or url-encode ] bi* "&" glue ;

: make-request-token-params ( params -- assoc )
    [
        "1.0" "oauth_version" set
        random-32 "oauth_nonce" set
        "HMAC-SHA1" "oauth_signature_method" set

        [ consumer-token>> key>> "oauth_consumer_key" set ]
        [ callback-uri>> "oauth_callback" set ]
        [ timestamp>> "oauth_timestamp" set ] tri
    ] H{ } make-assoc ;

:: signed-request-token-params ( uri request-method params -- signed-params )
    params make-request-token-params >alist sort-keys :> alist
    request-method uri assoc signature-base-string :> sbs
    params consumer-token>> secret>> f hmac-key :> key
    sbs key sha1 hmac-bytes >base64 :> signature
    alist { "oauth_signature" signature } prefix ;

: <request-token-request> ( uri params -- request )
    [ [ "POST" ] dip signed-request-token-params ] [ drop ] 2bi
    <post-request> ;

: extract-user-data ( assoc -- assoc' )
    [ drop { "oauth_token" "oauth_token_secret" } member? not ] assoc-filter ;

: parse-request-token ( params response data -- token )
    [ [ consumer-token>> ] [ callback-uri>> ] bi ]
    [ drop ]
    [
        [ "oauth_token" swap at ]
        [ "oauth_token_secret" swap at ]
        [ extract-user-data ] tri
    ] tri*
    <request-token> ;

: obtain-request-token ( uri params -- token )
    [ nip ] [ <request-token-request> http-request ] 2bi
    parse-request-token ;

! Work in progress

: uri-with-additional-query-part ( uri query-part -- uri )
    ! Given a URI string or PURI uri, adds the string QUERY-PART
    ! to the end of the URI.  If it has query params already they
    ! are added onto it.
    [ >url ] dip '[ _ assoc-union ] change-query ;

: build-auth-string ( params -- string )
    [ [ present url-encode ] bi@ "=" glue ] { } assoc>map ", " join
    "OAuth " prepend ;

: oauth-request ( request params -- response data )
    [ clone ] dip
    build-auth-string "Authorization" set-header
    http-request ;
