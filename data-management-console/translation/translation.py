import gc
import json
from collections import defaultdict

from metadata_mgmt.metadatareader import MetadataReader
from mgmt_logging.logger import Logger
from postgres.postgresexecutor import PostgresExecutor
from runtime_mgmt.datagroupmanager import DataGroupManager
from schema_mgmt.ingestorconstants import IngestorConstants
from schema_mgmt.memorymanager import MemoryManager
from schema_mgmt.tables import TableDefinition
from translation.foreignkeyhandler import ForeignKeyHandler, ForeignKeyException
from translation.translationerrormanager import TranslationErrorManager, TranslationException


class QuarantineToStagingTranslator:

    def __init__(self):
        self.err_mgr = TranslationErrorManager()
        self.known_mapping_functions = {
            "identity": QuarantineToStagingTranslator.identity_func,
            "wdpa_id_from_pid": QuarantineToStagingTranslator.wdpa_id_from_pid,
            "parcel_id_from_pid": QuarantineToStagingTranslator.parcel_id_from_pid,
            "multi-key": QuarantineToStagingTranslator.translate_delimited_string,
            "foreign-key": QuarantineToStagingTranslator.lookup_foreign_key,
            "check-year": QuarantineToStagingTranslator.valid_year,
            "translate-boolean": QuarantineToStagingTranslator.translate_boolean,
            "get_integer": QuarantineToStagingTranslator.get_integer,
            "check_valid_double": QuarantineToStagingTranslator.check_valid_double
        }
        self.input_columns = defaultdict(list)
        self.default_columns = defaultdict(list)
        self.distinct_rows_only = {}

    def wdpa_id_from_pid(self, parcel_id, _):
        parts = parcel_id.split("_")
        return parts[0]

    def parcel_id_from_pid(self, parcel_id, _):
        parts = parcel_id.split("_")
        if len(parts) == 1:
            return ""
        return parts[len(parts) - 1]

    def translate_delimited_string(self, multi_key_string, mapping_properties, row_with_values, originator):
        codes = multi_key_string.split(mapping_properties["delimiter"])
        codes = [country.strip() for country in codes]
        lookup_table = mapping_properties["lookup_table"]
        target_assoc_column = mapping_properties["code_column"]
        source_columns = mapping_properties["source_columns"]
        rows_to_add = []
        for code in codes:
            try:
                row_to_add = dict(
                    zip(source_columns, [row_with_values[source_column] for source_column in source_columns]))
            except KeyError as k:
                print(str(k))
                self.err_mgr.add_key_error(k)
            else:
                foreign_key = ForeignKeyHandler.get_code_for_description(lookup_table, code)
                row_to_add[target_assoc_column] = foreign_key
                row_to_add[PostgresExecutor.get_originator_column_name()] = originator
                rows_to_add.append(row_to_add)
        return rows_to_add

    def identity_func(self, data_val, _):
        return data_val

    def lookup_foreign_key(self, value_of_key, mapping_properties):
        lookup_table = mapping_properties["lookup_table"]
        foreign_key = ForeignKeyHandler.get_code_for_description(lookup_table, value_of_key)
        return foreign_key

    def translate_boolean(self, value_of_key: str, _):
        if value_of_key.lower() == "true":
            return 1
        return 0

    def get_integer(self, value_of_key:str, _):
        parts = value_of_key.split(' ')
        if len(parts) == 0:
            return 0
        try:
            return int(parts[0])
        except ValueError:
            return 0

    def check_valid_double(self, value_of_key:str, _):
        try:
            test = float(value_of_key)
            return value_of_key
        except ValueError:
            return 0

    def valid_year(self, year_in, _):
        try:
            return int(year_in)
        except ValueError:
            print(f"Forcing {year_in} to 0 in valid_year")
            return 0

    def read_translation_schema(self, schema_file):
        self.input_columns = defaultdict(list)
        with open(schema_file, 'r') as file:
            raw_schema = json.load(file)
            raw_schema.pop("version")
            for key, val in raw_schema.items():
                # use match syntax when we have Python 3.10 installed
                if key == "Defaults":
                    for el in val:
                        target_table_name = el['target_table']
                        self.default_columns[target_table_name].append(el)
                elif key == "Distinct":
                    self.distinct_rows_only = val
                else:
                    for el in val:
                        source_column_name = el['name']
                        self.input_columns[source_column_name].append(el)
                print(f'Key {key} had {len(val)} mappings defined')

    def translate(self, driving_table, data_group, time_of_creation, scan_only=False):
        driving_column = DataGroupManager.driving_column(data_group)
        # prime the table cache
        MetadataReader.tables(force=True)
        # collect all the foreign keys
        tables_to_translate = DataGroupManager.tables(data_group)
        for table_name in tables_to_translate:
            table_def: TableDefinition = MetadataReader.tables()[table_name]
            foreign_keys = table_def.foreign_keys()
            for fk in foreign_keys:
                ForeignKeyHandler.load_keys(PostgresExecutor, fk.target_table, fk.target_columns[0], time_of_creation)
        # ForeignKeyHandler.load_keys(PostgresExecutor, "iucn_cat", "description", time_of_creation)
        # ForeignKeyHandler.load_keys(PostgresExecutor, "no_take", "description", time_of_creation)
        # ForeignKeyHandler.load_keys(PostgresExecutor, "iso3", "code", time_of_creation)
        # ForeignKeyHandler.load_keys(PostgresExecutor, "data_providers", "responsible_party", time_of_creation)
        if driving_column:
            list_of_originators = PostgresExecutor.get_quarantine_data_by_driving_column(driving_table, driving_column)
            for originator in list_of_originators:
                PostgresExecutor.open_read_cursor()
                originator_id = originator[0]
                print(f"Processing originator {originator_id}")
                Logger.get_logger().info(f"Processing originator {originator_id}")
                PostgresExecutor.get_cursor_for_driving_column(self.input_columns, originator_id, driving_table,
                                                               driving_column)
                transformed_row_count = self.handle_translation_in_chunks(scan_only, originator_id)
                log_info = f'Metadata provider {originator_id} has supplied {transformed_row_count} rows'
                Logger.get_logger().info(log_info)
                log_info = MemoryManager.memory_as_str(f"Memory was :")
                Logger.get_logger().info(log_info)
                PostgresExecutor.close_read_cursor()
                gc.collect()
        else:
            print(f"Starting on full table")
            PostgresExecutor.open_read_cursor()
            PostgresExecutor.get_cursor_for_driving_column(self.input_columns, 0, driving_table, driving_column)
            if self.distinct_rows_only.keys():
                chunk_size = 10000000   # got to grab all rows
            else:
                chunk_size = 5000
            transformed_row_count = self.handle_translation_in_chunks(scan_only, chunk_size=chunk_size)
            print(f'Full table was {transformed_row_count} rows')
            PostgresExecutor.close_read_cursor()
            gc.collect()

    # called with the cursor already primed with the rows we need to process
    def handle_translation_in_chunks(self, scan_only, originator_id=IngestorConstants.WCMC_SPECIAL_PROVIDER_ID, chunk_size=5000):
        transformed_row_count = 0
        all_rows_stored = defaultdict(int)
        while True:
            all_transformed_row_values = defaultdict(list)
            rows = PostgresExecutor.get_row_chunk(chunk_size)
            if not rows:
                break
            for row in rows:
                column_index = 0
                transformed_row_values = {}
                for column_name, translation_property_list in self.input_columns.items():
                    for translation_properties in translation_property_list:
                        target_table = translation_properties["target_table"]
                        target_name = translation_properties.get("target_name") or column_name
                        if target_table not in transformed_row_values.keys():
                            transformed_row_values[target_table] = [{ "originator_id" : originator_id }]
                        if "function" in translation_properties:
                            function_to_run = self.known_mapping_functions[translation_properties.get("function")]
                            val = row[column_index]
                            if translation_properties.get("source_table"):
                                source_table = translation_properties["source_table"]
                                try:
                                    val_to_store = function_to_run(self, val, translation_properties,
                                                                   transformed_row_values[source_table][0],
                                                                   originator_id)
                                    if val_to_store is not None:
                                        transformed_row_values[target_table] = val_to_store
                                except ForeignKeyException as foreign_key_exception:
                                    print(str(foreign_key_exception))
                                    self.err_mgr.add_foreign_key_error(foreign_key_exception)
                            else:
                                try:
                                    val_to_store = function_to_run(self, val, translation_properties)
                                    transformed_row_values[target_table][0][target_name] = val_to_store
                                except ForeignKeyException as foreign_key_exception:
                                    print(str(foreign_key_exception))
                                    self.err_mgr.add_foreign_key_error(foreign_key_exception)
                        else:
                            # even if the value is None (representing an incoming NULL), we need to reflect this
                            try:
                                transformed_row_values[target_table][0][target_name] = row[column_index]
                            except Exception as e:
                                print(str(e))
                                print("ERROR: Should never hit this")
                    column_index += 1
                # at this point, the transformed rows are now in our hand - put them into the staging tables
                transformed_row_count += 1
                for table_name, rows in transformed_row_values.items():
                    for transformed_row in rows:
                        all_transformed_row_values[table_name].append(transformed_row)
            print(f'Read in {transformed_row_count} so far - storing the data')
            # now store the transformed data
            self.err_mgr.raise_any_errors()
            if not scan_only:
                PostgresExecutor.begin_transaction()
                rows_stored = PostgresExecutor.store_transformed_and_associated_rows(all_transformed_row_values, self.distinct_rows_only)
                for target_table, row_count in rows_stored.items():
                    all_rows_stored[target_table] += row_count
                PostgresExecutor.end_transaction()
            all_rows_stored = defaultdict(int)
        return all_rows_stored
