require 'rake'

class ImportTools::PostgresHandler
  attr_reader :current_conn_values

  def initialize
    self.current_conn_values = ActiveRecord::Base.configurations[Rails.env]
  end

  def connect_to db_name
    pg_conn_values = current_conn_values.merge('database' => db_name)
    ActiveRecord::Base.establish_connection pg_conn_values
    ActiveRecord::Base.connection
  end

  def create_database database_name
    connection = connect_to('postgres')
    connection.create_database(database_name)

    connect_to(database_name)
    Rails.application.load_tasks
    Rake::Task['db:migrate'].invoke
  end

  def drop_database database_name
    close_connections_to(database_name)
    connection = connect_to('postgres')
    connection.drop_database(database_name)
  end

  def rename_database database_name, new_database_name
    close_connections_to(database_name)

    query = "ALTER DATABASE #{database_name} RENAME TO #{new_database_name}"
    connection = connect_to('postgres')
    connection.execute(query)
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

    connection = connect_to('postgres')
    connection.execute(query)
  end
end
