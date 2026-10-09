# Threads only -- clustered mode is off. Any library with its own thread pool
# should be sized to match this. See docs/known-issues.md on the missing request
# timeout and what going clustered would need.
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i
threads threads_count, threads_count

port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }

# Clustered mode. `preload_app!` is required with workers, and on_worker_boot
# must reconnect anything opened at boot -- Ruby cannot share connections across
# forked processes.
#
# workers ENV.fetch("WEB_CONCURRENCY") { 2 }
# preload_app!
# on_worker_boot do
#   ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
# end

# Lets `rails restart` restart puma.
plugin :tmp_restart
