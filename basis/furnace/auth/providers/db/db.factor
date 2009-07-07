! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors classes.singleton continuations db.transactions
db db.persistent db.tuples db.types furnace.auth.providers
kernel ;
IN: furnace.auth.providers.db

PERSISTENT: user
    { "id" +db-assigned-key+ }
    { "username" { VARCHAR 256 } }
    { "realname" { VARCHAR 256 } }
    { "password" BLOB NOT-NULL }
    { "salt" INTEGER NOT-NULL }
    { "email" { VARCHAR 256 } }
    { "ticket" { VARCHAR 256 } }
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
