! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors db.binders db.connections
db.postgresql.connections.private db.query-objects
db.sqlite.connections db.statements db.types namespaces
tools.test ;
IN: db.query-objects.tests

! Test expansion of insert
TUPLE: qdog id age ;

[
T{ statement
    { sql "INSERT INTO qdog (id) VALUES(?);" }
    { in
        {
            T{ in-binder
                { class qdog }
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
                        { class qdog }
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
                { class qdog }
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
                        { class qdog }
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
                { class qdog }
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
                { class qdog }
                { table-name "qdog" }
                { column-name "id" }
                { type INTEGER }
            }
            T{ out-binder
                { class qdog }
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
            { out
                {
                    T{ out-binder
                        { class qdog }
                        { table-name "qdog" }
                        { column-name "id" }
                        { type INTEGER }
                    }
                    T{ out-binder
                        { class qdog }
                        { table-name "qdog" }
                        { column-name "age" }
                        { type INTEGER }
                    }
                }
            }
            { in
                {
                    T{ in-binder
                        { class qdog }
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
                { class qdog }
                { table-name "qdog" }
                { column-name "age" }
                { type INTEGER }
                { value 1 }
            }
            T{ in-binder
                { class qdog }
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
                        { class qdog }
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
                        { class qdog }
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
                { class qdog }
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
                        { class qdog }
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
                { class qdog }
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
            { out
                {
                    T{ count-function
                        { class qdog }
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
                { class qdog }
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
                { class qdog }
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
            { out
                {
                    T{ count-function
                        { class qdog }
                        { table-name "qdog" }
                        { column-name "id" }
                        { type INTEGER }
                    }
                }
            }
            { in
                {
                    T{ in-binder
                        { class qdog }
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

