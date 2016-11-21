Bystander::Transports::Slack.configure do |slack|
  slack.username    'Bystander'
  slack.webhook_url  ENV['SLACK_WEBHOOK_URL']
  slack.channel     '#pp-bystander'

  slack.prepend     "#{ENV['RAILS_ENV']} - (##{Process.pid}):"
end

Bystander.scene('import') do
  actors do
    add Download
    add Search::Index, :indexer
    add Wdpa::Release, :release
    add Wdpa::SourceImporter, :source_importer
    add Wdpa::ProtectedAreaImporter, :pa_importer
    add Wdpa::DownloadGenerator, :download_generator
    add Wdpa::CountryGeometryPopulator, :geometry_populator
    add ImportTools::WebHandler, :web_handler
  end

  acts do
    add :download, :make_current, notify: :wrap
    add :indexer, :create, {
      notify: :wrap,
      heartbeat: {
        every: 10,
        block: -> { "Elements in index: #{Search::Index.count}" }
      },
      ensure: -> (return_value) {
        Search::Index.count == (ProtectedArea.count + Country.count + Region.count)
      }
    }
    add :release, :download, notify: :wrap
    add :source_importer, :import, notify: :wrap
    add :pa_importer, :import, notify: :wrap
    add :download_generator, :generate, notify: :wrap

    add :web_handler, :under_maintenance, notify: :wrap
  end
end
