# These are the components of the grammar supported by the DSL.
# Each component returns whether it can consume the token or tokens at the head of the token list passed to it
# If it cannot accept the token(s), FSMEnum.NOT_ACCEPTED should be returned; if it can accept the tokens, it should
# return the next status (e.g.FSMEnum.FIELD_CLAUSE_COMPLETE) as well as the tail of the token list (i.e. having removed
# the tokens it would consume to change states)
from enum import Enum


class FieldTerminal:
    pass


class ValueTerminal:
    pass


class UnaryOperator(Enum):
    MINUS = "-"


class BinaryOperator(Enum):
    AND = "AND",
    OR = "OR",
    EQUALS = "=",
    NOT_EQUALS = "<>",
    LESS_THAN = "<",
    GREATER_THAN = ">",
    LESS_THAN_OR_EQUALS = "<=",
    GREATER_THAN_OR_EQUAL = ">="


class SelectionOperator(Enum):
    LEFT_SQ_BRA = "[",
    RIGHT_SQ_BRA = "]"


class UnaryOperatorClause:

    def consume_token(self, operator_tok):
        pass


class BinaryOperatorClause:

    def __init__(self, bin_op_clause):
        self.right_clause = None
        self.binary_operator = None
        self.left_clause = bin_op_clause

    def consume_token(self, token_list):
        if len(token_list) < 1:
            return FSMEnum.NOT_ACCEPTED, None
        self.binary_operator = token_list[0]  # check against accepted operators
        self.right_clause = FieldClause()
        potential_status, remaining_token_list = self.right_clause.consume_token(token_list[1:])
        return potential_status, remaining_token_list


class SelectionClause:

    def __init__(self):
        self.field_clause = None
        self.bin_op = None

    def consume_token(self, token_list):
        if len(token_list) == 0:
            return FSMEnum.NOT_ACCEPTED, None
        if token_list[0] == "[":
            self.field_clause = FieldClause()
            status, remaining_token_list = self.field_clause.consume_token(token_list[1:])
            if status == FSMEnum.FIELD_CLAUSE_COMPLETE:
                potential_status, remaining_token_list = self.consume_token(remaining_token_list)
                if potential_status != FSMEnum.NOT_ACCEPTED:
                    return potential_status, remaining_token_list
        if token_list[0] == "]":
            return FSMEnum.TABLE_OR_PATH_SEPARATOR_OR_FIELDS, token_list[1:]
        # now check for further clauses
        self.bin_op = BinaryOperatorClause(self.field_clause)
        potential_status, remaining_token_list = self.bin_op.consume_token(token_list)
        if potential_status == FSMEnum.FIELD_CLAUSE_COMPLETE:
            potential_status, remaining_token_list = self.consume_token(remaining_token_list)
            if potential_status != FSMEnum.NOT_ACCEPTED:
                return potential_status, remaining_token_list
        return FSMEnum.NOT_ACCEPTED, None

    def is_binary_clause(self):
        return self.bin_op is not None


class FieldClause:

    def __init__(self):
        self.operator = None
        self.field_value = None
        self.field_name = None

    def consume_token(self, token_list):
        if len(token_list) < 4:
            return FSMEnum.NOT_ACCEPTED, None
        self.field_name = token_list[0]
        self.operator = token_list[1]
        self.field_value = token_list[2]
        return FSMEnum.FIELD_CLAUSE_COMPLETE, token_list[3:]


class TableName:

    def __init__(self):
        self._table_name = None

    def consume_token(self, token_list):
        if len(token_list) == 0:
            return FSMEnum.NOT_ACCEPTED, None
        self._table_name = token_list[0]
        return FSMEnum.SELECT_OR_TABLE, token_list[1:]

    def name(self):
        return self._table_name


class TablePath:

    def consume_token(self, token_list):
        # rare case - empty token list signifies a statement end too
        if len(token_list) == 0 or token_list[0] != ".":
            return FSMEnum.NOT_ACCEPTED, None
        return FSMEnum.TABLE_NAME, token_list[1:]


class StatementSeparator:

    def consume_token(self, token_list):
        # rare case - empty token list signifies a statement end too
        if len(token_list) == 0 or token_list[0] == "&&":
            return FSMEnum.STATEMENT_COMPLETED, token_list[1:]
        return FSMEnum.NOT_ACCEPTED, None


class FieldName:

    def __init__(self, field_name):
        self.field_name = field_name


class PathKeyword:
    def consume_token(self, token_list):
        if len(token_list) and token_list[0] == "path":
            return FSMEnum.PATH_EQUALS, token_list[1:]
        return FSMEnum.NOT_ACCEPTED, None


class PathEqualsKeyword:
    def consume_token(self, token_list):
        if len(token_list) and token_list[0] == "=":
            return FSMEnum.TABLE_NAME, token_list[1:]
        return FSMEnum.NOT_ACCEPTED, None


class TableNameSeparator:

    def consume_token(self, token_list):
        if len(token_list) == 0 or token_list[0] != ".":
            return FSMEnum.NOT_ACCEPTED, None
        return FSMEnum.TABLE_NAME, token_list[1:]


