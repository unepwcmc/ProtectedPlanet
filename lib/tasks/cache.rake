namespace :cache do
  desc "Clear the Rails cache (everything except downloads which is handled by Redis)"
  task :clear do
    logger = Logger.new(STDOUT)

    logger.info "Clearing cache..."

    abort('Aborting: Rails cache is nil') if Rails.cache.nil?
    Rails.cache.clear

    logger.info "Done."
  end
end
