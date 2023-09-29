# Meaningful exceptions for when we want to report errors
class ColumnByNameException(Exception):
    pass

class FKByNameException(Exception):
    pass

class FKColumnMappingException(Exception):
    pass