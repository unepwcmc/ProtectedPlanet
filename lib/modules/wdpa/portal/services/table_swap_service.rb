module Wdpa
  module Portal
    module Services
      class TableSwapService
        def self.promote_staging_to_live
          initialize_swap_variables
          prepare_for_swap

          execute_swap_phases
        end

        def self.initialize_swap_variables
          Rails.logger.info '🚀 Starting table swap: staging → live...'
          @backup_timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
          @swapped_tables = []
          @connection = ActiveRecord::Base.connection
          @constraint_errors = []
          @index_errors = []
        end

        def self.execute_swap_phases
          execute_atomic_swaps_phase
          execute_index_copy_phase
        end

        def self.execute_atomic_swaps_phase
          @connection.transaction do
            validate_staging_tables
            perform_atomic_swaps
            copy_foreign_keys_inside_transaction
            Rails.logger.info "✅ Swaps and foreign keys completed (backup timestamp: #{@backup_timestamp})"
          rescue StandardError => e
            Rails.logger.error "❌ Table swap failed: #{e.message}"
            raise ActiveRecord::Rollback
          end
        end

        def self.execute_index_copy_phase
          copy_indexes_outside_transaction
          verify_constraints_and_indexes

          if @index_errors.any?
            handle_index_copy_errors
          else
            create_complete_backup(@backup_timestamp)
            Rails.logger.info '✅ Indexes copied and complete backup created successfully'
          end
        rescue StandardError => e
          Rails.logger.error "❌ Index copy failed: #{e.message}"
          Rails.logger.error "🔄 Consider running manual rollback: TableSwapService.rollback_to_backup('#{@backup_timestamp}')"
          raise e
        end

        def self.handle_index_copy_errors
          Rails.logger.error '❌ Index copy had errors. Attempting automatic rollback...'
          attempt_automatic_rollback
          raise StandardError, "Index copy failed: #{@index_errors.count} index errors. Automatic rollback attempted."
        end

        # --- VALIDATION ---

        def self.validate_staging_tables
          Rails.logger.info '🔎 Validating staging tables...'
          missing, empty = validate_table_existence_and_content

          raise "Missing staging tables: #{missing.join(', ')}" if missing.any?
          Rails.logger.warn "⚠️ Empty staging tables: #{empty.join(', ')}" if empty.any?
        end

        def self.validate_table_existence_and_content
          missing = []
          empty = []

          Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash.each do |live, staging|
            unless @connection.table_exists?(staging)
              missing << staging
              next
            end

            next if junction_table?(live)
            empty << staging if table_empty?(staging)
          end

          [missing, empty]
        end

        def self.table_empty?(table_name)
          @connection.select_value("SELECT COUNT(*) FROM #{table_name}").to_i.zero?
        end

        def self.junction_table?(table_name)
          Wdpa::Portal::Config::PortalImportConfig.junction_tables.key?(table_name)
        end

        # --- SWAPS ---

        def self.perform_atomic_swaps
          Rails.logger.info '🔄 Performing atomic swaps...'
          staging_to_live = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash.invert

          Wdpa::Portal::Config::PortalImportConfig.swap_sequence_live_table_names.each do |live_table|
            staging_table = staging_to_live[live_table]
            next unless staging_table && @connection.table_exists?(staging_table)

            swap_single_table(live_table, staging_table)
            @swapped_tables << live_table
          end
        end

        def self.swap_single_table(live_table, staging_table)
          backup_table = "#{live_table}_backup_#{@backup_timestamp}"

          if @connection.table_exists?(live_table)
            @connection.execute("ALTER TABLE #{live_table} RENAME TO #{backup_table}")
            Rails.logger.debug "📦 Backup created: #{backup_table}"
          end

          @connection.execute("ALTER TABLE #{staging_table} RENAME TO #{live_table}")
          Rails.logger.info "✅ Promoted #{staging_table} → #{live_table}"
        end

        # --- TRANSACTION-AWARE CONSTRAINT & INDEX COPYING ---

        def self.copy_foreign_keys_inside_transaction
          Rails.logger.info '🔄 Copying constraints & indexes from backup tables...'

          # Process tables in dependency order (independent -> main -> junction)
          Wdpa::Portal::Config::PortalImportConfig.swap_sequence_live_table_names.each do |live_table|
            backup_table = "#{live_table}_backup_#{@backup_timestamp}"
            next unless @connection.table_exists?(backup_table)

            copy_foreign_keys_from_backup(live_table, backup_table)
            Rails.logger.debug "✅ Foreign keys copied for #{live_table}"
          end

          Rails.logger.info '🔗 Foreign key copying completed'
        end

        def self.copy_indexes_outside_transaction
          Rails.logger.info '📊 Copying indexes outside transaction (CONCURRENTLY)...'

          # Process tables sequentially to avoid connection conflicts
          all_table_names.each do |live_table|
            backup_table = "#{live_table}_backup_#{@backup_timestamp}"
            next unless @connection.table_exists?(backup_table)

            begin
              copy_indexes_from_backup(live_table, backup_table)
              Rails.logger.debug "✅ Indexes copied for #{live_table}"
            rescue StandardError => e
              @index_errors << { table: live_table, error: e.message }
              Rails.logger.warn "⚠️ Failed to copy indexes for #{live_table}: #{e.message}"
            end
          end

          Rails.logger.info "📊 Index copying completed with #{@index_errors.count} errors"
        end

        def self.copy_foreign_keys_from_backup(live_table, backup_table)
          fk_count = 0
          get_foreign_key_constraints(backup_table).each do |constraint_name, definition|
            next if constraint_exists?(live_table, constraint_name)

            @connection.execute("ALTER TABLE #{live_table} ADD CONSTRAINT #{constraint_name} #{definition}")
            Rails.logger.debug "🔗 Copied FK #{constraint_name} to #{live_table}"
            fk_count += 1
          end

          Rails.logger.debug "🔗 Copied #{fk_count} foreign keys to #{live_table}"
        end

        def self.get_foreign_key_constraints(backup_table)
          @connection.execute(<<~SQL).map { |row| [row['conname'], row['definition']] }
            SELECT conname, pg_get_constraintdef(oid) as definition
            FROM pg_constraint
            WHERE conrelid = '#{backup_table}'::regclass
            AND contype = 'f'
          SQL
        end

        def self.constraint_exists?(table, constraint_name)
          result = @connection.select_value(
            "SELECT 1 FROM pg_constraint WHERE conrelid = '#{table}'::regclass AND conname = '#{constraint_name}'"
          )
          !result.nil?
        end

        def self.copy_indexes_from_backup(live_table, backup_table)
          index_count = 0
          failed_indexes = []

          get_indexes_from_backup(backup_table).each do |index_name, index_def|
            next if index_exists?(live_table, index_name)

            result = create_index_concurrently(live_table, backup_table, index_name, index_def)
            if result[:success]
              index_count += 1
            else
              failed_indexes << result[:error]
            end
          end

          handle_index_copy_results(live_table, index_count, failed_indexes)
        end

        def self.get_indexes_from_backup(backup_table)
          @connection.execute(<<~SQL).map { |row| [row['indexname'], row['indexdef']] }
            SELECT indexname, indexdef
            FROM pg_indexes
            WHERE tablename = '#{backup_table}'
            AND indexname NOT LIKE '%_pkey'
          SQL
        end

        def self.create_index_concurrently(live_table, backup_table, index_name, index_def)
          live_index_def = index_def.gsub(/ON #{backup_table}/, "ON #{live_table}")
          concurrent_def = live_index_def.gsub(/CREATE (UNIQUE )?INDEX/, 'CREATE \1INDEX CONCURRENTLY')

          @connection.execute(concurrent_def)
          Rails.logger.debug "📊 Copied index #{index_name} to #{live_table}"
          { success: true }
        rescue StandardError => e
          Rails.logger.warn "⚠️ Failed to copy index #{index_name} to #{live_table}: #{e.message}"
          { success: false, error: { name: index_name, error: e.message } }
        end

        def self.handle_index_copy_results(live_table, index_count, failed_indexes)
          if failed_indexes.any?
            Rails.logger.warn "⚠️ #{live_table}: #{failed_indexes.count} indexes failed, #{index_count} succeeded"
            @index_errors.concat(failed_indexes.map { |idx| { table: live_table, error: "#{idx[:name]}: #{idx[:error]}" } })
          end

          Rails.logger.debug "📊 Copied #{index_count} indexes to #{live_table}"
        end

        def self.index_exists?(table, index_name)
          result = @connection.select_value(
            "SELECT 1 FROM pg_indexes WHERE tablename = '#{table}' AND indexname = '#{index_name}'"
          )
          !result.nil?
        end

        def self.attempt_automatic_rollback
          Rails.logger.info '🔄 Attempting automatic rollback due to index creation failures...'

          begin
            rollback_to_backup(@backup_timestamp)
            Rails.logger.info '✅ Automatic rollback completed successfully'
          rescue StandardError => e
            Rails.logger.error "❌ Automatic rollback failed: #{e.message}"
            Rails.logger.error "🔄 Manual rollback required: TableSwapService.rollback_to_backup('#{@backup_timestamp}')"
          end
        end

        # Create a complete backup with constraints and indexes for better rollback
        def self.create_complete_backup(backup_timestamp)
          Rails.logger.info '💾 Creating complete backup with constraints and indexes...'

          all_table_names.each do |live_table|
            complete_backup_table = "#{live_table}_complete_backup_#{backup_timestamp}"

            # Create table with all constraints and indexes
            @connection.execute("CREATE TABLE #{complete_backup_table} (LIKE #{live_table} INCLUDING ALL)")

            # Copy data
            @connection.execute("INSERT INTO #{complete_backup_table} SELECT * FROM #{live_table}")

            Rails.logger.debug "💾 Created complete backup: #{complete_backup_table}"
          end

          Rails.logger.info '✅ Complete backup created successfully'
        end

        # Rollback to complete backup (preserves all constraints and indexes)
        def self.rollback_to_complete_backup(backup_timestamp)
          Rails.logger.info "🔄 Rolling back to complete backup: #{backup_timestamp}"
          @connection = ActiveRecord::Base.connection
          rollback_count = 0

          @connection.transaction do
            all_table_names.each do |live_table|
              complete_backup_table = "#{live_table}_complete_backup_#{backup_timestamp}"
              next unless @connection.table_exists?(complete_backup_table)

              # Drop current live table
              if @connection.table_exists?(live_table)
                @connection.execute("DROP TABLE #{live_table} CASCADE")
                Rails.logger.debug "🗑️ Dropped current live table: #{live_table}"
              end

              # Restore from complete backup
              @connection.execute("ALTER TABLE #{complete_backup_table} RENAME TO #{live_table}")
              Rails.logger.info "✅ Restored #{complete_backup_table} → #{live_table}"
              rollback_count += 1
            end

            Rails.logger.info "✅ Complete rollback completed: #{rollback_count} tables restored with all constraints/indexes"
          rescue StandardError => e
            Rails.logger.error "❌ Complete rollback failed: #{e.message}"
            raise ActiveRecord::Rollback
          end
        end

        # --- UTILITIES ---

        def self.prepare_for_swap
          @connection.execute('SELECT 1')
          @connection.execute('SET lock_timeout = 30000') # 30s
          @connection.execute('SET statement_timeout = 300000') # 5m
        end

        def self.all_table_names
          Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash.keys
        end

        # --- CLEANUP & MONITORING ---

        def self.cleanup_old_backups(keep_days = 7)
          Rails.logger.info "🧹 Cleaning up backup tables older than #{keep_days} days..."
          cutoff_date = keep_days.days.ago.strftime('%Y%m%d')
          cleaned_count = 0

          @connection.tables.each do |table|
            next unless table.match?(/^.+_backup_\d{8}_\d{6}$/)

            backup_timestamp = table.match(/_backup_(\d{8}_\d{6})$/)[1]
            next unless backup_timestamp < cutoff_date

            @connection.drop_table(table)
            Rails.logger.info "🗑️ Dropped old backup: #{table}"
            cleaned_count += 1
          end

          Rails.logger.info "✅ Cleaned up #{cleaned_count} old backup tables"
          cleaned_count
        end

        def self.verify_constraints_and_indexes
          Rails.logger.info '🔍 Verifying constraints and indexes...'
          issues = verify_table_basics

          all_table_names.each do |table|
            next unless @connection.table_exists?(table)
            verify_table_constraints_and_indexes(table)
          end

          handle_verification_results(issues, 'Constraints and indexes verification')
        end

        def self.verify_swap_success
          Rails.logger.info '🔍 Verifying swap success...'
          issues = verify_table_basics
          handle_verification_results(issues, 'Swap verification')
        end

        def self.verify_table_basics
          issues = []
          all_table_names.each do |table|
            next unless @connection.table_exists?(table)

            issues << "#{table} is empty" if table_empty?(table) && !junction_table?(table)
            issues << "#{table} is not accessible: #{test_table_access(table)}" unless test_table_access(table).nil?
          end
          issues
        end

        def self.verify_table_constraints_and_indexes(table)
          fk_count = @connection.select_value("SELECT COUNT(*) FROM pg_constraint WHERE conrelid = '#{table}'::regclass AND contype = 'f'").to_i
          index_count = @connection.select_value("SELECT COUNT(*) FROM pg_indexes WHERE tablename = '#{table}' AND indexname NOT LIKE '%_pkey'").to_i
          
          Rails.logger.debug "🔗 #{table} has #{fk_count} foreign keys"
          Rails.logger.debug "📊 #{table} has #{index_count} indexes"
        end

        def self.test_table_access(table)
          @connection.execute("SELECT 1 FROM #{table} WHERE FALSE")
          nil
        rescue StandardError => e
          e.message
        end

        def self.handle_verification_results(issues, verification_type)
          if issues.any?
            Rails.logger.error "❌ #{verification_type} failed: #{issues.join(', ')}"
            return false
          end

          Rails.logger.info "✅ #{verification_type} successful"
          true
        end

        def self.swap_metrics
          {
            tables_swapped: @swapped_tables&.count || 0,
            backup_timestamp: @backup_timestamp,
            duration: @swap_duration,
            success: @swap_success || false,
            constraint_errors: @constraint_errors&.count || 0,
            index_errors: @index_errors&.count || 0
          }
        end

        # --- ROLLBACK FUNCTIONALITY ---

        def self.rollback_to_backup(backup_timestamp)
          Rails.logger.info "🔄 Rolling back to backup timestamp: #{backup_timestamp}"
          @connection = ActiveRecord::Base.connection

          validate_backup_tables_exist(backup_timestamp)
          execute_rollback_transaction(backup_timestamp)
        end

        def self.validate_backup_tables_exist(backup_timestamp)
          missing_backups = all_table_names.reject do |live_table|
            backup_table = "#{live_table}_backup_#{backup_timestamp}"
            @connection.table_exists?(backup_table)
          end

          if missing_backups.any?
            missing_tables = missing_backups.map { |table| "#{table}_backup_#{backup_timestamp}" }
            raise StandardError, "Cannot rollback: Missing backup tables: #{missing_tables.join(', ')}"
          end
        end

        def self.execute_rollback_transaction(backup_timestamp)
          rollback_count = 0

          @connection.transaction do
            all_table_names.each do |live_table|
              backup_table = "#{live_table}_backup_#{backup_timestamp}"
              restore_table_from_backup(live_table, backup_table)
              rollback_count += 1
            end

            Rails.logger.info "✅ Rollback completed: #{rollback_count} tables restored"
            Rails.logger.warn '⚠️ Note: Rollback restores original constraints/indexes. New constraints/indexes are lost.'
          rescue StandardError => e
            Rails.logger.error "❌ Rollback failed: #{e.message}"
            raise ActiveRecord::Rollback
          end
        end

        def self.restore_table_from_backup(live_table, backup_table)
          if @connection.table_exists?(live_table)
            @connection.execute("DROP TABLE #{live_table} CASCADE")
            Rails.logger.debug "🗑️ Dropped current live table: #{live_table}"
          end

          @connection.execute("ALTER TABLE #{backup_table} RENAME TO #{live_table}")
          Rails.logger.info "✅ Restored #{backup_table} → #{live_table}"
        end

        def self.list_available_backups
          @connection = ActiveRecord::Base.connection
          backup_tables = @connection.tables.select { |table| table.match?(/^.+_backup_\d{8}_\d{6}$/) }
          
          backup_tables.map { |table| parse_backup_table_info(table) }
                       .group_by { |b| b[:timestamp] }
        end

        def self.parse_backup_table_info(table)
          backup_timestamp = table.match(/_backup_(\d{8}_\d{6})$/)[1]
          table_name = table.gsub(/_backup_\d{8}_\d{6}$/, '')

          {
            table: table_name,
            backup_table: table,
            timestamp: backup_timestamp,
            created_at: parse_backup_timestamp(backup_timestamp)
          }
        end

        def self.parse_backup_timestamp(timestamp)
          # Parse YYYYMMDD_HHMMSS format
          year = timestamp[0..3].to_i
          month = timestamp[4..5].to_i
          day = timestamp[6..7].to_i
          hour = timestamp[9..10].to_i
          minute = timestamp[11..12].to_i
          second = timestamp[13..14].to_i

          Time.new(year, month, day, hour, minute, second)
        rescue StandardError
          nil
        end

        # --- ENHANCED SWAP WITH METRICS ---

        def self.promote_staging_to_live_with_metrics
          start_time = Time.current
          @swap_success = false

          begin
            promote_staging_to_live
            @swap_success = true
          ensure
            @swap_duration = Time.current - start_time
            Rails.logger.info "📊 Swap completed in #{@swap_duration.round(2)}s"
          end
        end
      end
    end
  end
end
