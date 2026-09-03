namespace :search do
  desc 'Reindex the full text search'
  task reindex: :environment do
    logger = Logger.new(STDOUT)
    notifier = SlackNotifier.new('search:reindex')
    notifier.phase('Manually triggered: reindexing full text search')

    logger.info "Deleting index..."
    Search::Index.delete
    logger.info "Populating index..."
    Search::Index.create
    logger.info "Clearing cache"
    Rake::Task['cache:clear'].invoke

    logger.info "Reindex complete."
    notifier.phase_complete('Manually triggered: Full text search reindex complete')
  end

  namespace :cms do
    desc 'Reindex CMS search'
    task reindex: :environment do
      logger = Logger.new(STDOUT)
      notifier = SlackNotifier.new('search:cms:reindex')
      notifier.phase('Manually triggered: reindexing CMS search')

      logger.info "Deleting index..."
      Search::Index.delete([Search::CMS_INDEX])
      logger.info "Populating index..."
      Search::Index.create_cms_fragments

      logger.info "Reindex complete."
      notifier.phase_complete('Manually triggered: CMS search reindex complete')
    end
  end
end
