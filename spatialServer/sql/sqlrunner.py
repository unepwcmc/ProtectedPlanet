class SqlRunner:

    @staticmethod
    def execute_line(cursor, line: str):
        try:
            cursor.execute(line.strip())
            return True
        except Exception as e:
            print(str(e))
            return False

    @staticmethod
    def execute(cursor, sql_file):
        with open(sql_file, 'r') as file:
            line_to_execute = ''
            for line in file.readlines():
                if len(line.strip("\n")) and "/*" not in line:
                    trimmed_line = line.strip('\n')
                    line_to_execute += line
                    if trimmed_line.endswith(';'):
                        print( f'[Executing] -> {line_to_execute}')
                        SqlRunner.execute_line(cursor, line_to_execute)
                        line_to_execute = ''
        print('Completed')
