# Creates and drops schemas so used as part of the application installation process
# Also handles the special sql installation needs associated with reference data

import traceback

from install_json.json_path import JsonPath
from util.logger import Logger
from postgres.postgresexecutor import PostgresExecutor
from schema_management.extractor import Extractor
from schema_management.virtualcolumngenerator import VirtualColumnGenerator
from sql.sql_runner import SqlRunner


class SchemaPopulator:

    @staticmethod
    def create_schema(schema_to_populate, cursor, is_reference_data=False):
        Logger.get_logger().info("Reading schemas")
        HISTORICAL_COLS = JsonPath.make_json_path('historical_columns')
        historical_sch, _ = Extractor.get_all_definitions(HISTORICAL_COLS)
        historical_table_def = historical_sch[0]

        INGESTION_COLS = JsonPath.make_json_path('ingestion_columns')
        ingestion_sch, _ = Extractor.get_all_definitions(INGESTION_COLS)
        ingestion_table_def = ingestion_sch[0]

        APP_SCHEMA_FILE = JsonPath.make_json_path(schema_to_populate)
        try:
            OBJECTID_COLS = JsonPath.make_json_path('objectid_columns')
            objectid_sch, _ = Extractor.get_all_definitions(OBJECTID_COLS)
            objectid_table_def = objectid_sch[0]

            Logger.get_logger().info("Creating staging tables")
            print("Creating staging tables")
            _, app_schema_tables = Extractor.get_all_definitions(APP_SCHEMA_FILE, objectid_table_def=objectid_table_def)
            PostgresExecutor.code_tables(app_schema_tables, 'stg', True, schema_to_populate)

            Logger.get_logger().info("Creating main tables")
            print("Creating main tables")
            schema_tables, app_schema_tables = Extractor.get_all_definitions(APP_SCHEMA_FILE, historical_table_def, ingestion_table_def, objectid_table_def)
            PostgresExecutor.code_tables(app_schema_tables, None, True, schema_to_populate)

            # give the staging tables a way to default populate their id fields
            if is_reference_data:
                for table in app_schema_tables:
                    SqlRunner.execute_file_with_substitution(cursor, '../sql/template_staging.sql', {"%REFERENCE_TABLE_NAME%": table.name()})
            Logger.get_logger().info("Create foreign key virtual column functions")
            VirtualColumnGenerator.create_virtual_column_functions(cursor, schema_tables)

            Logger.get_logger().info("Creating indexes ")
        except Exception as ex:
            print(str(ex))
            traceback.print_exc(limit=None, file=None, chain=True)
            raise ex

    @staticmethod
    def drop_schema(schema_to_remove, remove_metadata=True):
        APP_SCHEMA_FILE = JsonPath.make_json_path(schema_to_remove)
        Logger.get_logger().info("Removing staging tables")
        print("Removing staging tables")
        _, app_schema_tables = Extractor.get_all_definitions(APP_SCHEMA_FILE)
        PostgresExecutor.code_tables(app_schema_tables, 'stg', True, schema_to_remove, drop_only=True, remove_metadata=remove_metadata)

        Logger.get_logger().info("Removing main tables")
        print("Removing main tables")
        _, app_schema_tables = Extractor.get_all_definitions(APP_SCHEMA_FILE)
        PostgresExecutor.code_tables(app_schema_tables, None, True, schema_to_remove, drop_only=True, remove_metadata=remove_metadata)