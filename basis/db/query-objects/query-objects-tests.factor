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
    { sql "SELECT id, age FROM qdog WHERE age = ?;" }
    { in
        {
            T{ in-binder
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
                    T{ in-binder
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
    { sql "UPDATE qdog SET age = ? WHERE age = ?;" }
    { in
        {
            T{ in-binder
                { table-name "qdog" }
                { column-name "age" }
                { type INTEGER }
                { value 1 }
            }
            T{ in-binder
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
                    T{ in-binder
                        { table-name "qdog" }
                        { column-name "age" }
                        { type INTEGER }
                        { value 1 }
                    }
                }
            }
            { where
                {
                    T{ in-binder
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
    { sql "DELETE FROM qdog WHERE age = ?;" }
    { in
        {
            T{ in-binder
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
                    T{ in-binder
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
    { sql "SELECT COUNT(id) FROM qdog;" }
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
    { sql "SELECT COUNT(id) FROM qdog WHERE age = ?;" }
    { in
        {
            T{ in-binder
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
                    T{ in-binder
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
        "SELECT id, name, id, user_id, street, city, zip FROM user LEFT JOIN user ON user.id = address.user_id;"
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
