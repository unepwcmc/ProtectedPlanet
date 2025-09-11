# frozen_string_literal: true

require 'securerandom'

module Wdpa
  module Portal
    module Services
      class TableRollbackService
        include Concerns::TableOperationUtilities

        # --- MAIN OPERATIONS ---

        def self.rollback_to_backup(backup_timestamp)
          service = new
          service.initialize_rollback_variables(backup_timestamp)
          service.prepare_for_rollback

          begin
            service.instance_variable_get(:@connection).transaction do
              service.validate_backup_tables_exist
              service.perform_atomic_rollbacks
              Rails.logger.info "✅ Rollback completed (backup timestamp: #{service.instance_variable_get(:@backup_timestamp)})"
              Rails.logger.info '✅ Table rollback completed successfully'
            rescue StandardError => e
              Rails.logger.error "❌ Table rollback failed: #{e.message}"
              raise ActiveRecord::Rollback
            end
          rescue StandardError => e
            Rails.logger.error "❌ Transaction failed: #{e.message}"
            raise
          ensure
            service.reset_connection_settings
          end
        end

        # --- INITIALIZATION ---

        def initialize_rollback_variables(backup_timestamp)
          Rails.logger.info '🔄 Starting table rollback...'
          @backup_timestamp = backup_timestamp
          @swapped_tables = []
          @connection = ActiveRecord::Base.connection
          @index_cache = {}
        end

        def prepare_for_rollback
          @connection.execute('SELECT 1')
          @original_lock_timeout = get_current_setting('lock_timeout')
          @original_statement_timeout = get_current_setting('statement_timeout')
          @connection.execute("SET lock_timeout = #{Wdpa::Portal::Config::PortalImportConfig.lock_timeout_ms}")
          @connection.execute("SET statement_timeout = #{Wdpa::Portal::Config::PortalImportConfig.statement_timeout_ms}")
          Rails.logger.debug "🔧 Set timeouts: lock=#{Wdpa::Portal::Config::PortalImportConfig.lock_timeout_ms}ms, statement=#{Wdpa::Portal::Config::PortalImportConfig.statement_timeout_ms}ms"
        end

        def reset_connection_settings
          @connection.execute(@original_lock_timeout ? "SET lock_timeout = '#{@original_lock_timeout}'" : 'SET lock_timeout = DEFAULT')
          @connection.execute(@original_statement_timeout ? "SET statement_timeout = '#{@original_statement_timeout}'" : 'SET statement_timeout = DEFAULT')
          Rails.logger.debug '🔄 Restored original timeouts'
        rescue StandardError => e
          Rails.logger.error "❌ Failed to reset connection settings: #{e.message}"
        end

        # --- VALIDATION ---

        def validate_backup_tables_exist
          missing = all_table_names.reject do |live_table|
            backup_table = Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(live_table, @backup_timestamp)
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
            backup_table = Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(live_table, @backup_timestamp)
            staging_table = live_to_staging[live_table]

            rollback_single_table(live_table, backup_table, staging_table)
            @swapped_tables << live_table
          end

          Rails.logger.info "✅ Rolled back #{@swapped_tables.length} tables: #{@swapped_tables.join(', ')}"
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

        def self.cleanup_old_backups(keep_days = 3)
          service = new
          service.initialize_rollback_variables(nil)
          service.cleanup_old_backups_impl(keep_days)
        end

        def cleanup_old_backups_impl(keep_days)
          Rails.logger.info "🧹 Cleaning up backup tables older than #{keep_days} days..."
          cutoff_date = keep_days.days.ago.strftime('%y%m%d')
          cleaned_count = 0

          @connection.tables.each do |table|
            next unless Wdpa::Portal::Config::PortalImportConfig.is_backup_table?(table)

            backup_timestamp = Wdpa::Portal::Config::PortalImportConfig.extract_backup_timestamp(table)
            # Extract date part (first 6 characters: YYMMDD) for comparison
            backup_date = backup_timestamp[0..5]
            next unless backup_date < cutoff_date

            @connection.drop_table(table)
            Rails.logger.info "🗑️ Dropped old backup: #{table}"
            cleaned_count += 1
          end

          Rails.logger.info "✅ Cleaned up #{cleaned_count} old backup tables"
          cleaned_count
        end

        def self.list_available_backups
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
      end
    end
  end
end
