class ImportWorkers::MainWorker < ImportWorker
  def perform
    Wdpa::Importer.import
  ensure
    finalise_job
  end
end
