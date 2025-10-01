# frozen_string_literal: true

require 'securerandom'
require 'csv'

module Wdpa
  module Portal
    module Services
      module Concerns
        module TableOperationUtilities
          # --- TIMEOUT MANAGEMENT ---

          def setup_timeouts(lock_timeout_ms, statement_timeout_ms)
            @original_lock_timeout = get_current_setting('lock_timeout')
            @original_statement_timeout = get_current_setting('statement_timeout')
            @connection.execute("SET lock_timeout = #{lock_timeout_ms}")
            @connection.execute("SET statement_timeout = #{statement_timeout_ms}")
            Rails.logger.debug "🔧 Set timeouts: lock=#{lock_timeout_ms}ms, statement=#{statement_timeout_ms}ms"
          end

          def restore_timeouts
            @connection.execute(@original_lock_timeout ? "SET lock_timeout = '#{@original_lock_timeout}'" : 'SET lock_timeout = DEFAULT')
            @connection.execute(@original_statement_timeout ? "SET statement_timeout = '#{@original_statement_timeout}'" : 'SET statement_timeout = DEFAULT')
            Rails.logger.debug '🔄 Restored original timeouts'
          rescue StandardError => e
            Rails.logger.error "❌ Failed to restore connection settings: #{e.message}"
          end

          # --- OBJECT QUERIES ---

          # Only returning indexes
          def get_table_indexes(table_name)
            return @index_cache[table_name] if @index_cache[table_name]

            result = @connection.execute(<<~SQL)
              SELECT indexname, indexdef
              FROM pg_indexes
              WHERE tablename = '#{table_name}'
              AND schemaname = 'public'
            SQL

            indexes = result.map { |row| { name: row['indexname'], definition: row['indexdef'] } }
            @index_cache[table_name] = indexes
            indexes.reject { |idx| idx[:name].end_with?('_pkey') }
          end

          def get_table_sequences(table_name, schema_name = 'public')
            sql = <<~SQL
              SELECT s.relname AS sequence_name
              FROM pg_class s
              JOIN pg_namespace n ON s.relnamespace = n.oid
              JOIN pg_depend d ON d.objid = s.oid
              JOIN pg_class t ON d.refobjid = t.oid
              JOIN pg_namespace tn ON t.relnamespace = tn.oid
              WHERE s.relkind = 'S'
                AND n.nspname = $1
                AND tn.nspname = $2
                AND t.relname = $3
                AND d.deptype = 'a'
            SQL

            result = @connection.exec_query(sql, 'SQL', [[nil, schema_name], [nil, schema_name], [nil, table_name]])

            sequences = result.map { |row| { name: row['sequence_name'] } }

            Rails.logger.debug "🔍 Found #{sequences.length} sequences for #{schema_name}.#{table_name}: #{sequences.map do |s|
                                                                                                            s[:name]
                                                                                                          end.join(', ')}"

            sequences
          end

          # --- OBJECT RENAMING ---

          def rename_database_object(object_type, table_name, old_name, new_name)
            return if old_name == new_name

            case object_type
            when 'index'
              sql = "ALTER INDEX #{old_name} RENAME TO #{new_name}"
            when 'constraint'
              sql = "ALTER TABLE #{table_name} RENAME CONSTRAINT #{old_name} TO #{new_name}"
            when 'sequence'
              sql = "ALTER SEQUENCE #{old_name} RENAME TO #{new_name}"
            end

            execute_with_error_handling(sql, "✅ Renamed #{object_type}: #{old_name} → #{new_name}")
          end

          # --- VALIDATION ---

          def validate_staging_table(staging_table_name)
            live_table_name = Wdpa::Portal::Config::PortalImportConfig.get_live_table_name_from_staging_name(staging_table_name)

            # Skip validation for junction tables
            return true if junction_table?(staging_table_name)

            # Validate primary key compatibility
            validate_staging_live_table_primary_key(staging_table_name, live_table_name)
          end

          def validate_staging_live_table_primary_key(staging_table, live_table)
            live_pk_name = get_primary_key_name(live_table)
            staging_pk_name = get_primary_key_name(staging_table)

            unless live_pk_name && staging_pk_name
              raise "Primary key mismatch: live=#{live_pk_name}, staging=#{staging_pk_name}"
            end

            # For staging tables, we expect the primary key to have a staging_ prefix
            # that should match the live table's primary key when the prefix is removed
            expected_staging_pk_name = "staging_#{live_pk_name}"

            unless staging_pk_name == expected_staging_pk_name
              raise "Primary key name mismatch: expected '#{expected_staging_pk_name}', got '#{staging_pk_name}'"
            end

            true
          end

          def junction_table?(table_name)
            junction_tables = Wdpa::Portal::Config::PortalImportConfig.junction_tables.values
            junction_tables.include?(table_name)
          end

          # --- UTILITIES ---

          def execute_with_error_handling(sql, success_message, error_prefix = '⚠️ Failed')
            @connection.execute(sql)
            Rails.logger.debug success_message
          rescue StandardError => e
            Rails.logger.warn "#{error_prefix}: #{e.message}"
          end

          def get_current_setting(setting_name)
            result = @connection.execute("SHOW #{setting_name}")
            result.first[setting_name]
          end

          def all_table_names
            Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash.keys
          end

          def clear_index_cache(table_name = nil)
            if table_name
              @index_cache.delete(table_name)
              Rails.logger.debug "🗑️ Cleared index cache for #{table_name}"
            else
              @index_cache.clear
              Rails.logger.debug '🗑️ Cleared all index cache'
            end
          end

          def index_exists?(index_name)
            result = @connection.execute(<<~SQL)
              SELECT 1
              FROM pg_indexes
              WHERE indexname = '#{index_name}'
              AND schemaname = 'public'
            SQL
            result.any?
          end

          def sequence_exists?(sequence_name)
            result = @connection.execute(<<~SQL)
              SELECT 1
              FROM pg_class s
              JOIN pg_namespace n ON s.relnamespace = n.oid
              WHERE s.relkind = 'S'
              AND n.nspname = 'public'
              AND s.relname = '#{sequence_name}'
            SQL
            result.any?
          end

          def generate_unique_index_name(candidate_index_name = nil)
            # If candidate name is provided and available, use it
            return candidate_index_name if candidate_index_name && !index_exists?(candidate_index_name)

            # Otherwise, generate a random unique name
            loop do
              random_suffix = SecureRandom.hex(4)
              candidate_name = "idx_#{random_suffix}"

              # Check if this name is available
              return candidate_name unless index_exists?(candidate_name)
            end
          end

          def parse_backup_timestamp(timestamp)
            # Parse YYMMDDHHMM format (e.g., 2509101533)
            year = 2000 + timestamp[0..1].to_i
            month = timestamp[2..3].to_i
            day = timestamp[4..5].to_i
            hour = timestamp[6..7].to_i
            minute = timestamp[8..9].to_i

            Time.new(year, month, day, hour, minute, 0)
          rescue StandardError
            nil
          end

          def get_primary_key_name(table_name)
            query = <<~SQL
              SELECT conname
              FROM pg_constraint#{' '}
              WHERE conrelid = '#{table_name}'::regclass#{' '}
              AND contype = 'p'
            SQL

            result = @connection.execute(query)
            result.first&.dig('conname')
          end

          def find_matching_backup(live_index, backup_indexes)
            live_cols = extract_columns_from_index(live_index[:definition])
            live_is_unique = live_index[:definition].include?('UNIQUE')

            # Fallback to structure matching if no name match found
            matching = backup_indexes.find do |backup|
              backup_cols = extract_columns_from_index(backup[:definition])
              backup_is_unique = backup[:definition].include?('UNIQUE')

              live_cols == backup_cols && live_is_unique == backup_is_unique
            end

            Rails.logger.debug "🔍 Found match: #{matching&.dig(:name)}"
            matching
          end

          def extract_columns_from_index(definition)
            # Matches everything inside the first parentheses after "ON table"
            match = definition.match(/ON\s+\S+\s*\((.+?)\)/i)
            return [] unless match

            columns_str = match[1]

            # Use CSV parser to handle commas inside expressions safely
            columns = CSV.parse_line(columns_str, col_sep: ',', quote_char: '"')

            # Strip whitespace and surrounding quotes
            columns.map { |c| c.strip.gsub(/\A["']|["']\z/, '') }
          end
        end
      end
    end
  end
end
