namespace :portal_importer do
  def refresh_materialized_views
    puts 'Refreshing materialized views...'
    puts 'This will create unique indexes and refresh all portal views with latest data.'

    begin
      Wdpa::Portal::Utils::ViewManager.refresh_materialized_views
      puts '✅ Materialized views refreshed successfully'
      puts '✅ All views now have latest data and concurrent refresh is enabled'
    rescue StandardError => e
      puts "❌ Failed to refresh materialized views: #{e.message}"
      puts '💡 Check that the materialized views exist and are accessible'
      raise e
    end
  end

  desc 'Create staging tables'
  task create_staging: :environment do
    puts 'Creating staging tables...'

    begin
      Wdpa::Portal::Utils::StagingTableManager.create_staging_tables
      puts "✅ Staging tables created: #{Wdpa::Portal::Config::StagingConfig.staging_tables.join(', ')}"
    rescue StandardError => e
      puts "❌ Failed to create staging tables: #{e.message}"
      puts '🔄 Rolling back any partially created tables...'

      # Force cleanup to ensure system is in clean state
      Wdpa::Portal::Utils::StagingTableManager.drop_staging_tables
      puts '✅ Rollback completed - all staging tables removed'

      # Re-raise the error for proper error handling
      raise e
    end
  end

  desc 'Refresh materialized views (creates indexes and refreshes data)'
  task refresh_materialized_views: :environment do
    refresh_materialized_views
  end

  desc 'Drop staging tables'
  task drop_staging: :environment do
    puts 'Dropping staging tables...'
    Wdpa::Portal::Utils::StagingTableManager.drop_staging_tables
    puts 'Staging tables dropped'
  end

  desc 'Portal importer'
  task import: :environment do
    puts 'start importing portal data'

    begin
      puts '🏗️ Creating staging tables...'
      Wdpa::Portal::Utils::StagingTableManager.create_staging_tables
      puts '✅ Staging tables created'

      puts ''
      puts '🔄 Refreshing materialized views...'
      refresh_materialized_views

      puts ''
      puts '🚀 Running Portal Importer...'
      puts '=============================='

      # Run the portal importer (skip view refresh since we already did it)
      results = Wdpa::Portal::Importer.import(refresh_materialized_views: false)

      puts ''
      puts '📊 Import Results:'
      puts '=================='

      # Display results as printable hash
      puts results.inspect

      # Also show as JSON for better readability
      puts ''
      puts '📋 Results as JSON:'
      puts '=================='
      puts JSON.pretty_generate(results)

      # Show staging table counts
      puts ''
      puts '📈 Staging Table Results:'
      puts '=========================='
      Wdpa::Portal::Config::StagingConfig.staging_tables.each do |table|
        count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{table}").to_i
        puts "  #{table}: #{count} records"
      end
    rescue StandardError => e
      puts ''
      puts "❌ Portal import failed: #{e.message}"
      puts e.backtrace.first(5)
    end
  end
end
