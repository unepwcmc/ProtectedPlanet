# Our internal representation of the metadata of a database table.  Used by the Translator, StagingDataPromoter
# and Query Service, and stored in the metadata table.  Read in upon service startup by the MetadataReader.
import copy

from mgmt_logging.logger import Logger
from schema_management.tableexceptions import ColumnByNameException, FKByNameException, FKColumnMappingException


class TableColumn:
    def __init__(self, table_name, name, data_type):
        self.table_name = table_name.strip()
        self.name = name.strip()
        self.data_type = data_type

    def __str__(self):
        return f"{self.name} : {self.data_type}"

    def convert(self, converter):
        return converter.encode_column(self.name, self.data_type)

    def metadata(self):
        return self.table_name, self.name, self.data_type, ""

    def copy(self):
        return TableColumn(self.table_name, self.name, self.data_type)


class VirtualColumn:
    key_count = 0

    def __init__(self, table_name, name, associated_column_name, function_to_call, representation):
        self.table_name = table_name
        self.name = name
        self.associated_column_name = associated_column_name
        self.function_to_call = function_to_call
        self.representation = representation

    @classmethod
    def next_key(cls):
        val = cls.key_count
        cls.key_count += 1
        return val

    def convert(self, _):
        return None

    def metadata(self):
        return self.table_name, self.name, "VIRTUAL COLUMN", f"{self.associated_column_name}:{self.function_to_call}:{self.representation}"

    def __str__(self):
        return f"{self.name} reporting on {self.associated_column_name}"

    @staticmethod
    def parse_out_key_elements(extra_info):
        [associated_column_name, function_to_call, representation] = extra_info.split(":")
        return associated_column_name, function_to_call, representation


class PrimaryKey:
    def __init__(self, table_name, column_names):
        self.column_names = column_names
        self.name = "PK_" + table_name
        self.table_name = table_name

    def convert(self, converter):
        return converter.code_primary_key(self.column_names)

    def metadata(self):
        return self.table_name, self.name, "PRIMARY KEY", ",".join(self.column_names)


class IndexRequest:
    key_count = 0

    def __init__(self, table_name, column_names):
        self.column_names = column_names
        self.name = table_name + str(self.next_key())
        self.table_name = table_name

    @classmethod
    def next_key(cls):
        val = cls.key_count
        cls.key_count += 1
        return val

    def convert(self, converter, area):
        return converter.code_index_request(self.table_name, area, self.column_names, self.name)

    def metadata(self):
        return self.table_name, self.name, "INDEX REQUEST", ",".join(self.column_names)


class ForeignKeyCounter:
    key_count = 0

    @classmethod
    def next_key(cls):
        val = cls.key_count
        cls.key_count += 1
        return val


class ForeignKey:

    def __init__(self, table_name, source_columns, target_table, target_columns, lookup_columns, known_as):
        self.table_name = table_name
        self.source_columns = [source_column.strip() for source_column in source_columns]
        self.target_table = target_table
        self.target_columns = [target_column.strip() for target_column in target_columns]
        self.lookup_columns = [lookup_column.strip() for lookup_column in lookup_columns]
        self.known_as = known_as
        self.name = "FK_" + table_name + str(ForeignKeyCounter.next_key())

    def convert(self, converter):
        return converter.codeForeignKey(self.source_columns, self.target_table, self.target_columns)

    def metadata(self):
        key_columns = ",".join(self.source_columns) + ":" + self.target_table + ":" + ",".join(
            self.target_columns) + ":" + ",".join(self.lookup_columns) + ":" + self.known_as
        return self.table_name, self.name, "FOREIGN KEY", key_columns

    @staticmethod
    def parse_out_key_columns(combined_string: str):
        parts = combined_string.split(":")
        source_columns = parts[0].split(",")
        target_table = parts[1]
        target_columns = parts[2].split(",")
        if len(parts) > 3:
            lookup_columns = parts[3].split(",")
        else:
            lookup_columns = target_columns
        if len(parts) > 4:
            known_as = parts[4]
        else:
            associated_name = source_columns[0]
            known_as = associated_name[0:len(associated_name) - 3]  # remove the _id as a temporary measure

        return source_columns, target_table, target_columns, lookup_columns, known_as

    def is_one_to_one(self):
        return True


