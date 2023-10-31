from __future__ import annotations
from typing import Any
from runtime_mgmt.runtimemanagementexceptions import CellNotSetException, UnknownFieldToSetException, \
    RowCellCannotContainValueException


class RowCell:

    def __init__(self, field: str):
        self._field = field
        self._is_set = False
        self._val = None

    def field(self):
        return self._field

    def is_set(self):
        return self._is_set

    def set_value(self, val: Any):
        self._val = val
        self._is_set = True

    def value(self):
        if self._is_set:
            return self._val
        raise CellNotSetException(f'{self.field} is not set')


class Row:

    def __init__(self, fields, table_name:str):
        self._fields: dict[str, Any] = {field.name(): field for field in fields}
        self._table_name = table_name
        self._values: dict[str, RowCell] = {field.name(): RowCell(field.name()) for field in fields}

    def __eq__(self, other):
        return self._values == other._values

    def __hash__(self):
        return hash(self._values.values())

    def get_field_value(self, field_name: str) -> Any:
        cell_to_set: RowCell = self._values.get(field_name)
        if cell_to_set is None:
            raise UnknownFieldToSetException(f'{field_name} is not a field in {self._table_name}')
        return cell_to_set.value()

    def populated_fields_as_dict(self) -> dict:
        row_representation = {}
        for key, row_cell in self._values.items():
            if row_cell.is_set():
                row_representation[key] = row_cell.value()
        return row_representation

    def set_field_value_if_present(self, field_name:str, val:Any):
        cell_to_set: RowCell = self._values.get(field_name)
        if cell_to_set is None:
            return
        self.set_field_value(field_name, val)

    def set_field_value(self, field_name: str, val: Any):
        cell_to_set: RowCell = self._values.get(field_name)
        if cell_to_set is None:
            err_msg = f'Field [{field_name}] is not a field in table [{self._table_name}]'
            raise UnknownFieldToSetException(err_msg)
        if isinstance(val, str):
            field_info = self._fields.get(field_name)
            data_type:str = field_info.data_type().lower()
            if 'varchar' in data_type:
                length_as_str = data_type[data_type.find('(') + 1:data_type.find(')')]
                length_of_field = int(length_as_str)
                if length_of_field < len(val):
                    raise RowCellCannotContainValueException(self._table_name, field_name, length_of_field, len(val))
        cell_to_set.set_value(val)

    def table_name(self):
        return self._table_name

    @staticmethod
    def unique(rows:list[Row]) -> list[Row]:
        return list(set(rows))