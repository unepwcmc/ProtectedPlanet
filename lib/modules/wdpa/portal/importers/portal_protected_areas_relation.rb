# TO_BE_DELETED_STEP_1: This relation should be updated once Step 1 materialized views are ready
# This relation provides access to portal standard polygons and points data

module Wdpa
  module Portal
    module Importers
      class PortalProtectedAreasRelation
        # TODO_IMPORT: Update this method once Step 1 provides actual materialized views
        # This method queries portal_standard_polygons and portal_standard_points views in batches
        def find_in_batches
          batch_size = Wdpa::Portal::Config::StagingConfig.batch_import_protected_areas_from_view_size
          
          # Query both polygons and points views with proper batching
          Wdpa::Portal::Config::StagingConfig.portal_views.each do |view_name|
            next unless view_name.include?('polygons') || view_name.include?('points')
            
            total_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{view_name}").to_i
            offset = 0

            while offset < total_count
              query = "SELECT * FROM #{view_name} LIMIT #{batch_size} OFFSET #{offset}"
              batch = ActiveRecord::Base.connection.select_all(query)
              yield batch
              offset += batch_size
            end
          end
        end

        # TODO_IMPORT: Update this method once Step 1 provides actual materialized views
        def count
          total_count = 0
          
          # TODO_IMPORT: Verify view names and schema once Step 1 is ready
          Wdpa::Portal::Config::StagingConfig.portal_views.each do |view_name|
            next unless view_name.include?('polygons') || view_name.include?('points')
            
            count_result = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{view_name}")
            total_count += count_result.to_i
          end
          
          total_count
        end

        # TODO_IMPORT: Update this method once Step 1 provides actual materialized views
        def exists?
          # TODO_IMPORT: Verify view names and schema once Step 1 is ready
          Wdpa::Portal::Config::StagingConfig.portal_views.any? do |view_name|
            next unless view_name.include?('polygons') || view_name.include?('points')
            
            begin
              ActiveRecord::Base.connection.select_value("SELECT 1 FROM #{view_name} LIMIT 1")
              true
            rescue
              false
            end
          end
        end

        # TODO_IMPORT: Update this method once Step 1 provides actual materialized views
        def portal_views_exist?
          # TODO_IMPORT: Verify view names and schema once Step 1 is ready
          Wdpa::Portal::Config::StagingConfig.portal_views.all? do |view_name|
            ActiveRecord::Base.connection.table_exists?(view_name)
          end
        end
      end
    end
  end
end
