from typing import Any


class TranslationReferencingUnknownFKException(Exception):
    pass


class TranslationNot1ToNException(Exception):

    def __init__(self, target_attribute:str, target_table:str):
        super().__init__('Is referenced by a 1:1 key - need to be 1:n')
        self._target_attribute = target_attribute
        self._target_table = target_table

    def target_attribute(self):
        return self._target_attribute

    def target_table(self):
        return self._target_table

class UnknownAttributeException(Exception):

    def __init__(self, target_table_name: str, lookup_column:str, value: Any):
        super().__init__(f'UnknownAttributeException of value {str(value)} on {target_table_name}')
        self._target_table_name = target_table_name
        self._lookup_column = lookup_column
        self._value = value

    def lookup_column(self):
        return self._lookup_column

    def target_table(self):
        return self._target_table_name

    def value(self):
        return self._value

class WithOtherSpecifiedIncorrectlyInTranslationException(Exception):
    pass