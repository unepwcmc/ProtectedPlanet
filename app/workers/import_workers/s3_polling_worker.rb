class ImportWorkers::S3PollingWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => :import, :backtrace => true

  def perform 
    last_import = ImportTools.last_import
    if last_import.nil? || Wdpa::S3.new_wdpa?(last_import.started_at)
      Rails.logger.info("Start ImportWorkers::S3PollingWorker.perform")
      create_import
    end
  end

  private

  def create_import
    begin
      ImportTools.create_import
      ImportWorkers::MainWorker.perform_async
    rescue ImportTools::AlreadyRunningImportError => e
      Rails.logger.warn("error occured during ImportWorkers::S3PollingWorker.create_import: #{e.message}")
      return
    end
  end
end
