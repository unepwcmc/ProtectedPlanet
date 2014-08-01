namespace :search do
  desc "Reindex the full text search"
  task reindex: :environment do
    logger = Logger.new(STDOUT)

    logger.info "Reindexing search...."
    Search.reindex
    logger.info "Reindex complete."
  end
end
