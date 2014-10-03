class ImportWorkers::FinaliserWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => :import

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
    import.finalise
  end

  def refresh_data
    Search::Index.delete
    Search::Index.create

    Geospatial::Calculator.calculate_statistics
    Download.make_current
    ImportTools::WebHandler.clear_cache
  end
end
