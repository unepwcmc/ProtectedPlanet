from postgres.postgresexecutor import PostgresExecutor
from mgmt_logging.logger import Logger
class SqlRunner():

    @staticmethod
    def execute(sql_file):
        with open(sql_file, 'r') as file:
            for line in file.readlines():
                if len(line.strip("\n")):
                    PostgresExecutor._cursor.execute(line)
                    Logger.get_logger().info(line)
