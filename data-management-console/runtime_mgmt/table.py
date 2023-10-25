from runtime_mgmt.row import Row
from schema_management.tabledefinitions import TableColumn
from util.metadatareader import MetadataReader


class Table:

    def __init__(self, table_name: str):
        self._table_definition = MetadataReader.tables().get(table_name)
        self._new_row = None
        self._rows = []
        self._last_watermark = 0

    def add_row(self) -> Row:
        self._new_row = Row(self.get_all_fields(), self.name())
        self._rows.append(self._new_row)
        return self._new_row

    def commit(self):
        self._last_watermark = len(self._rows)
        self._new_row = None

    def current_row(self) -> Row:
        return self._new_row

    def get_all_fields(self) -> list[TableColumn]:
        return self._table_definition.columns()

    def name(self) -> str:
        return self._table_definition.name()

    def rollback(self):
        self._rows = self._rows[:self._last_watermark]
        self._new_row = None

    def rows(self):
        return self._rows

    def store_row(self, row: Row):
        self._rows.append(row)
        self.commit()

    def unique_all(self, uniqueness_key: str | list[str] = None):
        self._last_watermark = 0
        return self.unique_new(uniqueness_key)

    def unique_new(self, uniqueness_key: str | list[str] = None):
        # if nothing added, clear out
        if self._last_watermark == len(self._rows):
            return
        if uniqueness_key is not None:
            if isinstance(uniqueness_key, str):
                unique_rows = {row.get_field_value(uniqueness_key): row for row in self._rows[self._last_watermark:]}
            else:
                unique_rows = {tuple([row.get_field_value(key) for key in uniqueness_key]): row for row in self._rows[self._last_watermark:]}
            unique_rows = list(unique_rows.values())
        else:
            unique_rows = Row.unique(self._rows[self._last_watermark:])
        self._rows = self._rows[0:self._last_watermark] + unique_rows
        self._last_watermark = len(self._rows)


class TableStore:

    def __init__(self):
        self._tables = {}

    def get_table(self, table_name: str, add_if_absent: bool = False) -> Table | None:
        table = self._tables.get(table_name)
        if table is None and add_if_absent:
            table = Table(table_name)
            self._tables[table_name] = table
        return table

    def reset(self):
        self._tables.clear()

    @staticmethod
    def rows_as_dict(rows: list[Row]) -> list[dict]:
        rows_as_dict = []
        for row in rows:
            rows_as_dict.append(row.populated_fields_as_dict())
        return rows_as_dict

    def tables(self) -> list:
        return list(self._tables.keys())
