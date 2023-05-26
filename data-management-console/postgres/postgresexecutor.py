import traceback
from postgres.postgresconverter import PostgresConverter
from mgmt_logging.logger import Logger


class PostgresExecutor:

    _cursor = None
    _conn = None

    @classmethod
    def get_next_ingestion_id(cls):
        sql = 'SELECT MAX(ingestion_id) FROM INGESTION_HISTORY'
        cls._cursor.execute(sql)
        rows = cls._cursor.fetchall()
        max_used = rows[0][0] or 0
        Logger.get_logger().info(f"Next ingestion id is {max_used + 1}")
        return max_used + 1

    @classmethod
    def get_staging_data_originators(cls, driving_table):
        sql = PostgresConverter.get_staging_data_originators(driving_table)
        cls._cursor.execute(sql)
        originator_ids = [row[0] for row in cls._cursor.fetchall()]
        return originator_ids

    @classmethod
    def construct_query_clause(cls, quarantine_table, target_table, originator_id, closed_universe):
        [main_clause, quarantine_positions, target_positions] = PostgresConverter.construct_query_clause(quarantine_table, target_table, originator_id, closed_universe)
        cls._cursor.execute(main_clause)
        rows = cls._cursor.fetchall()
        return [rows, quarantine_positions, target_positions]

    @classmethod
    def begin_transaction(cls, conn):
        cls._conn = conn
        Logger.get_logger().info("Beginning transaction")
        cls._cursor = cls._conn.cursor()
        cls._cursor.execute("BEGIN TRANSACTION")
        return cls._cursor

    @classmethod
    def end_transaction(cls):
        Logger.get_logger().info("Ending transaction")
        if cls._cursor is not None:
            cls._cursor.execute("COMMIT")
            cls._cursor = None

    @classmethod
    def rollback(cls):
        if cls._cursor is None:
            return
        cls._cursor.execute("ROLLBACK")
        cls._cursor = None

    @classmethod
    def get_time_from_database(cls):
        sql = PostgresConverter.get_time_from_database()
        cls._cursor.execute(sql)
        row = cls._cursor.fetchone()
        return str(row[0])

    @classmethod
    def print_count_as_of(cls, target_table, time_of_interest):
        sql = PostgresConverter.count_as_of(target_table, time_of_interest)
        cls._cursor.execute(sql)
        rows = cls._cursor.fetchall()
        deleted_rows = rows[0][1] or 0
        active_rows = rows[0][0] - deleted_rows
        Logger.get_logger().info(f'---------------{target_table.name} has {active_rows} active rows and {deleted_rows} deleted rows')
    @classmethod
    def replace_tables(cls, tables, area, store_metadata, schema):
        converter = PostgresConverter()
        Logger.get_logger().info(f'Area {area}, table count {len(tables)}')
        for table in tables:
            drop_command = converter.drop_table(schema, table, area)
            Logger.get_logger().info(drop_command)
 #           clear_command = converter.clear_metadata_for_this_table(schema, table, area)
#            Logger.get_logger().info(clear_command)
            try:
                cls._cursor.execute(drop_command)
