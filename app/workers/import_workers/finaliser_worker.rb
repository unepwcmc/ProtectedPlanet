class ImportWorkers::FinaliserWorker
  include Sidekiq::Worker

  def perform
    import = ImportTools.current_import
    import.finalise
  end

  private

  def clear_cache
  end
end
