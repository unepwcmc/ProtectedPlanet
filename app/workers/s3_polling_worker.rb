class S3PollingWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    last_import = ImportTools.last_import

    if last_import.nil? || Wdpa::S3.new_wdpa?(last_import.started_at)
      WdpaImportWorker.perform_async
    end
  end
end
