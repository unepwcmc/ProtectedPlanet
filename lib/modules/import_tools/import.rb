class ImportTools::Import
  attr_reader :id

  def initialize id=nil
    self.id = id || Time.now.to_i

    unless id
      lock_import
      create_db
    end
  end

  def self.find id
    self.new id
  end

  def with_context &block
    pg_handler.with_db(db_name, &block)
  end

  def started_at
    Time.at(self.id)
  end

  def increase_total_jobs_count
    redis_handler.increase_total_jobs_count(self.id)
  end

  def increase_completed_jobs_count
    redis_handler.increase_completed_jobs_count(self.id)
  end

  private
  attr_writer :id

  def lock_import
    raise ImportTools::AlreadyRunningImportError unless redis_handler.lock(self.id)
  end

  def create_db
    pg_handler.create_database(db_name)
  end

  def db_name
    "import_db_#{self.id}"
  end

  def redis_handler
    @redis_handler ||= ImportTools::RedisHandler.new
  end

  def pg_handler
    @pg_handler ||= ImportTools::PostgresHandler.new
  end
end
