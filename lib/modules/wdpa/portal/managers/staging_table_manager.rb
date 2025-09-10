# frozen_string_literal: true

module Wdpa
  module Portal
    module Managers
      class StagingTableManager
        def self.create_staging_tables
          drop_staging_tables

          Wdpa::Portal::Config::PortalImportConfig.staging_tables.each do |table_name|
            create_staging_table(table_name)
          end
        end

        def self.drop_staging_tables
          Wdpa::Portal::Config::PortalImportConfig.staging_tables.each do |table_name|
            if ActiveRecord::Base.connection.table_exists?(table_name)
              ActiveRecord::Base.connection.drop_table(table_name)
              Rails.logger.info "Dropped staging table: #{table_name}"
            end
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
          create_exact_table_copy(live_table_name, staging_table_name)
          Rails.logger.info "Created staging table: #{staging_table_name}"
        end

        def self.create_exact_table_copy(source_table_name, target_table_name)
          connection = ActiveRecord::Base.connection

          sql = <<~SQL
            CREATE TABLE #{target_table_name}
            (LIKE #{source_table_name}
             INCLUDING DEFAULTS
             INCLUDING CONSTRAINTS
             INCLUDING INDEXES
             INCLUDING COMMENTS)
          SQL

          connection.execute(sql)
          Rails.logger.debug "Created #{target_table_name} as exact copy of #{source_table_name}"
        end

        def self.column_exists?(table_name, column_name)
          connection = ActiveRecord::Base.connection
          connection.columns(table_name).any? { |col| col.name == column_name.to_s }
        end
      end
    end
  end
end
