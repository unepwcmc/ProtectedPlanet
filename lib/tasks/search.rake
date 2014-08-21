namespace :search do
  desc 'Reindex the full text search'
  task reindex: :environment do
    logger = Logger.new(STDOUT)

    logger.info "Emptying index."
    Search::Index.empty
    logger.info "Populating index."
    Search::Index.index_all

    logger.info "Reindex complete."
  end
end
