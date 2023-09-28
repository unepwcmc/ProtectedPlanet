# Define some exceptions specific to the tokenizing process to support meaningful error messages
class UnterminatedStringException(Exception):
    pass


class MalformedCompoundBlockException(Exception):
    pass
