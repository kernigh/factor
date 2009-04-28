! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: assocs classes.parser classes.singleton db2.connections
kernel lexer namespaces parser sequences classes.mixin ;
IN: db2.types

HOOK: sql-type>string db-connection ( type -- string )
HOOK: sql-modifiers>string db-connection ( modifiers -- string )

MIXIN: sql-type
MIXIN: sql-modifier

: define-sql-type ( word -- )
    sql-type add-mixin-instance ;

: define-sql-modifier ( word -- )
    sql-modifier add-mixin-instance ;

<<

SYNTAX: SQL-TYPE:
    CREATE-WORD define-sql-type ;

SYNTAX: SQL-TYPES:
    ";" parse-tokens
    [ create-class-in define-sql-type ] each ;

SYNTAX: SQL-MODIFIER:
    CREATE-WORD define-sql-modifier ;

SYNTAX: SQL-MODIFIERS:
    ";" parse-tokens
    [ create-class-in define-sql-modifier ] each ;
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
    URL ;

SQL-MODIFIERS: +db-assigned-id+ +user-assigned-id+ +random-id+ ;
UNION: +primary-key+ +db-assigned-id+ +user-assigned-id+ +random-id+ ;

SQL-MODIFIERS: +autoincrement+ +serial+ +unique+ +default+ +null+ +not-null+
+foreign-id+ +has-many+ +on-update+ +on-delete+ +restrict+ +cascade+
+set-null+ +set-default+ ;

SQL-MODIFIERS: PRIMARY-KEY SERIAL AUTOINCREMENT UNIQUE
DEFAULT NOT-NULL NULL ;

ERROR: no-sql-type name ;
ERROR: no-sql-modifier name ;

: ensure-sql-type ( object -- object )
    dup sql-type? [ no-sql-type ] unless ;

: ensure-sql-modifier ( object -- object )
    dup sql-modifier? [ no-sql-modifier ] unless ;
