namespace :db do
  desc "Lazily seed the database from an existing dump"
  task lazy_seed: :environment do
    logger = Logger.new(STDOUT)

    logger.info "Importing seeds from PostgreSQL dump..."

    db_config = Rails.configuration.database_configuration[Rails.env]
    dump_path = Rails.root.join("lib", "data", "seeds", "pre_seeded_database.sql")

    pg_handler = ImportTools::PostgresHandler.new
    sucessfully_seeded = pg_handler.seed(db_config['database'], dump_path)

    logger.info('Done.') if sucessfully_seeded
  end

  namespace :test do
    task prepare: :environment do
      Rake::Task["db:seed"].invoke
    end
  end
end
