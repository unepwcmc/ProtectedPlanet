# Disabled unless Slack webhook URL is present because Bystander has no error handling in place
#
# The scene block below references autoloaded constants (Download, Search::Index).
# Under Rails 7.1 + Zeitwerk those are not resolvable while initializers run, so
# this raised `NameError: uninitialized constant Download` at boot. It only bit
# environments that actually set SLACK_WEBHOOK_URL, which is why it went unnoticed.
# after_initialize runs once, after autoloading is set up.
#
# `Bystander.scene` calls load_hooks, which REDEFINES the listed methods to wrap
# them in a Slack notification. So the actors here are not documentation -- every
# caller of these methods notifies #pp-bystander, wherever it is called from.
#
# The legacy WDPA S3 import was removed in Aug 2026 and its actors went with it
# (Wdpa::Release, Wdpa::SourceImporter, Wdpa::ProtectedAreaImporter and
# Wdpa::CountryGeometryPopulator). The whole ImportTools module, whose
# WebHandler#under_maintenance was also an actor here, was deleted in Sep 2026
# once nothing called it. What remains is still live: the
# portal release calls both Search::Index.create and Download.clear_downloads from
# app/services/portal_release/cleanup.rb, and `rake search:reindex` calls the former.
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
      end
    end
  end
end
