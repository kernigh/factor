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
    [ define-singleton-class ]
    [ sql-type add-mixin-instance ] bi ;

: define-sql-modifier ( word -- )
    [ define-singleton-class ]
    [ sql-modifier add-mixin-instance ] bi ;

<<

SYNTAX: SQL-TYPE:
    CREATE-CLASS define-sql-type ;

SYNTAX: SQL-TYPES:
    ";" parse-tokens
    [ create-class-in define-sql-type ] each ;

SYNTAX: SQL-MODIFIER:
    CREATE-CLASS define-sql-modifier ;

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

SQL-MODIFIERS: PRIMARY-KEY SERIAL AUTOINCREMENT UNIQUE
DEFAULT NOT-NULL NULL RANDOM-ID ;

ERROR: no-sql-type name ;
ERROR: no-sql-modifier name ;

: ensure-sql-type ( object -- object )
    dup sql-type? [ no-sql-type ] unless ;

: ensure-sql-modifier ( object -- object )
    dup sql-modifier? [ no-sql-modifier ] unless ;
