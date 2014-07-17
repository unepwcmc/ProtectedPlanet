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
    pg_handler = ImportTools::PostgresHandler.new
    pg_handler.with_db(db_name, block)
  end

  private
  attr_writer :id

  def lock_import
    redis_handler = ImportTools::RedisHandler.new
    raise ImportTools::AlreadyRunningImportError unless redis_handler.lock(self.id)
  end

  def create_db
    pg_handler = ImportTools::PostgresHandler.new
    pg_handler.create_database(db_name)
  end

  def db_name
    "import_db_#{self.id}"
  end
end
