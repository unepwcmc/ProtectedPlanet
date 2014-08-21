namespace :search do
  desc 'Reindex the full text search'
  task reindex: :environment do
    logger = Logger.new(STDOUT)

    logger.info "Dropping index."
    Search::Index.drop
    logger.info "Populating index."
    Search::Index.index_all

    logger.info "Reindex complete."
  end
end
