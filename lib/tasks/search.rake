namespace :search do
  desc "Reindex the full text search"
  task reindex: :environment do
    logger = Logger.new(STDOUT)

    Elasticsearch::Client.new.delete_by_query(
      index: 'protected_areas', q: '*:*'
    )

    [Country, Region, ProtectedArea].each do |model|
      logger.info "Reindexing #{model}...."
      Search::Index.index model.without_geometry
    end

    logger.info "Reindex complete."
  end
end
