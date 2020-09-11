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

    Rails.logger.info("===CONNECTED TO POSTGRES===")
    Rails.logger.info("===DB CONFIGS===")
    Rails.logger.info(ActiveRecord::Base.configurations)
    Rails.logger.info(Rails.configuration.database_configuration)
    Rails.logger.info(ActiveRecord::Base.connection.current_database)
    Rails.logger.info(ProtectedArea.connection.current_database)
    Rails.logger.info(ProtectedArea.column_names)
    Rails.logger.info("===DB CONFIGS===")

    connect_to(database_name)
    Rails.application.load_tasks

    Rails.logger.info("===CONNECTED TO NEW IMPORT DB===")
    Rails.logger.info("===DB CONFIGS===")
    Rails.logger.info(ActiveRecord::Base.configurations)
    Rails.logger.info(Rails.configuration.database_configuration)
    Rails.logger.info(ActiveRecord::Base.connection.current_database)
    Rails.logger.info(ProtectedArea.connection.current_database)
    Rails.logger.info(ProtectedArea.column_names)
    Rails.logger.info("===DB CONFIGS===")

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

  def seed
    Rake::Task['db:seed'].invoke
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
