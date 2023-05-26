class ForeignKeyException(Exception):
    pass

class ForeignKeyHandler:

    _cached_keys = {}

    @classmethod
    def load_keys(cls, executor, lookup_table, lookup_column, code_column, time_of_creation):
        all_keys = executor.load_keys(lookup_table, code_column, lookup_column, time_of_creation)
        cls._cached_keys[lookup_table.lower()] = all_keys

    @classmethod
    def get_code_for_description(cls, table_name, description_value):
        table_keys = cls._cached_keys.get(table_name.lower())
        if table_keys is None:
            err_msg = f'No foreign keys known for {table_name}'
            raise ForeignKeyException(err_msg)
        description = table_keys.get(description_value.strip())
        if description is None:
            err_msg = f'No such description as {description_value} within foreign key {table_name}'
            raise ForeignKeyException(err_msg)
        return description