class S3PollingWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    _, last_timestamp = Sidekiq.redis do |client|
      client.zrevrangebyscore(
        "#{Rails.application.secrets.redis['wdpa_imports_prefix']}:success",
        '+inf', '-inf',
        {withscores: true, limit: [0, 1]}
      )
    end

    if last_timestamp.nil? || Wdpa::S3.new_wdpa?(last_timestamp)
      WdpaImportWorker.perform_async
    end
  end
end
