! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: db2.persistent db2.types tools.test assocs namespaces
accessors ;
IN: db2.persistent.tests

TUPLE: manufacturer id name ;

TUPLE: color id name ;

TUPLE: car id manufacturer-id color-id year model ;

PERSISTENT: car {
    { { "id" "foooid" } { INTEGER } { NOT-NULL SERIAL PRIMARY-KEY } }
    { "manufacturer-id" INTEGER }
    { "year" INTEGER }
    { "model" VARCHAR }
}

[
T{ persistent
    { class car }
    { table-name "car" }
    { columns
        {
            T{ db-column
                { accessor id>> }
                { name "foooid" }
                { type INTEGER }
                { modifiers { NOT-NULL SERIAL PRIMARY-KEY } }
            }
            T{ db-column
                { accessor manufacturer-id>> }
                { name "manufacturer_id" }
                { type INTEGER }
            }
            T{ db-column
                { accessor year>> }
                { name "year" }
                { type INTEGER }
            }
            T{ db-column
                { accessor model>> }
                { name "model" }
                { type VARCHAR }
            }
        }
    }
}
] [
    car persistent-table get at
] unit-test
