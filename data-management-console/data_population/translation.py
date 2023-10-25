from __future__ import annotations

import gc
import json
from collections import defaultdict
from datetime import datetime
from typing import Callable, Any
from uuid import UUID

from data_population.foreignkeyhandler import ForeignKeyHandler, NonExistentForeignKeyException
from data_population.ingestorconstants import IngestorConstants
from data_population.translationerrormanager import TranslationErrorManager
from data_population.translationexceptions import UnknownAttributeException, \
    WithOtherSpecifiedIncorrectlyInTranslationException
from data_population.translationfkhelper import TranslationFKHelper
from data_population.translationreferencedataobject import TranslationReferenceDataObject
from install_json.json_path import JsonPath
from postgres.postgresexecutor import PostgresExecutor
from runtime_mgmt.row import Row
from runtime_mgmt.runtimemanagementexceptions import RowCellCannotContainValueException, UnknownFieldToSetException
from runtime_mgmt.table import TableStore, Table
from schema_management.extractor import Extractor
from schema_management.tabledefinitions import ForeignKey, ForeignKeyN
from util.datagroupmanager import DataGroupManager
from util.executor import Executor
from util.logger import Logger
from util.memorymanager import MemoryManager
from util.metadatareader import MetadataReader


class QuarantineToStagingTranslator:
    reference_data_error_summaries = {}
    QUARANTINE_STAGING_PREFIX = 'stg_'

    def __init__(self, data_group: str, time_of_creation: str):
        self._data_group = data_group
        DataGroupManager.parameterize(JsonPath.make_json_path('data_group'))
        self._translation_schema = DataGroupManager.translation_schema(data_group)
        self._time_of_creation = time_of_creation
        self._error_manager = TranslationErrorManager()
        self._driving_table = None
        self._table_store = None
        self._known_mapping_functions = {
            "identity": QuarantineToStagingTranslator.identity_func,
            "site_id_from_pid": QuarantineToStagingTranslator.site_id_from_pid,
            "parcel_id_from_pid": QuarantineToStagingTranslator.parcel_id_from_pid,
            "multi-key": QuarantineToStagingTranslator.translate_delimited_string,
            "multi-key-with-other": QuarantineToStagingTranslator.translate_delimited_with_other,
            "multi-category": QuarantineToStagingTranslator.translate_concatenated_categories,
            "foreign-key": QuarantineToStagingTranslator.lookup_foreign_key_value,
            "foreign-key-with-other": QuarantineToStagingTranslator.lookup_foreign_key_with_other_value,
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
        self._input_columns = defaultdict(list)
        self._default_columns = defaultdict(list)
        self._distinct_rows_only = {}
        self._master_id = 0

    @staticmethod
    def add_reference_data_summary(uuid: UUID, translator: QuarantineToStagingTranslator):
        obj_to_store = TranslationReferenceDataObject(translator._driving_table, translator._time_of_creation,
                                                      translator._data_group, translator._error_manager)
        QuarantineToStagingTranslator.reference_data_error_summaries[str(uuid)] = obj_to_store

    def site_id_from_pid(self, parcel_id, dummy, _):
        parts = parcel_id.split("_")
        return int(parts[0])

    def parcel_id_from_pid(self, parcel_id, dummy, _):
        parts = parcel_id.split("_")
        if len(parts) == 1:
            return ""
        return parts[len(parts) - 1]

    def store_foreign_key_values_in_association_table(self, values, assoc_table: Table, source_columns: list,
                                                      row_with_values: Row, target_table: str, code_attribute: str,
                                                      target_column_in_assoc: str, originator: int):
        ForeignKeyHandler.load_keys(PostgresExecutor, code_attribute, target_table, self._time_of_creation)
        for value in values:
            try:
                row_to_add = assoc_table.add_row()
                for source_column in source_columns:
                    row_to_add.set_field_value(source_column, row_with_values.get_field_value(source_column))
                foreign_key_value = ForeignKeyHandler.get_id_for_code(code_attribute, target_table, value)
                row_to_add.set_field_value(target_column_in_assoc, foreign_key_value)
                row_to_add.set_field_value(PostgresExecutor.get_originator_column_name(), originator)
            except KeyError as k:
                self._error_manager.add_unknown_source_columns(source_columns, target_table)
                assoc_table.rollback()
                # gather errors for reporting
            except UnknownAttributeException as ua:
                self._error_manager.add_unknown_attribute(ua.target_table(), ua.value())
                try:
                    lookup_column = ua.lookup_column()
                    reference_table = ua.target_table()
                    # also check whether this value would fit in the reference table if it were accepted
                    test_table = Table(reference_table)
                    test_row = test_table.add_row()
                    # if the value is too long to fit in the reference table, this will raise a RowCellCannotContainValueException which is
                    # caught by run_extended_function
                    test_row.set_field_value(lookup_column, value)
                    assoc_table.rollback()
                except RowCellCannotContainValueException as rcccve:
                    self._error_manager.add_field_too_long_error(
                        rcccve.table_name(),
                        rcccve.field_name(),
                        rcccve.length_of_field(),
                        rcccve.length_of_value()
                    )
                    assoc_table.rollback()
            except NonExistentForeignKeyException as foreign_key_exception:
                self._error_manager.add_nonexistent_foreign_key_error(foreign_key_exception.table_name(),
                                                                      foreign_key_exception.fk_target_table_name(),
                                                                      foreign_key_exception.lookup_column())
                assoc_table.rollback()
        # remove duplicates after translation
        assoc_table.unique_new(source_columns + [target_column_in_assoc])

    def translate_delimited_string(self, multi_key_string, mapping_properties, row_with_values, originator):
        code_attribute: str = mapping_properties["target_attribute"]
        target_table: str = mapping_properties["target_table"]
        fk: ForeignKey = TranslationFKHelper.fk_for_attribute(target_table,
                                                              code_attribute)  # this has to be a ForeignKeyN
        if not isinstance(fk, ForeignKeyN):
            self._error_manager.add_translation_not_1ton(code_attribute, target_table)
            return
        target_column_in_assoc = fk.target_columns()[0]
        assoc_table_name = fk.association_table_alias()
        source_columns = fk.source_columns()
        value_set = multi_key_string.split(mapping_properties["delimiter"])
        # remove duplicates
        values = {value.strip(): True for value in value_set}
        values = list(values.keys())
        assoc_table = self._table_store.get_table(assoc_table_name, add_if_absent=True)
        self.store_foreign_key_values_in_association_table(values, assoc_table, source_columns, row_with_values,
                                                           target_table, code_attribute, target_column_in_assoc,
                                                           originator)

    def translate_delimited_with_other(self, multi_key_string: str, mapping_properties: dict, row_with_values: Row,
                                       originator: int):
        code_attribute: str = mapping_properties["target_attribute"]
        target_table: str = mapping_properties["target_table"]
        fk: ForeignKey = TranslationFKHelper.fk_for_attribute(target_table, code_attribute)
        if not isinstance(fk, ForeignKeyN):
            self._error_manager.add_translation_not_1ton(code_attribute, target_table)
            return
        target_column_in_assoc = fk.target_columns()[0]
        assoc_table_name = fk.association_table_alias()
        source_columns = fk.source_columns()
        position = multi_key_string.lower().find("other:")
        residual_field_value = ""
        if position == -1:
            value_set = multi_key_string.split(mapping_properties["delimiter"])
        else:
            # handle the other clause being the first
            string_to_split = multi_key_string[0:position - 1] if position > 1 else ""
            string_to_split = string_to_split + mapping_properties["delimiter"] + "Other:"
            value_set = string_to_split.split(mapping_properties["delimiter"])
            value_set = list(filter(None, value_set))
            residual_field_value = multi_key_string[position + 6:].strip() if len(multi_key_string) > (
                    position + 6) else ""
        # remove duplicates
        values = {value.strip(): True for value in value_set}
        values = list(values.keys())
        assoc_table = self._table_store.get_table(assoc_table_name, add_if_absent=True)
        self.store_foreign_key_values_in_association_table(values, assoc_table, source_columns, row_with_values,
                                                           target_table, code_attribute, target_column_in_assoc,
                                                           originator)

        # now fill in the "Other" field - rise an exception if the translation specified was foreigh-key-with-other
        # but there is nowehere actually to put such data
        try:
            residual_field_name = fk.other_field()
            if residual_field_name == '':
                raise WithOtherSpecifiedIncorrectlyInTranslationException(code_attribute)
            row_with_values.set_field_value(residual_field_name, residual_field_value)
            assoc_table.commit()
        except UnknownFieldToSetException as ufs:
            existing_err_msg = getattr(ufs, 'message', str(ufs))
            err_msg = f'While setting attribute: [{code_attribute}] -> {existing_err_msg}'
            assoc_table.rollback()
            raise UnknownFieldToSetException(err_msg)

    def translate_concatenated_categories(self, multi_category_string, mapping_properties, row_with_values, originator):
        code_attribute: str = mapping_properties["target_attribute"]
        target_table: str = mapping_properties["target_table"]
        fk: ForeignKey = TranslationFKHelper.fk_for_attribute(target_table, code_attribute)
        if not isinstance(fk, ForeignKeyN):
            self._error_manager.add_translation_not_1ton(code_attribute, target_table)
            return
        target_column_in_assoc = fk.target_columns()[0]
        assoc_table_name = fk.association_table_alias()
        source_columns = fk.source_columns()
        start_character = mapping_properties["delimiter"][0]
        end_character = mapping_properties["delimiter"][1]
        # remove the first element which will be empty
        value_set = list(filter(None, multi_category_string.split(start_character)))
        values = [value.replace(end_character, '') for value in value_set]
        assoc_table = self._table_store.get_table(assoc_table_name, add_if_absent=True)
        self.store_foreign_key_values_in_association_table(values, assoc_table, source_columns, row_with_values,
                                                           target_table, code_attribute, target_column_in_assoc,
                                                           originator)

    def identity_func(self, data_val, dummy, _):
        return data_val

    def lookup_foreign_key_value(self, value_of_key, mapping_properties, _):
        target_attribute: str = mapping_properties["target_attribute"]
        target_table: str = mapping_properties["target_table"]
        try:
            ForeignKeyHandler.load_keys(PostgresExecutor, target_attribute, target_table, self._time_of_creation)
            foreign_key_value = ForeignKeyHandler.get_id_for_code(target_attribute, target_table, value_of_key)
            return foreign_key_value
        except UnknownAttributeException as ua:
            # catch the unknown attribute exception
            self._error_manager.add_unknown_attribute(ua.target_table(), ua.value())
            lookup_column = ua.lookup_column()
            reference_table = ua.target_table()
            # also check whether this value would fit in the reference table if it were accepted
            test_table = Table(reference_table)
            test_row = test_table.add_row()
            # if the value is too long to fit in the reference table, this will raise a RowCellCannotContainValueException which is
            # caught by run_extended_function
            test_row.set_field_value(lookup_column, value_of_key)
            return 0

    def lookup_foreign_key_with_other_value(self, value_of_key: str, mapping_properties: dict, row_with_values: Row):
        target_attribute = mapping_properties["target_attribute"]
        target_table = mapping_properties["target_table"]
        fk: ForeignKey = TranslationFKHelper.fk_for_attribute(target_table, target_attribute)
        residual_field = fk.other_field()
        position = value_of_key.lower().find("other:")
        try:
            # there is an "Other:" entry so get the FK for that
            if residual_field and position != -1:
                ForeignKeyHandler.load_keys(PostgresExecutor, target_attribute, target_table, self._time_of_creation)
                foreign_key_value = ForeignKeyHandler.get_id_for_code(target_attribute, target_table, "other:")
                row_with_values.set_field_value(residual_field, value_of_key[position + 6:].strip() if len(value_of_key) > (
                        position + 6) else "")
                return foreign_key_value
            # no "Other:" entry, just an FK
            ForeignKeyHandler.load_keys(PostgresExecutor, target_attribute, target_table, self._time_of_creation)
            foreign_key_value = ForeignKeyHandler.get_id_for_code(target_attribute, target_table, value_of_key)
            row_with_values.set_field_value(residual_field, '')
            return foreign_key_value
        except UnknownFieldToSetException as ufs:
            existing_err_msg = getattr(ufs, 'message', str(ufs))
            err_msg = f'While setting attribute: [{target_attribute}] -> {existing_err_msg}'

            raise UnknownFieldToSetException(err_msg)
        except UnknownAttributeException as ua:
            self._error_manager.add_unknown_attribute(ua.target_table(), ua.value())
            lookup_column = ua.lookup_column()
            reference_table = ua.target_table()
            # also check whether this value would fit in the reference table if it were accepted
            test_table = Table(reference_table)
            test_row = test_table.add_row()
            # if the value is too long to fit in the reference table, this will raise a RowCellCannotContainValueException which is
            # caught by run_extended_function
            test_row.set_field_value(lookup_column, value_of_key)
            return 0

    def translate_boolean(self, value_of_key: str, dummy, _):
        if value_of_key.lower() == "true":
            return 1
        return 0

    def get_integer(self, value_of_key: str, dummy, _):
        parts = value_of_key.split(' ')
        if len(parts) == 0:
            return 0
        try:
            return int(parts[0])
        except ValueError:
            return 0

    def check_valid_double(self, value_of_key: str, dummy, _):
        try:
            test = float(value_of_key)
            return test
        except ValueError:
            return 0

    def check_valid_integer(self, value_of_key: str, dummy, _):
        try:
            test = int(value_of_key)
            return test
        except ValueError:
            return 0

    def valid_year(self, year_in, dummy, _):
        try:
            return int(year_in)
        except ValueError:
            print(f"Forcing {year_in} to 0 in valid_year")
            return 0

    def valid_date(self, date_in: str, dummy, _):
        try:
            return datetime.strptime(date_in, '%d/%m/%Y').date()
        except ValueError:
            print(f'{date_in} cannot be converted to a valid date - returning sentinel value')
            return datetime.strptime('01/01/1970', '%d/%m/%Y').date()

    def valid_month_and_year(self, date_in: str, dummy, _):
        try:
            return datetime.strptime(date_in, '%b-%y').date()
        except ValueError:
            print(f'{date_in} cannot be converted to a valid date - returning sentinel value')
            return datetime.strptime('Jan-70', '%b-%y').date()

    def constant0(self, dummy1, dummy2, _):
        return 0

    def constant1(self, dummy1, dummy2, _):
        return 1

    def read_translation_schema(self, schema_file):
        self._input_columns = defaultdict(list)
        with open(schema_file, 'r') as file:
            raw_schema = json.load(file)
            raw_schema.pop("version")
            for key, val in raw_schema.items():
                # use match syntax when we have Python 3.10 installed
                if key == "Defaults":
                    for el in val:
                        target_table_name = el['target_table']
                        self._default_columns[target_table_name].append(el)
                elif key == "Distinct":
                    self._distinct_rows_only = val
                else:
                    for el in val:
                        source_column_name = el['name']
                        self._input_columns[source_column_name].append(el)
                print(f'Key {key} had {len(val)} mappings defined')

    def get_all_tables(self):
        all_table_names = []
        for table in DataGroupManager.tables(self._data_group):
            all_table_names.append(table)
            association_tables, _ = Extractor.extract_association_and_target_table_names(table, MetadataReader.tables())
            for assoc_table in association_tables:
                all_table_names.append(assoc_table)
        return all_table_names

    def clear_staging_tables(self):
        cursor = PostgresExecutor.begin_transaction()
        for table in self.get_all_tables():
            sql = f"TRUNCATE TABLE {QuarantineToStagingTranslator.QUARANTINE_STAGING_PREFIX}{table}"
            print(sql)
            cursor.execute(sql)
        PostgresExecutor.end_transaction()

    def run_delimited_function(self, function_to_run: Callable, val: Any, translation_properties: dict,
                               current_row: Row, originator_id: int):
        try:
            function_to_run(self, val, translation_properties, current_row, originator_id)
        # transformed_row_values[assoc_table_name] = val_to_store
        except RowCellCannotContainValueException as rcccve:
            self._error_manager.add_field_too_long_error(
                rcccve.table_name(),
                rcccve.field_name(),
                rcccve.length_of_field(),
                rcccve.length_of_value()
            )

    def run_extended_function(self, function_to_run: Callable, val: Any, translation_properties: dict, current_row: Row,
                              target_name: str):
        try:
            val_to_store = function_to_run(self, val, translation_properties, current_row)
            current_row.set_field_value(target_name, val_to_store)
        except NonExistentForeignKeyException as foreign_key_exception:
            print(str(foreign_key_exception))
            self._error_manager.add_nonexistent_foreign_key_error(
                foreign_key_exception.table_name(),
                foreign_key_exception.fk_target_table_name(),
                foreign_key_exception.lookup_column())
        except RowCellCannotContainValueException as rcccve:
            self._error_manager.add_field_too_long_error(
                rcccve.table_name(),
                rcccve.field_name(),
                rcccve.length_of_field(),
                rcccve.length_of_value()
            )

    def store_standard_field(self, target_table: Table, field_name: str, val: Any):
        try:
            target_table.current_row().set_field_value(field_name, val)
        except RowCellCannotContainValueException as rcccve:
            self._error_manager.add_field_too_long_error(
                rcccve.table_name(),
                rcccve.field_name(),
                rcccve.length_of_field(),
                rcccve.length_of_value()
            )

    def translate(self, executor, driving_table, scan_only=False):
        self._driving_table = driving_table
        self._table_store = TableStore()
        MetadataReader.tables(executor, force=True)
        self.read_translation_schema(JsonPath.make_json_path(self._translation_schema))
        self.clear_staging_tables()
        is_loaded_by_WCMC = DataGroupManager.is_loaded_by_WCMC(self._data_group)
        # prime the table cache
        if not is_loaded_by_WCMC:
            driving_column = DataGroupManager.driving_column(self._data_group)
            list_of_originators = executor.get_quarantine_data_by_driving_column(driving_table, driving_column)
            for originator in list_of_originators:
                executor.open_read_cursor()
                originator_id = originator[0]
                print(f"Processing originator {originator_id}")
                Logger.get_logger().info(f"Processing originator {originator_id}")
                executor.get_cursor_for_driving_column(self._input_columns, driving_table, originator_id,
                                                       driving_column)
                transformed_row_count = self.handle_translation_in_chunks(executor, scan_only, originator_id,
                                                                          chunk_size=5000)
                log_info = f'Metadata provider {originator_id} has supplied {transformed_row_count} rows'
                Logger.get_logger().info(log_info)
                log_info = MemoryManager.memory_as_str(f"Memory was :")
                Logger.get_logger().info(log_info)
                executor.close_read_cursor()
                gc.collect()
        else:
            print(f"Starting on full table")
            executor.open_read_cursor()
            executor.get_cursor_for_driving_column(self._input_columns, driving_table)
            if self._distinct_rows_only.keys():
                chunk_size = 10000000  # got to grab all rows
            else:
                chunk_size = 5000
            transformed_row_count = self.handle_translation_in_chunks(executor, scan_only, chunk_size=chunk_size)
            print(f'Full table was {transformed_row_count} rows')
            executor.close_read_cursor()
            gc.collect()

    # called with the cursor already primed with the rows we need to process
    def handle_translation_in_chunks(self, executor, scan_only,
                                     originator_id=IngestorConstants.WCMC_SPECIAL_PROVIDER_ID,
                                     chunk_size=5000):
        transformed_row_count = 0
        while True:
            # all_transformed_row_values = defaultdict(list)
            # initialize the list of tables we shall populate (association tables will be added on-the-fly)
            self._table_store.reset()
            non_association_table_names = set()
            for _, translation_property_list in self._input_columns.items():
                for translation_properties in translation_property_list:
                    target_table_name = translation_properties["target_table"]
                    self._table_store.get_table(target_table_name)
                    non_association_table_names.add(target_table_name)
            rows = PostgresExecutor.get_row_chunk(chunk_size)
            if not rows:
                break
            for row in rows:
                column_index = 0
                # transformed_row_values = {}
                # add a new row
                for name in non_association_table_names:
                    self._table_store.get_table(name, add_if_absent=True).add_row()
                for column_name, translation_property_list in self._input_columns.items():
                    for translation_properties in translation_property_list:
                        target_table = self._table_store.get_table(translation_properties["target_table"])
                        target_name = translation_properties.get("target_name") or column_name
                        # if target_table n ot in transformed_row_values.keys():
                        # transformed_row_values[target_table] = [{"originator_id": originator_id}]
                        if "function" in translation_properties:
                            function_to_run = self._known_mapping_functions[translation_properties.get("function")]
                            val = row[column_index]
                            if translation_properties.get("delimiter"):
                                self.run_delimited_function(function_to_run, val, translation_properties,
                                                            target_table.current_row(), originator_id)
                            else:
                                self.run_extended_function(function_to_run, val, translation_properties,
                                                           target_table.current_row(), target_name)
                        else:
                            self.store_standard_field(target_table, target_name, row[column_index])
                    column_index += 1
                transformed_row_count += 1
            print(f'Read in {transformed_row_count} so far - storing the data')
            # now store the transformed data
            self._error_manager.raise_any_errors()
            if not scan_only:
                self.persist(executor, self._table_store)
                self._table_store.reset()
        return transformed_row_count

    def persist(self, executor: Executor, table_store: TableStore):
        count_of_rows_stored = defaultdict(int)
        executor.begin_transaction()
        rows_stored = executor.store_transformed_and_associated_rows(table_store, self._distinct_rows_only)
        for target_table, row_count in rows_stored.items():
            count_of_rows_stored[target_table] += row_count
        ForeignKeyHandler.reset()
        executor.end_transaction()
        return count_of_rows_stored

    @staticmethod
    def import_reference_data(uuid: str) -> tuple[bool, TableStore | None, str | None, str | None]:
        error_object: TranslationReferenceDataObject = QuarantineToStagingTranslator.reference_data_error_summaries.get(
            uuid)
        if error_object is None:
            return False, None, None, None
        table_store = TableStore()
        for unknown_attribute_value in error_object.error_manager().unknown_attributes():
            table_name = unknown_attribute_value[0]
            reference_data_table = table_store.get_table(table_name, add_if_absent=True)
            row = reference_data_table.add_row()
            row.set_field_value('code', unknown_attribute_value[1])
            row.set_field_value('description', unknown_attribute_value[1])
            row.set_field_value('is_standard', 0)
        return True, table_store, error_object.data_group(), error_object.creation_time()

    @staticmethod
    def widen_fields(executor: Executor, uuid: str):
        error_object: TranslationReferenceDataObject = QuarantineToStagingTranslator.reference_data_error_summaries.get(
            uuid)
        for field_length_error in error_object.error_manager().field_length_errors():
            target_table = field_length_error[0]
            target_attribute = field_length_error[1]
            required_width = field_length_error[3]
            executor.widen_field(QuarantineToStagingTranslator.QUARANTINE_STAGING_PREFIX + target_table,
                                 target_attribute, required_width)
            executor.widen_field(target_table, target_attribute, required_width)
            MetadataReader.tables(executor, force=True)

    @staticmethod
    def remove_error_object(uuid_for_this_run: str):
        QuarantineToStagingTranslator.reference_data_error_summaries.pop(uuid_for_this_run)
