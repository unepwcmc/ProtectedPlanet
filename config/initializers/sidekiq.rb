# Both halves are configured on purpose. configure_server covers the Sidekiq
# process; configure_client covers Puma (and rails runner / rake), which is what
# actually pushes jobs. Previously only the server was configured and the client
# fell back to Sidekiq's own ENV["REDIS_URL"] default -- harmless while both
# resolved to the same URL, but PPRedis now pins a logical database, and a client
# still reading the raw URL would enqueue into database 0 while the server polled
# database 3. Jobs would vanish exactly as they did when the co-located apps were
# stealing them. See config/initializers/redis.rb.
%i[configure_server configure_client].each do |half|
  Sidekiq.public_send(half) do |config|
    config.redis = { url: PPRedis.url }
  end
end

# The `pdf` capsule renders in a long-lived shared Chrome. Ruby owns its
# lifetime (lib/modules/shared_chrome.rb) rather than a bash wrapper around the
# container command, so the browser is a child of this process and gets reaped,
# and the container command stays a plain `bundle exec sidekiq`.
#
# configure_server only yields in a Sidekiq process, so Puma never starts a
# browser. The capsule check gates it further: only a config declaring a `pdf`
# capsule starts a browser, so any other Sidekiq role never does.
#
# The check sits INSIDE the :startup hook rather than out here so it reads the
# configuration the CLI actually loaded, whatever the parse/boot order is.
Sidekiq.configure_server do |config|
  config.on(:startup) do
    SharedChrome.start! if config.capsules.key?('pdf')

    # sidekiq-cron stores the schedule in Redis, so re-syncing it on every boot
    # is idempotent even across the job role's multiple replicas / deploys.
    #
    # Not scheduled in dev/test at all. To test the cron wiring itself, temporarily
    # hardcode a short cron string below (e.g. '*/3 * * * *') and revert it after.
    search_reindex_cron =
      if Rails.env.production?
        '0 22 * * *' # Every night at 22:00
      elsif Rails.env.staging?
        '0 22 * * 1' # Every Monday at 22:00
      # For dev mode comment it out if no need for testing the feature
      # elsif Rails.env.development?
      #   '*/3 * * * *' # Every 3 mins
      end

    if search_reindex_cron
      Sidekiq::Cron::Job.load_from_hash(
        'search_reindex' => {
          'cron' => search_reindex_cron,
          'class' => 'SearchReindexWorker'
        }
      )
    else
      # load_from_hash only adds/updates -- it never removes a job that's no
      # longer in the hash. Without this, toggling the dev schedule on and off
      # leaves the old cron entry alive in Redis, still firing on its own.
      Sidekiq::Cron::Job.find('search_reindex')&.destroy
    end
  end

  config.on(:shutdown) { SharedChrome.stop! }
end
