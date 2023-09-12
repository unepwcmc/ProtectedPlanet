import time
import traceback

from postgres.postgresconverter import PostgresConverter
from mgmt_logging.logger import Logger
from schema_management.ingestionstats import IngestionStats


class PostgresExecutor:
    _read_cursor = None
    _read_cursor_open_count = 0
    _read_cursor_close_count = 0
    _write_cursor = None
    _write_cursor_open_count = 0
    _write_cursor_close_count = 0
    _foreign_key_cursor = None
    _foreign_key_cursor_open_count = 0
    _conn = None

    @classmethod
    def get_next_ingestion_id(cls):
        sql = 'SELECT MAX(ingestion_id) FROM INGESTION_HISTORY'
        cls._read_cursor.execute(sql)
        rows = cls._read_cursor.fetchall()
        max_used = rows[0][0] or 0
        Logger.get_logger().info(f"Next ingestion id is {max_used + 1}")
        return max_used + 1

    @classmethod
    def get_staging_data_originators(cls, driving_table):
        sql = PostgresConverter.get_staging_data_originators(driving_table)
        cls._read_cursor.execute(sql)
        originator_ids = [row[0] for row in cls._read_cursor.fetchall()]
        return originator_ids

    @classmethod
    def construct_query_clause(cls, quarantine_table, target_table, originator_id, closed_universe):
        [main_clause, quarantine_positions, target_positions] = PostgresConverter.construct_query_clause(
            quarantine_table, target_table, originator_id, closed_universe)
        try:
            cls._read_cursor.execute(main_clause)
            return [quarantine_positions, target_positions]
        except Exception as ex:
            print(str(ex))
            [main_clause, quarantine_positions, target_positions] = PostgresConverter.construct_query_clause(
                quarantine_table, target_table, originator_id, closed_universe)
            print(f"Construct query clause had a problem: {main_clause}")
            raise ex

    @classmethod
    def set_connection(cls, conn):
        cls._conn = conn

    @classmethod
    def open_read_cursor(cls):
        if cls._read_cursor is None or cls._read_cursor.closed:
            cls._read_cursor = cls._conn.cursor()
            cls._read_cursor_open_count += 1
        return cls._read_cursor

    @classmethod
    def close_read_cursor(cls):
        if cls._read_cursor is not None:
            cls._read_cursor.close()
            cls._read_cursor_close_count += 1
            cls._read_cursor = None


    @classmethod
    def foreign_key_cursor(cls):
        if cls._foreign_key_cursor is None or cls._foreign_key_cursor.closed:
            cls._foreign_key_cursor = cls._conn.cursor()
            cls._foreign_key_cursor_open_count += 1
        return cls._foreign_key_cursor

    @classmethod
    def begin_transaction(cls):
        Logger.get_logger().info("Beginning transaction")
        if cls._write_cursor is None or cls._write_cursor.closed:
            cls._write_cursor = cls._conn.cursor()
            cls._write_cursor_open_count += 1
        cls._write_cursor.execute("BEGIN TRANSACTION")
        return cls._write_cursor

    @classmethod
    def end_transaction(cls):
        Logger.get_logger().info("Ending transaction")
        if cls._write_cursor is not None:
            cls._write_cursor.execute("COMMIT")
            cls._write_cursor.close()
            cls._write_cursor_close_count += 1
            cls._write_cursor = None

    @classmethod
    def rollback(cls):
        if cls._write_cursor is not None:
            cls._write_cursor.execute("ROLLBACK")
            cls._write_cursor.close()
            cls._write_cursor_close_count += 1
            cls._write_cursor = None
        if cls._read_cursor is not None:
            cls._read_cursor.close()
            cls._read_cursor = None
            cls._read_cursor_close_count += 1

    @classmethod
    def get_time_from_database(cls):
        sql = PostgresConverter.get_time_from_database()
        cls._read_cursor.execute(sql)
        row = cls._read_cursor.fetchone()
        return str(row[0])

    @classmethod
    def print_count_as_of(cls, target_table, time_of_interest):
        sql = PostgresConverter.count_as_of(target_table, time_of_interest)
        cls._read_cursor.execute(sql)
        rows = cls._read_cursor.fetchall()
        deleted_rows = rows[0][1] or 0
        active_rows = rows[0][0] - deleted_rows
        Logger.get_logger().info(
            f'---------------{target_table.name} has {active_rows} active rows and {deleted_rows} deleted rows')

    @classmethod
    def code_tables(cls, tables, area, store_metadata, schema, drop_only=False, remove_metadata=True,
                    add_objectid_index=True):
        converter = PostgresConverter()
        Logger.get_logger().info(f'Area {area}, table count {len(tables)}')
        for table in tables:
            drop_command = converter.drop_table(schema, table, area)
            Logger.get_logger().info(drop_command)
            print(drop_command)
            clear_command = converter.clear_metadata_for_this_table(schema, table, area)
            try:
                cls._write_cursor.execute(drop_command)
                if remove_metadata:
                    Logger.get_logger().info(clear_command)
                    print(clear_command)
                    cls._write_cursor.execute(clear_command)
            # TODO - refine the below exception handler as it's very broad in this form
            except Exception as e:
                Logger.get_logger().info(f'No existing table {table.name}')
                print(str(e))
                # if we couldn't drop a table because it's not there, that's fine
                if drop_only:
                    continue
                cls.rollback()
            else:
                if drop_only:
                    continue
                try:
                    create_command = converter.code_table(schema, table, area)
                    Logger.get_logger().info(create_command)
                    print(create_command)
                    cls._write_cursor.execute(create_command)
                    index_commands = converter.code_indexes(schema, table, area)
                    for index_command in index_commands:
                        print(index_command)
                        Logger.get_logger().info(index_command)
                        cls._write_cursor.execute(index_command)
                    if add_objectid_index:
                        create_objectid_index_command = converter.create_objectid_index(schema, table, area)
                        Logger.get_logger().info(create_objectid_index_command)
                        cls._write_cursor.execute(create_objectid_index_command)
                    if store_metadata:
                        metadata_row_commands = PostgresConverter.store_metadata(schema, table, area)
                        for metadata_command in metadata_row_commands:
                            Logger.get_logger().info(metadata_command)
                            print(metadata_command)
                            cls._write_cursor.execute(metadata_command)
                except Exception as ex:
                    print(str(ex))
                    traceback.print_exc(limit=None, file=None, chain=True)
                    cls.rollback()
                else:
                    print(f'Created table {table.name}')

    @classmethod
    def print_total_count(cls, target_table):
        sql = f'SELECT COUNT(1) FROM {target_table.name} '
        cls._read_cursor.execute(sql)
        rows = cls._read_cursor.fetchall()
        Logger.get_logger().info(f'---------------There are {rows[0][0]} rows for {target_table.name}')

    @classmethod
    def print_current_view(cls, target_table):
        sql = f"SELECT * FROM {target_table.name} WHERE ToZ=TIMESTAMP '9999-01-01 00:00:00' "
        sql += f" AND EffectiveToZ=TIMESTAMP '9999-01-01 00:00:00' AND isDeleted = 0"
        cls._read_cursor.execute(sql)
        rows = cls._read_cursor.fetchall()
        Logger.get_logger().info(f'---------------Showing all current rows for {target_table.name}')
        for row in rows:
            Logger.get_logger().info(row)

    @classmethod
    def print_current_total_count(cls, target_table):
        sql = f"SELECT COUNT(1), SUM(IsDeleted) FROM {target_table.name} WHERE ToZ=TIMESTAMP '9999-01-01 00:00:00' "
        sql += f" AND EffectiveToZ=TIMESTAMP '9999-01-01 00:00:00'"
        cls._read_cursor.execute(sql)
        rows = cls._read_cursor.fetchall()
        deleted_rows = rows[0][1]
        active_rows = rows[0][0] - deleted_rows
        Logger.get_logger().info(
            f'---------------{target_table.name} has {active_rows} active rows and {deleted_rows} deleted rows')

    @classmethod
    def print_view_as_of(cls, target_table, time_of_interest):
        sql = f"SELECT * FROM {target_table.name} WHERE FromZ <= '{time_of_interest}' AND ToZ > '{time_of_interest}' "
        sql += f" AND EffectiveFromZ <='{time_of_interest}' AND EffectiveToZ > '{time_of_interest}' AND isDeleted = 0"
        cls._read_cursor.execute(sql)
        rows = cls._read_cursor.fetchall()
        Logger.get_logger().info(f'---------------Showing all rows as of {target_table.name}')
        for row in rows:
            Logger.get_logger().info(row)

    @classmethod
    def load_keys(cls, lookup_table, lookup_column, id_column, time_of_creation):
        keys = {}
        sql = PostgresConverter.load_keys(lookup_table, lookup_column, id_column, time_of_creation)
        cursor = cls.foreign_key_cursor()
        cursor.execute(sql)
        rows = cursor.fetchall()
        for row in rows:
            foreign_key_value = str(row[1]).lower()
            keys[foreign_key_value] = row[0]
        Logger.get_logger().info(f'Foreign key table {lookup_table} had {len(rows)} rows at {time_of_creation}')
        return keys

    @classmethod
    def get_quarantine_data_by_driving_column(cls, lookup_table, driving_column):
        sql_metadata_ids = PostgresConverter.get_quarantine_data_by_driving_column(lookup_table, driving_column)
        cls._read_cursor.execute(sql_metadata_ids)
        metadata_ids = list(cls._read_cursor.fetchall())
        metadata_ids.sort()
        return metadata_ids

    @classmethod
    def get_cursor_for_driving_column(cls, input_columns, driving_table: str, originator_id: int = None,
                                      driving_column: str = None):
        sql = PostgresConverter.get_rows_for_given_driver_column_value(input_columns, originator_id, driving_table,
                                                                       driving_column)
        cls._read_cursor.execute(sql)

    @classmethod
    def get_row_chunk(cls, chunk_size):
        return cls._read_cursor.fetchmany(chunk_size)

    @classmethod
    def store_transformed_and_associated_rows(cls, transformed_row_values, distinct_rows):
        CHUNK_SIZE = 100000
        target_tables_list = list(transformed_row_values.keys())
        array_of_vals_to_store_list = list(transformed_row_values.values())
        i = 0
        rows_stored = {}
        while i < len(target_tables_list):
            target_table = target_tables_list[i]
            rows_stored[target_table] = 0
            array_of_vals_to_store = array_of_vals_to_store_list[i]
            #        for target_table, array_of_vals_to_store in transformed_row_values.items():
            if len(array_of_vals_to_store) == 0:
                continue
            if target_table in distinct_rows.keys():
                key = distinct_rows[target_table]
                if isinstance(key, str):
                    dict_of_vals = {val[key]: val for val in array_of_vals_to_store}
                else:
                    dict_of_vals = {tuple([val[key_el] for key_el in key]): val for val in array_of_vals_to_store}
                array_of_vals = list(dict_of_vals.values())
            else:
                array_of_vals = array_of_vals_to_store
            start_index = 0
            end_index = len(array_of_vals)
            while start_index < end_index:
                # take a chunk of values within a single SQL statement
                vals_to_persist = array_of_vals[start_index:start_index + CHUNK_SIZE]
                sql = PostgresConverter.construct_sql_to_store(target_table, vals_to_persist)
                if sql is None:  # there were no values
                    continue
                try:
                    cls._write_cursor.execute(sql)
                except Exception as e:
                    print(sql)
                    print(str(e))
                    time.sleep(100)
                    traceback.print_exc(limit=None, file=None, chain=True)
                else:
                    start_index += len(vals_to_persist)
                    print(f'{target_table} stored {start_index} so far')
            rows_stored[target_table] = end_index
            i += 1
        return rows_stored

    @classmethod
    def get_originator_column_name(cls):
        return PostgresConverter.get_originator_column_name()

    @classmethod
    def delete_staging_rows(cls, table_name):
        cls._write_cursor.execute(PostgresConverter.delete_staging_rows(table_name))

    @classmethod
    def create_deleted_row(cls, row, target_table, target_positions, ingestion_id, time_of_creation):
        cols = list(target_positions.keys())
        cols.remove("FromZ")
        cols.remove("ToZ")
        cols.remove("EffectiveFromZ")
        cols.remove("EffectiveToZ")
        cols.remove("ingestion_id")
        cols.remove("IsDeleted")
        cols.remove("objectid")
        sql = f"INSERT INTO {target_table.name} (" + ",".join(
            cols) + ",FromZ, ToZ, EffectiveFromZ, EffectiveToZ, ingestion_id, IsDeleted ) SELECT "
        values = []
        for columnName in cols:
            if columnName not in ["FromZ", "ToZ", "EffectiveFromZ", "EffectiveToZ", "ingestion_id", "IsDeleted"]:
                values.append(f' {columnName} ')

        values.append("'" + time_of_creation + "'")  # FromZ
        values.append("'9999-01-01 00:00:00'")  # ToZ
        values.append("'" + time_of_creation + "'")  # EffectiveFromZ
        values.append("'9999-01-01 00:00:00'")  # EffectiveToZ
        values.append(str(ingestion_id))
        values.append(str(1))  # isDeleted
        sql += ",".join(values)
        sql += f" FROM {target_table.name} WHERE objectid={row[target_positions['objectid']]}"
        cls._write_cursor.execute(sql)

    @classmethod
    def timestamp_existing_row(cls, row, target_positions, target_table, modification_time):
        sql = f"UPDATE {target_table.name} SET ToZ = '{modification_time}' WHERE objectid={row[target_positions['objectid']]}"
        cls._write_cursor.execute(sql)

    @classmethod
    def add_ingestion(cls, ingestion_provider_ids, ingestion_id, time_of_creation, data_group, stats):
        sql = 'INSERT INTO INGESTION_HISTORY(ingestion_id, ingestion_time, ingestion_stage_id, data_group) '
        sql += f'SELECT {ingestion_id}, TIMESTAMP \'{time_of_creation}\','
        sql += f" id, '{data_group}' FROM ingestion_stages WHERE description='Entered into history'"
        cls._write_cursor.execute(sql)
        sql = 'INSERT INTO INGESTION_HISTORY_PROVIDERS(ingestion_id, ingestion_data_source_id, added, equaled, updated, deleted, already_deleted) VALUES '
        values_array = []
        for ingestion_provider_id in ingestion_provider_ids:
            vals: IngestionStats = stats[ingestion_provider_id]
            values_array.append(
                f'({ingestion_id}, {ingestion_provider_id}, {vals.added}, {vals.equal}, {vals.updated}, {vals.deleted}, {vals.already_deleted})')
        sql += ",".join(values_array)
        cls._write_cursor.execute(sql)
        print('Added ingestion')

    @classmethod
    def create_new_row(cls, row, source_table, source_positions, target_table, ingestion_id,
                       time_of_creation):
        cols = list(source_positions.keys())
        cols.remove("objectid")  # dont copy objectid across
        sql = f"INSERT INTO {target_table.name} (" + ",".join(
            cols) + ",FromZ, ToZ, EffectiveFromZ, EffectiveToZ, ingestion_id, IsDeleted ) SELECT "
        values = []
        for columnName in cols:
            values.append(f' {columnName} ')

        values.append("'" + time_of_creation + "'")  # FromZ
        values.append("'9999-01-01 00:00:00'")  # ToZ
        values.append("'" + time_of_creation + "'")  # EffectiveFromZ
        values.append("'9999-01-01 00:00:00'")  # EffectiveToZ
        values.append(str(ingestion_id))
        values.append(str(0))  # isDeleted
        sql += ",".join(values)
        sql += f" FROM {source_table.name} WHERE objectid={row[source_positions['objectid']]}"
        cls._write_cursor.execute(sql)

    @classmethod
    def print_all_rows(cls, target_table):
        sql = f'SELECT * FROM {target_table.name} '
        cls._read_cursor.execute(sql)
        rows = cls._read_cursor.fetchall()
        Logger.get_logger().info(f'---------------Showing all rows for {target_table.name}')
        for row in rows:
            Logger.get_logger().info(row)
