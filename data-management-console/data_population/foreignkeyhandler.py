from data_population.translationexceptions import UnknownAttributeException
from util.metadatareader import MetadataReader
from schema_management.tabledefinitions import ForeignKey, ForeignKeyN
from data_population.translationfkhelper import TranslationFKHelper


class NonExistentForeignKeyException(Exception):

    def __init__(self, table_name: str, fk_target_table_name: str, lookup_column: str):
        super().__init__('NonExistentForeignKeyException')
        self._table_name = table_name
        self._fk_target_table_name = fk_target_table_name
        self._lookup_column = lookup_column

    def table_name(self):
        return self._table_name

    def fk_target_table_name(self):
        return self._fk_target_table_name

    def lookup_column(self):
        return self._lookup_column


class ForeignKeyHandler:
    _cached_keys = {}

    @classmethod
    def load_keys(cls, executor, target_attribute_name, target_table_name, time_of_creation):
        fk: ForeignKey = TranslationFKHelper.fk_for_attribute(target_table_name, target_attribute_name)
        lookup_column = fk.lookup_columns()[0]
        target_column = fk.target_columns()[0]
        lookup_key = fk.target_table() + "_" + lookup_column
        existing_keys = cls._cached_keys.get(lookup_key)
        if not existing_keys:
            all_keys = executor.load_keys(fk.target_table(), lookup_column, target_column, time_of_creation)
            cls._cached_keys[lookup_key] = all_keys

    @classmethod
    def get_id_for_code(cls, target_attribute_name, target_table_name, value_of_key):
        fk: ForeignKey = TranslationFKHelper.fk_for_attribute(target_table_name, target_attribute_name)
        lookup_column = fk.lookup_columns()[0]
        lookup_key = fk.target_table() + "_" + lookup_column
        table_keys = cls._cached_keys.get(lookup_key)
        if table_keys is None:
            raise NonExistentForeignKeyException(target_table_name, fk.target_table(), lookup_column)
        # make comparisons case-insensitive by making everything lower case.  Remove leading and trailing whitespace
        # otherwise migration throws up too many of these errors
        target_attribute_value = table_keys.get(value_of_key.lower().strip())
        if target_attribute_value is None:
            raise UnknownAttributeException(fk.target_table(), lookup_column, value_of_key)
        return target_attribute_value

    @classmethod
    def get_relationship(cls, upstream_table_name, downstream_table_name):
        # first look in the upstream table for the FK relationship
        tables = MetadataReader.tables()
        upstream_foreign_keys: list[ForeignKey] = tables[upstream_table_name].foreign_keys()
        for fk in upstream_foreign_keys:
            if fk.table_name() == upstream_table_name and fk.target_table() == downstream_table_name:
                return ([f'{upstream_table_name}.{src}' for src in fk.source_columns()],
                        [f'{downstream_table_name}.{src}' for src in fk.target_columns()],
                        fk.is_one_to_one())
        downstream_foreign_keys: list[ForeignKey] = tables[downstream_table_name].foreign_keys()
        for fk in downstream_foreign_keys:
            if fk.table_name() == downstream_table_name and fk.target_table() == upstream_table_name:
                return ([f'{upstream_table_name}.{src}' for src in fk.target_columns()],
                        [f'{downstream_table_name}.{src}' for src in fk.source_columns()],
                        # normally, this means we're looking from the reference table backwards along the foreign key to the
                        # table containing the id's.  However, the case of _internal_ keys for a Foreign Key (not a Foreign Key N) is always 1:1 so
                        # recognize this case
                        fk.known_as() == '_internal_' and not isinstance(fk, ForeignKeyN))
        raise NonExistentForeignKeyException(upstream_table_name, downstream_table_name, 'No relationship')

    @staticmethod
    def get_association_foreign_keys(association_table_name: str, main_table_name: str) -> tuple:
        tables = MetadataReader.tables()
        association_foreign_keys: list[ForeignKey] = tables[association_table_name].foreign_keys()
        # there should be 2 FK's, one point upstream and one pointing downstream
        assert (len(association_foreign_keys) == 2)
        if association_foreign_keys[0].target_table() == main_table_name:
            return ([f'{association_table_name}.{src_col}' for src_col in association_foreign_keys[0].source_columns()],
                    [f'{association_table_name}.{src_col}' for src_col in association_foreign_keys[1].source_columns()],
                    [f'{main_table_name}.{target_col}' for target_col in association_foreign_keys[0].target_columns()])
        return ([f'{association_table_name}.{src_col}' for src_col in association_foreign_keys[1].source_columns()],
                [f'{association_table_name}.{src_col}' for src_col in association_foreign_keys[0].source_columns()],
                [f'{main_table_name}.{target_col}' for target_col in association_foreign_keys[1].target_columns()])

    @classmethod
    def reset(cls):
        cls._cached_keys.clear()