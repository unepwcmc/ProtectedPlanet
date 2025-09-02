module Wdpa
  module Portal
    module Importers
      class PortalSourcesRelation
        # TODO_IMPORT: Update this method once Step 1 materialized views are ready
        # This method currently uses a placeholder table name for portal sources
        # Once Step 1 is complete, this table should exist in the Portal database
        def find_each
          # TODO: Verify this table name matches what Step 1 developer creates
          if portal_sources_exist?
            # TODO_IMPORT: Update this query once Step 1 provides the actual column names
            # The current query assumes standard source column names
            query = "SELECT * FROM #{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')}"
            
            ActiveRecord::Base.connection.select_all(query).each do |row|
              yield row
            end
          else
            # Sources should always come from portal sources table
            # No CSV fallback - this is a required table
            raise StandardError, "#{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')} table is required but does not exist"
          end
        end

        def count
          if portal_sources_exist?
            # TODO_IMPORT: Verify this table name matches what Step 1 developer creates
            ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')}").to_i
          else
            # Sources should always come from portal sources table
            # No CSV fallback - this is a required table
            raise StandardError, "#{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')} table is required but does not exist"
          end
        end

        def portal_sources_exist?
          # TODO_IMPORT: Verify this table name matches what Step 1 developer creates
          # portal sources is now a table that acts like a view
          ActiveRecord::Base.connection.table_exists?(Wdpa::Portal::Config::StagingConfig.portal_view_for('sources'))
        end

        private

        def query_portal_sources
          # TODO_IMPORT: Update this method once Step 1 materialized views are ready
          # This method will query the actual portal sources table
          # TODO_IMPORT: Verify this table name matches what Step 1 developer creates
          query = "SELECT * FROM #{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')}"
          
          ActiveRecord::Base.connection.select_all(query)
        end

        # Remove CSV fallback methods - sources should always come from portal table
        # def query_csv_sources - REMOVED
        # def count_csv_sources - REMOVED
      end
    end
  end
end
