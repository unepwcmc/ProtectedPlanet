import json

from metadata_mgmt.metadatareader import MetadataReader
from metadata_mgmt.unknowntableforforeignkeyexception import UnknownTableForForeignKeyException
from schema_management.abbreviatename import AbbreviateName
from schema_management.tables import TableDefinition, TableColumn, ForeignKey, PrimaryKey, VirtualColumn, \
    ForeignKeyN, IndexRequest
from mgmt_logging.logger import Logger
from schema_management.virtualcolumngenerator import VirtualColumnGenerator


class Extractor:
    @staticmethod
    def extract(incoming_json, table_name):
        data_type = incoming_json['type']
        print(f'Extracting {table_name}:{data_type}')
        # can't use match syntax until Python 3.10
        if data_type == "FOREIGN KEY":
            source_columns = incoming_json['source cols']
            target_table = incoming_json['target table']
            target_cols = incoming_json['target cols']
            lookup_cols = incoming_json['lookup cols']
            known_as = incoming_json['known as']
            return ForeignKey(table_name, source_columns, target_table, target_cols, lookup_cols, known_as)
        elif data_type == "FOREIGN KEY N":
            source_columns = incoming_json['source cols']
            target_table = incoming_json['target table']
            target_cols = incoming_json['target cols']
            lookup_cols = incoming_json['lookup cols']
            known_as = incoming_json['known as']
            if incoming_json.get('association table alias'):
                association_table_alias = incoming_json['association table alias']
            else:
                association_table_alias = AbbreviateName.abbreviate_name([table_name, target_table, known_as])
            return ForeignKeyN(table_name, source_columns, target_table, target_cols, lookup_cols, known_as, association_table_alias)
        elif data_type == "PRIMARY KEY":
            pk_field_names = incoming_json['PK fields']
            return PrimaryKey(table_name, pk_field_names)
        elif data_type == "VIRTUAL COLUMN":
            name = incoming_json["name"]
            function_to_call = incoming_json["function"]
            associated_column_name = incoming_json["associated"]
            representation = incoming_json["representation"]
            return VirtualColumn(table_name, name, associated_column_name, function_to_call, representation)
        else:
            name = incoming_json["name"]
            return TableColumn(table_name, name, data_type)

    @staticmethod
    def add_extra_columns(tables, history, ingest, objectid):
        if history is not None:
            tables = list(map(lambda x: x.add_historical_columns(history), tables))
        if ingest is not None:
            tables = list(map(lambda x: x.add_ingestion_columns(ingest), tables))
        if objectid is not None:
            tables = list(map(lambda x: x.add_objectid_columns(objectid), tables))
        return tables

    @staticmethod
    def extract_tables(schema, history, ingest, objectid):
        Logger.get_logger().info(f'Extracting tables: history is {history}, ingest is {ingest}')
        tables = [TableDefinition(table['name'],
                                  [Extractor.extract(el, table['name']) for el in table['elements']])
                  for table in schema['tables']]
        Logger.get_logger().info(f'Received schema for {len(tables)} tables')
        tables = Extractor.add_extra_columns(tables, history, ingest, objectid)
        return tables

    @staticmethod
    def extract_association_and_target_table_names(table_name, all_tables: dict):
        assoc_table_names = []
        target_table_names = []
        schema_table = all_tables[table_name]
        foreign_keys_for_assoc: list[ForeignKeyN] = list(
            filter(lambda x: isinstance(x, ForeignKeyN), schema_table.elements))
        for fk in foreign_keys_for_assoc:
            if fk.known_as == '_internal_':
                continue
            target_table_names.append(fk.target_table)
            assoc_table_name = fk.association_table_alias
            assoc_table_names.append(assoc_table_name)
        return assoc_table_names, target_table_names

    @staticmethod
    def extract_association_tables(schema_tables, existing_tables, history, ingest, objectid):
        assoc_tables = []
        for schema_table in schema_tables:
            foreign_keys_for_assoc: list[ForeignKeyN] = list(
                filter(lambda x: isinstance(x, ForeignKeyN), schema_table.elements))
            for fk in foreign_keys_for_assoc:
                if fk.known_as == '_internal_':
                    continue
                assoc_table_name = fk.association_table_alias
                # we'll need data about column types from the target table
                target_table = list(filter(lambda x: x.name == fk.target_table, schema_tables))
                if not target_table:
                    target_table_actual = existing_tables.get(fk.target_table)
                else:
                    target_table_actual = target_table[0]
                if target_table_actual is None:
                    raise UnknownTableForForeignKeyException(fk.target_table)

                # get all the cols in one place, gathered from source and target (so we can be sure to match the types)
                cols = []
                try:
                    cols: list = [schema_table.column_by_name(coll).copy() for coll in fk.source_columns] + [
                        target_table_actual.column_by_name(coll).copy() for coll in
                        fk.target_columns]
                except Exception as e:
                    print(str(e))
                # we change the name - this is why we needed to copy in the step above
                for col in cols:
                    col.table_name = assoc_table_name

                primary_key = PrimaryKey(assoc_table_name, fk.source_columns + fk.target_columns)
                cols.append(primary_key)

                originator_id_column = TableColumn(assoc_table_name, "originator_id", "int")
                cols.append(originator_id_column)
                index_request_src = IndexRequest(assoc_table_name, fk.source_columns)
                index_request_tgt = IndexRequest(assoc_table_name, fk.target_columns)
                cols.append(index_request_src)
                cols.append(index_request_tgt)
                try:
                    assoc_table_to_create = TableDefinition(assoc_table_name, cols)
                    assoc_tables.append(assoc_table_to_create)
                except Exception as e:
                    print(str(e))

        assoc_tables_added = Extractor.add_extra_columns(assoc_tables, history, ingest, objectid)
        return assoc_tables_added

    @staticmethod
    def get_all_definitions(schema_file, historical_table_def=None, ingestion_table_def=None, objectid_table_def=None,
                            is_foundation=False):
        print(f'Loading file {schema_file}')
        with open(schema_file, 'r') as file:
            raw_schema = json.load(file)
            schema_tables = list(
                Extractor.extract_tables(raw_schema, historical_table_def, ingestion_table_def, objectid_table_def))
            if not is_foundation:
                VirtualColumnGenerator.create_virtual_columns(schema_tables)
                assoc_tables = Extractor.extract_association_tables(schema_tables, MetadataReader.tables(True),
                                                                    historical_table_def, ingestion_table_def,
                                                                    objectid_table_def)
                schema_tables += assoc_tables
            print(f'Completed file {schema_file}')
            return schema_tables
