namespace :db do
  desc "Lazily seed the database from an existing dump"
  task lazy_seed: :environment do
    logger = Logger.new(STDOUT)

    logger.info "Importing from PostgreSQL dump..."

    db_config = Rails.configuration.database_configuration[Rails.env]
    dump_path = Rails.root.join("lib", "data", "seeds", "pre_seeded_database.sql")

    command = []
    command << "PGPASSWORD=#{db_config["password"]}" if db_config["password"].present?
    command << "psql -d #{db_config["database"]} -U #{db_config["username"]} -h #{db_config["host"]} < #{dump_path.to_s}"

    if system(command.join(" "))
      logger.info "Done."
    end
  end
end
