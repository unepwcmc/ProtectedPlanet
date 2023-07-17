from postgres.postgresexecutor import PostgresExecutor
from mgmt_logging.logger import Logger


class SqlRunner:

    @staticmethod
    def execute(sql_file, cursor):
        with open(sql_file, 'r') as file:
            for line in file.readlines():
                if len(line.strip("\n")) and "/*" not in line:
                    print(f'Executing {line}')
                    try:
                        cursor.execute(line.strip())
                    except Exception as e:
                        print(str(e))
                    else:
                        Logger.get_logger().info(line)
