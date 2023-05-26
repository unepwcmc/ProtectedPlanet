import json
from schema_mgmt.tables import TableDefinition, TableColumn, ForeignKey, PrimaryKey
from mgmt_logging.logger import Logger

class Extractor:
    @staticmethod
    def extract(incoming_json, table_name):
        data_type = incoming_json['type']
        print(f'Extracting {table_name}:{data_type}')
        match data_type:
            case "FOREIGN KEY":
                source_columns = incoming_json['source cols']
                target_table = incoming_json['target table']
                target_cols = incoming_json['target cols']
                return ForeignKey(table_name, source_columns, target_table, target_cols)
            case "PRIMARY KEY":
                pk_field_names = incoming_json['PK fields']
                return PrimaryKey(table_name, pk_field_names)
            case _:
                name = incoming_json["name"]
                return TableColumn(table_name, name, data_type)

    @staticmethod
    def extract_tables(schema, history, ingest):
        Logger.get_logger().info(f'Extracting tables: history is {history}, ingest is {ingest}')
        tables = [TableDefinition(table['name'],
                                  [Extractor.extract(el, table['name']) for el in table['elements']])
                  for table in schema['tables']]
        Logger.get_logger().info(f'Received schema for {len(tables)} tables')
        if history is not None:
            tables = list(map(lambda x: x.add_historical_columns(history), tables))
        if ingest is not None:
            tables = list(map(lambda x: x.add_ingestion_columns(ingest), tables))
        return tables

    @staticmethod
    def get_all_definitions(schema_file, historical_table_def=None, ingestion_table_def=None):
        print(f'Loading file {schema_file}')
        with open(schema_file, 'r') as file:
            raw_schema = json.load(file)
            schema_tables = list(Extractor.extract_tables(raw_schema, historical_table_def, ingestion_table_def))
            print(f'Completed file {schema_file}')
            return schema_tables
