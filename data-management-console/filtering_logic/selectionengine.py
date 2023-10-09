# The SelectionEngine receives a DSL query, tokenizes it, executes a Finite State Machine to
# (1) check the DSL corresponds to the grammar (2) build up an execution stack of tokens
# (3) turn those tokens into an executionchain (4) invoke the execution chain
# (5) return the answers as a hierarchical dictionary of dictionaries.
# By checking the grammar first, we can protect against many SQL injection attacks (as we do not support
# many of those syntaxes as part of the grammar)
import time
from collections import deque
from typing import Union

import psycopg2

from filtering_logic.blockregistry import BlockRegistry
from filtering_logic.datablockfactory import DataBlockFactory
from filtering_logic.selectionengineexceptions import UnterminatedStringException
from filtering_logic.datablock import DataBlock
from filtering_logic.queryexceptions import InvalidTermException
from filtering_logic.executionchain import ExecutionChain
from filtering_logic.selectioncriteria import *
from metadata_mgmt.metadatareader import MetadataReader
from postgres.postgresexecutor import PostgresExecutor
from schema_management.extractor import Extractor
from filtering_logic.newdsl import process_new_dsl

class LineState:

    def __init__(self, line_to_process):
        self.line_to_process: str = line_to_process
        # replace all double quotes with single quotes as this will be passed to the database as a literal
        self.line_to_process.replace('"', "'")
        self.cursor = 0

    def get_token(self) -> Union[str, None]:
        token_start = self.cursor
        line_end = len(self.line_to_process)
        while token_start < line_end and self.line_to_process[token_start:token_start + 1].isspace():
            token_start += 1
        if token_start == line_end:
            return None
        token_end = token_start
        if self.line_to_process[token_end:token_end + 1] in "[]:;,.":
            token_end += 1
        elif self.line_to_process[token_end:token_end + 1] in "'":
            token_end += 1
            while token_end < line_end and self.line_to_process[token_end:token_end + 1] not in "'":
                token_end += 1
            if token_end < line_end and self.line_to_process[token_end] == "'":
                token_end += 1
            else:
                err_msg = f"Unterminated string >> {self.line_to_process[token_start:token_end]}"
                raise UnterminatedStringException(err_msg)
        elif self.line_to_process[token_end:token_end + 1] in "<=>&":
            while token_end < line_end and self.line_to_process[token_end:token_end + 1] in "<=>&":
                token_end += 1
        else:
            while token_end < line_end and self.line_to_process[token_end:token_end + 1] not in "<=>& []:;,.":
                token_end += 1
        tok = self.line_to_process[token_start:token_end]
        self.cursor = token_end
        return tok


