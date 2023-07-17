from abc import ABC, abstractmethod


# a datablock acts as a unit in a data pipeline. It declares 4 things:
#   the name of the schema piece it can handle
#   the datastreamer it requires to fetch the data, including any configuration parameters for that streamer
#   the keys which it uses to attach to any prior block in the pipeline
#   the keys to which subsequent blocks in the pipeline can attach

class DataBlock(ABC):

    def __init__(self, name):
        self._name = name
        self._where_clause = ""
        self._fields = []

    def add_fields_and_table(self, fields):
        # append the fields
        self._fields += fields

    def add_where_clause(self, where_clause):
        self._where_clause = where_clause

    def fields(self):
        return self._fields

    def name(self):
        return self._name

    def where_clause(self):
        return self._where_clause

    def is_filtered(self):
        return len(self._where_clause) != 0

    def reset(self):
        self._where_clause = ""
        self._fields = []

    @abstractmethod
    def streamer(self):
        pass

    @abstractmethod
    def forward_keys(self):
        pass

    @abstractmethod
    def backward_keys(self):
        pass
