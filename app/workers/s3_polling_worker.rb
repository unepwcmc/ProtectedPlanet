class S3PollingWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => :import, :backtrace => true

  def perform
    last_import = ImportTools.last_import

    if last_import.nil? || Wdpa::S3.new_wdpa?(last_import.started_at)
      create_import
      send_confirmation_email last_import
    end
  end

  private

  def send_confirmation_email import
    ImportConfirmationMailer.create(import)
  end

  def create_import
    begin
      ImportTools.create_import
    rescue ImportTools::AlreadyRunningImportError
      return
    end
  end
end
