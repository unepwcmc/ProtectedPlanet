import json


class DataGroupManager:
    _data_group_dictionary = None

    @classmethod
    def parameterize(cls, data_group_file):
        with open(data_group_file, 'r') as file:
            cls._data_group_dictionary = json.load(file)

    @classmethod
    def tables(cls, data_group):
        if cls._data_group_dictionary.get(data_group) is None:
            err_msg = "No such data group as {data_group} exists"
            raise KeyError(err_msg)
        return cls._data_group_dictionary[data_group]["tables"]

    @classmethod
    def originator_ids(cls, data_group):
        return cls._data_group_dictionary[data_group]["originator_ids"]

    @classmethod
    def driving_table(cls, data_group):
        return cls._data_group_dictionary[data_group]["driving_table"]

    @classmethod
    def driving_column(cls, data_group):
        return cls._data_group_dictionary[data_group]["driving_column"]

    @classmethod
    def translation_schema(cls, data_group):
        return cls._data_group_dictionary[data_group]["translation_schema"]

