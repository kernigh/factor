! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db.connections db.introspection
db.sqlite.introspection db.tester db.types tools.test ;
IN: db.sqlite.introspection.tests


: test-sqlite-introspection ( -- )
    [
        {
        T{ table-schema
            { table "computer" }
            { columns
                {
                    T{ column
                        { name "name" }
                        { type VARCHAR }
                        { modifiers "" }
                    }
                    T{ column
                        { name "os" }
                        { type VARCHAR }
                        { modifiers "" }
                    }
                    T{ column
                        { name "version" }
                        { type INTEGER }
                        { modifiers "" }
                    }
                }
            }
        }
        }
    ] [
        sqlite-test-db [
            "computer" query-table-schema
        ] with-db
    ] unit-test ;

[ test-sqlite-introspection ] test-sqlite
