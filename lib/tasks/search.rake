namespace :search do
  desc 'Reindex the full text search'
  task reindex: :environment do
    logger = Logger.new(STDOUT)

    Elasticsearch::Client.new.delete_by_query(
      index: 'protected_areas', q: '*:*'
    )

    logger.info "Indexing countries..."
    Search::Index.index Country.without_geometry.all
    logger.info "Indexing regions..."
    Search::Index.index Region.without_geometry.all

    logger.info "Indexing protected areas..."
    pa_relation = ProtectedArea.without_geometry.includes(
      [{:countries_for_index => :region_for_index}, :sub_locations, :designation, :iucn_category]
    )
    Search::ParallelIndexer.index pa_relation

    logger.info "Reindex complete."
  end
end