class ForeignKeyN(ForeignKey):

    def __init__(self, table_name, source_columns, target_table, target_columns, lookup_columns, known_as, association_table_alias):
        super().__init__(table_name, source_columns, target_table, target_columns, lookup_columns, known_as)
        self.association_table_alias = association_table_alias

    def metadata(self):
        key_columns = ",".join(self.source_columns) + ":" + self.target_table + ":" + ",".join(
            self.target_columns) + ":" + ",".join(self.lookup_columns) + ":" + self.known_as + ":" + self.association_table_alias
        return self.table_name, self.name, "FOREIGN KEY N", key_columns

    def is_one_to_one(self):
        return False

    @staticmethod
    def parse_out_key_columns(combined_string: str):
        parts = combined_string.split(":")
        assert(len(parts) == 6)
        source_columns = parts[0].split(",")
        target_table = parts[1]
        target_columns = parts[2].split(",")
        lookup_columns = parts[3].split(",")
        known_as = parts[4]
        association_table_alias = parts[5]
        return source_columns, target_table, target_columns, lookup_columns, known_as, association_table_alias

class TableRow:
    def __init__(self, table_def):
        self.table_def = table_def  # this is a TableDefinition
        self.fields = {}

    def get_value(self, column_name):
        if column_name in self.fields:
            return self.fields[column_name]
        return None

    def set_value(self, column_name, val):
        self.fields[column_name] = val

    def __eq__(self, other_row):
        return (self.table_def.name == other_row.table_def.name) and (self.fields == other_row.fields)


class TableDefinition:
    def __init__(self, name, elements):
        self.name = name
        self.elements = elements

    def __str__(self):
        elements = [str(el) for el in self.elements]
        return f"{self.name} has {len(self.elements)} elements -> {','.join(elements)}"

    def convert(self, converter):
        non_index_cols = filter(lambda x: not isinstance(x, IndexRequest), self.columns())
        cols = [el.convert(converter) for el in non_index_cols]
        if self.primary_key() is not None:
            cols.append(self.primary_key().convert(converter))
        return cols

    def convert_index_requests(self, converter, area):
        indexes = [el.convert(converter, area) for el in self.indexes()]
        return indexes

    def add_historical_columns(self, historical_table_def):
        Logger.get_logger().info(f'Adding historical columns from {historical_table_def.name} to {self.name}')
        historical_columns_added = copy.deepcopy(historical_table_def.columns())
        for el in historical_columns_added:
            el.table_name = self.name
        elements = self.elements + historical_columns_added
        historical_primary_key = historical_table_def.primary_key()
        if historical_primary_key is not None:
            Logger.get_logger().info(f'Historical primary key is {historical_primary_key.column_names}')
            self_primary_key = self.primary_key()
            if self_primary_key is not None:
                self_primary_key.column_names = self_primary_key.column_names + historical_primary_key.column_names
                Logger.get_logger().info(f'There are now {len(self_primary_key.column_names)} elements in the PK')
        return TableDefinition(self.name, elements)

    def add_objectid_columns(self, objectid_table_def):
        objectid_columns_added = copy.deepcopy(objectid_table_def.columns())
        for el in objectid_columns_added:
            el.table_name = self.name
        elements = self.elements + objectid_columns_added
        return TableDefinition(self.name, elements)

    def add_ingestion_columns(self, ingestion_table_def):
        ingestion_columns_added = copy.deepcopy(ingestion_table_def.columns())
        for el in ingestion_columns_added:
            el.table_name = self.name
        elements = self.elements + ingestion_columns_added
        return TableDefinition(self.name, elements)

    def primary_key(self):
        primary_key = filter(lambda x: isinstance(x, PrimaryKey), self.elements)
        vals = list(primary_key)
        if len(vals) == 0:
            return None
        return vals[0]

    def columns(self) -> list[TableColumn]:
        return list(filter(lambda x: isinstance(x, TableColumn), self.elements))

    def foreign_keys(self) -> list[ForeignKey]:
        return list(filter(lambda x: isinstance(x, ForeignKey), self.elements))

    def virtual_columns(self) -> list[VirtualColumn]:
        return list(filter(lambda x: isinstance(x, VirtualColumn), self.elements))

    def indexes(self) -> list[IndexRequest]:
        return list(filter(lambda x: isinstance(x, IndexRequest), self.elements))

    def column_by_name(self, column_name: str) -> TableColumn:
        lower_column_name = column_name.lower()
        cols = list(filter(lambda x: isinstance(x, TableColumn) and x.name.lower() == lower_column_name, self.elements))
        if len(cols) != 1:
            cols = list(
                filter(lambda x: isinstance(x, VirtualColumn) and x.name.lower() == lower_column_name, self.elements))
            if len(cols) != 1:
                err_msg = f"Don't have one and only one matching column, either real or virtual: {column_name}"
                raise ColumnByNameException(err_msg)
            return cols[0]
        return cols[0]

    def add_column(self, new_column):
        self.elements.append(new_column)

    def fk_for_attribute(self, target_attribute):
        fks = self.foreign_keys()
        for fk in fks:
            if fk.known_as == target_attribute:
                return fk
        err_msg = f"Table {self.name} doesn't have a Foreign Key known as {target_attribute}"
        raise FKByNameException(err_msg)