class SelectionEngine:

    def __init__(self):
        self.statements = []
        self._current_state = FSMEnum.START
        self._current_stack = deque()
        self.cursor = 0
        self.page_size = 0
        self.permitted_transitions = {
            FSMEnum.START: [PathKeyword],
            FSMEnum.PATH_EQUALS: [PathEqualsKeyword],
            FSMEnum.SELECT_OR_TABLE: [TableNameSeparator, PathSeparator, SelectionClause, PathCompletion],
            FSMEnum.TABLE_NAME: [TableName],
            FSMEnum.FIELDS: [FieldList],
            FSMEnum.STATEMENT_IN_COMPLETION: [StatementSeparator],
            FSMEnum.TABLE_OR_PATH_SEPARATOR_OR_FIELDS: [TableNameSeparator, PathSeparator, PathCompletion],
            FSMEnum.FIELDS_OR_TIMESTAMP_OR_ASOF_OR_OFFSET_OR_LIMIT: [FieldGroup, Timestamp, AsOf, Offset, Limit]
        }
        self.reset()

    def reset(self):
        self._current_state = FSMEnum.START
        self._current_stack = deque()

    def get_transitions(self, potential_state) -> list:
        permitted_transitions = self.permitted_transitions.get(potential_state)
        return permitted_transitions

    def process_lines(self, lines_to_process: list[str]):
        for i in range(0, len(lines_to_process)):
            print(f"processing {lines_to_process[i]}")
            self.process_line(lines_to_process[i])
            self.reset()

    def process_line(self, line_to_process):
        line_state = LineState(line_to_process)
        token_list = []
        while True:
            token = line_state.get_token()
            if token is None:
                break
            token_list.append(token)
        start_transitions = self.get_transitions(FSMEnum.START)  # our start state
        was_processed, remaining_token_list = self.process_line_internal(token_list, start_transitions)
        if not was_processed:
            print("Failed")
        else:
            print(f"We have {len(self.statements)} statements")

    def process_line_internal(self, token_list, permitted_transitions) -> (bool, list):
        for class_type in permitted_transitions:
            # need to create an instance of the type
            node = class_type()
            # allow us to consume multiple tokens
            potential_state, remaining_token_list = node.consume_token(token_list)
            # token is accepted
            if potential_state == FSMEnum.STATEMENT_COMPLETED:
                # capture the statement
                self._current_stack.append(node)
                self.statements.append(self._current_stack.copy())
                self._current_stack.clear()
                return True, remaining_token_list
            if potential_state is not FSMEnum.NOT_ACCEPTED:
                next_stage_permitted_transitions = self.get_transitions(potential_state)
                if not next_stage_permitted_transitions:
                    self._current_stack.appendleft(remaining_token_list)
                    return True, remaining_token_list

                # this node could accept its piece - push it onto the stack
                self._current_stack.append(node)
                was_processed, remaining_token_list = self.process_line_internal(remaining_token_list,
                                                                                 next_stage_permitted_transitions)
                # if successful, this should return all the way up, leaving the stack in place
                if was_processed:
                    return True, remaining_token_list
                # somewhere downstream failed - backtrack
                self._current_stack.pop()
            # keep going around until all options exhausted
        #        return False, remaining_token_list
        err_msg = f'Invalid Term detected: >>> {" ".join(token_list)}'
        raise InvalidTermException(err_msg)

    def process_query(self, query: str) -> dict:
        start_time = time.time()
        self.process_lines([query])
        #        self.process_lines(
        #            [
        #                "path=iso3[code='ESP'].wdpa[site_id < 100000]&&fields=wdpa:name&&fields=iso3:description&&timestamp=2023-06-28",
        #                "path=iso3[code='ESP'].wdpa.pame;iso3.wdpa.green_list&&fields=iso3:code,description&&fields=wdpa:site_id,parcel_id,name&&fields=pame:source_data_title&&fields=green_list:url&&timestamp=2026-06-28",
        #                "path=wdpa[pa_def='0']&&fields=wdpa:site_id,parcel_id,name, pa_def",
        #                "path=wdpa&&fields=wdpa:site_id,parcel_id,name, pa_def&&fields=spatial_data:shape_area",
        #                "path=wdpa&&fields=wdpa:site_id,parcel_id,name, pa_def&&fields=spatial_data:shape_area&&timestamp=2021-01-01&&as_of=2018-01-01",
        #                "path=wdpa&&fields=wdpa:site_id,parcel_id,name, pa_def&&fields=spatial_data:shape_area&&&&timestamp=2023-07-01&&as_of=2023-07-01",
        #            ])

        duration = time.time() - start_time
        print(f"Took {duration} seconds to parse the statements")
        for statement in self.statements:
            start_time = time.time()
            BlockRegistry.clear_where_conditions()
            ch = ExecutionChain()
            # each statement is a deque that must follow a specific pattern
            # PathKeyword
            # PathEquals
            # { TableName [SelectionClause] }* PathSeparator }*
            # { TableName [SelectionClause] PathCompletion }
            # { { FieldGroup FieldList } | { Flag FlagList } }*

            element = statement.popleft()
            if not isinstance(element, PathKeyword):
                raise RuntimeError("Missing Path Keyword")
            element = statement.popleft()
            if not isinstance(element, PathEqualsKeyword):
                raise RuntimeError("Missing Path Equals Kwyword")
            element = statement.popleft()
            table_names = []
            master_timestamp = None
            master_as_of = None
            master_offset = 0
            master_limit = 10000
            fully_qualified_table_name = []
            next_el = None
            while True:
                if isinstance(element, TableName):
                    table_name = element.name()
                    table_names.append(table_name)
                    fully_qualified_table_name.append(table_name)
                    data_block: DataBlock = ch.get_block_for_name(table_name, fully_qualified_table_name)
                    next_el = statement.popleft()
                    if isinstance(next_el, SelectionClause):
                        if next_el.is_binary_clause():
                            left_field_name = next_el.bin_op.left_clause.field_name
                            left_operator = next_el.bin_op.left_clause.operator
                            left_field_value = next_el.bin_op.left_clause.field_value
                            binary_operator = next_el.bin_op.binary_operator
                            right_field_name = next_el.bin_op.right_clause.field_name
                            right_operator = next_el.bin_op.right_clause.operator
                            right_field_value = next_el.bin_op.right_clause.field_value
                            where_clause = f"{table_name}.{left_field_name} {left_operator} {left_field_value} {binary_operator} {table_name}.{right_field_name} {right_operator} {right_field_value}"
                        else:
                            field_name = next_el.field_clause.field_name
                            operator = next_el.field_clause.operator
                            field_value = next_el.field_clause.field_value
                            where_clause = f"{table_name}.{field_name} {operator} {field_value}"
                        next_el = statement.popleft()
                        data_block.add_where_clause(where_clause)
                    ch.add_block(table_names, data_block)
                if isinstance(next_el, TableNameSeparator):
                    element = statement.popleft()
                    continue
                fully_qualified_table_name = []  # reset the path if we've finished collecting the fully qualified table name
                if isinstance(next_el, PathCompletion):
                    element = statement.popleft()
                    break
                if isinstance(next_el, PathSeparator):
                    table_names = []
                    element = statement.popleft()
                    continue
                raise RuntimeError("Unexpected sequence in statement")
            while element:
                if isinstance(element, FieldGroup):
                    table_name = element.table_name
                    block_for_fields = ch.get_block_for_name(table_name, [])
                    element = statement.popleft() if len(statement) else None
                    if not isinstance(element, FieldList):
                        raise RuntimeError("Fieldlist must follow a FieldGroup")
                    fields = [table_name + "." + field_name for field_name in element.field_names]
                    block_for_fields.add_fields_and_table(fields)
                    element = statement.popleft() if len(statement) else None
                elif isinstance(element, Timestamp):
                    master_timestamp = element.timestamp
                    element = statement.popleft() if len(statement) else None
                elif isinstance(element, AsOf):
                    master_as_of = element.as_of_timestamp
                    element = statement.popleft() if len(statement) else None
                elif isinstance(element, Offset):
                    master_offset = element.offset
                    element = statement.popleft() if len(statement) else None
                elif isinstance(element, Limit):
                    master_limit = element.limit
                    element = statement.popleft() if len(statement) else None
                else:
                    err_msg = f"Unexpected token {type(element)} found"
                    raise RuntimeError(err_msg)

            if master_timestamp is None:
                master_timestamp = '9998-01-01 00:00:00'
            if master_as_of is None:
                master_as_of = '9998-01-01 00:00:00'
            chain_of_objects = process_new_dsl(ch.get_chain(), master_timestamp, master_as_of, master_offset, master_limit)
