! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs combinators.smart db2.persistent
db2.types namespaces tools.test ;
IN: db2.persistent.tests

TUPLE: manufacturer id name ;

TUPLE: color id name ;

TUPLE: car id manufacturer-id color-id year model ;

PERSISTENT: car
    { { "id" "foooid" } { INTEGER } { NOT-NULL SERIAL PRIMARY-KEY } }
    { "manufacturer-id" INTEGER }
    { "year" INTEGER }
    { "model" VARCHAR } ;

[ V{ "manufacturer_id" "year" "model" } ]
[ car persistent-table get at column-names>> ] unit-test
