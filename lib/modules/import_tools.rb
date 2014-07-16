module ImportTools
  def self.with_db db_name
    pg_handler = PostgresHandler.new

    pg_handler.create_database(db_name)
    pg_handler.with_db(db_name, &Proc.new)
  end
end
