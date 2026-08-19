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
