class ImportTools::Import
  include Confirmable
  include ActiveToken
  token_domain 'wdpa_imports'

  attr_reader :completed

  def initialize token=nil
    self.token = token || Time.now.to_i

    unless token
      lock_import
      create_db
      self.use_import_db = true
    end
  end

  def use_import_db= import_db_on
    if import_db_on
      pg_handler.connect_to(db_name)
    else
      pg_handler.connect_to(Rails.configuration.database_configuration[Rails.env]['database'])
    end
  end

  def stop finalise=true
    swap_databases if finalise
    add_to_completed_imports
  ensure
    self.use_import_db = false
    unlock_import
  end

  def increase_total_jobs_count
    redis_handler.increase_property(token, :total_jobs)
  end

  def increase_completed_jobs_count
    all_jobs_completed = redis_handler.increase_property_and_compare(
      token, :completed_jobs, :total_jobs
    )

    self.completed = all_jobs_completed
  end

  def completed?
    completed
  end

  def started_at
    Time.at(token)
  end

  private
  attr_writer :completed

  def lock_import
    raise ImportTools::AlreadyRunningImportError unless redis_handler.lock(self.token)
  end

  def unlock_import
    redis_handler.unlock
  end

  def create_db
    pg_handler.create_database(db_name)
    pg_handler.seed
  end

  def swap_databases
    current_db_name = Rails.configuration.database_configuration[Rails.env]["database"]
    pg_handler.drop_database("#{current_db_name}_backup")
    pg_handler.rename_database(current_db_name, "#{current_db_name}_backup")
    pg_handler.rename_database(db_name, current_db_name)
  end

  def add_to_completed_imports
    redis_handler.add_to_previous_imports(self.token)
  end

  def db_name
    "import_db_#{self.token}"
  end

  def redis_handler
    @redis_handler ||= ImportTools::RedisHandler.new
  end

  def pg_handler
    @pg_handler ||= ImportTools::PostgresHandler.new
  end
end
