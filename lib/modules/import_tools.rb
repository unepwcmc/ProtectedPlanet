module ImportTools
  class AlreadyRunningImportError < StandardError; end;

  def self.create_import
    Import.new
  end

  def self.current_import
    redis_handler = RedisHandler.new
    current_import_id = redis_handler.current_id

    current_import_id.present? ? Import.find(current_import_id) : nil
  end

  def self.last_import
    redis_handler = RedisHandler.new
    last_import_id = redis_handler.previous_ids.last

    last_import_id.present? ? Import.find(last_import_id) : nil
  end
end
