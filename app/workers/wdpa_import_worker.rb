class WdpaImportWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    begin
      import = ImportTools.create_import
    rescue ImportTools::AlreadyRunningImportError
      return
    end

    import.with_context do
      Wdpa::Importer.import
    end
  end
end
