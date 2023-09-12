# a datablock acts as a unit in a data pipeline. It declares 4 things:
#   the name of the schema piece it can handle
#   the datastreamer it requires to fetch the data, including any configuration parameters for that streamer
#   the keys which it uses to attach to any prior block in the pipeline
#   the keys to which subsequent blocks in the pipeline can attach
from filtering_logic.postgresstreamer import PostgresStreamer


class DataBlock:

    def __init__(self, name):
        self._name = name
        self._where_clause = ""
        self._fields = []
        self.stream = None

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

    def streamer(self):
        self.stream = PostgresStreamer()
        return self.stream



class AssociationDataBlock(DataBlock):
    def __init__(self, name: list[str], first_block: DataBlock, second_block: DataBlock):
        super().__init__(".".join(name))
        self.first_block = first_block
        self.second_block = second_block
