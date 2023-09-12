from mgmt_logging.logger import Logger


class SqlRunner:

    @staticmethod
    def execute_line(cursor, line: str):
        try:
            cursor.execute(line.strip())
        except Exception as e:
            print(str(e))
        else:
            Logger.get_logger().info(line)

    @staticmethod
    def execute(cursor, sql_file):
        with open(sql_file, 'r') as file:
            for line in file.readlines():
                if len(line.strip("\n")) and "/*" not in line:
                    print(f'Executing {line}')
                    SqlRunner.execute_line(cursor, line)

    @staticmethod
    def execute_file_with_substitution(cursor, sql_file, replacement_dictionary):
        with open(sql_file, 'r') as file:
            for line in file.readlines():
                if len(line.strip("\n")) and "/*" not in line:
                    for token, value in replacement_dictionary.items():
                        line = line.replace(token, value)
                    print(f'Executing {line}')
                    SqlRunner.execute_line(cursor, line)
