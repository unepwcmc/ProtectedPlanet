import json
from collections import defaultdict

from psycopg2 import ProgrammingError

from mgmt_logging.logger import Logger
from postgres.postgresexecutor import PostgresExecutor
from translation.foreignkeyhandler import ForeignKeyHandler


class QuarantineToStagingTranslator():

	def __init__(self):
		self.known_mapping_functions = {
			"identity": QuarantineToStagingTranslator.identity,
			"parcel_id_from_pid": QuarantineToStagingTranslator.parcel_id_from_pid,
			"multi-key": QuarantineToStagingTranslator.translate_delimited_string,
			"foreign-key": QuarantineToStagingTranslator.lookup_foreign_key
		}

	@staticmethod
	def identity(data_val, _):
		return data_val


	@staticmethod
	def parcel_id_from_pid(parcel_id, _):
		parts = parcel_id.split("_")
		return parts[len(parts)-1]


	@staticmethod
	def translate_delimited_string(multi_key_string, mapping_properties, row_with_values, originator):
		codes = multi_key_string.split(mapping_properties["delimiter"])
		codes = [country.strip() for country in codes]
		lookup_table = mapping_properties["lookup_table"]
		lookup_column = mapping_properties["lookup_column"]
		target_assoc_column = mapping_properties["code_column"]
		source_columns = mapping_properties["source_columns"]
		rows_to_add = []
		for code in codes:
			row_to_add = dict(zip(source_columns, [row_with_values[source_column] for source_column in source_columns]))
#			foreign_key = PostgresExecutor.get_foreign_key(lookup_table, lookup_column, target_assoc_column, code)
			foreign_key = ForeignKeyHandler.get_code_for_description(lookup_table, code)
			row_to_add[target_assoc_column] = foreign_key
			row_to_add[PostgresExecutor.get_originator_column_name()] = originator
			rows_to_add.append(row_to_add)

		return rows_to_add


	@staticmethod
	def lookup_foreign_key(value_of_key, mapping_properties):
		lookup_table = mapping_properties["lookup_table"]
		lookup_column = mapping_properties["lookup_column"]
		code_column = mapping_properties["code_column"]
		foreign_key = ForeignKeyHandler.get_code_for_description(lookup_table, value_of_key)
		return foreign_key


	def read_translation_schema(self, schema_file):
		self.input_columns = defaultdict(list)
		with open(schema_file, 'r') as file:
			raw_schema = json.load(file)
			raw_schema.pop("version")
			for key, val in raw_schema.items():
				print(f'Key {key} has {len(val)} mappings defined')
				for el in val:
					source_column_name = el['name']
					self.input_columns[source_column_name].append(el)

	def translate(self, driving_table, driving_column, time_of_creation):
		PostgresExecutor.begin_transaction(PostgresExecutor._conn)
		ForeignKeyHandler.load_keys(PostgresExecutor, "iucn_cat", "description", "code", time_of_creation)
		ForeignKeyHandler.load_keys(PostgresExecutor, "marine_enum", "description", "code", time_of_creation)
		ForeignKeyHandler.load_keys(PostgresExecutor, "iso3", "code", "code", time_of_creation)
		if driving_column:
			list_of_originators = PostgresExecutor.get_quarantine_data_by_driving_column(driving_table, driving_column)
			PostgresExecutor.end_transaction()
			for originator in list_of_originators:
				originator_id = originator[0]
				print(f"Processing originator {originator_id}")
				Logger.get_logger().info(f"Processing originator {originator_id}")
				PostgresExecutor.begin_transaction(PostgresExecutor._conn)
				PostgresExecutor.get_cursor_for_driving_column(self.input_columns, originator_id, driving_table,driving_column)
				transformed_row_count = self.handle_chunk(originator_id)
				PostgresExecutor.end_transaction()
				print(f'Metadata provider {originator_id} has supplied {transformed_row_count} rows')
				PostgresExecutor.end_transaction()
		else:
			print(f"Starting on full table")
			PostgresExecutor.begin_transaction(PostgresExecutor._conn)
			PostgresExecutor.get_cursor_for_driving_column(self.input_columns, 0, driving_table, driving_column)
			transformed_row_count = self.handle_chunk()
			PostgresExecutor.end_transaction()
			print(f'Full table was {transformed_row_count} rows')

	# called with the cursor already primed with the rows we need to process
	def handle_chunk(self, originator_id=None):
		transformed_row_count = 0
		all_transformed_row_values = defaultdict(list)
		while True:
			try:
				rows = PostgresExecutor.get_row_chunk(10000)
				if not rows:
					break
			except ProgrammingError as e:
				break
			else:
				for row in rows:
					column_index = 0
					transformed_row_values = {}
					for column_name, translation_property_list in self.input_columns.items():
						for translation_properties in translation_property_list:
							target_table = translation_properties["target_table"]
							target_name = translation_properties.get("target_name") or column_name
							if target_table not in transformed_row_values.keys():
								transformed_row_values[target_table] = [{}]
							if "function" in translation_properties:
								function_to_run = self.known_mapping_functions[translation_properties.get("function")]
								val = row[column_index]
								if translation_properties.get("source_table"):
									source_table = translation_properties["source_table"]
									val_to_store = function_to_run(val, translation_properties, transformed_row_values[source_table][0], originator_id)
									if val_to_store is not None:
										transformed_row_values[target_table] = val_to_store
								else:
									val_to_store = function_to_run(val, translation_properties)
									if val_to_store is not None:
										transformed_row_values[target_table][0][target_name] = val_to_store
							else:
								if row[column_index] is not None:
									transformed_row_values[target_table][0][target_name] = row[column_index]
						column_index += 1
					# at this point, the transformed rows are now in our hand - put them into the staging tables
					transformed_row_count += 1
					for table_name, rows in transformed_row_values.items():
						for row in rows:
							all_transformed_row_values[table_name].append(row)
				print(f'Read in {transformed_row_count} so far')
		PostgresExecutor.end_transaction()
		# now store the transformed data
		PostgresExecutor.begin_transaction(PostgresExecutor._conn)
		PostgresExecutor.store_transformed_and_associated_rows(all_transformed_row_values)
		return transformed_row_count