! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db db.binders db.errors db.orm db.orm.examples
db.orm.fql db.statements db.statements.tests db.tester db.types
kernel literals multiline tools.test ;
IN: db.orm.fql.tests

: test-fql-user ( -- )
    [ "drop table user;" sql-command ] ignore-table-missing

    [ ] [ user create-table sql-command ] unit-test

    [ ] [
        {
            $[ user "user" "name" VARCHAR "erg" f <in-binder> ]
            $[ user "user" "age" INTEGER 28 f <in-binder> ]
        } <insert>
        expand-fql sql-bind-typed-command
    ] unit-test


    [ ] [
        <select>
            $[ user "user0" "name" VARCHAR "erg" f <in-binder> ] >>in
            {
                $[ user "user0" "name" VARCHAR f <out-binder> ]
                $[ user "user0" "age" INTEGER f <out-binder> ]
            } >>out
        expand-fql sql-bind-typed-query
    ] unit-test

    [
        { { "erg" 28 } }
    ] [
        <select>
            $[ user "user0" "name" VARCHAR "erg" f <in-binder> ] >>in
            {
                $[ user "user0" "name" VARCHAR f <out-binder> ]
                $[ user "user0" "age" INTEGER f <out-binder> ]
            } >>out
        expand-fql sql-bind-typed-query
    ] unit-test
    ;




/*

: test-fql ( -- )
    create-computer-table

    [ "INSERT INTO computer (name, os) VALUES (?, ?)" ]
    [
        "computer"
        { { "name" { "lol" VARCHAR } } { "os" { "os2" VARCHAR } } } <insert>
        expand-fql sql>>
    ] unit-test

    [ "select name, os from computer" ]
    [
        select new
            { "name" "os" } >>names
            "computer" >>from
        expand-fql sql>>
    ] unit-test
    
    [ "select name, os from computer group by os order by lol offset 100 limit 3" ]
    [
        select new
            { "name" "os" } >>names
            "computer" >>from
            "os" >>group-by
            "lol" >>order-by
            100 >>offset
            3 >>limit
        expand-fql sql>>
    ] unit-test

    [
        "select name, os from computer where hmm > ? or foo is ? group by os order by lol offset 100 limit 3"
    ] [
        select new
            { "name" "os" } >>names
            "computer" >>from
            T{ or-sequence
                { sequence { T{ op-gt f "hmm" { 1 INTEGER } } T{ op-is f "foo" { "NULL" NULL } } } }
            } >>where
            "os" >>group-by
            "lol" >>order-by
            100 >>offset
            3 >>limit expand-fql sql>>
    ] unit-test

    [ "delete from computer order by omg limit 3" ]
    [
        delete new
            "computer" >>tables
            "omg" >>order-by
            3 >>limit
        expand-fql sql>>
    ] unit-test

    [ "update computer set name = ? order by omg limit 3" ]
    [
        update new
            "computer" >>tables
            "name" >>keys
            "oscar" >>values
            "omg" >>order-by
            3 >>limit
        expand-fql sql>>
    ] unit-test

    [ "select count(name) from computer" ]
    [
        select new
            "computer" >>from
            "name" <fql-count> >>names
        expand-fql sql>>
    ] unit-test

    ! nonsensical query
    [ "select min(name) from computer" ]
    [
        select new
            "computer" >>from
            "name" <fql-min> >>names
        expand-fql sql>>
    ] unit-test

    ;

[ test-fql ] test-dbs


: test-multi-select ( -- )
    <select>
    { "user.username" "blog.id" "blog.url" "post.id" "post.date"
    "post.title" "post.content" } >>names
    "post" >>from
    "blog" "blog.id" "post.blog_id" <left-outer-join>
    "user" "user.id" "blog.user_id" <left-outer-join>
    2array >>join
    "blog.url" "erg"  <op-eq> 1array >>where
    expand-fql ;

T{ tuple-out
    { table "user" }
    { class user }
    { slots { "username" } }
}
T{ tuple-out
    { table "blog" }
    { class blog }
    { slots { "id" "url" } }
}
T{ tuple-out
    { table "post" }
    { class post }
    { slots { "id" "date" "title" "content" } }
}

*/
