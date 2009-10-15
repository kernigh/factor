! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors classes.singleton continuations db db.orm
db.orm.persistent db.transactions db.types
furnace.auth.providers kernel ;
IN: furnace.auth.providers.db

PERSISTENT: user
    { "username" VARCHAR +primary-key+ }
    { "realname" VARCHAR }
    { "password" BLOB NOT-NULL }
    { "salt" INTEGER NOT-NULL }
    { "email" VARCHAR }
    { "ticket" VARCHAR }
    { "capabilities" FACTOR-BLOB }
    { "profile" FACTOR-BLOB }
    { "deleted" INTEGER NOT-NULL } ;

SINGLETON: users-in-db

M: users-in-db get-user
    drop <user> select-tuple ;

M: users-in-db new-user
    drop
    [
        user new
            over username>> >>username
        select-tuple [
            drop f
        ] [
            dup insert-tuple
        ] if
    ] with-transaction ;

M: users-in-db update-user
    drop update-tuple ;
