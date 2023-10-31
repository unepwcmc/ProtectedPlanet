from typing import Any


class CellNotSetException(Exception):
    pass


class UnknownFieldToSetException(Exception):

    def __init__(self, err_msg):
        self._err_msg = err_msg

    def __str__(self):
        return self._err_msg

class RowCellCannotContainValueException(Exception):

    def __init__(self, table_name:str, field_name:str, length_of_field:int, length_of_value:int):
        super().__init__(f'{table_name}:{field_name} of length {length_of_field} is trying to store a value of length {length_of_value}')
        self._table_name = table_name
        self._field_name = field_name
        self._length_of_field = length_of_field
        self._length_of_value = length_of_value

    def field_name(self):
        return self._field_name

    def length_of_field(self):
        return self._length_of_field

    def length_of_value(self):
        return self._length_of_value

    def table_name(self):
        return self._table_name


class ValueNeedsToBeCoercedException(Exception):

    def __init__(self, table_name:str, field_name:str, current_value:Any, proposed_value:Any):
        self._table_name = table_name
        self._field_name = field_name
        self._current_value = current_value
        self._proposed_value = proposed_value

    def current_value(self):
        return self._current_value

    def field_name(self):
        return self._field_name

    def proposed_value(self):
        return self._proposed_value

    def table_name(self):
        return self._table_name

