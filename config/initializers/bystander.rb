# Disabled unless Slack webhook URL is present because Bystander has no error handling in place
#
# The scene block below references autoloaded constants (Download, Search::Index,
# Wdpa::*, ImportTools::WebHandler). Under Rails 7.1 + Zeitwerk those are not
# resolvable while initializers run, so this raised
# `NameError: uninitialized constant Download` at boot. It only bit environments
# that actually set SLACK_WEBHOOK_URL, which is why it went unnoticed.
# after_initialize runs once, after autoloading is set up.
if ENV['SLACK_WEBHOOK_URL'].present?
  Bystander::Transports::Slack.configure do |slack|
    slack.username    'Bystander'
    slack.webhook_url  ENV['SLACK_WEBHOOK_URL']
    slack.channel     '#pp-bystander'

    slack.prepend     "#{ENV['RAILS_ENV']} - (##{Process.pid}):"
  end

  Rails.application.config.after_initialize do
    Bystander.scene('import') do
      actors do
        add Download
        add Search::Index, :indexer
        add Wdpa::Release, :release
        add Wdpa::SourceImporter, :source_importer
        add Wdpa::ProtectedAreaImporter, :pa_importer
        # As of 19Aug2025 CountryGeometryPopulator is not used as stats are now from NC team
        add Wdpa::CountryGeometryPopulator, :geometry_populator
        add ImportTools::WebHandler, :web_handler
      end

      acts do
        add :download, :clear_downloads, notify: :wrap
        add :indexer, :create, {
          notify: :wrap,
          heartbeat: {
            every: 10,
            block: -> { "Elements in index: #{Search::Index.count}" }
          },
          ensure: -> (return_value) {
            Search::Index.count == (ProtectedArea.count + Country.count)
          }
        }
        add :release, :download, notify: :wrap
        add :source_importer, :import, notify: :wrap
        add :pa_importer, :import, notify: :wrap

        add :web_handler, :under_maintenance, notify: :wrap
      end
    end
  end
end
