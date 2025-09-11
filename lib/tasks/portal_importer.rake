namespace :portal_importer do
  def refresh_materialized_views
    puts 'Refreshing materialized views...'
    puts 'This will create unique indexes and refresh all portal views with latest data.'

    begin
      Wdpa::Portal::Managers::ViewManager.refresh_materialized_views
      puts '✅ Materialized views refreshed successfully'
      puts '✅ All views now have latest data and concurrent refresh is enabled'
    rescue StandardError => e
      puts "❌ Failed to refresh materialized views: #{e.message}"
      puts '💡 Check that the materialized views exist and are accessible'
      raise e
    end
  end

  desc 'Import data to staging tables'
  task import: :environment do
    puts '📥 Importing data to staging tables...'
    puts 'This imports fresh data from sources into staging tables.'

    begin
      puts '🏗️ Creating staging tables...'
      Wdpa::Portal::Managers::StagingTableManager.create_staging_tables
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
      Wdpa::Portal::Config::PortalImportConfig.staging_tables.each do |table|
        count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{table}").to_i
        puts "  #{table}: #{count} records"
      end
    rescue StandardError => e
      puts ''
      puts "❌ Portal import failed: #{e.message}"
      puts e.backtrace.first(5)
    end
  end

  desc 'Swap staging tables to live'
  task swap_tables: :environment do
    puts '🔄 Swapping staging tables to live...'
    puts 'This will promote all staging tables to live tables with atomic backup.'

    begin
      Wdpa::Portal::Services::TableSwapService.promote_staging_to_live
      puts '✅ Table swap completed successfully'
      puts '📦 Live tables have been replaced with staging data'
      puts '💾 Original live tables backed up with timestamp'
    rescue StandardError => e
      puts "❌ Table swap failed: #{e.message}"
      puts '🔄 Transaction was rolled back - no changes made to live tables'
      raise e
    end
  end

  desc 'Rollback to specific backup timestamp'
  task :rollback, [:timestamp] => :environment do |_t, args|
    timestamp = args[:timestamp]

    if timestamp.nil? || timestamp.empty?
      puts '❌ Please provide a backup timestamp'
      puts 'Usage: rake portal_importer:rollback[20250110_143022]'
      puts 'Run "rake portal_importer:list_backups" to see available timestamps'
      exit 1
    end

    puts "🔄 Rolling back to backup: #{timestamp}"
    puts 'This will restore live tables from the specified backup.'

    begin
      # Wdpa::Portal::Services::TableRollbackService.rollback_to_backup("250911162528")
      Wdpa::Portal::Services::TableRollbackService.rollback_to_backup(timestamp)
      puts '✅ Rollback completed successfully'
      puts '📦 Live tables have been restored from backup'
    rescue StandardError => e
      puts "❌ Rollback failed: #{e.message}"
      puts '🔄 Transaction was rolled back - no changes made'
      raise e
    end
  end

  # ============================================================================
  # UTILITY & MAINTENANCE TASKS
  # ============================================================================

  desc 'Create staging tables'
  task create_staging: :environment do
    puts '🏗️ Creating staging tables...'
    puts 'This creates empty staging tables with the same structure as live tables.'

    begin
      Wdpa::Portal::Managers::StagingTableManager.create_staging_tables
      puts "✅ Staging tables created: #{Wdpa::Portal::Config::PortalImportConfig.staging_tables.join(', ')}"
    rescue StandardError => e
      puts "❌ Failed to create staging tables: #{e.message}"
      puts '🔄 Rolling back any partially created tables...'

      # Force cleanup to ensure system is in clean state
      Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
      puts '✅ Rollback completed - all staging tables removed'

      # Re-raise the error for proper error handling
      raise e
    end
  end

  desc 'Drop staging tables'
  task drop_staging: :environment do
    puts '🗑️ Dropping staging tables...'
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
    puts '✅ Staging tables dropped'
  end

  desc 'List available backups for rollback'
  task list_backups: :environment do
    puts '📋 Available backups:'
    puts '===================='

    begin
      backups = Wdpa::Portal::Services::TableRollbackService.list_available_backups

      if backups.empty?
        puts 'No backups found'
      else
        backups.each do |timestamp, tables|
          puts "📅 #{timestamp}:"
          tables.each do |table_info|
            puts "  - #{table_info[:table]} (#{table_info[:backup_table]})"
          end
          puts ''
        end
      end
    rescue StandardError => e
      puts "❌ Failed to list backups: #{e.message}"
      raise e
    end
  end

  desc 'Clean up old backup tables (default: 3 days)'
  task :cleanup_backups, [:keep_days] => :environment do |_t, args|
    keep_days = (args[:keep_days] || 3).to_i

    puts "🧹 Cleaning up backup tables older than #{keep_days} days..."

    begin
      cleaned_count = Wdpa::Portal::Services::TableSwapService.cleanup_old_backups(keep_days)
      puts "✅ Cleaned up #{cleaned_count} old backup tables"
    rescue StandardError => e
      puts "❌ Cleanup failed: #{e.message}"
      raise e
    end
  end

  desc 'Refresh materialized views'
  task refresh_materialized_views: :environment do
    refresh_materialized_views
  end

  # # ============================================================================
  # # TABLE CLEANUP TASKS
  # # ============================================================================

  # desc 'Clean up tables with VACUUM and REINDEX CONCURRENTLY'
  # task :cleanup_tables, [:table_names] => :environment do |_t, args|
  #   table_names = args[:table_names]&.split(',')&.map(&:strip)

  #   if table_names && table_names.any?
  #     puts "🧹 Cleaning up specific tables: #{table_names.join(', ')}"
  #     Wdpa::Portal::Services::TableCleanupService.cleanup_specific_tables(table_names)
  #   else
  #     puts '🧹 Cleaning up all portal tables...'
  #     Wdpa::Portal::Services::TableCleanupService.cleanup_after_swap
  #   end

  #   puts '✅ Table cleanup completed'
  # end

  # desc 'Show table statistics and cleanup recommendations'
  # task :table_stats, [:table_name] => :environment do |_t, args|
  #   table_name = args[:table_name]

  #   if table_name
  #     puts "📊 Statistics for table: #{table_name}"
  #     puts '=' * 50

  #     stats = Wdpa::Portal::Services::TableCleanupService.get_table_statistics(table_name)
  #     puts "Total size: #{stats[:total_size]}"
  #     puts "Table size: #{stats[:table_size]}"
  #     puts "Indexes size: #{stats[:indexes_size]}"
  #     puts "Index count: #{stats[:index_count]}"

  #     puts "\n🔍 Cleanup recommendations:"
  #     puts '-' * 30
  #     recommendations = Wdpa::Portal::Services::TableCleanupService.get_cleanup_recommendations(table_name)
  #     if recommendations.any?
  #       recommendations.each { |rec| puts "• #{rec}" }
  #     else
  #       puts '• No specific recommendations - table appears healthy'
  #     end
  #   else
  #     puts '📊 Statistics for all portal tables:'
  #     puts '=' * 50

  #     Wdpa::Portal::Config::PortalImportConfig.swap_sequence_live_table_names.each do |table|
  #       next unless ActiveRecord::Base.connection.table_exists?(table)

  #       puts "\n📋 #{table}:"
  #       stats = Wdpa::Portal::Services::TableCleanupService.get_table_statistics(table)
  #       puts "  Total size: #{stats[:total_size]}"
  #       puts "  Index count: #{stats[:index_count]}"
  #     end
  #   end
  # end

  # desc 'VACUUM ANALYZE all portal tables'
  # task vacuum_tables: :environment do
  #   puts '🧹 Running VACUUM ANALYZE on all portal tables...'

  #   Wdpa::Portal::Config::PortalImportConfig.swap_sequence_live_table_names.each do |table_name|
  #     next unless ActiveRecord::Base.connection.table_exists?(table_name)

  #     puts "🧹 VACUUM ANALYZE #{table_name}..."
  #     start_time = Time.current

  #     begin
  #       ActiveRecord::Base.connection.execute("VACUUM ANALYZE #{table_name}")
  #       duration = Time.current - start_time
  #       puts "✅ Completed #{table_name} (#{duration.round(2)}s)"
  #     rescue StandardError => e
  #       puts "❌ Failed #{table_name}: #{e.message}"
  #     end
  #   end

  #   puts '✅ VACUUM ANALYZE completed for all tables'
  # end

  # desc 'REINDEX CONCURRENTLY all portal table indexes'
  # task reindex_tables: :environment do
  #   puts '🔄 Running REINDEX CONCURRENTLY on all portal table indexes...'

  #   Wdpa::Portal::Config::PortalImportConfig.swap_sequence_live_table_names.each do |table_name|
  #     next unless ActiveRecord::Base.connection.table_exists?(table_name)

  #     # Get all indexes for the table
  #     result = ActiveRecord::Base.connection.execute(<<~SQL)
  #       SELECT indexname
  #       FROM pg_indexes
  #       WHERE tablename = '#{table_name}'
  #       AND schemaname = 'public'
  #       ORDER BY indexname
  #     SQL

  #     indexes = result.map { |row| row['indexname'] }
  #     next if indexes.empty?

  #     puts "🔄 Reindexing #{indexes.length} indexes for #{table_name}..."

  #     indexes.each do |index_name|
  #       puts "  🔄 REINDEX CONCURRENTLY #{index_name}..."
  #       start_time = Time.current

  #       begin
  #         ActiveRecord::Base.connection.execute("REINDEX CONCURRENTLY INDEX #{index_name}")
  #         duration = Time.current - start_time
  #         puts "  ✅ Completed #{index_name} (#{duration.round(2)}s)"
  #       rescue StandardError => e
  #         puts "  ❌ Failed #{index_name}: #{e.message}"
  #       end
  #     end
  #   end

  #   puts '✅ REINDEX CONCURRENTLY completed for all indexes'
  # end
end
