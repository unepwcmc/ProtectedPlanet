# frozen_string_literal: true

require 'securerandom'

module Wdpa
  module Portal
    module Services
      module Core
        class TableRollbackService
          include Concerns::TableOperationUtilities

          # --- MAIN OPERATIONS ---

          def self.rollback_to_backup(backup_timestamp, notifier: nil)
            Rails.logger.info '🔄 Starting table rollback...'
            service = new
            service.initialize_rollback_variables(backup_timestamp)
            service.instance_variable_set(:@notifier, notifier)
            service.prepare_for_rollback
            service.execute_rollback_transaction
          end

          def execute_rollback_transaction
            begin
              @connection.transaction do
                validate_backup_tables_exist
                perform_atomic_rollbacks
                Rails.logger.info "✅ Rollback completed (backup timestamp: #{@backup_timestamp})"
              end
            rescue StandardError => e
              Rails.logger.error "❌ Rollback transaction failed: #{e.class}: #{e.message}"
              # Transaction will be rolled back automatically
              raise
            ensure
              restore_after_rollback
            end
          end

          # --- INITIALIZATION ---
          def restore_after_rollback
            restore_timeouts
          end

          def initialize_rollback_variables(backup_timestamp)
            @backup_timestamp = backup_timestamp
            @swapped_tables = []
            @connection = ActiveRecord::Base.connection
            @index_cache = {}
          end

          def prepare_for_rollback
            @connection.execute('SELECT 1')
            setup_timeouts(
              Wdpa::Portal::Config::PortalImportConfig.lock_timeout_ms,
              Wdpa::Portal::Config::PortalImportConfig.statement_timeout_ms
            )
          end

          # --- VALIDATION ---

          def validate_backup_tables_exist
            missing = all_table_names.reject do |live_table|
              backup_table = Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(live_table,
                @backup_timestamp)
              @connection.table_exists?(backup_table)
            end

            raise "Missing backup tables: #{missing.join(', ')}" if missing.any?

            Rails.logger.info '✅ All backup tables exist'
          end

          # --- ROLLBACK ---

          def perform_atomic_rollbacks
            Rails.logger.info '🔄 Performing atomic rollbacks...'
            live_to_staging = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash

            Wdpa::Portal::Config::PortalImportConfig.swap_sequence_live_table_names.each do |live_table|
              backup_table = Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(live_table,
                @backup_timestamp)
              staging_table = live_to_staging[live_table]

              rollback_single_table(live_table, backup_table, staging_table)
              @swapped_tables << live_table
            end

            Rails.logger.info "✅ Rolled back #{@swapped_tables.length} tables: #{@swapped_tables.join(', ')}"
            @notifier&.rollback_step_completed('rollback_tables', @backup_timestamp, "Rolled back #{@swapped_tables.length} tables (backup #{@backup_timestamp})")
            
            # Rollback portal materialized views (backup → prod)
            rollback_portal_materialized_views
            
            # Rollback portal downloads view (backup → prod)
            rollback_portal_downloads_view
          end

          def rollback_single_table(live_table, backup_table, staging_table)
            # Step 1: Move current live to staging (if it exists)
            if @connection.table_exists?(live_table)
              @connection.execute("DROP TABLE IF EXISTS #{staging_table} CASCADE")
              @connection.execute("ALTER TABLE #{live_table} RENAME TO #{staging_table}")
              Rails.logger.debug "✅ Live table #{live_table} -> Staging table #{staging_table}"
            end

            # Step 2: Restore backup to live
            @connection.execute("ALTER TABLE #{backup_table} RENAME TO #{live_table}")
            Rails.logger.debug "✅ Backup table #{backup_table} -> Live table #{live_table}"

            process_database_objects_after_rollback(live_table, staging_table)
          end

          def process_database_objects_after_rollback(live_table, staging_table)
            # Step 1: Rename primary keys
            rename_primary_keys_after_rollback(live_table, staging_table)

            # # Step 2: Rename indexes
            rename_indexes_after_rollback(live_table, staging_table)
            # # Step 3: Rename sequences
            rename_sequences_after_rollback(live_table, staging_table)
          end

          # --- DATABASE OBJECT MANAGEMENT ---

          def rename_primary_keys_after_rollback(live_table, staging_table)
            Rails.logger.debug "🔧 Renaming primary keys for #{live_table} and #{staging_table}"

            live_pkey_name = get_primary_key_name(live_table)
            staging_pkey_name = get_primary_key_name(staging_table)

            return unless live_pkey_name && staging_pkey_name

            # Rename staging primary key to add staging_ prefix
            staging_new_name = Wdpa::Portal::Config::PortalImportConfig.generate_staging_table_index_name(staging_pkey_name)
            rename_database_object('constraint', staging_table, staging_pkey_name, staging_new_name)
            # Rename live primary key to staging name
            rename_database_object('constraint', live_table, live_pkey_name, staging_pkey_name)
          end

          def rename_indexes_after_rollback(live_table, staging_table)
            Rails.logger.debug "🔧 Renaming indexes for #{live_table} and #{staging_table}"

            live_indexes = get_table_indexes(live_table)
            staging_indexes = get_table_indexes(staging_table)

            live_indexes.each do |live_index|
              matching_staging = find_matching_backup(live_index, staging_indexes)

              if matching_staging
                # Rename staging index to original index or unique name if not available or over 63 characters
                staging_new_name = generate_unique_index_name(Wdpa::Portal::Config::PortalImportConfig.generate_staging_table_index_name(matching_staging[:name]))
                rename_database_object('index', staging_table, matching_staging[:name], staging_new_name)

                # Rename live index to staging name
                rename_database_object('index', live_table, live_index[:name], matching_staging[:name])

                # Remove the matched staging index from the array to prevent duplicate matches
                staging_indexes.reject! { |staging| staging[:name] == matching_staging[:name] }
              else
                Rails.logger.warn "⚠️ No matching staging index found for live index: #{live_index[:name]}"
              end
            end
          end

          def rename_sequences_after_rollback(live_table, staging_table)
            Rails.logger.debug "🔧 Renaming sequences for #{live_table} and #{staging_table}"

            live_sequences = get_table_sequences(live_table)
            staging_sequences = get_table_sequences(staging_table)

            # Rename live sequences to staging names
            staging_sequences.each do |sequence|
              old_name = sequence[:name]
              new_name = "staging_#{old_name}"

              rename_database_object('sequence', staging_table, old_name, new_name)
            end

            # Rename staging sequences to original names
            live_sequences.each do |sequence|
              old_name = sequence[:name]
              new_name = Wdpa::Portal::Config::PortalImportConfig.remove_backup_suffix(old_name)

              rename_database_object('sequence', live_table, old_name, new_name)
            end
          end

          # --- CLEANUP & MONITORING ---

          def self.list_available_backups
            Rails.logger.info 'ℹ️ The return array will be showing from latest to oldest timestamps.'
            service = new
            service.initialize_rollback_variables(nil)
            service.list_available_backups_impl
          end

          def list_available_backups_impl
            backup_tables = @connection.tables.select do |table|
              Wdpa::Portal::Config::PortalImportConfig.is_backup_table?(table)
            end
            backup_tables
              .map { |table| Wdpa::Portal::Config::PortalImportConfig.extract_backup_timestamp(table) }
              .uniq
              .sort
              .reverse
          end


          # --- PORTAL MATERIALIZED VIEW ROLLBACK ---

          def rollback_portal_materialized_views
            Rails.logger.info '🔄 Rolling back portal materialized views...'
            
            Wdpa::Portal::Config::PortalImportConfig.portal_live_materialised_view_values.each do |live_materialised_view|
              backup_view = Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(live_materialised_view, @backup_timestamp)
              staging_view = Wdpa::Portal::Config::PortalImportConfig.get_staging_materialised_view_name_from_live(live_materialised_view)

              # Move current prod to staging for safety if exists
              if Wdpa::Portal::Managers::ViewManager.materialized_view_exists?(live_materialised_view)
                @connection.execute("DROP MATERIALIZED VIEW IF EXISTS #{staging_view} CASCADE")
                @connection.execute("ALTER MATERIALIZED VIEW #{live_materialised_view} RENAME TO #{staging_view}")
                # Rename indexes on the new staging MV to add staging prefix (to avoid name collisions with restored live)
                Wdpa::Portal::Managers::ViewManager.rename_materialised_view_indexes_add_staging_prefix(staging_view)
              end
              # Restore backup to prod if exists
              if Wdpa::Portal::Managers::ViewManager.materialized_view_exists?(backup_view)
                # Before promotion, restore canonical index names by removing backup prefix
                Wdpa::Portal::Managers::ViewManager.rename_materialised_view_indexes_remove_backup_prefix(backup_view)
                @connection.execute("ALTER MATERIALIZED VIEW #{backup_view} RENAME TO #{live_materialised_view}")
              end
            end

            Rails.logger.info '✅ Portal materialized views rolled back'
            @notifier&.rollback_step_completed('rollback_materialized_views', @backup_timestamp, "Rolled back portal materialized views (backup #{@backup_timestamp})")
          rescue StandardError => e
            Rails.logger.warn("⚠️ Portal materialized views rollback failed: #{e.class}: #{e.message}")
            # Continue; table rollback already completed. Views can be fixed manually.
          end

          def rollback_portal_downloads_view
            Rails.logger.info '🔄 Rolling back portal downloads view...'
            begin
              PortalRelease::Preflight.rollback_portal_download_view(@backup_timestamp)
              @notifier&.rollback_step_completed('rollback_downloads_view', @backup_timestamp, "Rolled back portal downloads view (backup #{@backup_timestamp})")
            rescue StandardError => e
              Rails.logger.warn("⚠️ Portal downloads view rollback failed: #{e.class}: #{e.message}")
              # Continue; table rollback already completed. View can be fixed manually.
            end
          end
        end
      end
    end
  end
end
