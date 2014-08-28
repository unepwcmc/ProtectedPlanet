namespace :search do
  desc 'Reindex the full text search'
  task reindex: :environment do
    logger = Logger.new(STDOUT)

    logger.info "Deleting index..."
    Search::Index.delete
    logger.info "Populating index..."
    Search::Index.create

    logger.info "Reindex complete."
  end
end
