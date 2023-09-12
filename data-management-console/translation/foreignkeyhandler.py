import time

from metadata_mgmt.metadatareader import MetadataReader
from schema_management.tables import ForeignKey
from translation.translationfkhelper import TranslationFKHelper

class ForeignKeyException(Exception):
    pass


class ForeignKeyHandler:
    _cached_keys = {}

    @classmethod
    def load_keys(cls, executor, target_attribute_name, target_table_name, time_of_creation):
        fk: ForeignKey = TranslationFKHelper.fk_for_attribute(target_table_name, target_attribute_name)
        lookup_column = fk.lookup_columns[0]
        target_column = fk.target_columns[0]
        lookup_key = fk.target_table + "_" + lookup_column
        existing_keys = cls._cached_keys.get(lookup_key)
        if not existing_keys:
            all_keys = executor.load_keys(fk.target_table, lookup_column, target_column, time_of_creation)
            cls._cached_keys[lookup_key] = all_keys

    @classmethod
    def get_id_for_code(cls, target_attribute_name, target_table_name, value_of_key):
        fk: ForeignKey = TranslationFKHelper.fk_for_attribute(target_table_name, target_attribute_name)
        lookup_column = fk.lookup_columns[0]
        lookup_key = fk.target_table + "_" + lookup_column
        table_keys = cls._cached_keys.get(lookup_key)
        if table_keys is None:
            err_msg = f'No foreign keys known for {lookup_key}'
            raise ForeignKeyException(err_msg)
        target_attribute_value = table_keys.get(value_of_key.lower())
        if target_attribute_value is None:
            return 1
        return target_attribute_value

    @classmethod
    def get_relationship(cls, upstream_table_name, downstream_table_name):
        # first look in the upstream table for the FK relationship
        tables = MetadataReader.tables()
        upstream_foreign_keys: list[ForeignKey] = tables[upstream_table_name].foreign_keys()
        for fk in upstream_foreign_keys:
            if fk.table_name == upstream_table_name and fk.target_table == downstream_table_name:
                return ([f'{upstream_table_name}.{src}' for src in fk.source_columns],
                        [f'{downstream_table_name}.{src}' for src in fk.target_columns],
                        fk.is_one_to_one())
        downstream_foreign_keys: list[ForeignKey] = tables[downstream_table_name].foreign_keys()
        for fk in downstream_foreign_keys:
            if fk.table_name == downstream_table_name and fk.target_table == upstream_table_name:
                return ([f'{upstream_table_name}.{src}' for src in fk.target_columns],
                        [f'{downstream_table_name}.{src}' for src in fk.source_columns],
                        False)
        err_msg = f"No relationship exists between {upstream_table_name} and {downstream_table_name}"
        raise ForeignKeyException(err_msg)
