module ImportTools
  class AlreadyRunningImportError < StandardError; end;

  def self.create_import
    Import.new
  end

  def self.current_import
    redis_handler = RedisHandler.new
    current_import_token = redis_handler.current_token

    current_import_token.present? ? Import.new(current_import_token) : nil
  end

  def self.last_import
    redis_handler = RedisHandler.new
    last_import_token = redis_handler.previous_imports.last

    last_import_token.present? ? Import.new(last_import_token) : nil
  end

  def self.dump_path
    Rails.root.join("lib", "data", "seeds", "pre_seeded_database.sql")
  end
end
