from mgmt_logging.logger import Logger
from postgres.postgresexecutor import PostgresExecutor
from schema_mgmt.extractor import Extractor
from sql.sql_runner import SqlRunner


class WDPASchemaPopulator():

    @staticmethod
    def create_wdpa_schema(schema_to_populate):
        Logger.get_logger().info("Reading schemas")
        HISTORICAL_COLS = "../json/historical_columns.json"
        historical_sch = Extractor.get_all_definitions(HISTORICAL_COLS)
        historical_table_def = historical_sch[0]

        INGESTION_COLS = "../json/ingestion_columns.json"
        ingestion_sch = Extractor.get_all_definitions(INGESTION_COLS)
        ingestion_table_def = ingestion_sch[0]

        APP_SCHEMA_FILE = '../json/WDPA.json'
        try:
            Logger.get_logger().info("Creating staging tables")
            app_schema_tables = list(Extractor.get_all_definitions(APP_SCHEMA_FILE))
            PostgresExecutor.replace_tables(app_schema_tables, 'staging', True, schema_to_populate)

            Logger.get_logger().info("Creating main tables")
            app_schema_tables = list(Extractor.get_all_definitions(APP_SCHEMA_FILE, historical_table_def, ingestion_table_def))
            PostgresExecutor.replace_tables(app_schema_tables, None, True, schema_to_populate)

            Logger.get_logger().info("Creating indexes ")
            SqlRunner.execute('../sql/wdpa/wdpa.sql')
            Logger.get_logger().info("Created indexes")
        except Exception as e:
            print(str(e))

    @staticmethod
    def create_source_schema(schema_to_populate):
        HISTORICAL_COLS = "../json/historical_columns.json"
        historical_sch = Extractor.get_all_definitions(HISTORICAL_COLS)
        historical_table_def = historical_sch[0]

        INGESTION_COLS = "../json/ingestion_columns.json"
        ingestion_sch = Extractor.get_all_definitions(INGESTION_COLS)
        ingestion_table_def = ingestion_sch[0]

        SOURCE_SCHEMA_FILE = '../json/source_table.json'

        try:
            Logger.get_logger().info("Creating staging tables")
            app_schema_tables = list(Extractor.get_all_definitions(SOURCE_SCHEMA_FILE))
            PostgresExecutor.replace_tables(app_schema_tables, 'staging', True, schema_to_populate)

            Logger.get_logger().info("Creating main tables")
            app_schema_tables = list(Extractor.get_all_definitions(SOURCE_SCHEMA_FILE, historical_table_def, ingestion_table_def))
            PostgresExecutor.replace_tables(app_schema_tables, None, True, schema_to_populate)
            Logger.get_logger().info("Constructed Source tables")

        except Exception as e:
            print(str(e))