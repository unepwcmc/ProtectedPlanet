namespace :cache do
  desc "Clear the Rails cache (Home page, PA Page)"
  task clear: :environment do
    logger = Logger.new(STDOUT)

    logger.info "Clearing cache..."

    Rails.cache.clear

    logger.info "Done."
  end
end
