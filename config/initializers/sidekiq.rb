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
# browser. The capsule check gates it further: job_import
# (config/sidekiq-import.yml) declares no `pdf` capsule and must not start one,
# because nothing it runs rasterizes.
#
# The check sits INSIDE the :startup hook rather than out here so it reads the
# configuration the CLI actually loaded, whatever the parse/boot order is.
Sidekiq.configure_server do |config|
  config.on(:startup) do
    SharedChrome.start! if config.capsules.key?('pdf')
  end

  config.on(:shutdown) { SharedChrome.stop! }
end
