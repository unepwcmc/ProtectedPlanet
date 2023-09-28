# Raised when the extractor reckons the schema is incorrect in its definition of a 1:N foreign key

class UnknownTableForForeignKeyException(Exception):
    pass
