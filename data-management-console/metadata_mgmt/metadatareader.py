from postgres.postgresexecutor import PostgresExecutor
from schema_mgmt.tables import TableDefinition, TableColumn, PrimaryKey


class MetadataReader:
	_metadata_tables = None

	@classmethod
	def tables(cls, force=False):
		if not force and cls._metadata_tables is not None:
			print("--------------\nReturning metadata from cache\n-------------")
			return cls._metadata_tables
		tables = {}
		PostgresExecutor._cursor.execute('SELECT SchemaName, TableName, ColumnName, Type, KeyColumns FROM METADATA ORDER BY TableName, ColumnName')
		rows = PostgresExecutor._cursor.fetchall()
		last_name = ""
		for row in rows:
			[schema_name, table_name, column_name, type, key_columns] = row
			if table_name != last_name:
				print("-----------------------------------")
				print(f"Reading metadata for table {table_name}")
				last_name = table_name
			if table_name not in tables:
				tables[table_name] = TableDefinition(table_name, [])
			match type:
				case "FOREIGN KEY":
					print("Skipping foreign key")
				case "PRIMARY KEY":
					pk = PrimaryKey(table_name, key_columns)
					tables[table_name].elements.append(pk)
					print(f"Primary Key on {key_columns}")
				case _:
					col = TableColumn(table_name, column_name, type)
					print(f'Added column {column_name}')
					tables[table_name].elements.append(col)
		print(f"Populated {len(tables)} tables")
		cls._metadata_tables = tables
		return tables
