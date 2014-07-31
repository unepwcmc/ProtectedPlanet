class ImportWorkers::WdpaImportWorker < ImportWorker
  def perform
    ImportTools.current_import.with_context{ Wdpa::Importer.import }
  ensure
    finalise_job
  end
end
