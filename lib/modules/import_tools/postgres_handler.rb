class ImportTools::PostgresHandler
  attr_reader :current_conn_values

  def initialize
    self.current_conn_values = ActiveRecord::Base.configurations[Rails.env]
  end

  def with_db db_name, &block
    pg_conn_values = self.current_conn_values.merge('database' => db_name)
    ActiveRecord::Base.establish_connection pg_conn_values
    block.call(ActiveRecord::Base.connection)
  ensure
    ActiveRecord::Base.establish_connection self.current_conn_values
  end

  def create_database database_name
    with_db('postgres') { |connection| connection.create_database(database_name) }
  end

  def drop_database database_name
    with_db('postgres') { |connection| connection.drop_database(database_name) }
  end


  private
  attr_writer :current_conn_values
end

