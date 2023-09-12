import traceback

from postgres.postgresexecutor import PostgresExecutor
from schema_management.tables import TableDefinition, PrimaryKey, ForeignKey, VirtualColumn, TableColumn, \
    ForeignKeyN


class MetadataReader:
    _metadata_tables = None

    @classmethod
    def tables(cls, force=False):
        if not force and cls._metadata_tables is not None:
            return cls._metadata_tables
        tables = {}
        cursor = PostgresExecutor.open_read_cursor()
        cursor.execute(
            'SELECT DISTINCT 1, TableName, ColumnName, Type, KeyColumns FROM metadata ORDER BY TableName, ColumnName')
        rows = cursor.fetchall()
        last_name = ""
        for row in rows:
            [_, table_name, column_name, data_type, key_column_info] = row
            if table_name != last_name:
                # print(f"Reading metadata for table {table_name}")
                last_name = table_name
            if table_name not in tables:
                tables[table_name] = TableDefinition(table_name, [])
            # use "match" syntax once we have Python 3.10 installed
            if data_type == "FOREIGN KEY":
                source_columns, target_table, target_columns, lookup_columns, known_as = ForeignKey.parse_out_key_columns(key_column_info)
                fk = ForeignKey(table_name, source_columns, target_table, target_columns, lookup_columns, known_as)
                tables[table_name].elements.append(fk)
            elif data_type == "FOREIGN KEY N":
                source_columns, target_table, target_columns, lookup_columns, known_as, association_table_alias = ForeignKeyN.parse_out_key_columns(key_column_info)
                fk = ForeignKeyN(table_name, source_columns, target_table, target_columns, lookup_columns, known_as, association_table_alias)
                tables[table_name].elements.append(fk)
            # print(f"Foreign Key for source columns {source_columns} to target {target_table}:{target_columns}")
            elif data_type == "PRIMARY KEY":
                pk = PrimaryKey(table_name, key_column_info.split(","))
                tables[table_name].elements.append(pk)
            elif data_type == "VIRTUAL COLUMN":
                associated_column_name, function_to_call, representation = VirtualColumn.parse_out_key_elements(key_column_info)
                vc = VirtualColumn(table_name, column_name, associated_column_name, function_to_call, representation)
                tables[table_name].elements.append(vc)
            elif data_type == "INDEX REQUEST":
                continue
            else:
                col = TableColumn(table_name, column_name, data_type)
                # print(f'Added column {column_name}')
                try:
                    tables[table_name].elements.append(col)
                except Exception as e:
                    print(str(e))
                    traceback.print_exc(limit=None, file=None, chain=True)
        print(f"Populated {len(tables)} tables")
        cls._metadata_tables = tables
        return tables
