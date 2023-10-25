# Meaningful exceptions for when we want to report errors
class ColumnByNameException(Exception):
    pass


class FKByNameException(Exception):
    pass


class FKColumnMappingException(Exception):
    pass

class DuplicateFieldDeclaration(Exception):

    def __init__(self, duplicate_fields:dict):
        super().__init__('Duplicate Field Declaration detected')
        self._duplicate_fields = duplicate_fields

    def __str__(self):
        return str(self._duplicate_fields)

class LowerCaseColumnsOnlyException(Exception):
    pass