class PostgresConverter:
	@staticmethod
	def code_column(name, data_type):
		return f'{name} {data_type}'

	@staticmethod
	def code_foreign_key(source_columns, target_table, target_columns):
		source = ",".join(source_columns)
		target = ",".join(target_columns)
		return f'CONSTRAINT fk_name FOREIGN_KEY({source}) REFERENCES {target_table}({target})'

	@staticmethod
	def code_primary_key(columns):
		primary_key_fields = ",".join(columns)
		return f' PRIMARY KEY({primary_key_fields})'

	@staticmethod
	def fully_qualified_table_name(table_name, area):
		if area is not None:
			table_name = area + "_" + table_name
		return table_name

	@staticmethod
	def code_table(schema, table, area):
		return f'CREATE TABLE {PostgresConverter.fully_qualified_table_name(table.name, area)} ({",".join(table.convert(PostgresConverter()))})'

	@staticmethod
	def drop_table(schema, table, area):
		return f'DROP TABLE IF EXISTS {PostgresConverter.fully_qualified_table_name(table.name, area)}'

	@staticmethod
	def store_metadata(schema, table, area):
		sql = []
		for el in table.elements:
			element_value = el.metadata()
			element_value = (PostgresConverter.fully_qualified_table_name(element_value[0], area), element_value[1], element_value[2], element_value[3])
			command = f"INSERT INTO METADATA(SchemaName, TableName, ColumnName, Type, KeyColumns) VALUES('{schema}', '{element_value[0]}', '{element_value[1]}', '{element_value[2]}', '{element_value[3]}')"
			sql.append(command)
		return sql

	@staticmethod
	def get_staging_data_originators(driving_table):
		return f"SELECT DISTINCT ORIGINATOR_ID FROM STAGING_{driving_table}"

	@staticmethod
	def clear_metadata_for_this_table(schema, table, area):
		return f"DELETE FROM METADATA WHERE SCHEMANAME='{schema}' AND TABLENAME='{PostgresConverter.fully_qualified_table_name(table.name, area)}'"

	"""
	def construct_query_clause(quarantine_table, target_table, originator_id):
		where_clause_components = []
		main_clause_components = []
		position = 0
		quarantine_positions = {}
		target_positions = {}
		for PK in quarantine_table.primary_key().column_names.split(","):
			where_clause_components.append(f"a.{PK}=b.{PK}")
		for col in quarantine_table.columns():
			main_clause_components.append(f"a.{col.name} ")
			quarantine_positions[col.name] = position
			position += 1
		for col in target_table.columns():
			main_clause_components.append(f"b.{col.name}")
			target_positions[col.name] = position
			position += 1
		where_clause = " ON " + " and ".join(where_clause_components)
		where_clause += f" WHERE (((a.ORIGINATOR_ID={originator_id}) AND ((b.ORIGINATOR_ID = a.ORIGINATOR_ID) OR (b.ORIGINATOR_ID IS NULL)))"
		where_clause += f" OR ((b.ORIGINATOR_ID={originator_id}) AND (a.ORIGINATOR_ID IS NULL))) "
		where_clause += f" AND ((b.ToZ=TIMESTAMP '9999-01-01 00:00:00') or (b.ToZ IS NULL)) "
		main_clause = f'SELECT {", ".join(main_clause_components)} FROM {quarantine_table.name} a FULL OUTER JOIN {target_table.name} b '
		main_clause += where_clause
		return (main_clause, quarantine_positions, target_positions)
	"""

	@staticmethod
	def construct_query_clause(quarantine_table, target_table, originator_id, closed_universe):
		# start with the Equal and Update cases
		where_clause_for_update_components = []
		where_clause_for_deletion_components = []
		main_clause_for_update_components = []
		position = 0
		quarantine_positions = {}
		target_positions = {}
		for PK in quarantine_table.primary_key().column_names.split(","):
			where_clause_for_update_components.append(f" a.{PK}=b.{PK} ")
			where_clause_for_deletion_components.append(f" a.{PK}=b.{PK} ")
		if originator_id is not None:
			where_clause_for_update_components.append(f"a.ORIGINATOR_ID={originator_id} ")
		where_clause_for_update_components.append(" b.ToZ=TIMESTAMP '9999-01-01 00:00:00'")
		for col in quarantine_table.columns():
			main_clause_for_update_components.append(f"a.{col.name} ")
			quarantine_positions[col.name] = position
			position += 1
		for col in target_table.columns():
			main_clause_for_update_components.append(f"b.{col.name}")
			target_positions[col.name] = position
			position += 1
		main_clause_for_update_components.append("'UPDATE'")
		main_clause_for_update = f'SELECT {", ".join(main_clause_for_update_components)} FROM {quarantine_table.name} a JOIN {target_table.name} b '
		where_clause_for_update = " ON " + " and ".join(where_clause_for_update_components)
		main_clause_for_update += where_clause_for_update

		main_clause_for_addition_components = []
		for col in quarantine_table.columns():
			main_clause_for_addition_components.append(f"a.{col.name} ")
		for col in target_table.columns():
			main_clause_for_addition_components.append("NULL")
		main_clause_for_addition_components.append("'ADD'")
		main_clause_for_addition = f'SELECT {", ".join(main_clause_for_addition_components)} FROM {quarantine_table.name} a WHERE '
		if originator_id is not None:
			main_clause_for_addition += f" a.ORIGINATOR_ID={originator_id} AND "
		main_clause_for_addition += f" NOT EXISTS (SELECT 1 FROM {target_table.name} b WHERE " + " AND ".join(where_clause_for_deletion_components)
		main_clause_for_addition += f" AND b.ToZ=TIMESTAMP '9999-01-01 00:00:00') "

		main_clause_for_deletion_components = []
		for col in quarantine_table.columns():
			main_clause_for_deletion_components.append("NULL")
		for col in target_table.columns():
			main_clause_for_deletion_components.append("NULL")	# we don't use these values and the spatial table would return massive answers
		main_clause_for_deletion_components.append("'DELETED'")
		main_clause_for_deletion = f'SELECT {", ".join(main_clause_for_deletion_components)} FROM {target_table.name} a WHERE '
		# if we have a closed universe (during migration), we know we have enough information to determine whether the record
		# has been moved to another provider, so don't filter by originator
		# when the universe is not closed (a single data provider's information is arriving), we should not delete (as of current knowledge)
		if originator_id is not None:
			main_clause_for_deletion += f" a.ORIGINATOR_ID={originator_id} AND "
		main_clause_for_deletion += " a.ToZ=TIMESTAMP '9999-01-01 00:00:00' AND a.ISDELETED=0 "
		main_clause_for_deletion += f" AND NOT EXISTS (SELECT 1 FROM {quarantine_table.name} b "
		main_clause_for_deletion += ' WHERE ' + " and ".join(where_clause_for_deletion_components)
		if not closed_universe and originator_id is not None:
			main_clause_for_deletion += f" AND b.ORIGINATOR_ID={originator_id}"
		main_clause_for_deletion += ")"

		main_clause = " UNION ".join([main_clause_for_addition, main_clause_for_update])
		return (main_clause, quarantine_positions, target_positions)

	@staticmethod
	def count_as_of(target_table, time_of_interest):
		sql = f"SELECT COUNT(1), SUM(IsDeleted) FROM {target_table.name} WHERE FromZ <= '{time_of_interest}' AND ToZ > '{time_of_interest}' "
		sql += f" AND EffectiveFromZ <='{time_of_interest}' AND EffectiveToZ > '{time_of_interest}'"
		return sql

	@staticmethod
	def get_time_from_database():
		return "SELECT now()::timestamp(0)"

	@staticmethod
	def load_keys(lookup_table, lookup_column, code_column, time_of_creation):
		return f"SELECT {code_column}, {lookup_column} from {lookup_table} WHERE FromZ <= TIMESTAMP '{time_of_creation}' AND ToZ > TIMESTAMP '{time_of_creation}'"
	@staticmethod
	def get_originator_column_name():
		return "ORIGINATOR_ID"

	@staticmethod
	def get_quarantine_data_by_driving_column(driving_table, driving_column):
		return f'SELECT DISTINCT {driving_column} FROM {driving_table}'

	@staticmethod
	def get_rows_for_given_driver_column_value(input_columns, originator_id, driving_table, driving_column):
		sql = f"SELECT {(',').join(input_columns.keys())} FROM {driving_table} "
		if driving_column:
			sql += f" WHERE {driving_column}={originator_id}"
		return sql

	@staticmethod
	def construct_sql_to_store(target_table, vals_to_store):
		if len(vals_to_store) == 0:
			return None
		try:
			cols_to_store = ",".join(vals_to_store[0].keys())
		except:
			print('Hmmm')
		else:
			sql = f"INSERT INTO staging_{target_table} ({cols_to_store}) VALUES"
			sub_sqls = []
			for val_to_store in vals_to_store:
				sub_sql = "("
				vals_to_insert = []
				for col, val in val_to_store.items():
					if isinstance(val, (int, float)):
						vals_to_insert.append(str(val))
					elif isinstance(val, str):
						vals_to_insert.append("'" + str(val).replace("'", "''") + "'")
					else:
						raise Exception(f"Unknown type for {col} as {type(val)}!!!")
				sub_sql += ",".join(vals_to_insert) + ")"
				sub_sqls.append(sub_sql)
			sql = sql + ",".join(sub_sqls)
			return sql

	@staticmethod
	def delete_staging_rows(table_def):
		return f"DELETE FROM {table_def.name}"
