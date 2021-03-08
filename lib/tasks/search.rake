namespace :search do
  desc 'Reindex the full text search'
  task reindex: :environment do
    logger = Logger.new(STDOUT)

    logger.info "Deleting index..."
    Search::Index.delete
    logger.info "Populating index..."
    Search::Index.create
    logger.info "Clearing cache"
    Rake::Task['cache:clear'].invoke

    logger.info "Reindex complete."
  end

  namespace :cms do
    desc 'Reindex CMS search'
    task reindex: :environment do
      logger = Logger.new(STDOUT)

      logger.info "Deleting index..."
      Search::Index.delete([Search::CMS_INDEX])
      logger.info "Populating index..."
      Search::Index.create_cms_fragments

      logger.info "Reindex complete."
    end
  end
end
