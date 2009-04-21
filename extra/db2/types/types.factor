! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: assocs classes.parser classes.singleton db2.connections
kernel lexer namespaces parser sequences ;
IN: db2.types

HOOK: sql-type>string db-connection ( type -- string )
HOOK: sql-modifiers>string db-connection ( modifiers -- string )

<<

SYMBOL: db-types

db-types [ H{ } clone ] initialize

SYMBOL: db-modifiers

db-modifiers [ H{ } clone ] initialize

>>

: define-db-type ( word -- )
    [ define-singleton-class ]
    [ dup db-types get set-at ] bi ;

: define-db-modifier ( word -- )
    [ define-singleton-class ]
    [ dup db-modifiers get set-at ] bi ;

<<

SYNTAX: SQL-TYPE:
    CREATE-WORD define-db-type ;

SYNTAX: SQL-TYPES:
    ";" parse-tokens
    [ create-class-in define-db-type ] each ;

SYNTAX: SQL-MODIFIER:
    CREATE-WORD define-db-modifier ;

SYNTAX: SQL-MODIFIERS:
    ";" parse-tokens
    [ create-class-in define-db-modifier ] each ;
>>

SQL-TYPES:
    INTEGER
    BIG-INTEGER
    SIGNED-BIG-INTEGER
    UNSIGNED-BIG-INTEGER
    DOUBLE
    REAL
    BOOLEAN
    TEXT
    VARCHAR
    DATE
    TIME
    DATETIME
    TIMESTAMP
    BLOB
    FACTOR-BLOB
    NULL
    URL ;

SQL-MODIFIERS: +db-assigned-id+ +user-assigned-id+ +random-id+ ;
UNION: +primary-key+ +db-assigned-id+ +user-assigned-id+ +random-id+ ;

SQL-MODIFIERS: +autoincrement+ +serial+ +unique+ +default+ +null+ +not-null+
+foreign-id+ +has-many+ +on-update+ +on-delete+ +restrict+ +cascade+
+set-null+ +set-default+ ;

SQL-MODIFIERS: PRIMARY-KEY SERIAL AUTOINCREMENT UNIQUE
DEFAULT NOT-NULL ;

NULL dup db-modifiers get set-at

ERROR: no-sql-type name ;
ERROR: no-sql-modifier name ;

: sql-type? ( object -- ? ) db-types get key? ;
: sql-modifier? ( object -- ? ) db-modifiers get key? ;

: ensure-sql-type ( object -- object )
    dup sql-type? [ no-sql-type ] unless ;

: ensure-sql-modifier ( object -- object )
    dup sql-modifier? [ no-sql-modifier ] unless ;
