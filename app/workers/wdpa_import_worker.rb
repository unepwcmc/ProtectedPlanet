class WdpaImportWorker
  @@REDIS_PREFIX = Rails.application.secrets.redis['wdpa_imports_prefix']
  @@LOCKING_KEY = "#{@@REDIS_PREFIX}:locking_key"

  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    return unless lock_import

    begin
      Wdpa::Importer.import
      log_success
    rescue => e
      log_failure(e)
    ensure
      unlock_import
    end
  end

  private

  def lock_import
    Sidekiq.redis{|client| client.setnx(@@LOCKING_KEY, Time.now.to_i)}
  end

  def unlock_import
    Sidekiq.redis{|client| client.del(@@LOCKING_KEY)}
  end

  def log_success
    success_key = "#{@@REDIS_PREFIX}:success"
    Sidekiq.redis do |client|
      client.zadd(
        success_key,
        Time.now.to_i,
        {message: 'Imported successfully'}.to_json
      )
    end
  end

  def log_failure error
    failure_key = "#{@@REDIS_PREFIX}:failure"
    Sidekiq.redis do |client|
      client.zadd(
        failure_key,
        Time.now.to_i,
        {message: error.message, backtrace: error.backtrace}.to_json
      )
    end
  end
end
