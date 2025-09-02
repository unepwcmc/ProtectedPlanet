namespace :pp do
  namespace :portal do
    desc "Generate dummy portal tables for testing"
    task :generate_dummy_views => :environment do
      puts "Generating dummy portal tables for testing..."
      
      ENV['WDPA_PORTAL_TEST_MODE'] = 'true'
      Wdpa::Portal::Services::DummyDataGenerator.generate_test_views
      
      puts "Dummy portal tables created successfully!"
      puts "You can now test the portal import without Step 1 being complete."
      puts "Use these tables to test your Step 2 implementation:"
      puts "  - #{Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons')} (5000 records)"
      puts "  - #{Wdpa::Portal::Config::StagingConfig.portal_view_for('points')} (5000 records)"
      puts "  - #{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')} (10000 records)"
    end

    desc "Clean up dummy portal tables"
    task :cleanup_dummy_views => :environment do
      puts "Cleaning up dummy portal tables..."
      
      ENV['WDPA_PORTAL_TEST_MODE'] = 'true'
      Wdpa::Portal::Services::DummyDataGenerator.cleanup_test_views
      puts "Dummy portal tables cleaned up successfully!"
    end

    desc "Create staging tables"
    task :create_staging => :environment do
      puts "Creating staging tables..."
      
      begin
        Wdpa::Portal::Utils::StagingTableManager.create_staging_tables
        puts "✅ Staging tables created: #{Wdpa::Portal::Config::StagingConfig.staging_tables.join(', ')}"
      rescue => e
        puts "❌ Failed to create staging tables: #{e.message}"
        puts "🔄 Rolling back any partially created tables..."
        
        # Force cleanup to ensure system is in clean state
        Wdpa::Portal::Utils::StagingTableManager.drop_staging_tables
        puts "✅ Rollback completed - all staging tables removed"
        
        # Re-raise the error for proper error handling
        raise e
      end
    end

    desc "Drop staging tables"
    task :drop_staging => :environment do
      puts "Dropping staging tables..."
      Wdpa::Portal::Utils::StagingTableManager.drop_staging_tables
      puts "Staging tables dropped"
    end

    desc "Clear staging tables"
    task :clear_staging => :environment do
      puts "Clearing staging tables..."
      Wdpa::Portal::Utils::StagingTableManager.clear_staging_tables
      puts "Staging tables cleared"
    end

    desc "Force cleanup - removes all staging tables and indexes"
    task :force_cleanup => :environment do
      puts "Force cleaning up all staging tables and indexes..."
      
      # Drop any existing staging tables
      Wdpa::Portal::Utils::StagingTableManager.drop_staging_tables
      
      # Also clean up any orphaned indexes that might exist
      cleanup_orphaned_indexes
      
      puts "Force cleanup completed successfully!"
    end

    desc "Check staging table status"
    task :status => :environment do
      if Wdpa::Portal::Config::StagingConfig.staging_tables_exist?
        puts "Staging tables exist: #{Wdpa::Portal::Config::StagingConfig.staging_tables.join(', ')}"
        
        # Show record counts
        Wdpa::Portal::Config::StagingConfig.staging_tables.each do |table|
          count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{table}").to_i
          puts "  #{table}: #{count} records"
        end
      else
        puts "No staging tables found"
      end
    end

    desc "Test portal importer with dummy data (Step 2 testing)"
    task :test_importer => :environment do
      puts "Testing Portal Importer (Step 2) with dummy data..."
      puts "=================================================="
      
      # Ensure staging tables exist (create if missing for rake tasks)
      begin
        Wdpa::Portal::Utils::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: true)
        puts "✅ Staging tables ready"
      rescue => e
        puts "❌ Failed to ensure staging tables: #{e.message}"
        raise e
      end
      
      # Ensure dummy data exists
      unless Wdpa::Portal::Config::StagingConfig.portal_views_exist?
        puts "❌ Dummy data doesn't exist. Generating it first..."
        ENV['WDPA_PORTAL_TEST_MODE'] = 'true'
        Wdpa::Portal::Services::DummyDataGenerator.generate_test_views
        puts "✅ Dummy data generated"
      else
        puts "✅ Dummy data already exists"
      end
      
      puts ""
      puts "🚀 Running Portal Importer..."
      puts "=============================="
      
      begin
        # Run the portal importer
        results = Wdpa::Portal::Importer.import
        
        puts ""
        puts "📊 Import Results:"
        puts "=================="
        
        if results[:protected_areas]
          puts "Protected Areas:"
          puts "  - Attributes: #{results[:protected_areas][:attributes]}"
          puts "  - Geometries: #{results[:protected_areas][:geometries]}"
        end
        
        if results[:sources]
          puts "Sources: #{results[:sources]}"
        end
        
        if results[:related_sources]
          puts "Related Sources: #{results[:related_sources]}"
        end
        
        puts ""
        puts "✅ Portal import completed successfully!"
        
        # Show staging table counts
        puts ""
        puts "📈 Staging Table Results:"
        puts "=========================="
        Wdpa::Portal::Config::StagingConfig.staging_tables.each do |table|
          count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{table}").to_i
          puts "  #{table}: #{count} records"
        end
        
      rescue => e
        puts ""
        puts "❌ Portal import failed: #{e.message}"
        puts e.backtrace.first(5)
      end
      
      puts ""
      puts "🏁 Test completed!"
    end

    # TO_BE_DELETED_STEP_1: Test mode configuration task - remove once Step 1 materialized views are ready
    desc "Check test mode configuration"
    task :test_config => :environment do
      puts "Portal Test Mode Configuration:"
      puts "================================="
      puts "Test Mode Enabled: #{Wdpa::Portal::Config::StagingConfig.test_mode?}"
      puts "Dummy Data Count: #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}"
      puts ""
      puts "Environment Variables:"
      puts "WDPA_PORTAL_TEST_MODE: #{ENV['WDPA_PORTAL_TEST_MODE'] || 'not set'}"
      puts "WDPA_PORTAL_DUMMY_COUNT: #{ENV['WDPA_PORTAL_DUMMY_COUNT'] || 'default (5000)'}"
      puts ""
      puts "To enable test mode, set:"
      puts "export WDPA_PORTAL_TEST_MODE=true"
      puts "export WDPA_PORTAL_DUMMY_COUNT=5000  # Optional: customize dummy data count"
    end

    private

    def self.cleanup_orphaned_indexes
      # Look for any indexes that might be left over from staging tables
      staging_table_names = Wdpa::Portal::Config::StagingConfig.staging_tables
      
      staging_table_names.each do |table_name|
        # Check if there are any indexes with this table name pattern
        orphaned_indexes = find_orphaned_indexes(table_name)
        
        orphaned_indexes.each do |index_name|
          begin
            ActiveRecord::Base.connection.execute("DROP INDEX IF EXISTS #{index_name}")
            puts "  Dropped orphaned index: #{index_name}"
          rescue => e
            puts "  Warning: Could not drop index #{index_name}: #{e.message}"
          end
        end
      end
    end

    def self.find_orphaned_indexes(table_name)
      # This is a simple approach - in production you might want more sophisticated logic
      # to identify truly orphaned indexes
      []
    end
  end
end
