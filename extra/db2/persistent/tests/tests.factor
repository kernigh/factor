! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs combinators.smart db2.persistent
db2.types namespaces tools.test kernel ;
IN: db2.persistent.tests

TUPLE: default-person id name birthdate email homepage ;

PERSISTENT: default-person
    { "id" INTEGER { PRIMARY-KEY AUTOINCREMENT } }
    { "name" VARCHAR }
    { "birthdate" TIMESTAMP }
    { "email" VARCHAR }
    { "homepage" URL } ;

: person1 ( -- person )
    default-person new
        "omg" >>name ;



TUPLE: computer name os version ;

PERSISTENT: computer
    { "name" VARCHAR }
    { "os" VARCHAR }
    { "version" INTEGER } ;



TUPLE: pet-store id name pets ;
TUPLE: pet id pet-store-id name type ;

PERSISTENT: pet-store
    { "id" INTEGER { PRIMARY-KEY AUTOINCREMENT } }
    { "name" VARCHAR } ;

PERSISTENT: pet
    { "id" INTEGER { PRIMARY-KEY AUTOINCREMENT } }
    { "pet-store-id" INTEGER }
    { "name" VARCHAR }
    { "type" VARCHAR } ;




TUPLE: pet-store2 id name pets ;
TUPLE: pet2 id name pet-type2-id ;
TUPLE: pet-type2 id ;

PERSISTENT: pet-store2
    { "id" INTEGER { PRIMARY-KEY AUTOINCREMENT } }
    { "name" VARCHAR } ;

PERSISTENT: pet2
    { "id" INTEGER { PRIMARY-KEY AUTOINCREMENT } }
    { "pet-store-id" INTEGER }
    { "name" VARCHAR }
    { "type" VARCHAR } ;



TUPLE: manufacturer id name ;

PERSISTENT: manufacturer
    { "id" INTEGER PRIMARY-KEY }
    { "name" VARCHAR } ;

TUPLE: color id name ;

PERSISTENT: color
    { "id" INTEGER PRIMARY-KEY }
    { "name" VARCHAR } ;

TUPLE: car id manufacturer-id year model ;
TUPLE: single-color-car < car color-id ;
TUPLE: multi-color-car < car colors ;

PERSISTENT: car
    { { "id" "foooid" } { INTEGER } { NOT-NULL SERIAL PRIMARY-KEY } }
    { "manufacturer-id" INTEGER }
    { "year" INTEGER }
    { "model" VARCHAR } ;

PERSISTENT: single-color-car
    { "color" color } ;

PERSISTENT: multi-color-car
    { "colors" color } ;

HAS-ONE: single-color-car color
HAS-MANY: multi-color-car color

! HAS-MANY: manufacturer car
! HAS-ONE: car manufacturer


! [ V{ "manufacturer_id" "year" "model" } ]
! [ car persistent-table get at column-names>> ] unit-test
