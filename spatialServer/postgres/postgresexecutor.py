class PostgresExecutor:
    _read_cursor = None
    _read_cursor_open_count = 0
    _read_cursor_close_count = 0
    _write_cursor = None
    _write_cursor_open_count = 0
    _write_cursor_close_count = 0
    _foreign_key_cursor = None
    _foreign_key_cursor_open_count = 0
    _conn = None

    @classmethod
    def get_next_ingestion_id(cls):
        sql = 'SELECT MAX(ingestion_id) FROM INGESTION_HISTORY'
        cls._read_cursor.execute(sql)
        rows = cls._read_cursor.fetchall()
        max_used = rows[0][0] or 0
        return max_used + 1

    @classmethod
    def set_connection(cls, conn):
        cls._conn = conn

    @classmethod
    def open_read_cursor(cls):
        if cls._read_cursor is None or cls._read_cursor.closed:
            cls._read_cursor = cls._conn.cursor()
            cls._read_cursor_open_count += 1
        return cls._read_cursor

    @classmethod
    def close_read_cursor(cls):
        if cls._read_cursor is not None:
            cls._read_cursor.close()
            cls._read_cursor_close_count += 1
            cls._read_cursor = None

    @classmethod
    def begin_transaction(cls):
        if cls._write_cursor is None or cls._write_cursor.closed:
            cls._write_cursor = cls._conn.cursor()
            cls._write_cursor_open_count += 1
        cls._write_cursor.execute("BEGIN TRANSACTION")
        return cls._write_cursor

    @classmethod
    def end_transaction(cls):
        if cls._write_cursor is not None:
            cls._write_cursor.execute("COMMIT")
            cls._write_cursor.close()
            cls._write_cursor_close_count += 1
            cls._write_cursor = None

    @classmethod
    def rollback(cls):
        if cls._write_cursor is not None:
            cls._write_cursor.execute("ROLLBACK")
            cls._write_cursor.close()
            cls._write_cursor_close_count += 1
            cls._write_cursor = None
        if cls._read_cursor is not None:
            cls._read_cursor.close()
            cls._read_cursor = None
            cls._read_cursor_close_count += 1
