class ImportWorkers::FinaliserWorker
  include Sidekiq::Worker

  def perform
    ImportTools::WebHandler.under_maintenance do
      finalise_import
      clear_cache
    end
  end

  private

  def finalise_import
    import = ImportTools.current_import
    import.finalise
  end

  def clear_cache
    ImportTools::WebHandler.clear_cache
  end
end
