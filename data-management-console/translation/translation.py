import gc
import json
from collections import defaultdict
from datetime import datetime

from metadata_mgmt.metadatareader import MetadataReader
from mgmt_logging.logger import Logger
from postgres.postgresexecutor import PostgresExecutor
from runtime_mgmt.datagroupmanager import DataGroupManager
from schema_management.extractor import Extractor
from schema_management.ingestorconstants import IngestorConstants
from schema_management.memorymanager import MemoryManager
from schema_management.tables import ForeignKey
from translation.foreignkeyhandler import ForeignKeyHandler, ForeignKeyException
from translation.translationerrormanager import TranslationErrorManager
from translation.translationfkhelper import TranslationFKHelper


class QuarantineToStagingTranslator:

    def __init__(self, data_group, time_of_creation):
        self.data_group = data_group
        DataGroupManager.parameterize('../json/data_group.json')
        self.translation_schema = DataGroupManager.translation_schema(data_group)
        self.time_of_creation = time_of_creation
        self.err_mgr = TranslationErrorManager()
        self.known_mapping_functions = {
            "identity": QuarantineToStagingTranslator.identity_func,
            "site_id_from_pid": QuarantineToStagingTranslator.site_id_from_pid,
            "parcel_id_from_pid": QuarantineToStagingTranslator.parcel_id_from_pid,
            "multi-key": QuarantineToStagingTranslator.translate_delimited_string,
            "multi-key-with-other": QuarantineToStagingTranslator.translate_delimited_with_other,
            "multi-category": QuarantineToStagingTranslator.translate_concatenated_categories,
            "foreign-key": QuarantineToStagingTranslator.lookup_foreign_key_value,
            "check-year": QuarantineToStagingTranslator.valid_year,
            "check-date": QuarantineToStagingTranslator.valid_date,
            "check-month-and-year": QuarantineToStagingTranslator.valid_month_and_year,
            "translate-boolean": QuarantineToStagingTranslator.translate_boolean,
            "get_integer": QuarantineToStagingTranslator.get_integer,
            "check-valid-double": QuarantineToStagingTranslator.check_valid_double,
            "check-valid-integer": QuarantineToStagingTranslator.check_valid_integer,
            "constant0": QuarantineToStagingTranslator.constant0,
            "constant1": QuarantineToStagingTranslator.constant1
        }
        self.input_columns = defaultdict(list)
        self.default_columns = defaultdict(list)
        self.distinct_rows_only = {}

    def site_id_from_pid(self, parcel_id, _):
        parts = parcel_id.split("_")
        return int(parts[0])

    def parcel_id_from_pid(self, parcel_id, _):
        parts = parcel_id.split("_")
        if len(parts) == 1:
            return ""
        return parts[len(parts) - 1]

    def translate_delimited_string(self, multi_key_string, mapping_properties, row_with_values, originator):
        target_attribute = mapping_properties["target_attribute"]
        target_table = mapping_properties["target_table"]
        fk: ForeignKey = TranslationFKHelper.fk_for_attribute(target_table, target_attribute)
        target_column = fk.target_columns[0]
        assoc_table_name = fk.association_table_alias
        source_columns = fk.source_columns
        value_set = multi_key_string.split(mapping_properties["delimiter"])
        # remove duplicates
        values = { value.strip() : True for value in value_set}
        values = list(values.keys())
        rows_to_add = []
        for value in values:
            try:
                row_to_add = dict(
                    zip(source_columns, [row_with_values[source_column] for source_column in source_columns]))
            except KeyError as k:
                print(str(k))
                self.err_mgr.add_key_error(k)
            else:
                ForeignKeyHandler.load_keys(PostgresExecutor, target_attribute, target_table, self.time_of_creation)
                foreign_key_value = ForeignKeyHandler.get_id_for_code(target_attribute, target_table, value)
                row_to_add[target_column] = foreign_key_value
                row_to_add[PostgresExecutor.get_originator_column_name()] = originator
                rows_to_add.append(row_to_add)
        return rows_to_add, assoc_table_name

    def translate_delimited_with_other(self, multi_key_string, mapping_properties, row_with_values, originator):
        target_attribute = mapping_properties["target_attribute"]
        target_table = mapping_properties["target_table"]
        fk: ForeignKey = TranslationFKHelper.fk_for_attribute(target_table, target_attribute)
        target_column = fk.target_columns[0]
        assoc_table_name = fk.association_table_alias
        source_columns = fk.source_columns
        position = multi_key_string.lower().find("other:")
        if position == -1:
            value_set = multi_key_string.split(mapping_properties["delimiter"])
        else:
            # handle the other clause being the first
            string_to_split = multi_key_string[0:position-1] if position > 1 else ""
            string_to_split = string_to_split + mapping_properties["delimiter"] + "Other" + mapping_properties["delimiter"]
            value_set = string_to_split.split(mapping_properties["delimiter"])
            value_set = list(filter(None, value_set))
        # remove duplicates
        values = { value.strip() : True for value in value_set}
        values = list(values.keys())
        rows_to_add = []
        for value in values:
            try:
                row_to_add = dict(
                    zip(source_columns, [row_with_values[source_column] for source_column in source_columns]))
            except KeyError as k:
                print(str(k))
                self.err_mgr.add_key_error(k)
            else:
                ForeignKeyHandler.load_keys(PostgresExecutor, target_attribute, target_table, self.time_of_creation)
                try:
                    foreign_key_value = ForeignKeyHandler.get_id_for_code(target_attribute, target_table, value)
                except Exception as e:
                    print(str(e))
                row_to_add[target_column] = foreign_key_value
                row_to_add[PostgresExecutor.get_originator_column_name()] = originator
                rows_to_add.append(row_to_add)
        # remove duplicates after translation
        rows_to_add = [dict(t) for t in {tuple(d.items()) for d in rows_to_add}]
        return rows_to_add, assoc_table_name

    def translate_concatenated_categories(self, multi_category_string, mapping_properties, row_with_values, originator):
        target_attribute = mapping_properties["target_attribute"]
        target_table = mapping_properties["target_table"]
        fk: ForeignKey = TranslationFKHelper.fk_for_attribute(target_table, target_attribute)
        target_column = fk.target_columns[0]
        assoc_table_name = fk.association_table_alias
        source_columns = fk.source_columns
        start_character = mapping_properties["delimiter"][0]
        end_character = mapping_properties["delimiter"][1]
        # remove the first element which will be empty
        value_set = list(filter(None, multi_category_string.split(start_character)))
        values = [value.replace(end_character, '') for value in value_set]
        rows_to_add = []
        for value in values:
            try:
                row_to_add = dict(
                    zip(source_columns, [row_with_values[source_column] for source_column in source_columns]))
            except KeyError as k:
                print(str(k))
                self.err_mgr.add_key_error(k)
            else:
                ForeignKeyHandler.load_keys(PostgresExecutor, target_attribute, target_table, self.time_of_creation)
                foreign_key_value = ForeignKeyHandler.get_id_for_code(target_attribute, target_table, value)
                row_to_add[target_column] = foreign_key_value
                row_to_add[PostgresExecutor.get_originator_column_name()] = originator
                rows_to_add.append(row_to_add)
        return rows_to_add, assoc_table_name


    def identity_func(self, data_val, _):
        return data_val

    def lookup_foreign_key_value(self, value_of_key, mapping_properties):
        target_attribute = mapping_properties["target_attribute"]
        target_table = mapping_properties["target_table"]
        ForeignKeyHandler.load_keys(PostgresExecutor, target_attribute, target_table, self.time_of_creation)
        foreign_key_value = ForeignKeyHandler.get_id_for_code(target_attribute, target_table, value_of_key)
        return foreign_key_value

    def translate_boolean(self, value_of_key: str, _):
        if value_of_key.lower() == "true":
            return 1
        return 0

    def get_integer(self, value_of_key: str, _):
        parts = value_of_key.split(' ')
        if len(parts) == 0:
            return 0
        try:
            return int(parts[0])
        except ValueError:
            return 0

    def check_valid_double(self, value_of_key: str, _):
        try:
            test = float(value_of_key)
            return test
        except ValueError:
            return 0

    def check_valid_integer(self, value_of_key: str, _):
        try:
            test = int(value_of_key)
            return test
        except ValueError:
            return 0

    def valid_year(self, year_in, _):
        try:
            return int(year_in)
        except ValueError:
            print(f"Forcing {year_in} to 0 in valid_year")
            return 0

    def valid_date(self, date_in:str, _):
        try:
            return datetime.strptime(date_in, '%d/%m/%Y').date()
        except ValueError:
            print(f'{date_in} cannot be converted to a valid date - returning sentinel value')
            return datetime.strptime('01/01/1970', '%d/%m/%Y').date()


    def valid_month_and_year(self, date_in:str, _):
        try:
            return datetime.strptime(date_in, '%b-%y').date()
        except ValueError:
            print(f'{date_in} cannot be converted to a valid date - returning sentinel value')
            return datetime.strptime('Jan-70', '%b-%y').date()


    def constant0(self, val_in, _):
        return 0

    def constant1(self, val_in, _):
        return 1

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


    def get_all_tables(self):
        all_table_names = []
        for table in DataGroupManager.tables(self.data_group):
            all_table_names.append(table)
            association_tables, _ = Extractor.extract_association_and_target_table_names(table, MetadataReader.tables())
            for assoc_table in association_tables:
                all_table_names.append(assoc_table)
        return all_table_names

    def clear_staging_tables(self):
        cursor = PostgresExecutor.begin_transaction()
        for table in self.get_all_tables():
            sql = f"TRUNCATE TABLE stg_{table}"
            print(sql)
            cursor.execute(sql)
        PostgresExecutor.end_transaction()

    def translate(self, executor, driving_table, scan_only=False):
        MetadataReader.tables(True)
        self.read_translation_schema('../json/' + self.translation_schema)
        self.clear_staging_tables()
        is_loaded_by_WCMC = DataGroupManager.is_loaded_by_WCMC(self.data_group)
        # prime the table cache
        MetadataReader.tables(force=True)
        if not is_loaded_by_WCMC:
            driving_column = DataGroupManager.driving_column(self.data_group)
            list_of_originators = executor.get_quarantine_data_by_driving_column(driving_table, driving_column)
            for originator in list_of_originators:
                executor.open_read_cursor()
                originator_id = originator[0]
                print(f"Processing originator {originator_id}")
                Logger.get_logger().info(f"Processing originator {originator_id}")
                executor.get_cursor_for_driving_column(self.input_columns, driving_table, originator_id,
                                                               driving_column)
                transformed_row_count = self.handle_translation_in_chunks(executor, scan_only, originator_id, chunk_size=5000)
                log_info = f'Metadata provider {originator_id} has supplied {transformed_row_count} rows'
                Logger.get_logger().info(log_info)
                log_info = MemoryManager.memory_as_str(f"Memory was :")
                Logger.get_logger().info(log_info)
                executor.close_read_cursor()
                gc.collect()
        else:
            print(f"Starting on full table")
            executor.open_read_cursor()
            executor.get_cursor_for_driving_column(self.input_columns, driving_table)
            if self.distinct_rows_only.keys():
                chunk_size = 10000000  # got to grab all rows
            else:
                chunk_size = 5000
            transformed_row_count = self.handle_translation_in_chunks(executor, scan_only, chunk_size=chunk_size)
            print(f'Full table was {transformed_row_count} rows')
            executor.close_read_cursor()
            gc.collect()

    # called with the cursor already primed with the rows we need to process
    def handle_translation_in_chunks(self, executor, scan_only, originator_id=IngestorConstants.WCMC_SPECIAL_PROVIDER_ID,
                                     chunk_size=5000):
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
                            transformed_row_values[target_table] = [{"originator_id": originator_id}]
                        if "function" in translation_properties:
                            function_to_run = self.known_mapping_functions[translation_properties.get("function")]
                            val = row[column_index]
                            if translation_properties.get("delimiter"):
                                try:
                                    val_to_store, assoc_table_name = function_to_run(self, val, translation_properties,
                                                                                     transformed_row_values[target_table][0],
                                                                                     originator_id)
                                    if val_to_store is not None:
                                        transformed_row_values[assoc_table_name] = val_to_store
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
                executor.begin_transaction()
                rows_stored = executor.store_transformed_and_associated_rows(all_transformed_row_values,
                                                                                     self.distinct_rows_only)
                for target_table, row_count in rows_stored.items():
                    all_rows_stored[target_table] += row_count
                executor.end_transaction()
            all_rows_stored = defaultdict(int)
        return all_rows_stored
