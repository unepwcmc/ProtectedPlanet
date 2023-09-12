import gc
import time
import traceback

from metadata_mgmt.metadatareader import MetadataReader
from mgmt_logging.logger import Logger
from postgres.postgresexecutor import PostgresExecutor
from schema_management.ingestionstats import IngestionStats
from schema_management.ingestor import Ingestor
from schema_management.ingestorconstants import IngestorConstants
from runtime_mgmt.datagroupmanager import DataGroupManager
from schema_management.memorymanager import MemoryManager

ALL_NUMERICAL = "all numerical"
TIME_OF_CREATION_NOW = "Now"


class LoaderFromStagingToMain:

    def __init__(self, data_group):
        self.data_group = data_group

    @staticmethod
    def process_individual_row(row, quarantine_positions, tolerances):
        try:
            # if there's no row in the main table, this is an add
            if row[len(quarantine_positions)] is None:
                return "RowToAdd"
            # if there's no row in the staging table, this is a delete operation
            if row[0] is None:
                return "RowToDelete"
            # must therefore be an update
            tolerance_to_apply = tolerances.get(ALL_NUMERICAL)
            for i in range(1, len(quarantine_positions)):
                quarantine_val = row[i]
                if type(quarantine_val) == bool:
                    if not quarantine_val:
                        return "RowToUpdate"
                elif isinstance(quarantine_val, (float, int)):
                    if quarantine_val > tolerance_to_apply:
                        return "RowToUpdate"
                else:
                    raise Exception("What are we looking at?")
            return "Equal"
        except Exception as ex:
            print(str(ex))
            raise ex

    def process_quarantine_rows(self, quarantine_table, target_table, originator_id, ingestion_id, time_of_creation,
                                executor, tolerances, closed_universe) -> IngestionStats:
        chunk_size = 10000
        start_time = time.time()
        try:
            PostgresExecutor.open_read_cursor()
            [quarantine_positions, target_positions] = executor.construct_query_clause(quarantine_table,
                                                                                       target_table,
                                                                                       originator_id,
                                                                                       closed_universe)
            summary = IngestionStats()
            total_rows = 0
            while True:
                # use a read cursor to get the chunks and a
                # separate write cursor to write out the added, updated and deleted rows
                rows = executor.get_row_chunk(chunk_size)
                if not rows:
                    break
                executor.begin_transaction()
                for row in rows:
                    action = self.process_individual_row(row, quarantine_positions, tolerances)
                    if action == "RowToAdd":
                        executor.create_new_row(row, quarantine_table, quarantine_positions, target_table,
                                                ingestion_id, time_of_creation)
                        summary.increment_add()
                    elif action == "Equal":
                        summary.increment_equal()
                    elif action == "RowToUpdate":
                        executor.timestamp_existing_row(row, target_positions, target_table, time_of_creation)
                        executor.create_new_row(row, quarantine_table, quarantine_positions, target_table,
                                                ingestion_id, time_of_creation)
                        summary.increment_update()
                    elif action == "RowToDelete":
                        executor.timestamp_existing_row(row, target_positions, target_table, time_of_creation)
                        executor.create_deleted_row(row, target_table, target_positions,
                                                    ingestion_id,
                                                    time_of_creation)
                        summary.increment_deleted()
                    elif action == "RowAlreadyDeleted":
                        summary.increment_already_deleted()
                    else:
                        Logger.get_logger().info("Not yet implemented")
                    total_rows += 1
                executor.end_transaction()
                gc.collect()
            MemoryManager.output_memory(f'After {total_rows} rows: ')
            duration = time.time() - start_time
            if total_rows:
                log_info = f'Time per row [{target_table.name}:{total_rows} rows] is {duration / total_rows}'
                print(log_info)
                Logger.get_logger().info(log_info)
            Logger.get_logger().info(summary)
            return summary
        except Exception as ex:
            print("Exception raised in staging data promoter")
            print(str(ex))
            traceback.print_exc(limit=None, file=None, chain=True)
            raise ex
        finally:
            PostgresExecutor.close_read_cursor()

    def ingest_standard(self, executor: PostgresExecutor, time_of_creation, tables_to_process: list[str],
                        tolerances={ALL_NUMERICAL: 1e-3}, closed_universe=False):
        executor.open_read_cursor()
        total_schema = MetadataReader.tables(force=True)
        driving_table = tables_to_process[0]
        if time_of_creation == TIME_OF_CREATION_NOW:
            time_of_creation = executor.get_time_from_database()
        # if we are called with an empty array of originator ids, this is a migration, so we assume a closed universe
        if DataGroupManager.is_loaded_by_WCMC(self.data_group):
            originator_ids = [10000]
        else:
            originator_ids = executor.get_staging_data_originators(driving_table)
        ingestion_id = Ingestor.get_next_ingestion_id(executor)
        MemoryManager.output_memory("Starting ingestion")
        PostgresExecutor.close_read_cursor()
        stats = {}
        for originator_id in originator_ids:
            print(f"Processing for originator {originator_id}")
            Logger.get_logger().info(f"Processing for originator {originator_id}")
            try:
                for table_name in tables_to_process:
                    quarantine_table = total_schema["stg_" + table_name]
                    target_table = total_schema[table_name]
                    summary = self.process_quarantine_rows(quarantine_table, target_table, originator_id, ingestion_id,
                                                           time_of_creation, executor, tolerances, closed_universe)
                    if table_name == driving_table or not driving_table:
                        stats[originator_id] = summary
                MemoryManager.output_memory(f"After originator {originator_id}")
            except Exception as e:
                print(str(e))
                executor.rollback()
                return
        Logger.get_logger().info("Adding ingestion information")
        executor.begin_transaction()
        ingestion_provider_ids = originator_ids or [IngestorConstants.WCMC_SPECIAL_PROVIDER_ID]
        Ingestor.add_ingestion(executor, ingestion_provider_ids, ingestion_id, time_of_creation, self.data_group, stats)
        executor.end_transaction()
