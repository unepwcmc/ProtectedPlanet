# The postgresstreamer is returned by the streamer() method of the datablocks (where appropriate)
# and knows how to turn a datablock into a series of SQL calls.
# Currently, it operates one table at a time, joining that table to its predecessor.  To achieve this,
# it creates a temporary table corresponding to the table in which it is interested (using column aliases
# instead of the actual column names, in order to avoid potential name clashes) and selects the subset of
# rows corresponding to the query into that temporary table.  Row limits may also be applied to top-level tables.
# The results are then read back from the temporary tables and turned into a ChainTable

import string
from collections import defaultdict

from filtering_logic.chaintable import ChainTable
from metadata_mgmt.metadatareader import MetadataReader
from postgres.postgresexecutor import PostgresExecutor
from schema_management.tables import TableDefinition, VirtualColumn


class PostgresStreamer:

    def __init__(self):
        self.all_tables = None
        self.where_conditions = []
        self.tables = None
        self.fields = None
        self.all_tables = MetadataReader.tables()

    def translate_virtual_fields(self, all_fields, master_timestamp, master_as_of):
        # if it's a calculated or a foreign key field, handle it here
        translated_fields = []
        for field in all_fields:
            parts = field.split(".")
            table_data: TableDefinition = self.all_tables[parts[0]]
            column_info = table_data.column_by_name(parts[1])
            if isinstance(column_info, VirtualColumn):
                print(f'Field is {field}')
                print(column_info.function_to_call)
                function_prototype = column_info.function_to_call
                function_prototype = function_prototype.replace('update_time', f"TIMESTAMP '{master_timestamp}'")
                function_prototype = function_prototype.replace('as_of', f"TIMESTAMP '{master_as_of}'")
                print(function_prototype)
                translated_fields.append(function_prototype)
            else:
                translated_fields.append(field)
        return translated_fields

    def chain(self, incoming: ChainTable, forward_keys: list, backward_keys_dict: dict, backward_keys_for_mapping: dict,
              fields_requested: list,
              table_name: str, conditions_requested: str, master_timestamp: str, master_as_of: str,
              master_offset, master_limit) -> ChainTable:
        temp_table_name = self.temporary_table_name(table_name)
        where_conditions = self.where_conditions
        # flatten the list of keys and remove duplicates
        backward_keys = []
        for k, v in backward_keys_dict.items():
            backward_keys += v
        # we may have duplicates in the backward keys, but it's easier later on
        # to grab contiguous fields in the row as we process the backward keys
        all_fields = forward_keys + backward_keys + fields_requested
        all_fields_for_create = [f"col{n} {self.qualified_column_type(all_fields[n])}" for n in
                                 range(0, len(all_fields))]
        all_fields_for_create.append("objectid int")
        all_fields_for_create.append("upper_objectid int")
        translated_fields = dict(
            zip([n + len(forward_keys + backward_keys) for n in range(0, len(fields_requested))],
                fields_requested))
        all_fields_translated = [f"{temp_table_name}.col{n}" for n in range(0, len(all_fields))]
        all_fields_translated.append(f"{temp_table_name}.objectid")
        all_fields_translated.append(f"{temp_table_name}.upper_objectid")
        all_fields_translated = dict(zip(all_fields, all_fields_translated))
        backward_keys_translated = {key: all_fields_translated[key] for key in backward_keys}
        tables = [table_name]
        if incoming is not None:
            tables = [incoming.name()] + tables
        if incoming is not None:
            abbreviated_backward = {self.unqualified_column_name(key): value for key, value in
                                    incoming.backward_keys().items()}
            for index in range(0, len(forward_keys)):
                translated_incoming_col = abbreviated_backward[
                    self.unqualified_column_name(backward_keys_for_mapping[index])]
                where_conditions.append(f'{translated_incoming_col} = {forward_keys[index]}')
        if conditions_requested:
            where_conditions.append(conditions_requested)
        create_sql = "CREATE TEMPORARY TABLE " + temp_table_name + " ("
        create_sql += ",".join(all_fields_for_create)
        create_sql += " )"
        all_fields_including_virtual = self.translate_virtual_fields(all_fields, master_timestamp, master_as_of)

        insert_sql = f"INSERT INTO {temp_table_name} SELECT * FROM ( SELECT " + ",".join(all_fields_including_virtual)
        tables = list(zip(tables, string.ascii_lowercase))
        # replace table names with aliases
        from_phrase = f", ROW_NUMBER() OVER (ORDER BY a.OBJECTID), {tables[0][0]}.objectid "
        row_number_sql = ""
        if master_limit is not None:
            max_rn = master_offset + master_limit - 1
            row_number_sql = f" WHERE ROW_NUMBER BETWEEN {master_offset} and {max_rn} "
        from_phrase += " FROM " + ",".join([t[0] + " " + t[1] for t in tables])
        insert_sql += from_phrase
        if where_conditions:
            # bracket these otherwise a user-defined clause containing OR will cause havoc with the logic
            bracketed_where_conditions = ['(' + where_cond + ')' for where_cond in where_conditions]
            where_clause = " WHERE " + " AND ".join(bracketed_where_conditions)
            insert_sql += where_clause
        else:
            insert_sql += " WHERE 1=1 "
        for (table, letter) in tables:
            insert_sql = insert_sql.replace(table + ".", letter + ".")
        if len(tables) == 1:
            insert_sql += f" AND a.FromZ <= TIMESTAMP '{master_timestamp}' AND a.ToZ > TIMESTAMP '{master_timestamp}' AND a.EffectiveFromZ <= TIMESTAMP '{master_as_of}' AND a.EffectiveToZ > TIMESTAMP '{master_as_of}'"
        if len(tables) == 2:
            insert_sql += f" AND b.FromZ <= TIMESTAMP '{master_timestamp}' AND b.ToZ > TIMESTAMP '{master_timestamp}' AND b.EffectiveFromZ <= TIMESTAMP '{master_as_of}' AND b.EffectiveToZ > TIMESTAMP '{master_as_of}'"
        insert_sql += ") x "
        if master_limit is not None:
            insert_sql += row_number_sql

        max_row_sql = f"SELECT COUNT(1) "
        max_row_sql += " FROM " + ",".join([t[0] + " " + t[1] for t in tables])
        if where_conditions:
            where_clause = " WHERE " + " AND ".join(where_conditions)
            max_row_sql += where_clause
        else:
            max_row_sql += " WHERE 1=1 "
        for (table, letter) in tables:
            max_row_sql = max_row_sql.replace(table + ".", letter + ".")
        if len(tables) == 1:
            max_row_sql += f" AND a.FromZ <= TIMESTAMP '{master_timestamp}' AND a.ToZ > TIMESTAMP '{master_timestamp}' AND a.EffectiveFromZ <= TIMESTAMP '{master_as_of}' AND a.EffectiveToZ > TIMESTAMP '{master_as_of}'"
        if len(tables) == 2:
            max_row_sql += f" AND b.FromZ <= TIMESTAMP '{master_timestamp}' AND b.ToZ > TIMESTAMP '{master_timestamp}'  AND b.EffectiveFromZ <= TIMESTAMP '{master_as_of}' AND b.EffectiveToZ > TIMESTAMP '{master_as_of}'"

        retrieval_cols = [f"col{n}" for n in range(0, len(all_fields))]
        retrieval_cols.append("objectid")
        retrieval_cols.append("upper_objectid")
        retrieval_sql = "SELECT " + ",".join(retrieval_cols) + f" FROM {temp_table_name}"
        # execute this lause and remember that this is where we have stored it
        cursor = PostgresExecutor.begin_transaction()
        print(create_sql)
        cursor.execute(create_sql)
        print(insert_sql)
        cursor.execute(insert_sql)
        actual_row_count = cursor.rowcount
        print(f"{temp_table_name} received {actual_row_count} rows on INSERT")
        print(max_row_sql)
        cursor.execute(max_row_sql)
        rows = cursor.fetchall()
        rows_available = rows[0][0]
        print(f"{temp_table_name} has max rows: {rows_available}")
        print(retrieval_sql)
        cursor.execute(retrieval_sql)
        rows = cursor.fetchall()
        print(f"Retrieved {len(rows)} after INSERT")
        forward_results = {}
        backward_results = {table_name: defaultdict(list) for table_name in backward_keys_dict.keys()}
        row_number_to_upper_level = {}
        for row in rows:
            forward_key = row[len(row) - 1]
            backward_key = row[len(row) - 2]
            row_result = {}
            for field_position, field_name in translated_fields.items():
                short_field_name = self.unqualified_column_name(field_name)
                row_result[short_field_name] = row[field_position]
            if forward_results.get(forward_key) is None:
                forward_results[forward_key] = {}
            forward_results[forward_key][backward_key] = row_result
            for table_name in backward_keys_dict.keys():
                backward_results[table_name][backward_key].append(forward_key)
            row_number_to_upper_level[backward_key] = forward_key
        #            backward_key_index = 0
        #            for table_name, backward_fields in backward_keys_dict.items():
        #                backward_key = row[len(forward_keys) + backward_key_index:len(forward_keys) + len(
        #                    backward_fields) + backward_key_index]
        #                backward_results[table_name][backward_key].append(forward_key)
        #                backward_key_index += len(backward_fields)
        PostgresExecutor.end_transaction()
        result = ChainTable(temp_table_name, backward_keys_translated, translated_fields, forward_results,
                            backward_results, row_number_to_upper_level, rows_available)
        return result

    def qualified_column_type(self, column_table_str):
        table_and_column_name = column_table_str.split(".")
        table_data: TableDefinition = self.all_tables[table_and_column_name[0]]
        column_info = table_data.column_by_name(table_and_column_name[1])
        if isinstance(column_info, VirtualColumn):
            return column_info.representation
        return column_info.data_type

    def unqualified_column_name(self, column_table_str):
        table_and_column_name = column_table_str.split(".")
        return table_and_column_name[1]

    def temporary_table_name(self, table_name):
        return f"{table_name}_t"

    def qualify_name(self, target_table, column_name):
        return target_table + "." + column_name
