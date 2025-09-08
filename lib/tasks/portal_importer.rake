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

    begin
      puts '🏗️ Creating staging tables...'
      Wdpa::Portal::Utils::StagingTableManager.create_staging_tables
      puts '✅ Staging tables created'

      puts ''
      puts '🚀 Running Portal Importer...'
      puts '=============================='

      # Run the portal importer
      results = Wdpa::Portal::Importer.import

      puts ''
      puts '📊 Import Results:'
      puts '=================='

      # Show all results
      results.each do |key, value|
        puts "#{key.to_s.humanize}:"

        case key
        when :protected_areas
          if value.is_a?(Hash)
            puts "  - Success: #{value[:success]}"
            puts "  - Soft Errors: #{value[:soft_errors]&.length || 0}"
            puts "  - Hard Errors: #{value[:hard_errors]&.length || 0}"
            if value[:additional_fields]
              puts "  - Duration: #{value[:additional_fields][:duration_hours]} hours"
              puts "  - Attributes: #{value[:additional_fields][:protected_areas_attributes]}"
              puts "  - Geometries: #{value[:additional_fields][:protected_areas_geometries]}"
              puts '  - Related Sources:'
              if value[:additional_fields][:protected_areas_related_sources]
                puts "    * PARCC: #{value[:additional_fields][:protected_areas_related_sources][:parcc]}"
                puts "    * Irreplaceability: #{value[:additional_fields][:protected_areas_related_sources][:irreplaceability]}"
              end
            end
          else
            puts "  #{value}"
          end
        when :sources, :green_list, :pame
          if value.is_a?(Hash)
            puts "  - Success: #{value[:success]}"
            puts "  - Imported Count: #{value[:imported_count]}" if value[:imported_count]
            puts "  - Soft Errors: #{value[:soft_errors]&.length || 0}"
            puts "  - Hard Errors: #{value[:hard_errors]&.length || 0}"
            # Show additional fields for specific importers
            if value[:additional_fields]
              if key == :pame
                if value[:additional_fields][:total_sources]
                  puts "  - Total Sources: #{value[:additional_fields][:total_sources]}"
                end
                if value[:additional_fields][:site_ids_not_recognised]
                  puts "  - Sites Not Recognised: #{value[:additional_fields][:site_ids_not_recognised]&.length || 0}"
                end
              elsif key == :green_list
                if value[:additional_fields][:invalid_wdpa_ids]
                  puts "  - Invalid WDPA IDs: #{value[:additional_fields][:invalid_wdpa_ids]&.length || 0}"
                end
                if value[:additional_fields][:not_found_wdpa_ids]
                  puts "  - Not Found WDPA IDs: #{value[:additional_fields][:not_found_wdpa_ids]&.length || 0}"
                end
                if value[:additional_fields][:duplicates]
                  puts "  - Duplicates: #{value[:additional_fields][:duplicates]&.length || 0}"
                end
              end
            end
          else
            puts "  #{value}"
          end
        when :country_statistics
          if value.is_a?(Hash)
            puts "  - Success: #{value[:success]}"
            puts "  - Soft Errors: #{value[:soft_errors]&.length || 0}"
            puts "  - Hard Errors: #{value[:hard_errors]&.length || 0}"
            if value[:additional_fields]
              puts "  - Country PA Geometry: #{value[:additional_fields][:country_pa_geometry]}"
              puts "  - Country Stats: #{value[:additional_fields][:country_stats]}"
              puts "  - Country PAME Stats: #{value[:additional_fields][:country_pame_stats]}"
            end
          else
            puts "  #{value}"
          end
        when :global_stats
          if value.is_a?(Hash)
            puts "  - Success: #{value[:success]}"
            puts "  - Fields Updated: #{value[:fields_updated]}" if value[:fields_updated]
            puts "  - Soft Errors: #{value[:soft_errors]&.length || 0}"
            puts "  - Hard Errors: #{value[:hard_errors]&.length || 0}"
          else
            puts "  #{value}"
          end
        when :story_map_links
          if value.is_a?(Hash)
            puts "  - Success: #{value[:success]}"
            puts "  - Links Processed: #{value[:links_processed]}" if value[:links_processed]
            puts "  - Links Created: #{value[:links_created]}" if value[:links_created]
            puts "  - Sites Not Found: #{value[:sites_not_found]}" if value[:sites_not_found]
            puts "  - Soft Errors: #{value[:soft_errors]&.length || 0}"
            puts "  - Hard Errors: #{value[:hard_errors]&.length || 0}"
          else
            puts "  #{value}"
          end
        when :country_overseas_territories, :biopama_countries, :aichi11_target
          if value.is_a?(Hash)
            puts "  - Success: #{value[:success]}"
            puts "  - Imported Count: #{value[:imported_count]}" if value[:imported_count]
            puts "  - Soft Errors: #{value[:soft_errors]&.length || 0}"
            puts "  - Hard Errors: #{value[:hard_errors]&.length || 0}"
            # Show specific fields for live table importers
            if key == :country_overseas_territories
              if value[:relationships_created]
                puts "  - Relationships Created: #{value[:relationships_created]&.keys&.length || 0}"
              end
              puts "  - Skipped: #{value[:skipped]&.length || 0}" if value[:skipped]
            elsif key == :biopama_countries
              puts "  - Countries Updated: #{value[:countries_updated]}" if value[:countries_updated]
              puts "  - Countries Not Found: #{value[:countries_not_found]}" if value[:countries_not_found]
            end
          else
            puts "  #{value}"
          end
        else
          puts "  #{value}"
        end
        puts ''
      end

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
