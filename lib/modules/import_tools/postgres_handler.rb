class ImportTools::PostgresHandler
  attr_reader :current_conn_values

  def initialize
    self.current_conn_values = ActiveRecord::Base.configurations[Rails.env]
  end

  def with_db db_name, &block
    pg_conn_values = current_conn_values.merge('database' => db_name)
    ActiveRecord::Base.establish_connection pg_conn_values
    block.call(ActiveRecord::Base.connection)
  ensure
    ActiveRecord::Base.establish_connection current_conn_values
  end

  def create_database database_name
    with_db('postgres') { |connection| connection.create_database(database_name) }
  end

  def drop_database database_name
    close_connections_to(database_name)
    with_db('postgres') { |connection| connection.drop_database(database_name) }
  end

  def rename_database database_name, new_database_name
    query = "ALTER DATABASE #{database_name} RENAME TO #{new_database_name}"

    close_connections_to(database_name)
    with_db('postgres') { |connection| connection.execute(query) }
  end

  def seed database_name, dump_path
    pg_password = current_conn_values['password']
    command = []

    command << "PGPASSWORD=#{pg_password}" if pg_password.present?
    command << """
      psql -d #{database_name}
           -U #{current_conn_values['username']}
           -h #{current_conn_values['host']}
      < #{dump_path.to_s}
    """.squish

    system(command.join(" "))
  end

  private
  attr_writer :current_conn_values

  def close_connections_to database_name
    query = """
      SELECT pg_terminate_backend(pg_stat_activity.pid)
      FROM pg_stat_activity
      WHERE pg_stat_activity.datname = '#{database_name}'
        AND pid <> pg_backend_pid();
    """.squish
    with_db('postgres') { |connection| connection.execute(query) }
  end
end

