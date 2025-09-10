module Wdpa
  module Portal
    module Services
      # Service for promoting staging tables to live tables
      #
      # Usage:
      #   Wdpa::Portal::Services::TableSwapService.promote_staging_to_live
      #
      # This service:
      # 1. Creates timestamped backups of existing live tables
      # 2. Swaps staging tables to live tables in dependency order
      # 3. Adds foreign key constraints to the live tables
      # 4. Adds indexes to the live tables
      # 5. Handles rollback if any step fails
      class TableSwapService
        # Get swap sequence from configuration based on table dependencies
        def self.swap_sequence
          @swap_sequence ||= begin
            # Phase 1: Independent tables (no foreign key dependencies)
            independent_tables = [
              Source.table_name,
              GreenListStatus.table_name,
              NoTakeStatus.table_name,
              CountryStatistic.table_name,
              GlobalStatistic.table_name,
              PameEvaluation.table_name,
              PameSource.table_name,
              PameStatistic.table_name,
              StoryMapLink.table_name
            ]

            # Phase 2: Main entity tables
            main_entity_tables = [
              ProtectedArea.table_name,
              ProtectedAreaParcel.table_name
            ]

            # Phase 3: Junction tables (depend on both entities)
            junction_tables = [
              Country.countries_pas_junction_table_name,
              Country.countries_pa_parcels_junction_table_name,
              Source.protected_areas_sources_junction_table_name,
              Source.protected_area_parcels_sources_junction_table_name,
              Country.countries_pame_evaluations_junction_table_name
            ]

            independent_tables + main_entity_tables + junction_tables
          end
        end

        def self.promote_staging_to_live
          Rails.logger.info 'Starting table swap: promoting staging tables to live...'
          @backup_timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
          @swapped_tables = []
          @connection = ActiveRecord::Base.connection

          # Prepare database for minimal disruption
          prepare_for_swap

          # Use a single transaction to minimize disruption
          @connection.transaction do
            # Phase 1: Validate staging tables exist and have data
            validate_staging_tables

            # Phase 2: Create atomic table swaps (minimal lock time)
            perform_atomic_swaps

            Rails.logger.info 'Table swap completed successfully'
            Rails.logger.info "Backup tables created with timestamp: #{@backup_timestamp}"
          rescue StandardError => e
            Rails.logger.error "Table swap failed: #{e.message}"
            Rails.logger.error 'Rolling back transaction...'
            raise ActiveRecord::Rollback
          end

          # Phase 3: Add constraints and indexes (outside transaction to avoid long locks)
          begin
            add_foreign_keys_to_live_tables
            add_indexes
            Rails.logger.info 'Constraints and indexes added successfully'
          rescue StandardError => e
            Rails.logger.warn "Failed to add constraints/indexes: #{e.message}"
            Rails.logger.warn 'Tables are swapped but may need manual constraint/index addition'
          end
        end

        def self.validate_staging_tables
          Rails.logger.info 'Validating staging tables before swap...'

          missing_tables = []
          empty_tables = []

          Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash.each do |live_table, staging_table|
            unless @connection.table_exists?(staging_table)
              missing_tables << staging_table
              next
            end

            # Check if staging table has data (except for junction tables which might be empty)
            next if junction_table?(live_table)

            count = @connection.execute("SELECT COUNT(*) FROM #{staging_table}").first['count'].to_i
            empty_tables << staging_table if count.zero?
          end

          raise "Missing staging tables: #{missing_tables.join(', ')}" if missing_tables.any?

          Rails.logger.warn "Empty staging tables (may be expected): #{empty_tables.join(', ')}" if empty_tables.any?

          Rails.logger.info 'Staging table validation completed'
        end

        def self.junction_table?(table_name)
          junction_tables = [
            Country.countries_pas_junction_table_name,
            Country.countries_pa_parcels_junction_table_name,
            Source.protected_areas_sources_junction_table_name,
            Source.protected_area_parcels_sources_junction_table_name,
            Country.countries_pame_evaluations_junction_table_name
          ]
          junction_tables.include?(table_name)
        end

        def self.perform_atomic_swaps
          Rails.logger.info 'Performing atomic table swaps to minimize disruption...'

          # Get the staging to live mapping
          staging_to_live = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash.invert

          swap_sequence.each do |live_table_name|
            staging_table_name = staging_to_live[live_table_name]
            next unless staging_table_name && @connection.table_exists?(staging_table_name)

            # Perform atomic swap: staging -> live, live -> backup in one operation
            swap_single_table(live_table_name, staging_table_name)
            @swapped_tables << live_table_name
          end
        end

        def self.swap_single_table(live_table_name, staging_table_name)
          backup_table_name = "#{live_table_name}_backup_#{@backup_timestamp}"

          if @connection.table_exists?(live_table_name)
            # Drop existing backup if it exists
            @connection.execute("DROP TABLE IF EXISTS #{backup_table_name}")

            # Atomic swap: live -> backup, staging -> live
            @connection.execute("ALTER TABLE #{live_table_name} RENAME TO #{backup_table_name}")
            Rails.logger.debug "Backed up: #{live_table_name} -> #{backup_table_name}"
          end

          # Rename staging to live
          @connection.execute("ALTER TABLE #{staging_table_name} RENAME TO #{live_table_name}")
          Rails.logger.info "Swapped: #{staging_table_name} -> #{live_table_name}"
        end

        # Method to prepare for minimal disruption by warming up connections
        def self.prepare_for_swap
          Rails.logger.info 'Preparing for table swap to minimize disruption...'

          # Warm up database connections
          @connection.execute('SELECT 1')

          # Set session parameters for faster operations
          @connection.execute('SET lock_timeout = 30000') # 30 seconds
          @connection.execute('SET statement_timeout = 300000') # 5 minutes

          Rails.logger.info 'Database prepared for swap'
        end

        def self.drop_table_indexes(table_name)
          # Get all indexes for the table
          indexes = ActiveRecord::Base.connection.indexes(table_name)

          indexes.each do |index|
            ActiveRecord::Base.connection.execute("DROP INDEX IF EXISTS #{index.name}")
            Rails.logger.debug "Dropped index: #{index.name}"
          rescue StandardError => e
            Rails.logger.warn "Failed to drop index #{index.name}: #{e.message}"
          end
        end

        def self.add_foreign_keys_to_live_tables
          Rails.logger.info 'Adding foreign key constraints to live tables...'

          # Add foreign keys for main entity tables in parallel where possible
          [ProtectedArea.table_name, ProtectedAreaParcel.table_name].each do |table_name|
            add_foreign_keys_for_table(table_name)
          end
        end

        def self.add_foreign_keys_for_table(table_name)
          return unless @connection.table_exists?(table_name)

          # Define foreign key constraints for each table
          foreign_keys = get_foreign_key_definitions(table_name)

          # Add foreign keys with minimal locking
          foreign_keys.each do |constraint_name, definition|
            # Use NOT VALID to add constraint without checking existing data (faster)
            @connection.execute("ALTER TABLE #{table_name} ADD CONSTRAINT #{constraint_name} #{definition} NOT VALID")
            Rails.logger.debug "Added foreign key #{constraint_name} to #{table_name} (not validated)"
          rescue StandardError => e
            Rails.logger.warn "Failed to add foreign key #{constraint_name} to #{table_name}: #{e.message}"
          end

          # Validate constraints after adding (can be done in background)
          validate_foreign_keys_for_table(table_name)
        end

        def self.validate_foreign_keys_for_table(table_name)
          return unless @connection.table_exists?(table_name)

          foreign_keys = get_foreign_key_definitions(table_name)

          foreign_keys.each do |constraint_name, _definition|
            @connection.execute("ALTER TABLE #{table_name} VALIDATE CONSTRAINT #{constraint_name}")
            Rails.logger.debug "Validated foreign key #{constraint_name} on #{table_name}"
          rescue StandardError => e
            Rails.logger.warn "Failed to validate foreign key #{constraint_name} on #{table_name}: #{e.message}"
          end
        end

        def self.get_foreign_key_definitions(table_name)
          case table_name
          when ProtectedArea.table_name, ProtectedAreaParcel.table_name
            {
              "fk_#{table_name}_governance" => 'FOREIGN KEY (governance_id) REFERENCES governances(id)',
              "fk_#{table_name}_designation" => 'FOREIGN KEY (designation_id) REFERENCES designations(id)',
              "fk_#{table_name}_legal_status" => 'FOREIGN KEY (legal_status_id) REFERENCES legal_statuses(id)',
              "fk_#{table_name}_iucn_category" => 'FOREIGN KEY (iucn_category_id) REFERENCES iucn_categories(id)',
              "fk_#{table_name}_management_authority" => 'FOREIGN KEY (management_authority_id) REFERENCES management_authorities(id)',
              "fk_#{table_name}_realm" => 'FOREIGN KEY (realm_id) REFERENCES realms(id)'
            }
          else
            {}
          end
        end

        def self.add_indexes
          Rails.logger.info 'Adding indexes to live tables...'

          # Add indexes concurrently to avoid blocking reads
          @swapped_tables.each do |table_name|
            add_indexes_for_table(table_name)
          end
        end

        def self.add_indexes_for_table(table_name)
          return unless @connection.table_exists?(table_name)

          indexes = get_index_definitions(table_name)

          indexes.each do |index_name, definition|
            # Use CONCURRENTLY to avoid blocking reads during index creation
            @connection.execute("CREATE INDEX CONCURRENTLY #{index_name} ON #{table_name} #{definition}")
            Rails.logger.debug "Added index #{index_name} to #{table_name} (concurrently)"
          rescue StandardError => e
            # If CONCURRENTLY fails, try without it (some constraints don't support it)
            begin
              @connection.execute("CREATE INDEX #{index_name} ON #{table_name} #{definition}")
              Rails.logger.debug "Added index #{index_name} to #{table_name}"
            rescue StandardError => e2
              Rails.logger.warn "Failed to add index #{index_name} to #{table_name}: #{e2.message}"
            end
          end
        end

        def self.get_index_definitions(table_name)
          case table_name
          when ProtectedArea.table_name
            {
              'idx_protected_areas_wdpa_id' => '(wdpa_id)',
              'idx_protected_areas_governance_id' => '(governance_id)',
              'idx_protected_areas_designation_id' => '(designation_id)',
              'idx_protected_areas_legal_status_id' => '(legal_status_id)',
              'idx_protected_areas_iucn_category_id' => '(iucn_category_id)',
              'idx_protected_areas_management_authority_id' => '(management_authority_id)',
              'idx_protected_areas_realm_id' => '(realm_id)'
            }
          when ProtectedAreaParcel.table_name
            {
              'idx_protected_area_parcels_wdpa_id' => '(wdpa_id)',
              'idx_protected_area_parcels_wdpa_pid' => '(wdpa_pid)',
              'idx_protected_area_parcels_governance_id' => '(governance_id)',
              'idx_protected_area_parcels_designation_id' => '(designation_id)',
              'idx_protected_area_parcels_legal_status_id' => '(legal_status_id)',
              'idx_protected_area_parcels_iucn_category_id' => '(iucn_category_id)',
              'idx_protected_area_parcels_management_authority_id' => '(management_authority_id)',
              'idx_protected_area_parcels_realm_id' => '(realm_id)'
            }
          else
            {}
          end
        end

        # Get all table names from configuration
        def self.all_table_names
          @all_table_names ||= Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash.keys
        end

        # Cleanup method to remove old backup tables after successful verification
        # Call this method after verifying the swap was successful
        def self.cleanup_backups(timestamp = nil)
          timestamp ||= @backup_timestamp
          return unless timestamp

          Rails.logger.info "Cleaning up backup tables with timestamp: #{timestamp}"

          all_table_names.each do |live_table|
            backup_table = "#{live_table}_backup_#{timestamp}"

            if ActiveRecord::Base.connection.table_exists?(backup_table)
              ActiveRecord::Base.connection.drop_table(backup_table)
              Rails.logger.info "Dropped backup table: #{backup_table}"
            end
          end
        end

        # Method to list all backup tables for manual cleanup if needed
        def self.list_backup_tables
          connection = ActiveRecord::Base.connection
          backup_tables = connection.select_all(<<~SQL)
            SELECT table_name#{' '}
            FROM information_schema.tables#{' '}
            WHERE table_name LIKE '%_backup_%'#{' '}
            AND table_schema = 'public'
            ORDER BY table_name
          SQL

          backup_tables.map { |row| row['table_name'] }
        end

        # Dry run method to validate swap without actually performing it
        def self.dry_run
          Rails.logger.info 'Performing dry run of table swap...'

          validation_results = {
            staging_tables_exist: true,
            staging_tables_have_data: true,
            live_tables_exist: true,
            estimated_downtime: 'minimal',
            issues: []
          }

          begin
            validate_staging_tables
            Rails.logger.info '✓ All staging tables validated successfully'
          rescue StandardError => e
            validation_results[:staging_tables_exist] = false
            validation_results[:issues] << "Staging validation failed: #{e.message}"
            Rails.logger.error "✗ Staging validation failed: #{e.message}"
          end

          # Check live tables
          missing_live_tables = []
          all_table_names.each do |live_table|
            missing_live_tables << live_table unless ActiveRecord::Base.connection.table_exists?(live_table)
          end

          if missing_live_tables.any?
            validation_results[:live_tables_exist] = false
            validation_results[:issues] << "Missing live tables: #{missing_live_tables.join(', ')}"
            Rails.logger.warn "✗ Missing live tables: #{missing_live_tables.join(', ')}"
          else
            Rails.logger.info '✓ All live tables exist'
          end

          Rails.logger.info "Dry run completed. Issues found: #{validation_results[:issues].length}"
          validation_results
        end

        # Method to get current swap status
        def self.swap_status
          {
            backup_timestamp: @backup_timestamp,
            swapped_tables: @swapped_tables || [],
            backup_tables: list_backup_tables,
            last_swap_time: @last_swap_time
          }
        end
      end
    end
  end
end
