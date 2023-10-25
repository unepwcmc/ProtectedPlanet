# Our internal representation of the metadata of a database table.  Used by the Translator, StagingDataPromoter
# and Query Service, and stored in the metadata table.  Read in upon service startup by the MetadataReader.
from __future__ import annotations
import copy

from util.logger import Logger
from schema_management.tableexceptions import ColumnByNameException, FKByNameException


class TableColumn:
    def __init__(self, table_name, name, data_type):
        self._table_name = table_name.strip()
        self._name = name.strip()
        self._data_type = data_type

    def __str__(self):
        return f"{self._name} : {self._data_type}"

    def convert(self, converter):
        return converter.encode_column(self._name, self._data_type)

    def copy(self):
        return TableColumn(self._table_name, self._name, self._data_type)

    def data_type(self):
        return self._data_type

    def metadata(self):
        return self._table_name, self._name, self._data_type, ""

    def name(self):
        return self._name

    def set_table_name(self, new_table_name: str):
        self._table_name = new_table_name

    def table_name(self):
        return self._table_name


class VirtualColumn:
    key_count = 0

    def __init__(self, table_name, name, associated_column_name, function_to_call, representation):
        self._table_name = table_name
        self._name = name
        self._associated_column_name = associated_column_name
        self._function_to_call = function_to_call
        self._representation = representation

    def associated_column_name(self):
        return self._associated_column_name

    def convert(self, _):
        return None

    def function_to_call(self):
        return self._function_to_call

    def metadata(self):
        return self._table_name, self._name, "VIRTUAL COLUMN", f"{self._associated_column_name}:{self._function_to_call}:{self._representation}"

    def name(self):
        return self._name

    @classmethod
    def next_key(cls):
        val = cls.key_count
        cls.key_count += 1
        return val

    def representation(self):
        return self._representation

    def __str__(self):
        return f"{self._name} reporting on {self._associated_column_name}"

    def table_name(self):
        return self._table_name

    @staticmethod
    def parse_out_key_elements(extra_info):
        [associated_column_name, function_to_call, representation] = extra_info.split(":")
        return associated_column_name, function_to_call, representation


class PrimaryKey:
    def __init__(self, table_name: str, column_names: list[str]):
        self._column_names = column_names
        self._name = "PK_" + table_name
        self._table_name = table_name

    def column_names(self):
        return self._column_names

    def convert(self, converter):
        return converter.code_primary_key(self._column_names)

    def metadata(self):
        return self._table_name, self._name, "PRIMARY KEY", ",".join(self._column_names)

    def set_column_names(self, column_names: list[str]):
        self._column_names = column_names


class IndexRequest:
    key_count = 0

    def __init__(self, table_name, column_names):
        self._column_names = column_names
        self._name = table_name + str(self.next_key())
        self._table_name = table_name

    @classmethod
    def next_key(cls):
        val = cls.key_count
        cls.key_count += 1
        return val

    def convert(self, converter, area):
        return converter.code_index_request(self._table_name, area, self._column_names, self._name)

    def metadata(self):
        return self._table_name, self._name, "INDEX REQUEST", ",".join(self._column_names)


class ForeignKeyCounter:
    key_count = 0

    @classmethod
    def next_key(cls):
        val = cls.key_count
        cls.key_count += 1
        return val


class ForeignKey:

    def __init__(self, table_name: str, source_columns: list[str], target_table: str, target_columns: list[str],
                 lookup_columns: list[str], known_as: str, other_field: str):
        self._table_name = table_name
        self._source_columns = [source_column.strip() for source_column in source_columns]
        self._target_table = target_table
        self._target_columns = [target_column.strip() for target_column in target_columns]
        self._lookup_columns = [lookup_column.strip() for lookup_column in lookup_columns]
        self._known_as = known_as
        self._other_field = other_field
        self._name = "FK_" + table_name + str(ForeignKeyCounter.next_key())

    def association_table_alias(self):
        raise Exception('Asking a Foreign Key for its association table alias')

    def convert(self, converter):
        return converter.codeForeignKey(self._source_columns, self._target_table, self._target_columns)

    def is_one_to_one(self):
        return True

    def known_as(self):
        return self._known_as

    def lookup_columns(self):
        return self._lookup_columns

    def metadata(self):
        key_columns = ",".join(self._source_columns) + ":" + self._target_table + ":" + ",".join(
            self._target_columns) + ":" + ",".join(
            self._lookup_columns) + ":" + self._known_as + ":" + self._other_field
        return self._table_name, self._name, "FOREIGN KEY", key_columns

    def other_field(self):
        return self._other_field

    @staticmethod
    def parse_out_key_columns(combined_string: str) -> tuple[list[str], str, list[str], list[str], str, str]:
        parts = combined_string.split(":")
        source_columns = parts[0].split(",")
        target_table = parts[1]
        target_columns = parts[2].split(",")
        lookup_columns = parts[3].split(",")
        known_as = parts[4]
        other_field = parts[5]
        return source_columns, target_table, target_columns, lookup_columns, known_as, other_field

    def source_columns(self) -> list[str]:
        return self._source_columns

    def table_name(self):
        return self._table_name

    def target_columns(self) -> list[str]:
        return self._target_columns

    def target_table(self) -> str:
        return self._target_table


