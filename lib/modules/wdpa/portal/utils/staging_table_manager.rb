module Wdpa
  module Portal
    module Utils
      class StagingTableManager
        def self.create_staging_tables
          # TO_BE_DELETED_STEP_1: Test mode logic - remove once Step 1 materialized views are ready
          # First, ensure any existing staging tables are completely removed
          drop_staging_tables
          
          Wdpa::Portal::Config::StagingConfig.staging_tables.each do |table_name|            
            create_staging_table(table_name)
          end
        end

        def self.drop_staging_tables
          Wdpa::Portal::Config::StagingConfig.staging_tables.each do |table_name|
            if ActiveRecord::Base.connection.table_exists?(table_name)
              drop_table_indexes(table_name)
              ActiveRecord::Base.connection.drop_table(table_name)
              Rails.logger.info "Dropped staging table: #{table_name}"
            end
          end
        end

        def self.clear_staging_tables
          Wdpa::Portal::Config::StagingConfig.staging_tables.each do |table_name|
            if ActiveRecord::Base.connection.table_exists?(table_name)
              ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name}")
              Rails.logger.info "Cleared staging table: #{table_name}"
            end
          end
        end

        def self.staging_tables_exist?
          Wdpa::Portal::Config::StagingConfig.staging_tables.all? do |table_name|
            ActiveRecord::Base.connection.table_exists?(table_name)
          end
        end

        # Shared method to ensure staging tables exist
        # Used by both rake tasks and importers
        def self.ensure_staging_tables_exist!(create_if_missing: false)
          unless staging_tables_exist?
            if create_if_missing
              Rails.logger.info "Staging tables don't exist. Creating them..."
              create_staging_tables
              Rails.logger.info "✅ Staging tables created successfully"
            else
              missing_tables = Wdpa::Portal::Config::StagingConfig.staging_tables.select do |table_name|
                !ActiveRecord::Base.connection.table_exists?(table_name)
              end
              error_msg = "Required staging tables are missing: #{missing_tables.join(', ')}. Please create staging tables before running import."
              Rails.logger.error error_msg
              raise StandardError, error_msg
            end
          end
        end

        private

        def self.create_staging_table(staging_table_name)
          live_table_name = Wdpa::Portal::Config::StagingConfig.get_live_table_name_from_staging_name(staging_table_name)
          create_exact_table_copy(live_table_name, staging_table_name)
          Rails.logger.info "Created staging table: #{staging_table_name}"
        end

        def self.create_exact_table_copy(source_table_name, target_table_name, options = {})
          connection = ActiveRecord::Base.connection
          
          # Default options for comprehensive copying
          default_options = {
            copy_structure: true,      # Copy table structure
            copy_constraints: true,    # Copy constraints
            copy_indexes: true,        # Copy indexes
            copy_storage: false,       # Copy storage parameters (usually not needed for staging)
            copy_comments: true,       # Copy table and column comments
            copy_triggers: false,      # Copy triggers (usually not needed for staging)
            empty_table: true          # Create empty table
          }.merge(options)
          
          if default_options[:copy_structure] && default_options[:copy_constraints]
            # Use CREATE TABLE LIKE for comprehensive copying
            sql = "CREATE TABLE #{target_table_name} (LIKE #{source_table_name}"
            sql += " INCLUDING ALL" if default_options[:copy_constraints]
            sql += " INCLUDING STORAGE" if default_options[:copy_storage]
            sql += " INCLUDING COMMENTS" if default_options[:copy_comments]
            sql += ")"
            
            connection.execute(sql)
            Rails.logger.debug "Created #{target_table_name} with comprehensive copying options"
          else
            # Fallback to simple schema copy
            create_exact_table_copy(source_table_name, target_table_name)
          end
          
          # Copy indexes separately if requested (CREATE TABLE LIKE doesn't copy indexes)
          if default_options[:copy_indexes]
            copy_indexes_from_table(source_table_name, target_table_name)
          end
        end

        def self.column_exists?(table_name, column_name)
          connection = ActiveRecord::Base.connection
          columns = connection.columns(table_name)
          columns.any? { |col| col.name == column_name.to_s }
        end

        def self.copy_indexes_from_table(source_table_name, target_table_name)
          # Copy indexes from source table to target table with renamed index names
          indexes = ActiveRecord::Base.connection.indexes(source_table_name)
          columns_info = ActiveRecord::Base.connection.columns(source_table_name).map { |c| [c.name, c.sql_type] }.to_h

          indexes.each do |index|
            begin
              # Create new index name for the staging table
              new_index_name = Wdpa::Portal::Config::StagingConfig.generate_staging_index_name(index.name)
              
              # Build the index creation SQL
              columns = index.columns.join(', ')
              unique = index.unique ? 'UNIQUE' : ''
              
              # Handle special index types (like GIST for geometry)
              index_type = ''
              if index.columns.any? { |col| columns_info[col] =~ /\Ageometry/i }
                index_type = 'USING GIST'
              end
              
              index_sql = "CREATE #{unique} INDEX #{new_index_name} ON #{target_table_name} #{index_type} (#{columns}) ".strip
              ActiveRecord::Base.connection.execute(index_sql)
              
              Rails.logger.debug "Created index: #{new_index_name}"
            rescue => e
              # Log the error but continue with other indexes
              Rails.logger.warn "Failed to create index for #{target_table_name}: #{e.message}"
            end
          end
        end

        def self.drop_table_indexes(table_name)
          # Get all indexes for the table
          indexes = ActiveRecord::Base.connection.indexes(table_name)
          
          indexes.each do |index|
            begin
              ActiveRecord::Base.connection.execute("DROP INDEX IF EXISTS #{index.name}")
              Rails.logger.debug "Dropped index: #{index.name}"
            rescue => e
              Rails.logger.warn "Failed to drop index #{index.name}: #{e.message}"
            end
          end
        end
      end
    end
  end
end
