class ImportWorkers::FinaliserWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    ImportTools::WebHandler.under_maintenance do
      finalise_import
      refresh_data
    end
  end

  private

  def finalise_import
    import = ImportTools.current_import
    import.finalise
  end

  def refresh_data
    Search.reindex
    Download.make_current
    ImportTools::WebHandler.clear_cache
  end
end
