class ImportWorkers::FinaliserWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => :import, :backtrace => true

  @@can_be_started = false
  cattr_accessor :can_be_started

  def perform
    ImportTools::WebHandler.under_maintenance do
      finalise_import
      refresh_data
    end
  ensure
    self.class.can_be_started = false
  end

  private

  def finalise_import
    import = ImportTools.current_import
    import.stop
  end

  def refresh_data
    # Transfer tables from previous database that
    # we can't get from the WDPA
    CmsTransfer.transfer
    ApiTransfer.transfer
    ActiveStorageTransfer.transfer

    # Clear the redis cache and delete all downloads
    # from the S3 bucket. This will trigger the generation
    # of new downloads, every time a user asks for one.
    Download.clear_downloads

    Search::Index.delete
    Search::Index.create
    
    # Here for historical reasons. Country stats are no more generated
    # dynamically, but received by the PA programme every month.
    # Geospatial::Calculator.calculate_statistics

    ImportTools::WebHandler.clear_cache
  end
end
