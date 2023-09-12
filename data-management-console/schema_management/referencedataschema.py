import sys

from postgres.postgresexecutor import PostgresExecutor
from schema_management.extractor import Extractor


class ReferenceDataSchemaPopulator:

    @staticmethod
    def create_reference_data_schema(schema_to_populate):
        HISTORICAL_COLS = "../json/historical_columns.json"
        historical_sch = Extractor.get_all_definitions(HISTORICAL_COLS)
        historical_table_def = historical_sch[0]

        INGESTION_COLS = "../json/ingestion_columns.json"
        ingestion_sch = Extractor.get_all_definitions(INGESTION_COLS)
        ingestion_table_def = ingestion_sch[0]

        OBJECTID_COLS = "../json/objectid_columns.json"
        objectid_sch = Extractor.get_all_definitions(OBJECTID_COLS)
        objectid_table_def = objectid_sch[0]

        SCHEMA_FILE = "../json/common_reference.json"
        app_schema_tables = list(Extractor.get_all_definitions(SCHEMA_FILE, objectid_table_def=objectid_table_def))
        PostgresExecutor.code_tables(app_schema_tables, 'stg', True, schema_to_populate)

        app_schema_tables = list(
            Extractor.get_all_definitions(SCHEMA_FILE, historical_table_def, ingestion_table_def, objectid_table_def))
        PostgresExecutor.code_tables(app_schema_tables, None, True, schema_to_populate)
