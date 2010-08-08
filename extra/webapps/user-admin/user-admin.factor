! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs combinators db.orm furnace
furnace.actions furnace.auth furnace.auth.login
furnace.auth.providers furnace.auth.providers.db
furnace.boilerplate furnace.redirection furnace.utilities
html.components html.forms http.server http.server.dispatchers
kernel namespaces sequences splitting strings urls validators
words ;
IN: webapps.user-admin

TUPLE: user-admin < dispatcher ;

: <user-list-action> ( -- action )
    <page-action>
        [ f <user> select-tuples "users" set-value ] >>init
        { user-admin "user-list" } >>template ;

: init-capabilities ( -- )
    capabilities get words>strings "capabilities" set-value ;

: validate-capabilities ( -- )
    "capabilities" value
    [ [ param empty? not ] keep set-value ] each ;

: selected-capabilities ( -- seq )
    "capabilities" value [ value ] filter [ string>word ] map ;

: validate-user ( -- )
    {
        { "username" [ v-username ] }
        { "realname" [ [ v-one-line ] v-optional ] }
        { "email" [ [ v-email ] v-optional ] }
    } validate-params ;

: <new-user-action> ( -- action )
    <page-action>
        [
            "username" param <user> from-object
            init-capabilities
        ] >>init

        { user-admin "new-user" } >>template

        [
            init-capabilities
            validate-capabilities

            validate-user

            {
                { "new-password" [ v-password ] }
                { "verify-password" [ v-password ] }
            } validate-params

            same-password-twice

            user new "username" value >>username select-tuple
            [ user-exists ] when
        ] >>validate

        [
            "username" value <user>
                "realname" value >>realname
                "email" value >>email
                "new-password" value >>encoded-password
                H{ } clone >>profile
                selected-capabilities >>capabilities

            insert-tuple

            URL" $user-admin" <redirect>
        ] >>submit ;

: validate-username ( -- )
    { { "username" [ v-username ] } } validate-params ;

: select-capabilities ( seq -- )
    [ t swap word>string set-value ] each ;

: <edit-user-action> ( -- action )
    <page-action>
        [
            validate-username

            "username" value <user> select-tuple
            [ from-object ] [ capabilities>> select-capabilities ] bi

            init-capabilities
        ] >>init

        { user-admin "edit-user" } >>template

        [
            "username" value <user> select-tuple
            [ from-object ] [ capabilities>> select-capabilities ] bi

            init-capabilities
            validate-capabilities

            validate-user

            {
                { "new-password" [ [ v-password ] v-optional ] }
                { "verify-password" [ [ v-password ] v-optional ] }
            } validate-params

            "new-password" "verify-password"
            [ value empty? not ] either? [
                same-password-twice
            ] when
        ] >>validate

        [
            "username" value <user> select-tuple
                "realname" value >>realname
                "email" value >>email
                selected-capabilities >>capabilities

            "new-password" value empty? [
                "new-password" value >>encoded-password
            ] unless

            update-tuple

            URL" $user-admin" <redirect>
        ] >>submit ;

: <delete-user-action> ( -- action )
    <action>
        [
            validate-username
            "username" value <user> delete-tuples
            URL" $user-admin" <redirect>
        ] >>submit ;

SYMBOL: can-administer-users?

can-administer-users? define-capability

: <user-admin> ( -- responder )
    user-admin new-dispatcher
        <user-list-action> "" add-responder
        <new-user-action> "new" add-responder
        <edit-user-action> "edit" add-responder
        <delete-user-action> "delete" add-responder
    <boilerplate>
        { user-admin "user-admin" } >>template
    <protected>
        "administer users" >>description
        { can-administer-users? } >>capabilities ;

: make-admin ( username -- )
    <user>
    select-tuple
    [ can-administer-users? suffix ] change-capabilities
    update-tuple ;