#                cls._cursor.execute(clear_command)
            # TODO - refine the below exception handler as it's very broad in this form
            except Exception as e:
                Logger.get_logger().info(f'No existing table {table.name}')
                print(str(e))
                PostgresExecutor.rollback()
            else:
                create_command = converter.code_table(schema, table, area)
                Logger.get_logger().info(create_command)
                try:
                    cls._cursor.execute(create_command)

                    if store_metadata:
                        metadata_row_commands = PostgresConverter.store_metadata(schema, table, area)
                        for metadata_command in metadata_row_commands:
                            Logger.get_logger().info(metadata_command)
                            cls._cursor.execute(metadata_command)
                except Exception as e:
                    print(str(e))
                    PostgresExecutor.rollback()


    @classmethod
    def print_total_count(cls, target_table):
        sql = f'SELECT COUNT(1) FROM {target_table.name} '
        cls._cursor.execute(sql)
        rows = cls._cursor.fetchall()
        Logger.get_logger().info(f'---------------There are {rows[0][0]} rows for {target_table.name}')

    @classmethod
    def print_current_view(cls, target_table):
        sql = f"SELECT * FROM {target_table.name} WHERE ToZ=TIMESTAMP '9999-01-01 00:00:00' "
        sql += f" AND EffectiveToZ=TIMESTAMP '9999-01-01 00:00:00' AND isDeleted = 0"
        cls._cursor.execute(sql)
        rows = cls._cursor.fetchall()
        Logger.get_logger().info(f'---------------Showing all current rows for {target_table.name}')
        for row in rows:
            Logger.get_logger().info(row)

    @classmethod
    def print_current_total_count(cls, target_table):
        sql = f"SELECT COUNT(1), SUM(IsDeleted) FROM {target_table.name} WHERE ToZ=TIMESTAMP '9999-01-01 00:00:00' "
        sql += f" AND EffectiveToZ=TIMESTAMP '9999-01-01 00:00:00'"
        cls._cursor.execute(sql)
        rows = cls._cursor.fetchall()
        deleted_rows = rows[0][1]
        active_rows = rows[0][0] - deleted_rows
        Logger.get_logger().info(f'---------------{target_table.name} has {active_rows} active rows and {deleted_rows} deleted rows')

    @classmethod
    def print_view_as_of(cls, target_table, time_of_interest):
        sql = f"SELECT * FROM {target_table.name} WHERE FromZ <= '{time_of_interest}' AND ToZ > '{time_of_interest}' "
        sql += f" AND EffectiveFromZ <='{time_of_interest}' AND EffectiveToZ > '{time_of_interest}' AND isDeleted = 0"
        cls._cursor.execute(sql)
        rows = cls._cursor.fetchall()
        Logger.get_logger().info(f'---------------Showing all rows as of {target_table.name}')
        for row in rows:
            Logger.get_logger().info(row)

    @classmethod
    def load_keys(cls, lookup_table, lookup_column, code_column, time_of_creation):
        keys = {}
        sql = PostgresConverter.load_keys(lookup_table, lookup_column, code_column, time_of_creation)
        cls._cursor.execute(sql)
        rows = cls._cursor.fetchall()
        for row in rows:
            foreign_key_value = row[0]      # these can be ints or characters
            if isinstance(foreign_key_value, str):
                foreign_key_value = foreign_key_value.strip()
            keys[foreign_key_value] = row[1]
        Logger.get_logger().info(f'Foreign key table {lookup_table} had {len(rows)} rows at {time_of_creation}')
        return keys


    @classmethod
    def get_quarantine_data_by_driving_column(cls, lookup_table, driving_column):
        sql_metadata_ids = PostgresConverter.get_quarantine_data_by_driving_column(lookup_table, driving_column)
        cls._cursor.execute(sql_metadata_ids)
        metadata_ids = list(cls._cursor.fetchall())
        metadata_ids.sort()
        return metadata_ids

    @classmethod
    def get_cursor_for_driving_column(cls, input_columns, originator_id, driving_table, driving_column):
        sql = PostgresConverter.get_rows_for_given_driver_column_value(input_columns, originator_id, driving_table, driving_column)
        cls._cursor.execute(sql)

    @classmethod
    def get_row_chunk(cls, chunk_size):
        return cls._cursor.fetchmany(chunk_size)

    @classmethod
    def store_transformed_and_associated_rows(cls, transformed_row_values):
        CHUNK_SIZE = 5000
        for target_table, array_of_vals_to_store in transformed_row_values.items():
            if len(array_of_vals_to_store) == 0:
                continue
            start_index = 0
            while start_index < len(array_of_vals_to_store):
                # take a chunk of values within a single SQL statement
                vals_to_persist = array_of_vals_to_store[start_index:start_index+CHUNK_SIZE]
                sql = PostgresConverter.construct_sql_to_store(target_table, vals_to_persist)
                if sql is None: # there were no values
                    continue
                try:
                    cls._cursor.execute(sql)
                    start_index += len(vals_to_persist)
                    print(f'{target_table} stored {start_index} so far')
                except Exception as e:
                    print(sql)
                    print(str(e))
                    traceback.print_exc(limit=None, file=None, chain=True)
