# frozen_string_literal: true

module Wdpa
  module Portal
    module Services
      module Core
        class TableCleanupService
          include Concerns::TableOperationUtilities

          # --- MAIN OPERATIONS ---

          def self.cleanup_after_swap
            service = new
            service.initialize_cleanup_variables
            service.prepare_for_cleanup

            begin
              service.perform_vacuum_operations
              Rails.logger.info '✅ Table vaccum completed successfully'

              # Also cleanup old backups after swap
              Rails.logger.info '🧹 Cleaning up old backups after swap...'
              service.cleanup_old_backups(Wdpa::Portal::Config::PortalImportConfig.keep_backup_count)
              Rails.logger.info '✅ Backup cleanup completed'

              # Cleanup orphaned release timestamps
              Rails.logger.info '🧹 Cleaning up orphaned release timestamps...'
              service.cleanup_orphaned_release_timestamps
              Rails.logger.info '✅ Release timestamp cleanup completed'
            rescue StandardError => e
              Rails.logger.error "❌ Table cleanup failed: #{e.message}"
              raise
            ensure
              service.restore_after_cleanup
            end
          end

          # --- INITIALIZATION ---
          def restore_after_cleanup
            restore_timeouts
          end

          def initialize_cleanup_variables
            Rails.logger.info '🧹 Starting table cleanup operations...'
            @connection = ActiveRecord::Base.connection
            @tables_to_cleanup = Wdpa::Portal::Config::PortalImportConfig.swap_sequence_live_table_names
            @original_lock_timeout = nil
            @original_statement_timeout = nil
            @index_cache = {}
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

          # --- BACKUP CLEANUP METHODS ---

          def cleanup_old_backups(keep_count)
            Rails.logger.info "🧹 Cleaning up backup tables and materialized views, keeping the last #{keep_count} backups..."

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
                # Cleanup backup tables for this timestamp
                if backup_groups[timestamp]
                  tables_to_drop = sort_tables_by_dependency(backup_groups[timestamp])
                  tables_to_drop.each do |table|
                    @connection.drop_table(table)
                    Rails.logger.info "🗑️ Dropped old backup table: #{table} (timestamp: #{timestamp})"
                    cleaned_count += 1
                  rescue ActiveRecord::StatementInvalid => e
                    if e.message.include?('DependentObjectsStillExist')
                      Rails.logger.warn "⚠️ Cannot drop #{table} due to dependencies, using CASCADE"
                      @connection.drop_table(table, if_exists: true, force: :cascade)
                      Rails.logger.info "🗑️ Dropped old backup table with CASCADE: #{table} (timestamp: #{timestamp})"
                      cleaned_count += 1
                    else
                      Rails.logger.error "❌ Failed to drop #{table}: #{e.message}"
                      raise e
                    end
                  end
                end

                # Cleanup backup materialized views for this timestamp
                backup_materialized_views = get_backup_materialized_views_for_timestamp(timestamp)
                Rails.logger.debug "🔍 Found #{backup_materialized_views.length} backup materialized views for timestamp #{timestamp}: #{backup_materialized_views.join(', ')}"

                backup_materialized_views.each do |materialized_view|
                  # SAFETY CHECK: Ensure we're only dropping backup views, never live views
                  unless Wdpa::Portal::Config::PortalImportConfig.is_backup_table?(materialized_view)
                    Rails.logger.error "❌ SAFETY CHECK FAILED: Attempted to drop non-backup view #{materialized_view} (skipping)"
                    next
                  end

                  # SAFETY CHECK: Ensure the view is not a currently live view
                  live_views = Wdpa::Portal::Config::PortalImportConfig.portal_live_materialised_view_values
                  if live_views.include?(materialized_view)
                    Rails.logger.error "❌ SAFETY CHECK FAILED: Attempted to drop live view #{materialized_view} (skipping)"
                    next
                  end

                  Rails.logger.debug "🗑️ Attempting to drop backup materialized view: #{materialized_view}"
                  # Drop without CASCADE first to avoid unintended side effects
                  begin
                    @connection.execute("DROP MATERIALIZED VIEW IF EXISTS #{materialized_view}")
                  rescue ActiveRecord::StatementInvalid => e
                    if e.message.include?('DependentObjectsStillExist') || e.message.include?('cannot be dropped')
                      Rails.logger.warn "⚠️ Cannot drop #{materialized_view} without CASCADE due to dependencies, retrying with CASCADE"
                      Rails.logger.warn "🔍 Dependencies: #{e.message}"
                      @connection.execute("DROP MATERIALIZED VIEW IF EXISTS #{materialized_view} CASCADE")
                    else
                      raise
                    end
                  end
                  Rails.logger.info "🗑️ Dropped old backup materialized view: #{materialized_view} (timestamp: #{timestamp})"
                  cleaned_count += 1
                rescue ActiveRecord::StatementInvalid => e
                  Rails.logger.error "❌ Failed to drop materialized view #{materialized_view}: #{e.message}"
                  # Continue with other views even if one fails
                end
              end

              Rails.logger.info "✅ Cleaned up #{cleaned_count} old backup objects (tables + materialized views), kept #{timestamps_to_keep.length} most recent backup(s)"
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

          def get_backup_materialized_views_for_timestamp(timestamp)
            backup_materialized_views = []

            # Get list of live materialized views
            live_materialized_views = Wdpa::Portal::Config::PortalImportConfig.portal_live_materialised_view_values
            
            Rails.logger.debug "🔍 Looking for backup materialized views for live views: #{live_materialized_views.join(', ')}"

            # For each live materialized view, check if a backup exists with the given timestamp
            live_materialized_views.each do |live_view|
              backup_view_name = Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(live_view, timestamp)
              
              # Check if the backup materialized view exists
              sql = <<~SQL
                SELECT 1
                FROM pg_matviews
                WHERE schemaname = 'public' AND matviewname = '#{backup_view_name}'
              SQL
              result = @connection.execute(sql)
              
              if result.any?
                backup_materialized_views << backup_view_name
                Rails.logger.debug "🔍 Found backup materialized view: #{backup_view_name}"
              end
            end

            Rails.logger.debug "🔍 Found #{backup_materialized_views.length} backup materialized views for timestamp #{timestamp}: #{backup_materialized_views.join(', ')}"
            backup_materialized_views
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

          # --- RELEASE TIMESTAMP CLEANUP METHODS ---

          def cleanup_orphaned_release_timestamps
            Rails.logger.info '🧹 Cleaning up orphaned backup timestamps in releases table...'

            @connection.transaction do
              available_timestamps = Wdpa::Portal::Services::Core::TableRollbackService.list_available_backups

              # Convert timestamp strings to datetime for database comparison
              available_datetimes = available_timestamps.map do |timestamp_string|
                ::Release.parse_backup_timestamp_string(timestamp_string)
              end.compact

              # Find releases with backup timestamps not in the available list
              orphaned_releases = ::Release.where.not(backup_timestamp: nil)
                .where.not(backup_timestamp: available_datetimes)
              orphaned_releases.update_all(backup_timestamp: nil)
            end
          end
        end
      end
    end
  end
end
