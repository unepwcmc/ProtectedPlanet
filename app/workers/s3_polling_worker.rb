class S3PollingWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    WdpaImportWorker.perform_async if no_last_import_or_new_wdpa?(last_import)
  end

  private

  def last_import
    Sidekiq.redis do |client|
      client.zrevrangebyscore(
        "#{Rails.application.secrets.redis['wdpa_imports_prefix']}:success",
        '+inf', '-inf',
        {withscores: true, limit: [0, 1]}
      )
    end
  end

  def no_last_import_or_new_wdpa? import
    last_timestamp = import.last
    last_time = Time.strptime(last_timestamp, '%s') if last_timestamp

    last_timestamp.nil? || Wdpa::S3.new_wdpa?(last_time)
  end
end
