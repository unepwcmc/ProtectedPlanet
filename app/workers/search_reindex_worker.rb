# Scheduled nightly by sidekiq-cron (config/initializers/sidekiq.rb), replacing
# the old host crontab entry that ran `rake search:reindex` at 22:00. Mirrors
# that task's steps directly rather than shelling out to Rake.
class SearchReindexWorker
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: false, backtrace: true

  def perform
    notifier = SlackNotifier.new('search:reindex')
    notifier.reindex_started
    Search::Index.delete
    Search::Index.create
    notifier.reindex_complete
  end
end
