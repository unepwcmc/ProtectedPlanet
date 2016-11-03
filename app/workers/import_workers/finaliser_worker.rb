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
    CmsTransfer.transfer
    ApiTransfer.transfer
    Download.make_current

    Search::Index.delete
    Search::Index.create

    Autocompletion.drop
    Autocompletion.populate

    #Geospatial::Calculator.calculate_statistics

    ImportTools::WebHandler.clear_cache
  end
end
