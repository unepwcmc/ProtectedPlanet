import psycopg2

class PostgresConnection:

    connection = None

    @classmethod
    def get_connection(cls):
        #create the connection initially or recreate it if it has closed since last used
        #classmethod so this is a singleton
        if cls.connection is None or (cls.connection.closed != 0):
            print("Opening connection")
            cls.connection = psycopg2.connect("dbname=WDPA user=postgres password=WCMC%1")
        return cls.connection

    @classmethod
    def get_cursor(cls):
        return cls.get_connection().cursor()

