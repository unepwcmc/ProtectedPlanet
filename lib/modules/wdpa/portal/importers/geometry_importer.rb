module Wdpa
  module Portal
    module Importers
      class GeometryImporter
        def self.import(target_table = nil)
          # Use centralized configuration for default table name
          target_table ||= Wdpa::Portal::Config::StagingConfig.get_staging_table_name_from_live_table('protected_areas')
          
          adapter = Wdpa::Portal::Adapters::ImportTablesAdapter.new
          relation = adapter.protected_areas_relation
          
          imported_count = 0
          errors = []

          # Process polygons and points separately using centralized configuration
          Wdpa::Portal::Config::StagingConfig.portal_views.each do |view|
            begin
              result = import_geometry_from_view(view, target_table)
              imported_count += result[:count]
              errors.concat(result[:errors])
            rescue => e
              errors << "Geometry import error for #{view}: #{e.message}"
            end
          end

          {
            success: errors.empty?,
            imported_count: imported_count,
            errors: errors
          }
        end

        private

        def self.import_geometry_from_view(view, target_table)
          # Use direct SQL to copy geometries from view to target table
          connection = ActiveRecord::Base.connection
          
          # Get geometry column name from target table
          geometry_column = get_geometry_column(target_table)
          
          # Use UPDATE with JOIN for efficient geometry copying
          update_query = <<~SQL
            UPDATE #{target_table} 
            SET #{geometry_column} = v.wkb_geometry
            FROM #{view} v
            WHERE #{target_table}.wdpa_id = v.wdpaid
          SQL
          
          result = connection.execute(update_query)
          
          { count: result.cmd_tuples, errors: [] }
        end

        def self.get_geometry_column(target_table)
          # Get the geometry column name from target table
          connection = ActiveRecord::Base.connection
          columns = connection.columns(target_table)
          
          # Look for geometry/geography columns
          geometry_col = columns.find { |col| col.type == :geometry || col.type == :geography }
          
          if geometry_col
            geometry_col.name
          else
            # Fallback to common geometry column names
            %w[wkb_geometry the_geom geometry geom].find do |col_name|
              connection.column_exists?(target_table, col_name)
            end || 'wkb_geometry'
          end
        end
      end
    end
  end
end
