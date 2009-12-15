! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.binders db.connections
db.postgresql.connections.private db.query-objects
db.sqlite.connections db.statements db.types namespaces
tools.test ;
IN: db.query-objects.tests

! Test expansion of insert
TUPLE: qdog id age ;

! Test joins
TUPLE: user id name ;
TUPLE: address id user-id street city state zip ;

[
T{ statement
    { sql "INSERT INTO qdog (id) VALUES(?);" }
    { in
        {
            T{ in-binder
                { table-name "qdog" }
                { column-name "id" }
                { type INTEGER }
                { value 0 }
            }
        }
    }
    { out V{ } }
    { errors V{ } }
}
] [
    T{ sqlite-db-connection } db-connection [
        T{ insert
            { in
                {
                    T{ in-binder
                        { table-name "qdog" }
                        { column-name "id" }
                        { type INTEGER }
                        { value 0 }
                    }
                }
            }
        } query-object>statement
    ] with-variable
] unit-test

[
T{ statement
    { sql "INSERT INTO qdog (id) VALUES($1);" }
    { in
        {
            T{ in-binder
                { table-name "qdog" }
                { column-name "id" }
                { type INTEGER }
                { value 0 }
            }
        }
    }
    { out V{ } }
    { errors V{ } }
}
] [
    T{ postgresql-db-connection } db-connection
    [
        T{ insert
            { in
                {
                    T{ in-binder
                        { table-name "qdog" }
                        { column-name "id" }
                        { type INTEGER }
                        { value 0 }
                    }
                }
            }
        } query-object>statement
    ] with-variable
] unit-test






[
T{ statement
    { sql "SELECT qdog.id, qdog.age FROM qdog WHERE qdog.age = ?;" }
    { in
        {
            T{ equal-binder
                { table-name "qdog" }
                { column-name "age" }
                { type INTEGER }
                { value 0 }
            }
        }
    }
    { out
        {
            T{ out-binder
                { table-name "qdog" }
                { column-name "id" }
                { type INTEGER }
            }
            T{ out-binder
                { table-name "qdog" }
                { column-name "age" }
                { type INTEGER }
            }
        }
    }
    { errors V{ } }
}
] [
    T{ sqlite-db-connection } db-connection
    [
        T{ select
            { from { "qdog" } }
            { out
                {
                    T{ out-binder
                        { table-name "qdog" }
                        { column-name "id" }
                        { type INTEGER }
                    }
                    T{ out-binder
                        { table-name "qdog" }
                        { column-name "age" }
                        { type INTEGER }
                    }
                }
            }
            { in
                {
                    T{ equal-binder
                        { table-name "qdog" }
                        { column-name "age" }
                        { type INTEGER }
                        { value 0 }
                    }
                }
            }
        } query-object>statement
    ] with-variable
] unit-test




[
T{ statement
    { sql "UPDATE qdog SET qdog.age = ? WHERE qdog.age = ?;" }
    { in
        {
            T{ equal-binder
                { table-name "qdog" }
                { column-name "age" }
                { type INTEGER }
                { value 1 }
            }
            T{ equal-binder
                { table-name "qdog" }
                { column-name "age" }
                { type INTEGER }
                { value 0 }
            }
        }
    }
    { out V{ } }
    { errors V{ } }
}
] [
    T{ sqlite-db-connection } db-connection
    [
        T{ update
            { in
                {
                    T{ equal-binder
                        { table-name "qdog" }
                        { column-name "age" }
                        { type INTEGER }
                        { value 1 }
                    }
                }
            }
            { where
                {
                    T{ equal-binder
                        { table-name "qdog" }
                        { column-name "age" }
                        { type INTEGER }
                        { value 0 }
                    }
                }
            }
        } query-object>statement
    ] with-variable
] unit-test

[
T{ statement
    { sql "DELETE FROM qdog WHERE qdog.age = ?;" }
    { in
        {
            T{ equal-binder
                { table-name "qdog" }
                { column-name "age" }
                { type INTEGER }
                { value 0 }
            }
        }
    }
    { out V{ } }
    { errors V{ } }
}
] [
    T{ sqlite-db-connection } db-connection
    [
        T{ delete
            { where
                {
                    T{ equal-binder
                        { table-name "qdog" }
                        { column-name "age" }
                        { type INTEGER }
                        { value 0 }
                    }
                }
            }
        } query-object>statement
    ] with-variable
] unit-test



[
T{ statement
    { sql "SELECT COUNT(qdog.id) FROM qdog;" }
    { in { } }
    { out
        {
            T{ count-function
                { table-name "qdog" }
                { column-name "id" }
                { type INTEGER }
            }
        }
    }
    { errors V{ } }
}
] [
    T{ sqlite-db-connection } db-connection
    [
        T{ select
            { from { "qdog" } }
            { out
                {
                    T{ count-function
                        { table-name "qdog" }
                        { column-name "id" }
                        { type INTEGER }
                    }
                }
            }
        } query-object>statement
    ] with-variable
] unit-test




[
T{ statement
    { sql "SELECT COUNT(qdog.id) FROM qdog WHERE qdog.age = ?;" }
    { in
        {
            T{ equal-binder
                { table-name "qdog" }
                { column-name "age" }
                { type INTEGER }
                { value 0 }
            }
        }
    }
    { out
        {
            T{ count-function
                { table-name "qdog" }
                { column-name "id" }
                { type INTEGER }
            }
        }
    }
    { errors V{ } }
}
] [
    T{ sqlite-db-connection } db-connection
    [
        T{ select
            { from { "qdog" } }
            { out
                {
                    T{ count-function
                        { table-name "qdog" }
                        { column-name "id" }
                        { type INTEGER }
                    }
                }
            }
            { in
                {
                    T{ equal-binder
                        { table-name "qdog" }
                        { column-name "age" }
                        { type INTEGER }
                        { value 0 }
                    }
                }
            }
        } query-object>statement
    ] with-variable
] unit-test


