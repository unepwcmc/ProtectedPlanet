module ImportTools
  class AlreadyRunningImportError < StandardError; end;

  def self.create_import
    Import.new
  end

  def self.current_import
    redis_handler = RedisHandler.new
    import_id = redis_handler.current_import_id

    import_id.present? ? Import.find(import_id) : nil
  end
end
