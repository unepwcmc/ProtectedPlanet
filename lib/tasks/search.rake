namespace :search do
  desc "Reindex the full text search"
  task reindex: :environment do
    logger = Logger.new(STDOUT)

    Elasticsearch::Client.new.delete_by_query(
      index: 'protected_areas', q: '*:*'
    )

    logger.info "Reindexing..."
    Search::Index.index_all
    logger.info "Reindex complete."
  end
end