class PathSeparator:

    def consume_token(self, token_list):
        if len(token_list) == 0 or token_list[0] != ";":
            return FSMEnum.NOT_ACCEPTED, None
        return FSMEnum.TABLE_NAME, token_list[1:]


class PathCompletion:

    def consume_token(self, token_list):
        if len(token_list) == 0 or token_list[0] != "&&":
            return FSMEnum.NOT_ACCEPTED, None
        return FSMEnum.FIELDS_OR_TIMESTAMP_OR_ASOF_OR_OFFSET_OR_LIMIT, token_list[1:]


class FieldList:

    def __init__(self):
        self.field_names = None

    def consume_token(self, token_list):
        if len(token_list) == 0:
            return FSMEnum.NOT_ACCEPTED, None
        cursor = 0
        self.field_names = []
        while cursor < len(token_list):
            self.field_names.append(token_list[cursor])
            if cursor == len(token_list) - 1:
                return FSMEnum.STATEMENT_COMPLETED, []
            if token_list[cursor + 1] == "&&":
                return FSMEnum.FIELDS_OR_TIMESTAMP_OR_ASOF_OR_OFFSET_OR_LIMIT, token_list[cursor + 2:]
            if token_list[cursor + 1] != ",":
                return FSMEnum.NOT_ACCEPTED, None
            cursor += 2
        return token_list[cursor:]


class FieldGroup:

    def __init__(self):
        self.table_name = None

    def consume_token(self, token_list):
        if len(token_list) < 5 or token_list[0] != "fields" or token_list[1] != "=":
            return FSMEnum.NOT_ACCEPTED, None
        self.table_name = token_list[2]
        if token_list[3] != ":":
            return FSMEnum.NOT_ACCEPTED, None
        return FSMEnum.FIELDS, token_list[4:]


class Timestamp:

    def __init__(self):
        self.timestamp = None

    def consume_token(self, token_list):
        if len(token_list) < 3 or token_list[0] != "timestamp" or token_list[1] != "=":
            return FSMEnum.NOT_ACCEPTED, None
        self.timestamp = token_list[2] + " 00:00:00"
        if len(token_list) == 3:
            return FSMEnum.STATEMENT_COMPLETED, []
        return FSMEnum.FIELDS_OR_TIMESTAMP_OR_ASOF_OR_OFFSET_OR_LIMIT, token_list[4:]


class AsOf:

    def __init__(self):
        self.as_of_timestamp = None

    def consume_token(self, token_list):
        if len(token_list) < 3 or token_list[0] != "as_of" or token_list[1] != "=":
            return FSMEnum.NOT_ACCEPTED, None
        self.as_of_timestamp = token_list[2]
        if len(token_list) == 3:
            return FSMEnum.STATEMENT_COMPLETED, []
        return FSMEnum.FIELDS_OR_TIMESTAMP_OR_ASOF_OR_OFFSET_OR_LIMIT, token_list[4:]


class Offset:

    def __init__(self):
        self.offset = 0

    def consume_token(self, token_list):
        if len(token_list) < 3 or token_list[0] != "offset" or token_list[1] != "=":
            return FSMEnum.NOT_ACCEPTED, None
        self.offset = int(token_list[2])
        if len(token_list) == 3:
            return FSMEnum.STATEMENT_COMPLETED, []
        return FSMEnum.FIELDS_OR_TIMESTAMP_OR_ASOF_OR_OFFSET_OR_LIMIT, token_list[4:]


class Limit:

    def __init__(self):
        self.limit = 0

    def consume_token(self, token_list):
        if len(token_list) < 3 or token_list[0] != "limit" or token_list[1] != "=":
            return FSMEnum.NOT_ACCEPTED, None
        self.limit = int(token_list[2])
        if len(token_list) == 3:
            return FSMEnum.STATEMENT_COMPLETED, []
        return FSMEnum.FIELDS_OR_TIMESTAMP_OR_ASOF_OR_OFFSET_OR_LIMIT, token_list[4:]


# call the state what it is expecting to receive
class FSMEnum(Enum):
    START = 0,
    PATH_EQUALS = 2,
    TABLE_OR_PATH_SEPARATOR_OR_FIELDS = 3,
    TABLE_NAME = 4,
    SELECT_OR_TABLE = 5,
    SELECT_OR_FIELDS_END = 6,
    FIELD_NAME = 7,
    FIELD_CLAUSE_COMPLETE = 8,
    BINARY_OPERATOR = 9,
    UNARY_OR_VALUE = 10,
    VALUE = 11,
    FIELDS = 12,
    FIELD_NAME_OR_END = 13,
    FIELDS_OR_TIMESTAMP_OR_ASOF_OR_OFFSET_OR_LIMIT = 14
    NOT_ACCEPTED = 15,
    FAIL = 16,
    STATEMENT_IN_COMPLETION = 17,
    STATEMENT_COMPLETED = 18,
