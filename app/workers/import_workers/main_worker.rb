class ImportWorkers::MainWorker < ImportWorkers::Base
  def perform
    Wdpa::Importer.import
  ensure
    finalise_job
  end
end
