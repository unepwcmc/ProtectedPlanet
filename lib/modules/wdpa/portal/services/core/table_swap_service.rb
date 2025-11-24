# frozen_string_literal: true

require 'securerandom'

module Wdpa
  module Portal
    module Services
      module Core
        class TableSwapService
          include Concerns::TableOperationUtilities

          # --- MAIN OPERATIONS ---

          def self.promote_staging_to_live
            service = new
            service.initialize_swap_variables
            service.prepare_for_swap

            begin
              service.instance_variable_get(:@connection).transaction do
                service.validate_staging_tables_existence
                service.perform_atomic_swaps
                Rails.logger.info "✅ Swaps completed (backup timestamp: #{service.instance_variable_get(:@backup_timestamp)})"
                Rails.logger.info '✅ Table swap completed successfully'
              rescue StandardError => e
                Rails.logger.error "❌ Table swap failed: #{e.message}"
                raise ActiveRecord::Rollback
              end
            rescue StandardError => e
              Rails.logger.error "❌ Transaction failed: #{e.message}"
              raise
            ensure
              service.restore_after_swap
            end

            # Return the backup timestamp for use by the release system
            service.instance_variable_get(:@backup_timestamp)
          end

          # --- INITIALIZATION ---

          def restore_after_swap
            restore_timeouts
          end

          def initialize_swap_variables
            Rails.logger.info '🚀 Starting table swap: staging → live...'
            @backup_timestamp = ::Release.current_backup_timestamp_string
            @swapped_tables = []
            @connection = ActiveRecord::Base.connection
            @index_cache = {}
          end

          def prepare_for_swap
            @connection.execute('SELECT 1')
            setup_timeouts(
              Wdpa::Portal::Config::PortalImportConfig.lock_timeout_ms,
              Wdpa::Portal::Config::PortalImportConfig.statement_timeout_ms
            )
          end

          # --- VALIDATION ---

          def validate_staging_tables_existence
            missing = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash.reject do |_live, staging|
              @connection.table_exists?(staging)
            end.keys

            raise "Missing staging tables: #{missing.join(', ')}" if missing.any?
          end

          # --- TABLE SWAPPING ---

          def perform_atomic_swaps
            Rails.logger.info '🔄 Performing atomic swaps...'
            live_to_staging = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash

            Wdpa::Portal::Config::PortalImportConfig.swap_sequence_live_table_names.each do |live_table|
              staging_table = live_to_staging[live_table]
              # next unless staging_table && @connection.table_exists?(staging_table)

              swap_single_table(live_table, staging_table)
              @swapped_tables << live_table
            end

            Rails.logger.info "✅ Swapped #{@swapped_tables.length} tables: #{@swapped_tables.join(', ')}"
            
            # Swap portal materialized views (staging → prod, prod → backup)
            swap_portal_materialized_views
          end

          def swap_single_table(live_table, staging_table)
            backup_table = Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(live_table, @backup_timestamp)

            # Validate staging table
            validate_staging_table(staging_table)

            @connection.execute("ALTER TABLE #{live_table} RENAME TO #{backup_table}")
            @connection.execute("ALTER TABLE #{staging_table} RENAME TO #{live_table}")

            process_database_objects_after_swap(live_table, backup_table)
          end

          def process_database_objects_after_swap(live_table, backup_table)
            # Step 1: Rename primary keys
            rename_primary_keys_after_swap(live_table, backup_table)
            # Step 2: Rename indexes
            rename_indexes_after_swap(live_table, backup_table)

            # Step 3: Rename sequences
            rename_sequences_after_swap(live_table, backup_table)
          end

          # --- DATABASE OBJECT MANAGEMENT ---
          def rename_primary_keys_after_swap(live_table, backup_table)
            tmp_pkey_name = get_primary_key_name(live_table)
            original_pkey_name = get_primary_key_name(backup_table)

            return unless tmp_pkey_name && original_pkey_name

            backup_new_name = Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(original_pkey_name,
              @backup_timestamp)

            # Rename original key name to use backup_new_name for backup table to free up the original name
            rename_database_object('constraint', backup_table, original_pkey_name, backup_new_name)
            # Rename live primary key to use original key name (canonical name)
            rename_database_object('constraint', live_table, tmp_pkey_name, original_pkey_name)
          end

          def rename_indexes_after_swap(live_table, backup_table)
            live_indexes   = get_table_indexes(live_table)
            backup_indexes = get_table_indexes(backup_table)

            live_indexes.each do |live_index|
              matching_backup = find_matching_backup(live_index, backup_indexes)

              next unless matching_backup

              # Rename backup index to keep a backup copy
              backup_new_name = generate_unique_index_name
              rename_database_object('index', backup_table, matching_backup[:name], backup_new_name)

              # Rename live index to the canonical backup index name
              rename_database_object('index', live_table, live_index[:name], matching_backup[:name])

              # Remove the matched backup index from the array to prevent duplicate matches
              backup_indexes.reject! { |backup| backup[:name] == matching_backup[:name] }
            end
          end

          def rename_sequences_after_swap(live_table, backup_table)
            # Get sequences for both tables
            live_sequences = get_table_sequences(live_table)
            backup_sequences = get_table_sequences(backup_table)

            # STEP 1: Rename backup sequences to add timestamp suffix
            if backup_sequences.any?
              backup_sequences.each do |sequence|
                old_name = sequence[:name]
                new_name = Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(old_name, @backup_timestamp)

                rename_database_object('sequence', backup_table, old_name, new_name)
              end
            end

            # STEP 2: Rename staging sequences to original names (now safe)
            return unless live_sequences.any?

            live_sequences.each do |sequence|
              old_name = sequence[:name]

              # Only process staging sequences
              next unless old_name.start_with?(Wdpa::Portal::Config::PortalImportConfig::STAGING_PREFIX)

              new_name = old_name.sub(/^#{Wdpa::Portal::Config::PortalImportConfig::STAGING_PREFIX}/, '')
              rename_database_object('sequence', live_table, old_name, new_name)
            end
          end

          # --- PORTAL MATERIALIZED VIEW SWAPPING ---

          def swap_portal_materialized_views
            Rails.logger.info '🔄 Swapping portal materialized views...'
            
            Wdpa::Portal::Config::PortalImportConfig.portal_live_materialised_view_values.each do |live_materialised_view|
              staging_view = Wdpa::Portal::Config::PortalImportConfig.get_staging_materialised_view_name_from_live(live_materialised_view)
              backup_view = Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(live_materialised_view, @backup_timestamp)

              # If staging view missing, skip view swap but continue table swap
              next unless Wdpa::Portal::Managers::ViewManager.materialized_view_exists?(staging_view)

              # Rename prod -> backup if prod exists
              if Wdpa::Portal::Managers::ViewManager.materialized_view_exists?(live_materialised_view)
                @connection.execute("ALTER MATERIALIZED VIEW #{live_materialised_view} RENAME TO #{backup_view}")

                # Rename indexes on the backup MV to avoid name collisions
                Wdpa::Portal::Managers::ViewManager.rename_materialised_view_indexes_add_backup_suffix(backup_view, @backup_timestamp)
              end
              # Promote staging -> prod
              @connection.execute("ALTER MATERIALIZED VIEW #{staging_view} RENAME TO #{live_materialised_view}")

              # After promotion, remove staging_ prefix from index names on the new live MV
              Wdpa::Portal::Managers::ViewManager.rename_materialised_view_indexes_remove_staging_prefix(live_materialised_view)
            end
            
            Rails.logger.info '✅ Portal materialized views swapped'
          rescue StandardError => e
            Rails.logger.warn("⚠️ Portal materialized views swap failed: #{e.class}: #{e.message}")
            # Continue; table swap already completed. Views can be fixed manually.
          end
        end
      end
    end
  end
end
