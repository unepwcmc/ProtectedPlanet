import time
from metadata_mgmt.metadatareader import MetadataReader
from mgmt_logging.logger import Logger
from postgres.postgresexecutor import PostgresExecutor


class LoaderFromStagingToMain:

	@staticmethod
	def process_individual_row(quarantine_table, target_table, row, quarantine_positions, target_positions, tolerances):
		quarantine_key = quarantine_table.primary_key()
		quarantine_vals = []
		for key in quarantine_key.column_names.split(","):
			pos = quarantine_positions[key]
			quarantine_vals.append(row[pos])
		target_key = target_table.primary_key()
		target_vals = []
		for key in target_key.column_names.split(","):
			pos = target_positions[key]
			target_vals.append(row[pos])
		if target_vals[0] is None:
			return "RowToAdd"
		if quarantine_vals[0] is None:
			if row[target_positions["IsDeleted"]] == 1:
				return "RowAlreadyDeleted"
			return "RowToDelete"
		for col in quarantine_table.columns():
			quarantine_pos = quarantine_positions[col.name]
			quarantine_val = row[quarantine_pos]
			target_pos = target_positions[col.name]
			target_val = row[target_pos]
			# apply toleranes here for numerical fields
			tolerance_to_apply = tolerances.get(quarantine_table.name) and tolerances.get(quarantine_table.name).get(col.name)
			if quarantine_val != target_val:
				return "RowToUpdate"
		return "Equal"

	def process_quarantine_rows(self, quarantine_table, target_table, originator_id, ingestion_id, time_of_creation, executor, tolerances, closed_universe):
		start_time = time.time()
		try:
			[rows, quarantine_positions, target_positions] = executor.construct_query_clause(quarantine_table, target_table, originator_id, closed_universe)
		except Exception as ex:
			print(str(ex))
			raise ex
		summary = {"add": 0, "equal": 0, "update": 0, "delete": 0, "already deleted": 0}
		for row in rows:
			action = self.process_individual_row(quarantine_table, target_table, row, quarantine_positions, target_positions, tolerances)
			match action:
				case "RowToAdd":
					executor.create_new_row(row, quarantine_table, quarantine_positions, target_table, originator_id, ingestion_id, time_of_creation)
					summary["add"] += 1
				case "Equal":
					summary["equal"] += 1
				case "RowToUpdate":
					executor.timestamp_existing_row(row, target_positions, target_table, time_of_creation)
					executor.create_new_row(row, quarantine_table, quarantine_positions, target_table, originator_id, ingestion_id, time_of_creation)
					summary["update"] += 1
				case "RowToDelete":
					executor.timestamp_existing_row(row, target_positions, target_table, time_of_creation)
					executor.create_deleted_row(row, target_table, target_positions, originator_id, ingestion_id, time_of_creation)
					summary["delete"] += 1
				case "RowAlreadyDeleted":
					summary["already deleted"] += 1
				case _:
					Logger.get_logger().info("Not yet implemented")
		duration = time.time() - start_time
		if rows:
			print(f'Time per row is {duration/len(rows)}')
		Logger.get_logger().info(f'Row count was {len(rows)}')
		Logger.get_logger().info(summary)
		return summary


	def ingest_standard(self, executor: PostgresExecutor, originator_ids, tables_to_process, time_of_creation, data_group, driving_table=None, tolerances=None):
		if tolerances is None:
			tolerances = {}
		total_schema = MetadataReader.tables(force=True)
		if time_of_creation == "Now":
			time_of_creation = executor.get_time_from_database()
		# if we are called with an empty array of originator ids, this is a migration so we assume a closed universe
		closed_universe = not originator_ids

		if driving_table is not None:
			originator_ids = executor.get_staging_data_originators(driving_table)
		ingestion_id = executor.get_next_ingestion_id()
		for originator_id in originator_ids:
			executor.begin_transaction(executor._conn)
			print(f"Processing for originator {originator_id}")
			Logger.get_logger().info(f"Processing for originator {originator_id}")
			try:
				for table_name in tables_to_process:
					quarantine_table = total_schema["staging_" + table_name]
					target_table = total_schema[table_name]
					self.process_quarantine_rows(quarantine_table, target_table, originator_id, ingestion_id, time_of_creation, executor, tolerances, closed_universe)
			except Exception as e:
				print(str(e))
				executor.rollback()
				raise e
			else:
				executor.end_transaction()
		executor.begin_transaction(executor._conn)
		ingestion_provider_ids = originator_ids or [10000]
		executor.add_ingestion(ingestion_provider_ids, ingestion_id, time_of_creation, data_group)
		executor.end_transaction()