[
T{ statement
    { sql
        "SELECT user.id, user.name, address.id, address.user_id, address.street, address.city, address.zip FROM user LEFT JOIN address ON user.id = address.user_id;"
    }
    { in { } }
    { out
        {
            T{ out-binder
                { table-name "user" }
                { column-name "id" }
                { type INTEGER }
            }
            T{ out-binder
                { table-name "user" }
                { column-name "name" }
                { type VARCHAR }
            }
            T{ out-binder
                { table-name "address" }
                { column-name "id" }
                { type INTEGER }
            }
            T{ out-binder
                { table-name "address" }
                { column-name "user_id" }
                { type INTEGER }
            }
            T{ out-binder
                { table-name "address" }
                { column-name "street" }
                { type VARCHAR }
            }
            T{ out-binder
                { table-name "address" }
                { column-name "city" }
                { type VARCHAR }
            }
            T{ out-binder
                { table-name "address" }
                { column-name "zip" }
                { type INTEGER }
            }
        }
    }
    { errors V{ } }
}
] [
    T{ sqlite-db-connection } db-connection
    [
        T{ select
            { out
                {
                    T{ out-binder
                        { table-name "user" }
                        { column-name "id" }
                        { type INTEGER }
                    }
                    T{ out-binder
                        { table-name "user" }
                        { column-name "name" }
                        { type VARCHAR }
                    }
                    T{ out-binder
                        { table-name "address" }
                        { column-name "id" }
                        { type INTEGER }
                    }
                    T{ out-binder
                        { table-name "address" }
                        { column-name "user_id" }
                        { type INTEGER }
                    }
                    T{ out-binder
                        { table-name "address" }
                        { column-name "street" }
                        { type VARCHAR }
                    }
                    T{ out-binder
                        { table-name "address" }
                        { column-name "city" }
                        { type VARCHAR }
                    }
                    T{ out-binder
                        { table-name "address" }
                        { column-name "zip" }
                        { type INTEGER }
                    }
                }
            }
            { from { "user" } }
            { join
                {
                    T{ join-binder
                        { table-name1 "user" }
                        { column-name1 "id" }
                        { table-name2 "address" }
                        { column-name2 "user_id" }
                    }
                }
            }
        } query-object>statement
    ] with-variable
] unit-test


[
T{ statement
    { sql
        "SELECT user.id, user.name FROM user WHERE (qdog.id = ? and qdog.id = ?);"
    }
    { in
        {
            T{ equal-binder
                { table-name "qdog" }
                { column-name "id" }
                { type INTEGER }
                { value 0 }
            }
            T{ equal-binder
                { table-name "qdog" }
                { column-name "id" }
                { type INTEGER }
                { value 1 }
            }
        }
    }
    { out
        {
            T{ out-binder
                { table-name "user" }
                { column-name "id" }
                { type INTEGER }
            }
            T{ out-binder
                { table-name "user" }
                { column-name "name" }
                { type VARCHAR }
            }
        }
    }
    { errors V{ } }
}
] [
    T{ sqlite-db-connection } db-connection
    [
        T{ select
            { in
                {
                    T{ and-binder
                        { binders
                            {
                                T{ equal-binder
                                    { table-name "qdog" }
                                    { column-name "id" }
                                    { type INTEGER }
                                    { value 0 }
                                }
                                T{ equal-binder
                                    { table-name "qdog" }
                                    { column-name "id" }
                                    { type INTEGER }
                                    { value 1 }
                                }
                            }
                        }
                    }
                }
            }
            { out
                {
                    T{ out-binder
                        { table-name "user" }
                        { column-name "id" }
                        { type INTEGER }
                    }
                    T{ out-binder
                        { table-name "user" }
                        { column-name "name" }
                        { type VARCHAR }
                    }
                }
            }
            { from { "user" } }
        } query-object>statement
    ] with-variable
] unit-test

[
T{ statement
    { sql
        "SELECT user.id, user.name FROM user WHERE (qdog.id > ? and qdog.id <= ?);"
    }
    { in
        {
            T{ greater-than-binder
                { table-name "qdog" }
                { column-name "id" }
                { type INTEGER }
                { value 0 }
            }
            T{ less-than-equal-binder
                { table-name "qdog" }
                { column-name "id" }
                { type INTEGER }
                { value 5 }
            }
        }
    }
    { out
        {
            T{ out-binder
                { table-name "user" }
                { column-name "id" }
                { type INTEGER }
            }
            T{ out-binder
                { table-name "user" }
                { column-name "name" }
                { type VARCHAR }
            }
        }
    }
    { errors V{ } }
}
] [
    T{ sqlite-db-connection } db-connection
    [
        T{ select
            { in
                {
                    T{ and-binder
                        { binders
                            {
                                T{ greater-than-binder
                                    { table-name "qdog" }
                                    { column-name "id" }
                                    { type INTEGER }
                                    { value 0 }
                                }
                                T{ less-than-equal-binder
                                    { table-name "qdog" }
                                    { column-name "id" }
                                    { type INTEGER }
                                    { value 5 }
                                }
                            }
                        }
                    }
                }
            }
            { out
                {
                    T{ out-binder
                        { table-name "user" }
                        { column-name "id" }
                        { type INTEGER }
                    }
                    T{ out-binder
                        { table-name "user" }
                        { column-name "name" }
                        { type VARCHAR }
                    }
                }
            }
            { from { "user" } }
        } query-object>statement
    ] with-variable
] unit-test
