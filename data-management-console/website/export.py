import sys

import psycopg2

from filtering_logic.blockregistry import BlockRegistry
from filtering_logic.datablockfactory import DataBlockFactory
from filtering_logic.selectionengine import SelectionEngine
from metadata_mgmt.metadatareader import MetadataReader
from postgres.postgresexecutor import PostgresExecutor
from runtime_mgmt.datagroupmanager import DataGroupManager
from schema_management.extractor import Extractor


def connection_string():
    connection_str = f"dbname={dbname} user={username} password={password} host={hostname}"
    print(connection_str)
    return connection_str



def export_to_csv(category):
    with psycopg2.connect(connection_string()) as conn:
        query_text = f"path={category}&&fields={category}:id,description"
        PostgresExecutor.set_connection(conn)
        tables = MetadataReader.tables()
        BlockRegistry.reset()
        # register each table name as a simple datablock
        # also register any association tables as associationdatablock
        for table in tables.keys():
            DataBlockFactory.create_simple_block(table)
            association_table_names, target_table_names = Extractor.extract_association_and_target_table_names(
                table, tables)
            for association_table_name, target_table_name in zip(association_table_names, target_table_names):
                # usually, for the forward order e.g. wdpa.iso3, we have the virtual columns
                # most queries are of the backward form iso3[code='BEL'].wdpa.  This may not
                DataBlockFactory.create_compound_block([table, target_table_name],
                                                       [association_table_name, target_table_name])
                DataBlockFactory.create_compound_block([target_table_name, table], [association_table_name, table])

        se = SelectionEngine()
        output = se.process_query(query_text)
        data = output["data"]
        f = open(f"c:\\users\warrens\\python\\{category}.csv", "w", encoding="utf-8")
        f.write("id,description\n")
        for data_item in data:
            id = data_item["id"]
            desc = data_item["description"]
            f.write(f"{id}, {desc}\n")
        f.close()

DataGroupManager.parameterize('../json/data_group.json')
if len(sys.argv) >= 2:
    port = int(sys.argv[1])
else:
    port = 8080

if len(sys.argv) >= 3:
    username = sys.argv[2]
else:
    username = "postgres"

if len(sys.argv) >= 4:
    dbname = sys.argv[3]
else:
    dbname = "WDPA"

if len(sys.argv) >= 5:
    hostname = sys.argv[4]
else:
    hostname = "127.0.0.1"

if len(sys.argv) >= 6:
    password = sys.argv[5]
else:
    password = "WCMC%1"

for category in ["designation_status", "orig_designation_status"]:
    export_to_csv(category)