class ForeignKeyN(ForeignKey):

    def __init__(self, table_name, source_columns, target_table, target_columns, lookup_columns, known_as, other_field,
                 association_table_alias):
        super().__init__(table_name, source_columns, target_table, target_columns, lookup_columns, known_as,
                         other_field)
        self._association_table_alias = association_table_alias

    def association_table_alias(self):
        return self._association_table_alias

    def is_one_to_one(self):
        return False

    def metadata(self):
        key_columns = ",".join(self._source_columns) + ":" + self._target_table + ":" + ",".join(
            self._target_columns) + ":" + ",".join(
            self._lookup_columns) + ":" + self._known_as + ":" + self._other_field + ":" + self._association_table_alias
        return self._table_name, self._name, "FOREIGN KEY N", key_columns

    @staticmethod
    def parse_out_key_columns(combined_string: str) -> tuple[list[str], str, list[str], list[str], str, str, str]:
        parts = combined_string.split(":")
        source_columns = parts[0].split(",")
        target_table = parts[1]
        target_columns = parts[2].split(",")
        lookup_columns = parts[3].split(",")
        known_as = parts[4]
        other_field = parts[5]
        association_table_alias = parts[6]
        return source_columns, target_table, target_columns, lookup_columns, known_as, other_field, association_table_alias


class TableDefinition:
    def __init__(self, name, elements):
        self._name = name
        self._elements = elements

    def elements(self):
        return self._elements

    def name(self):
        return self._name

    def __str__(self):
        elements = [str(el) for el in self._elements]
        return f"{self._name} has {len(self._elements)} elements -> {','.join(elements)}"

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
        Logger.get_logger().info(f'Adding historical columns from {historical_table_def.name()} to {self._name}')
        historical_columns_added = copy.deepcopy(historical_table_def.columns())
        for el in historical_columns_added:
            el._table_name = self._name
        elements = self._elements + historical_columns_added
        historical_primary_key = historical_table_def.primary_key()
        if historical_primary_key is not None:
            Logger.get_logger().info(f'Historical primary key is {historical_primary_key.column_names()}')
            self_primary_key = self.primary_key()
            if self_primary_key is not None:
                self_primary_key.set_column_names(
                    self_primary_key.column_names() + historical_primary_key.column_names())
                Logger.get_logger().info(f'There are now {len(self_primary_key.column_names())} elements in the PK')
        return TableDefinition(self._name, elements)

    def add_objectid_columns(self, objectid_table_def):
        objectid_columns_added = copy.deepcopy(objectid_table_def.columns())
        for el in objectid_columns_added:
            el._table_name = self._name
        elements = self._elements + objectid_columns_added
        return TableDefinition(self._name, elements)

    def add_ingestion_columns(self, ingestion_table_def):
        ingestion_columns_added = copy.deepcopy(ingestion_table_def.columns())
        for el in ingestion_columns_added:
            el._table_name = self._name
        elements = self._elements + ingestion_columns_added
        return TableDefinition(self._name, elements)

    def primary_key(self):
        primary_key = filter(lambda x: isinstance(x, PrimaryKey), self._elements)
        vals = list(primary_key)
        if len(vals) == 0:
            return None
        return vals[0]

    def columns(self) -> list[TableColumn]:
        return list(filter(lambda x: isinstance(x, TableColumn), self._elements))

    def foreign_keys(self) -> list[ForeignKey]:
        return list(filter(lambda x: isinstance(x, ForeignKey), self._elements))

    def virtual_columns(self) -> list[VirtualColumn]:
        return list(filter(lambda x: isinstance(x, VirtualColumn), self._elements))

    def indexes(self) -> list[IndexRequest]:
        return list(filter(lambda x: isinstance(x, IndexRequest), self._elements))

    def column_by_name(self, column_name: str) -> TableColumn:
        lower_column_name = column_name.lower()
        cols = list(
            filter(lambda x: isinstance(x, TableColumn) and x.name().lower() == lower_column_name, self._elements))
        if len(cols) != 1:
            cols = list(
                filter(lambda x: isinstance(x, VirtualColumn) and x.name().lower() == lower_column_name,
                       self._elements))
            if len(cols) != 1:
                err_msg = f"Don't have one and only one matching column, either real or virtual: {column_name}"
                raise ColumnByNameException(err_msg)
            return cols[0]
        return cols[0]

    def add_column(self, new_column):
        self._elements.append(new_column)

    def fk_for_attribute(self, target_attribute):
        fks = self.foreign_keys()
        for fk in fks:
            if fk.known_as() == target_attribute:
                return fk
        err_msg = f"Table {self._name} doesn't have a Foreign Key known as {target_attribute}"
        raise FKByNameException(err_msg)
