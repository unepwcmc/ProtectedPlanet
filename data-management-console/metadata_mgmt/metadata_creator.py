from schema_mgmt.extractor import Extractor
from postgres.postgresexecutor import PostgresExecutor

class MetadataCreator():

    @staticmethod
    def execute():
        METADATA_SCHEMA_FILE = "../json/foundation_tables.json"
        metadata_schema_tables = Extractor.get_all_definitions(METADATA_SCHEMA_FILE)
        PostgresExecutor.replace_tables(metadata_schema_tables, None, False, "common")



