# frozen_string_literal: true

module Wdpa
  module Portal
    module Services
      module Core
        class TableCleanupService
          include Concerns::TableOperationUtilities

          # --- MAIN OPERATIONS ---

          def self.cleanup_after_swap(swapped_tables = nil)
            service = new
            service.initialize_cleanup_variables(swapped_tables)
            service.prepare_for_cleanup

            begin
              service.perform_vacuum_operations
              service.perform_reindex_operations
              Rails.logger.info '✅ Table cleanup completed successfully'

              # Also cleanup old backups after swap
              Rails.logger.info '🧹 Cleaning up old backups after swap...'
              service.cleanup_old_backups_impl(3) # Keep last 3 backups by default
              Rails.logger.info '✅ Backup cleanup completed'
            rescue StandardError => e
              Rails.logger.error "❌ Table cleanup failed: #{e.message}"
              raise
            ensure
              service.restore_timeouts
            end
          end

          def self.cleanup_specific_tables(table_names)
            service = new
            service.initialize_cleanup_variables(table_names)
            service.prepare_for_cleanup

            begin
              service.perform_vacuum_operations
              service.perform_reindex_operations
              Rails.logger.info "✅ Cleanup completed for tables: #{table_names.join(', ')}"
            rescue StandardError => e
              Rails.logger.error "❌ Table cleanup failed: #{e.message}"
              raise
            ensure
              service.restore_timeouts
            end
          end

          def self.cleanup_old_backups(keep_count = 3)
            service = new
            service.initialize_cleanup_variables(nil)
            service.cleanup_old_backups_impl(keep_count)
          end

          # --- INITIALIZATION ---

          def initialize_cleanup_variables(swapped_tables = nil)
            Rails.logger.info '🧹 Starting table cleanup operations...'
            @connection = ActiveRecord::Base.connection
            @tables_to_cleanup = swapped_tables || Wdpa::Portal::Config::PortalImportConfig.swap_sequence_live_table_names
            @index_cache = {}
            @original_lock_timeout = nil
            @original_statement_timeout = nil
          end

          def prepare_for_cleanup
            @connection.execute('SELECT 1')
            setup_timeouts(
              Wdpa::Portal::Config::PortalImportConfig.lock_timeout_ms,
              Wdpa::Portal::Config::PortalImportConfig.statement_timeout_ms
            )
          end

          # --- VACUUM OPERATIONS ---

          def perform_vacuum_operations
            Rails.logger.info '🧹 Performing VACUUM operations...'

            @tables_to_cleanup.each do |table_name|
              next unless @connection.table_exists?(table_name)

              Rails.logger.info "🧹 VACUUM ANALYZE #{table_name}..."
              start_time = Time.current

              begin
                @connection.execute("VACUUM ANALYZE #{table_name}")
                duration = Time.current - start_time
                Rails.logger.info "✅ VACUUM ANALYZE completed for #{table_name} (#{duration.round(2)}s)"
              rescue StandardError => e
                Rails.logger.error "❌ VACUUM ANALYZE failed for #{table_name}: #{e.message}"
                # Continue with other tables even if one fails
              end
            end
          end

          # --- REINDEX OPERATIONS ---

          def perform_reindex_operations
            Rails.logger.info '🔄 Performing REINDEX CONCURRENTLY operations...'

            @tables_to_cleanup.each do |table_name|
              next unless @connection.table_exists?(table_name)

              # Get all indexes for the table
              indexes = get_table_indexes(table_name)
              next if indexes.empty?

              Rails.logger.info "🔄 Reindexing #{indexes.length} indexes for #{table_name}..."

              indexes.each do |index|
                perform_concurrent_reindex(table_name, index[:name])
              end
            end
          end

          def perform_concurrent_reindex(table_name, index_name)
            start_time = Time.current

            begin
              Rails.logger.debug "🔄 REINDEX CONCURRENTLY #{index_name}..."
              @connection.execute("REINDEX CONCURRENTLY INDEX #{index_name}")
              duration = Time.current - start_time
              Rails.logger.debug "✅ REINDEX CONCURRENTLY completed for #{index_name} (#{duration.round(2)}s)"
            rescue StandardError => e
              Rails.logger.warn "⚠️ REINDEX CONCURRENTLY failed for #{index_name}: #{e.message}"
              # Try regular REINDEX as fallback for critical indexes
              perform_regular_reindex(table_name, index_name) if critical_index?(index_name)
            end
          end

          def perform_regular_reindex(_table_name, index_name)
            start_time = Time.current

            begin
              Rails.logger.warn "🔄 Falling back to regular REINDEX for #{index_name}..."
              @connection.execute("REINDEX INDEX #{index_name}")
              duration = Time.current - start_time
              Rails.logger.info "✅ Regular REINDEX completed for #{index_name} (#{duration.round(2)}s)"
            rescue StandardError => e
              Rails.logger.error "❌ Regular REINDEX also failed for #{index_name}: #{e.message}"
            end
          end

          # --- UTILITY METHODS ---

          def critical_index?(index_name)
            # Consider primary key indexes and unique indexes as critical
            index_name.end_with?('_pkey') ||
              index_name.include?('unique') ||
              index_name.include?('_uk_')
          end

          # --- STATISTICS AND MONITORING ---

          def self.get_table_statistics(table_name)
            service = new
            service.initialize_cleanup_variables([table_name])

            stats = {}

            # Get table size
            result = service.instance_variable_get(:@connection).execute(<<~SQL)
              SELECT#{' '}
                pg_size_pretty(pg_total_relation_size('#{table_name}')) as total_size,
                pg_size_pretty(pg_relation_size('#{table_name}')) as table_size,
                pg_size_pretty(pg_indexes_size('#{table_name}')) as indexes_size
            SQL

            if result.any?
              first_row = result.first
              stats[:total_size] = first_row['total_size']
              stats[:table_size] = first_row['table_size']
              stats[:indexes_size] = first_row['indexes_size']
            end

            # Get index count using inherited method
            indexes = service.get_table_indexes(table_name)
            stats[:index_count] = indexes.length

            stats
          end

          def self.get_cleanup_recommendations(table_name)
            service = new
            service.initialize_cleanup_variables([table_name])

            recommendations = []

            # Check for bloated tables
            result = service.instance_variable_get(:@connection).execute(<<~SQL)
              SELECT#{' '}
                schemaname,
                tablename,
                n_dead_tup,
                n_live_tup,
                ROUND(n_dead_tup::numeric / GREATEST(n_live_tup, 1) * 100, 2) as dead_tuple_percentage
              FROM pg_stat_user_tables#{' '}
              WHERE tablename = '#{table_name}'
            SQL

            if result.any?
              stats_row = result.first
              dead_tuple_percentage = stats_row['dead_tuple_percentage'].to_f

              if dead_tuple_percentage > 10
                recommendations << "High dead tuple percentage (#{dead_tuple_percentage}%) - VACUUM recommended"
              end

              if dead_tuple_percentage > 50
                recommendations << "Very high dead tuple percentage (#{dead_tuple_percentage}%) - VACUUM FULL may be needed"
              end
            end

            # Check for unused indexes
            result = service.instance_variable_get(:@connection).execute(<<~SQL)
              SELECT#{' '}
                schemaname,
                tablename,
                indexname,
                idx_scan,
                idx_tup_read,
                idx_tup_fetch
              FROM pg_stat_user_indexes#{' '}
              WHERE tablename = '#{table_name}'
              AND idx_scan = 0
            SQL

            if result.any?
              unused_indexes = result.map { |index_row| index_row['indexname'] }
              recommendations << "Unused indexes detected: #{unused_indexes.join(', ')} - consider dropping"
            end

            recommendations
          end

          # --- BACKUP CLEANUP METHODS ---

          def cleanup_old_backups_impl(keep_count)
            Rails.logger.info "🧹 Cleaning up backup tables, keeping the last #{keep_count} backups..."

            @connection.transaction do
              # Group backup tables by timestamp
              backup_groups = group_backups_by_timestamp

              if backup_groups.length <= keep_count
                Rails.logger.info "✅ Only #{backup_groups.length} backup(s) found, keeping all (limit: #{keep_count})"
                return 0
              end

              # Sort by timestamp (newest first) and keep only the specified number
              sorted_timestamps = backup_groups.keys.sort.reverse
              timestamps_to_keep = sorted_timestamps.first(keep_count)
              timestamps_to_remove = sorted_timestamps - timestamps_to_keep

              cleaned_count = 0
              timestamps_to_remove.each do |timestamp|
                # Sort tables by dependency order (independent tables first, then dependent ones)
                tables_to_drop = sort_tables_by_dependency(backup_groups[timestamp])

                tables_to_drop.each do |table|
                  @connection.drop_table(table)
                  Rails.logger.info "🗑️ Dropped old backup: #{table} (timestamp: #{timestamp})"
                  cleaned_count += 1
                rescue ActiveRecord::StatementInvalid => e
                  if e.message.include?('DependentObjectsStillExist')
                    Rails.logger.warn "⚠️ Cannot drop #{table} due to dependencies, using CASCADE"
                    @connection.drop_table(table, if_exists: true, force: :cascade)
                    Rails.logger.info "🗑️ Dropped old backup with CASCADE: #{table} (timestamp: #{timestamp})"
                    cleaned_count += 1
                  else
                    Rails.logger.error "❌ Failed to drop #{table}: #{e.message}"
                    raise e
                  end
                end
              end

              Rails.logger.info "✅ Cleaned up #{cleaned_count} old backup tables, kept #{timestamps_to_keep.length} most recent backup(s)"
              cleaned_count
            end
          end

          def group_backups_by_timestamp
            backup_groups = {}

            @connection.tables.each do |table|
              next unless Wdpa::Portal::Config::PortalImportConfig.is_backup_table?(table)

              backup_timestamp = Wdpa::Portal::Config::PortalImportConfig.extract_backup_timestamp(table)
              backup_groups[backup_timestamp] ||= []
              backup_groups[backup_timestamp] << table
            end

            backup_groups
          end

          def sort_tables_by_dependency(tables)
            # Get deletion order: junction tables first, then main entities, then independent tables
            deletion_order = Wdpa::Portal::Config::PortalImportConfig.junction_tables.keys +
                             Wdpa::Portal::Config::PortalImportConfig.main_entity_tables.keys +
                             Wdpa::Portal::Config::PortalImportConfig.independent_table_names.keys

            # Create a mapping from original table names to backup table names
            backup_table_map = tables.index_by do |backup_table|
              Wdpa::Portal::Config::PortalImportConfig.extract_table_name_from_backup(backup_table)
            end

            # Sort by deletion order and return backup table names (compatible with older Ruby versions)
            deletion_order.map { |original_table| backup_table_map[original_table] }.compact
          end
        end
      end
    end
  end
end
