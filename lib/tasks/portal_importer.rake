namespace :portal_importer do
  desc 'Generate dummy portal tables for testing'
  task generate_dummy_views: :environment do
    puts 'Generating dummy portal tables for testing...'

    Wdpa::Portal::Services::DummyDataGenerator.generate_test_views

    puts 'Dummy portal tables created successfully!'
    puts 'You can now test the portal import without Step 1 being complete.'
    puts 'Use these tables to test your Step 2 implementation:'
    puts "  - #{Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons')} (5000 records)"
    puts "  - #{Wdpa::Portal::Config::StagingConfig.portal_view_for('points')} (5000 records)"
    puts "  - #{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')} (10000 records)"
  end

  desc 'Clean up dummy portal tables'
  task cleanup_dummy_views: :environment do
    puts 'Cleaning up dummy portal tables...'
    Wdpa::Portal::Services::DummyDataGenerator.cleanup_test_views
    puts 'Dummy portal tables cleaned up successfully!'
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

  desc 'Drop staging tables'
  task drop_staging: :environment do
    puts 'Dropping staging tables...'
    Wdpa::Portal::Utils::StagingTableManager.drop_staging_tables
    puts 'Staging tables dropped'
  end

  desc 'Portal importer'
  task import: :environment do
    puts 'start importing portal data'
    # Ensure staging tables exist (create if missing for rake tasks)
    begin
      Wdpa::Portal::Utils::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: true)
      puts '✅ Staging tables ready'
    rescue StandardError => e
      puts "❌ Failed to ensure staging tables: #{e.message}"
      raise e
    end

    # Ensure dummy data exists
    if Wdpa::Portal::Config::StagingConfig.portal_views_exist?
      puts '✅ Dummy data already exists'
    else
      puts "❌ Dummy data doesn't exist. Generating it first..."
      Wdpa::Portal::Services::DummyDataGenerator.generate_test_views
      puts '✅ Dummy data generated'
    end

    puts ''
    puts '🚀 Running Portal Importer...'
    puts '=============================='

    begin
      # Run the portal importer
      results = Wdpa::Portal::Importer.import

      puts ''
      puts '📊 Import Results:'
      puts '=================='

      if results[:protected_areas]
        puts 'Protected Areas:'
        puts "  - Attributes: #{results[:protected_areas][:attributes]}"
        puts "  - Geometries: #{results[:protected_areas][:geometries]}"
      end

      puts "Sources: #{results[:sources]}" if results[:sources]

      puts "Related Sources: #{results[:related_sources]}" if results[:related_sources]

      puts ''
      puts '✅ Portal import completed successfully!'

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

    puts ''
    puts '🏁 Test completed!'
  end

  # TO_BE_DELETED_STEP_1: Test mode configuration task - remove once Step 1 materialized views are ready
  desc 'Check test mode configuration'
  task test_config: :environment do
    puts 'Portal Test Mode Configuration:'
    puts '================================='
    puts "Dummy Data Count: #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}"
    puts ''
    puts 'Environment Variables:'
    puts "WDPA_PORTAL_TEST_MODE: #{ENV['WDPA_PORTAL_TEST_MODE'] || 'not set'}"
    puts "WDPA_PORTAL_DUMMY_COUNT: #{ENV['WDPA_PORTAL_DUMMY_COUNT'] || 'default (5000)'}"
    puts ''
    puts 'To enable test mode, set:'
    puts 'export WDPA_PORTAL_TEST_MODE=true'
    puts 'export WDPA_PORTAL_DUMMY_COUNT=5000  # Optional: customize dummy data count'
  end
end
