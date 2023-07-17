import string
import string
from collections import defaultdict

from filtering_logic.chaintable import ChainTable
from metadata_mgmt.metadatareader import MetadataReader
from postgres.postgresexecutor import PostgresExecutor
from schema_mgmt.tables import TableDefinition, VirtualColumn


class PostgresStreamer:

    def __init__(self):
        self.all_tables = None
        self.forward_keys = None
        self.backward_keys = None
        self.where_conditions = None
        self.tables = None
        self.fields = None

    def configure_base_sql(self, forward_keys: list, backward_keys: list, tables: list, where_conditions: list):
        self.forward_keys = forward_keys
        self.backward_keys = backward_keys
        self.tables = tables
        self.where_conditions = where_conditions
        self.tables = tables
        self.all_tables = MetadataReader.tables()

    def translate_virtual_fields(self, all_fields):
        # if it's a calculated or a foreign key field, handle it here
        translated_fields = []
        for field in all_fields:
            parts = field.split(".")
            table_data: TableDefinition = self.all_tables[parts[0]]
            column_info = table_data.column_by_name(parts[1])
            if isinstance(column_info, VirtualColumn):
                translated_fields.append(column_info.function_to_call)
            else:
                translated_fields.append(field)
        return translated_fields

    def chain(self, incoming: ChainTable, forward_keys: list, backward_keys: list, fields_requested: list,
              table_name: str, conditions_requested: str, master_timestamp: str, master_as_of: str,
              master_offset, master_limit) -> ChainTable:
        temp_table_name = self.temporary_table_name(table_name)
        where_conditions = self.where_conditions
        all_fields = self.forward_keys + self.backward_keys + fields_requested
        all_fields_for_create = [f"col{n} {self.qualified_column_type(all_fields[n])}" for n in
                                 range(0, len(all_fields))]
        all_fields_for_create.append("objectid int")
        translated_fields = dict(
            zip([n + len(self.forward_keys + self.backward_keys) for n in range(0, len(fields_requested))],
                fields_requested))
        all_fields_translated = [f"{temp_table_name}.col{n}" for n in range(0, len(all_fields))]
        all_fields_translated.append(f"{temp_table_name}.objectid")
        all_fields_translated = dict(zip(all_fields, all_fields_translated))
        backward_keys_translated = {key: all_fields_translated[key] for key in backward_keys}
        tables = self.tables
        if incoming is not None:
            tables = [incoming.name()] + self.tables
        if incoming is not None:
            # just get the suffixes
            abbreviated_backward = {self.unqualified_column_name(key): value for key, value in
                                    incoming.backward_keys().items()}
            for forward_key in forward_keys:
                translated_incoming_col = abbreviated_backward[self.unqualified_column_name(forward_key)]
                where_conditions.append(f'{translated_incoming_col} = {forward_key}')
        if conditions_requested:
            where_conditions.append(conditions_requested)
        drop_sql = "DROP TABLE IF EXISTS " + temp_table_name
        create_sql = "CREATE TABLE " + temp_table_name + " ("
        create_sql += ",".join(all_fields_for_create)
        create_sql += " )"
        all_fields_including_virtual = self.translate_virtual_fields(all_fields)
        insert_sql = f"INSERT INTO {temp_table_name} SELECT * FROM ( SELECT " + ",".join(all_fields_including_virtual)
        table_dict = dict(zip(tables, string.ascii_lowercase))
        tables = list(zip(tables, string.ascii_lowercase))
        # replace table names with aliases
        max_rn = master_offset + master_limit - 1   # as the between is inclusive
        from_phrase = f", ROW_NUMBER() OVER (ORDER BY a.OBJECTID) "
        from_phrase += " FROM " + ",".join([t[0] + " " + t[1] for t in tables])
        insert_sql += from_phrase
        if where_conditions:
            where_clause = " WHERE " + " AND ".join(where_conditions)
            insert_sql += where_clause
        for (table, letter) in tables:
            insert_sql = insert_sql.replace(table + ".", letter + ".")
        if master_timestamp is not None:
            insert_sql += "".join(
                [
                    f" AND {table_dict[orig_table_name]}.FromZ <= TIMESTAMP '{master_timestamp}' AND {table_dict[orig_table_name]}.ToZ > TIMESTAMP '{master_timestamp}'"
                    for orig_table_name in self.tables])
        if master_as_of is not None:
            insert_sql += "".join(
                [
                    f" AND {table_dict[orig_table_name]}.EffectiveFromZ <= TIMESTAMP '{master_as_of}' AND {table_dict[orig_table_name]}.EffectiveToZ > TIMESTAMP '{master_as_of}'"
                    for orig_table_name in self.tables])
        insert_sql += f") x WHERE ROW_NUMBER BETWEEN {master_offset} and {max_rn} "
        count_sql_start_index = insert_sql.find(" a.OBJECTID")+11
        count_sql_end_index = insert_sql.find(") x")
        count_sql = "SELECT COUNT(1) " + insert_sql[count_sql_start_index+2:count_sql_end_index]
        retrieval_cols = [f"col{n}" for n in range(0, len(all_fields))]
        retrieval_sql = "SELECT " + ",".join(retrieval_cols) + f" FROM {temp_table_name}"
        # execute this lause and remember that this is where we have stored it
        cursor = PostgresExecutor.begin_transaction()
        cursor.execute(drop_sql)
        cursor.execute(create_sql)
        print(insert_sql)
        cursor.execute(count_sql)
        rows_available = cursor.fetchone()
        max_rows_retrievable = rows_available[0]
        cursor.execute(insert_sql)
        rows_affected = cursor.rowcount
        print(f"{temp_table_name} received {rows_affected} rows on INSERT")
        cursor.execute(retrieval_sql)
        rows = cursor.fetchall()
        print(f"Retrieved {len(rows)} after INSERT")
        forward_results = defaultdict(list)
        backward_results = defaultdict(list)
        for row in rows:
            forward_key: list = row[0:len(self.forward_keys)]
            backward_key = row[len(self.forward_keys):len(forward_keys) + len(backward_keys)]
            row_result = {}
            for field_position, field_name in translated_fields.items():
                short_field_name = self.unqualified_column_name(field_name)
                row_result[short_field_name] = row[field_position]
            forward_results[forward_key] = row_result
            backward_results[backward_key].append(forward_key)
        PostgresExecutor.end_transaction()
        result = ChainTable(temp_table_name, backward_keys_translated, translated_fields, forward_results,
                            backward_results, max_rows_retrievable)
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
        return f"{table_name}_temp"

    def qualify_name(self, target_table, column_name):
        return target_table + "." + column_name
