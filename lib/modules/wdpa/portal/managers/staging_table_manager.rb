# frozen_string_literal: true

module Wdpa
  module Portal
    module Managers
      class StagingTableManager
        def self.include_indexes?
          lw = ActiveModel::Type::Boolean.new.cast(ENV['PP_RELEASE_STAGING_LIGHTWEIGHT'])
          return false if lw
          val = ENV['PP_RELEASE_STAGING_INCLUDE_INDEXES']
          return true if val.nil?
          ActiveModel::Type::Boolean.new.cast(val)
        end

        def self.include_foreign_keys?
          lw = ActiveModel::Type::Boolean.new.cast(ENV['PP_RELEASE_STAGING_LIGHTWEIGHT'])
          return false if lw
          val = ENV['PP_RELEASE_STAGING_INCLUDE_FKS']
          return true if val.nil?
          ActiveModel::Type::Boolean.new.cast(val)
        end

        def self.create_staging_tables
          drop_staging_tables
          create_all_staging_tables
          add_all_foreign_keys if include_foreign_keys?
        end

        def self.create_all_staging_tables
          Wdpa::Portal::Config::PortalImportConfig.staging_tables.each do |table_name|
            create_staging_table(table_name)
          end
        end

        def self.add_all_foreign_keys
          Wdpa::Portal::Config::PortalImportConfig.staging_tables.each do |table_name|
            add_foreign_keys_to_staging_table(table_name)
          end
        end

        def self.drop_staging_tables
          tables_to_drop = get_tables_in_drop_order
          tables_to_drop.each { |table_name| drop_table_safely(table_name) }
        end

        def self.get_tables_in_drop_order
          # Drop tables in reverse order of swap sequence to handle foreign key dependencies
          Wdpa::Portal::Config::PortalImportConfig.swap_sequence_live_table_names.reverse.map do |live_table|
            Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash[live_table]
          end.compact
        end

        def self.drop_table_safely(table_name)
          return unless ActiveRecord::Base.connection.table_exists?(table_name)

          begin
            ActiveRecord::Base.connection.drop_table(table_name)
            Rails.logger.info "Dropped staging table: #{table_name}"
          rescue ActiveRecord::StatementInvalid => e
            raise e unless e.message.include?('DependentObjectsStillExist')

            Rails.logger.warn "Cannot drop #{table_name} due to dependencies, using CASCADE"
            ActiveRecord::Base.connection.drop_table(table_name, if_exists: true, force: :cascade)
            Rails.logger.info "Dropped staging table with CASCADE: #{table_name}"
          end
        end

        def self.staging_tables_exist?
          Wdpa::Portal::Config::PortalImportConfig.staging_tables.all? do |table_name|
            ActiveRecord::Base.connection.table_exists?(table_name)
          end
        end

        def self.ensure_staging_tables_exist!(create_if_missing: false)
          return if staging_tables_exist?

          if create_if_missing
            Rails.logger.info "Staging tables don't exist. Creating them..."
            create_staging_tables
            Rails.logger.info '✅ Staging tables created successfully'
          else
            missing_tables = Wdpa::Portal::Config::PortalImportConfig.staging_tables.reject do |table_name|
              ActiveRecord::Base.connection.table_exists?(table_name)
            end
            error_msg = "Required staging tables are missing: #{missing_tables.join(', ')}. Please create staging tables before running import."
            Rails.logger.error error_msg
            raise StandardError, error_msg
          end
        end

        def self.create_staging_table(staging_table_name)
          live_table_name = Wdpa::Portal::Config::PortalImportConfig.get_live_table_name_from_staging_name(staging_table_name)
          unless ActiveRecord::Base.connection.table_exists?(live_table_name)
            Rails.logger.warn "Skipping staging for #{staging_table_name} because live table #{live_table_name} does not exist"
            return
          end
          create_exact_table_copy(live_table_name, staging_table_name)

          # If we excluded FKs at creation time (via LIKE options), ensure none remain
          unless include_foreign_keys?
            drop_all_foreign_keys(staging_table_name)
          end

          # Ensure primary key constraint on staging has the expected staging_ prefix
          rename_primary_key_to_staging_prefix(live_table_name, staging_table_name)

          Rails.logger.info "Created staging table: #{staging_table_name}"
        end

        def self.add_foreign_keys_to_staging_table(staging_table_name)
          live_table_name = Wdpa::Portal::Config::PortalImportConfig.get_live_table_name_from_staging_name(staging_table_name)
          add_foreign_keys(staging_table_name, live_table_name)
          Rails.logger.info "Added foreign keys to: #{staging_table_name}"
        end

        def self.create_exact_table_copy(source_table_name, target_table_name)
          connection = ActiveRecord::Base.connection

          # Build LIKE options dynamically to control indexes and constraints
          like_opts = [
            'INCLUDING DEFAULTS',
            'INCLUDING CONSTRAINTS' # includes PK/UNIQUE/NOT NULL; we will drop FKs if needed
          ]
          like_opts << 'INCLUDING INDEXES' if include_indexes?

          sql = <<~SQL
            CREATE TABLE #{target_table_name}
            (LIKE #{source_table_name}
             #{like_opts.join(' ')})
          SQL

          connection.execute(sql)

          # Clean up automatically generated _idx suffixes from indexes
          cleanup_auto_generated_index_suffixes(target_table_name)

          # Create separate sequence for staging table to avoid primary key conflicts
          create_staging_sequence(source_table_name, target_table_name)

          Rails.logger.debug "Created #{target_table_name} as copy of #{source_table_name} with options: #{like_opts.join(', ')}"
        end

        def self.create_staging_sequence(source_table_name, target_table_name)
          connection = ActiveRecord::Base.connection
          primary_key = connection.primary_key(source_table_name)

          # Skip sequence creation for junction tables (no primary key)
          unless primary_key
            Rails.logger.debug "Skipping sequence creation for junction table #{target_table_name} (no primary key)"
            return
          end

          # Use Rails 5.2 naming convention: table_column_seq
          sequence_name = "#{target_table_name}_#{primary_key}_seq"

          if sequence_exists?(sequence_name)
            Rails.logger.debug "Dropping existing sequence #{sequence_name} for #{target_table_name}"
            drop_sequence(connection, sequence_name)
          end

          create_new_sequence(connection, sequence_name, target_table_name)

          # Set ownership and permissions like Rails does
          set_sequence_ownership(connection, sequence_name, target_table_name, primary_key)
          set_table_default_to_sequence(connection, target_table_name, primary_key, sequence_name)
        end

        def self.create_new_sequence(connection, sequence_name, target_table_name)
          connection.execute(<<~SQL)
            CREATE SEQUENCE #{sequence_name}
            AS integer
            START WITH 1
            INCREMENT BY 1
            NO MINVALUE
            NO MAXVALUE
            CACHE 1
          SQL
          Rails.logger.debug "Created separate sequence #{sequence_name} for #{target_table_name}"
        end

        def self.set_sequence_ownership(connection, sequence_name, target_table_name, primary_key)
          # Set sequence ownership to the table column (like Rails does)
          connection.execute(<<~SQL)
            ALTER SEQUENCE #{sequence_name} OWNED BY #{target_table_name}.#{primary_key}
          SQL
          Rails.logger.debug "Set sequence ownership: #{sequence_name} -> #{target_table_name}.#{primary_key}"
        end

        def self.set_table_default_to_sequence(connection, target_table_name, primary_key, sequence_name)
          connection.execute(<<~SQL)
            ALTER TABLE #{target_table_name}
            ALTER COLUMN #{primary_key} SET DEFAULT nextval('#{sequence_name}'::regclass)
          SQL
        end

        def self.drop_sequence(connection, sequence_name)
          connection.execute("DROP SEQUENCE IF EXISTS #{sequence_name}")
          Rails.logger.debug "Dropped sequence #{sequence_name}"
        end

        def self.sequence_exists?(sequence_name)
          connection = ActiveRecord::Base.connection
          result = connection.execute(<<~SQL)
            SELECT EXISTS (
              SELECT 1 FROM pg_sequences
              WHERE schemaname = 'public'
              AND sequencename = '#{sequence_name}'
            )
          SQL
          exists_value = result.first.values.first
          %w[t true 1].include?(exists_value.to_s.downcase)
        end

        def self.add_foreign_keys(staging_table_name, live_table_name)
          connection = ActiveRecord::Base.connection
          live_foreign_keys = connection.foreign_keys(live_table_name)

          live_foreign_keys.each do |fk|
            add_single_foreign_key(connection, staging_table_name, fk)
          end
        end

        def self.drop_all_foreign_keys(staging_table_name)
          connection = ActiveRecord::Base.connection
          existing_fks = connection.foreign_keys(staging_table_name)
          existing_fks.each do |fk|
            begin
              connection.remove_foreign_key(staging_table_name, name: fk.name)
              Rails.logger.debug "Removed FK from #{staging_table_name}: #{fk.name}"
            rescue StandardError => e
              Rails.logger.warn "Failed to remove FK #{fk.name} from #{staging_table_name}: #{e.message}"
            end
          end
        end

        def self.add_single_foreign_key(connection, staging_table_name, fk)
          referenced_table = determine_referenced_table(fk.to_table)

          connection.add_foreign_key(staging_table_name, referenced_table,
            name: fk.name,
            column: fk.column,
            primary_key: fk.primary_key,
            on_delete: fk.on_delete)

          Rails.logger.debug "Added FK: #{staging_table_name}.#{fk.column} -> #{referenced_table}.#{fk.primary_key}"
        end

        def self.determine_referenced_table(live_table_name)
          # Check if there's a corresponding staging table using the config mapping
          staging_table_name = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash[live_table_name]
          # Reference staging table if it exists in our config
          # Reference live table if no staging table exists
          staging_table_name || live_table_name
        end

        # --- Primary key helpers (for swap compatibility) ---
        def self.get_primary_key_name(table_name)
          result = ActiveRecord::Base.connection.execute(<<~SQL)
            SELECT conname
            FROM pg_constraint
            WHERE conrelid = '#{table_name}'::regclass
              AND contype = 'p'
          SQL
          result.first&.dig('conname')
        end

        def self.rename_primary_key_to_staging_prefix(live_table_name, staging_table_name)
          live_pk = get_primary_key_name(live_table_name)
          staging_pk = get_primary_key_name(staging_table_name)

          # Skip if either side lacks a primary key (e.g., some junction tables)
          return unless live_pk && staging_pk

          expected = "staging_#{live_pk}"
          return if staging_pk == expected

          begin
            ActiveRecord::Base.connection.execute(
              "ALTER TABLE #{staging_table_name} RENAME CONSTRAINT #{staging_pk} TO #{expected}"
            )
            Rails.logger.debug "Renamed staging PK on #{staging_table_name}: #{staging_pk} -> #{expected}"
          rescue StandardError => e
            Rails.logger.warn "Failed to rename PK on #{staging_table_name}: #{e.message}"
          end
        end

        def self.cleanup_auto_generated_index_suffixes(table_name)
          connection = ActiveRecord::Base.connection

          # Get all indexes for the table
          indexes = connection.execute(<<~SQL)
            SELECT indexname, indexdef
            FROM pg_indexes
            WHERE tablename = '#{table_name}'
            AND schemaname = 'public'
            AND indexname LIKE '%_idx'
          SQL

          indexes.each do |index|
            old_name = index['indexname']

            # Only process indexes that end with _idx
            next unless old_name.end_with?('_idx')

            # Remove exactly one _idx suffix (regardless of how many there are)
            new_name = old_name.sub(/_idx$/, '')

            # Only rename if the new name doesn't already exist
            if index_exists?(connection, new_name)
              Rails.logger.debug "📝 Skipped renaming #{old_name} (target name #{new_name} already exists)"
            else
              begin
                connection.execute("ALTER INDEX #{old_name} RENAME TO #{new_name}")
                Rails.logger.debug "📝 Cleaned up index suffix: #{old_name} → #{new_name}"
              rescue StandardError => e
                Rails.logger.warn "⚠️ Failed to rename index #{old_name}: #{e.message}"
              end
            end
          end
        end

        def self.index_exists?(connection, index_name)
          result = connection.execute(<<~SQL)
            SELECT 1
            FROM pg_indexes
            WHERE indexname = '#{index_name}'
            AND schemaname = 'public'
          SQL
          result.any?
        end

        # Copy indexes from the live table to the staging table (useful when we skipped them at creation)
        def self.add_all_indexes
          Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash.each do |live_table, staging_table|
            add_indexes_to_staging_table(staging_table, live_table)
          end
        end

        def self.add_indexes_to_staging_table(staging_table_name, live_table_name)
          connection = ActiveRecord::Base.connection

          live_indexes = connection.indexes(live_table_name)
          staging_indexes = connection.indexes(staging_table_name)

          require 'set' unless defined?(Set)
          existing_signatures = staging_indexes.map do |ix|
            [ix.columns, ix.where, ix.unique, ix.using]
          end.to_set

          live_indexes.each do |ix|
            # Skip expression-only indexes we can’t reproduce via add_index easily
            next if ix.columns.nil? || ix.columns.empty?

            sig = [ix.columns, ix.where, ix.unique, ix.using]
            next if existing_signatures.include?(sig)

            options = {}
            options[:unique] = ix.unique if ix.unique
            options[:using]  = ix.using  if ix.using
            options[:where]  = ix.where  if ix.where

            begin
              connection.add_index(staging_table_name, ix.columns, **options)
              Rails.logger.debug "Added index on #{staging_table_name}(#{ix.columns.join(',')})"
            rescue StandardError => e
              Rails.logger.warn "Failed to add index on #{staging_table_name}(#{ix.columns.join(',')}): #{e.message}"
            end
          end
        end
      end
    end
  end
end