#            chain_of_objects = ch.construct_chain(master_timestamp, master_as_of, master_offset, master_limit)
            duration = time.time() - start_time
            print(f"Took {duration} seconds to construct the chain")
            # add in some key metadata
            chain_of_objects["start_position"] = master_offset
            chain_of_objects["end_position"] = master_offset + master_limit - 1
            chain_of_objects["duration"] = duration
            duration = time.time() - start_time
            print(f"Took {duration} seconds for execution chain")
            self.set_cursor(master_limit + master_offset)
            self.set_page_size(master_limit)
            return chain_of_objects

    def set_cursor(self, next_page_start):
        self.cursor = next_page_start

    def cursor_position(self):
        return self.cursor

    def set_page_size(self, page_size):
        self.page_size = page_size

    def get_page_size(self):
        return self.page_size


if __name__ == "__main__":
    connection_str = f"dbname=WDPA user=postgres password=WCMC%1"
    with psycopg2.connect(connection_str) as conn:
        PostgresExecutor.set_connection(conn)
        tables = MetadataReader.tables()
        BlockRegistry.reset()
        # register each table name as a simple datablock
        # also register any association tables as associationdatablock
        for table in tables.keys():
            DataBlockFactory.create_simple_block(table)
            association_table_names, target_table_names = Extractor.extract_association_and_target_table_names(
                table, tables)
            for association_table_name, target_table_name in zip(association_table_names, target_table_names):
                # usually, for the forward order e.g. wdpa.iso3, we have the virtual columns
                # most queries are of the backward form iso3[code='BEL'].wdpa.  This may not
                DataBlockFactory.create_compound_block([table, target_table_name],
                                                       [association_table_name, target_table_name])
                DataBlockFactory.create_compound_block([target_table_name, table], [association_table_name, table])

        SelectionEngine().process_query("path=wdpa[site_id = 903141 or parcel_id='A']&&fields=wdpa:site_id, parcel_id")
