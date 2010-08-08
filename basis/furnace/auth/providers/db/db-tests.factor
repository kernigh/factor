USING: accessors continuations db.connections db.orm db.sqlite
furnace.actions furnace.auth furnace.auth.login
furnace.auth.providers io.directories io.files.temp kernel
namespaces tools.test ;
IN: furnace.auth.providers.db.tests

<action> "test" <login-realm> realm set

[ "auth-test.db" temp-file delete-file ] ignore-errors

"auth-test.db" temp-file <sqlite-db> [

    [ user drop-table ] ignore-errors

    [ ] [ user create-table ] unit-test

    [ t ] [
        "slava" <user>
            "foobar" >>encoded-password
            "slava@factorcode.org" >>email
            H{ } clone >>profile
            users new-user
            username>> "slava" =
    ] unit-test

    [ f ] [
        "slava" <user>
            H{ } clone >>profile
        users new-user
    ] unit-test

    [ f ] [ "fdasf" "slava" check-login >boolean ] unit-test

    [ ] [ "foobar" "slava" check-login "user" set ] unit-test

    [ t ] [ "user" get >boolean ] unit-test

    [ ] [ "user" get "fdasf" >>encoded-password drop ] unit-test

    [ ] [ "user" get users update-user ] unit-test

    [ t ] [ "fdasf" "slava" check-login >boolean ] unit-test

    [ f ] [ "foobar" "slava" check-login >boolean ] unit-test
] with-db
