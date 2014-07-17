class WdpaImportWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    return unless ImportTools.create_import

    begin
      Wdpa::Importer.import
    rescue => e
      # ImportTools.abort_import
    end
  end
end
