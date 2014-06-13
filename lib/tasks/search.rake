namespace :search do
  desc "Reindex the full text search"
  task reindex: :environment do
    logger = Logger.new(STDOUT)

    logger.info "Reindexing search...."

    DB = ActiveRecord::Base.connection
    DB.execute("REFRESH MATERIALIZED VIEW tsvector_search_documents")

    logger.info "Reindex complete."
  end
end
