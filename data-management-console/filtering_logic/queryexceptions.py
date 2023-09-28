# Define some domain-specific exceptions that can be raised

class InvalidTermException(Exception):
    pass


class UnknownBlockException(Exception):
    pass


class RelationshipException(Exception):
    pass
