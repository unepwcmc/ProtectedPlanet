namespace :cache do
  desc "Clear the Rails cache (everything except downloads which is handled by Redis)"
  task clear: :environment do
    abort('Aborting: Rails cache is nil') if Rails.cache.nil?

    logger = Logger.new(STDOUT)

    logger.info "Clearing cache..."

    Rails.cache.clear

    logger.info "Done."
  end
end
