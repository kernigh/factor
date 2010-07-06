! Copyright (C) 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs base64 calendar checksums.hmac
checksums.sha combinators fry http http.client kernel locals
make math namespaces present random sequences sorting strings
urls urls.encoding ;
IN: oauth

! Based on http://github.com/skypher/cl-oauth/blob/master/src/core/consumer.lisp

TUPLE: token key secret user-data ;

TUPLE: request-token < token consumer callback-url verification-code authorized? ;

: <request-token> ( consumer-token callback-url key secret user-data -- token )
    request-token new
        swap >>user-data
        swap >>secret
        swap >>key
        swap >>callback-url
        swap >>consumer ;

TUPLE: request-token-params
consumer-token
timestamp
nonce
{ callback-url initial: "oob" } ;

: <request-token-params> ( -- params )
    request-token-params new
        now timestamp>unix-time >integer >>timestamp
        random-32 >>nonce ;

<PRIVATE

:: signature-base-string ( url request-method params -- string )
    [
        request-method % "&" %
        url present url-encode-full % "&" %
        params assoc>query url-encode-full %
    ] "" make ;

: hmac-key ( consumer-secret token-secret -- key )
    [ url-encode-full ] [ "" or url-encode-full ] bi* "&" glue ;

: make-request-token-params ( params -- assoc )
    [
        "1.0" "oauth_version" set
        "HMAC-SHA1" "oauth_signature_method" set

        {
            [ consumer-token>> key>> "oauth_consumer_key" set ]
            [ callback-url>> "oauth_callback" set ]
            [ timestamp>> "oauth_timestamp" set ]
            [ nonce>> "oauth_nonce" set ]
        } cleave
    ] H{ } make-assoc ;

:: signed-request-token-params ( url request-method params -- signed-params )
    params make-request-token-params >alist sort-keys :> alist
    url request-method alist signature-base-string :> sbs
    params consumer-token>> secret>> f hmac-key :> key
    sbs key sha1 hmac-bytes >base64 >string :> signature
    alist { "oauth_signature" signature } prefix ;

: <request-token-request> ( url params -- request )
    [ [ "POST" ] dip signed-request-token-params ] [ drop ] 2bi
    <post-request> ;

: extract-user-data ( assoc -- assoc' )
    [ drop { "oauth_token" "oauth_token_secret" } member? not ] assoc-filter ;

: parse-request-token ( params response data -- token )
    [ [ consumer-token>> ] [ callback-url>> ] bi ]
    [ drop ]
    [
        query>assoc
        [ "oauth_token" swap at ]
        [ "oauth_token_secret" swap at ]
        [ extract-user-data ] tri
    ] tri*
    <request-token> ;

PRIVATE>

: obtain-request-token ( url params -- token )
    [ nip ] [ <request-token-request> http-request ] 2bi
    parse-request-token ;

: authorize-url ( token -- url )
    "https://twitter.com/oauth/authorize" >url
        swap "oauth_token" set-query-param ;

TUPLE: access-token-params
request-token
timestamp
nonce ;

: <access-token-params> ( -- params )
    access-token-params new
        now timestamp>unix-time >integer >>timestamp
        random-32 >>nonce ;

<PRIVATE

: <access-token-request> ( url params -- request )
    
    ;

PRIVATE>

: obtain-access-token ( url params -- token )
    [ nip ] [ <access-token-request> http-request ] 2bi
    parse-access-token ;

! Work in progress

: url-with-additional-query-part ( url query-part -- url )
    ! Given a URI string or PURI url, adds the string QUERY-PART
    ! to the end of the URI.  If it has query params already they
    ! are added onto it.
    [ >url ] dip '[ _ assoc-union ] change-query ;

: build-auth-string ( params -- string )
    [ [ present url-encode-full ] bi@ "=" glue ] { } assoc>map ", " join
    "OAuth " prepend ;

: oauth-request ( request params -- response data )
    [ clone ] dip
    build-auth-string "Authorization" set-header
    http-request ;