#                Logger.get_logger().info(f"Inserted row into staging_{target_table}")

    @classmethod
    def get_originator_column_name(cls):
        return PostgresConverter.get_originator_column_name()

    @classmethod
    def delete_staging_rows(cls, table_name):
        cls._cursor.execute(PostgresConverter.delete_staging_rows(table_name))

    @classmethod
    def create_deleted_row(cls, row, target_table, target_positions, originator_id, ingestion_id, time_of_creation):
        cols = list(target_positions.keys())
        cols.remove("FromZ")
        cols.remove("ToZ")
        cols.remove("EffectiveFromZ")
        cols.remove("EffectiveToZ")
        cols.remove("INGEST_ID")
        cols.remove("IsDeleted")
        sql = f"INSERT INTO {target_table.name} (" + ",".join(
            cols) + ",FromZ, ToZ, EffectiveFromZ, EffectiveToZ, INGEST_ID, IsDeleted ) SELECT "
        values = []
        for columnName in cols:
            if columnName not in ["FromZ", "ToZ", "EffectiveFromZ", "EffectiveToZ", "INGEST_ID", "IsDeleted"]:
                values.append(f' {columnName} ')

        values.append("'" + time_of_creation + "'")  # FromZ
        values.append("'9999-01-01 00:00:00'")  # ToZ
        values.append("'" + time_of_creation + "'")  # EffectiveFromZ
        values.append("'9999-01-01 00:00:00'")  # EffectiveToZ
        values.append(str(ingestion_id))
        values.append(str(1))  # isDeleted
        sql += ",".join(values)
        sql += f" FROM {target_table.name} WHERE "
        where_clause = []
        primary_key_names = target_table.primary_key().column_names.split(",")
        for name in primary_key_names:
            if name != "ToZ":
                where_clause.append(f"{name}='{row[target_positions[name]]}'")
            else:
                where_clause.append(f"{name}='{time_of_creation}'")
        sql += " AND ".join(where_clause)
        if originator_id is not None:
            sql += " AND originator_id = " + str(originator_id)
        cls._cursor.execute(sql)

    @classmethod
    def timestamp_existing_row(cls, row, target_positions, target_table, modification_time):
        sql = f"UPDATE {target_table.name} SET ToZ = '{modification_time}' WHERE "
        where_phrases = []
        for PKField in target_table.primary_key().column_names.split(","):
            if (PKField == "ToZ") or (PKField == "EffectiveToZ"):
                continue
            val = row[target_positions[PKField]]
            where_phrases.append(f" {PKField}='{val}' ")
        sql += " AND ".join(where_phrases)
        sql += f" AND ToZ='9999-01-01 00:00:00' AND EffectiveToZ='9999-01-01 00:00:00'"
        cls._cursor.execute(sql)

    @classmethod
    def add_ingestion(cls, originator_ids, ingestion_id, time_of_creation, data_group):
        sql = 'INSERT INTO INGESTION_HISTORY(ingestion_id, ingestion_time, ingestion_stage, data_group) '
        sql += f'SELECT {ingestion_id}, TIMESTAMP \'{time_of_creation}\','
        sql += " code, data_group FROM ingestion_stages WHERE description='Entered into history'"
        print(sql)
        cls._cursor.execute(sql)
        print('Added ingestion')


    @classmethod
    def create_new_row(cls, row, source_table, source_positions, target_table, originator_id, ingestion_id, time_of_creation):
        cols = source_positions.keys()
        sql = f"INSERT INTO {target_table.name} (" + ",".join(
            cols) + ",FromZ, ToZ, EffectiveFromZ, EffectiveToZ, INGEST_ID, IsDeleted ) SELECT "
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
        sql += f" FROM {source_table.name} WHERE "
        where_clause = []
        primary_key_names = source_table.primary_key().column_names.split(",")
        for name in primary_key_names:
            where_clause.append(f"{name}='{row[source_positions[name]]}'")
        sql += " AND ".join(where_clause)
        if originator_id is not None:
            sql += " AND originator_id = " + str(originator_id)
        cls._cursor.execute(sql)

    @classmethod
    def print_all_rows(cls, target_table):
        sql = f'SELECT * FROM {target_table.name} '
        cls._cursor.execute(sql)
        rows = cls._cursor.fetchall()
        Logger.get_logger().info(f'---------------Showing all rows for {target_table.name}')
        for row in rows:
            Logger.get_logger().info(row)

