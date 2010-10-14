! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays db db.connections db.queries
db.statements kernel namespaces postgresql.db
postgresql.db.connections.private ;
IN: postgresql.db.queries

M: postgresql-db-connection current-db-name
    db-connection get db>> database>> ;

TUPLE: postgresql-table-row
    table_catalog
    table_schema
    table_name
    table_type
    self_referencing_column_name
    reference_generation
    user_defined_type_catalog
    user_defined_type_schema
    user_defined_type_name
    is_insertable_into
    is_typed
    commit_action ;

M: postgresql-db-connection table-row-class postgresql-table-row ;
