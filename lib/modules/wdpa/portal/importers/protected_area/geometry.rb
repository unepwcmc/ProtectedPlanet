# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      class ProtectedArea::Geometry < Base
        def self.import_to_staging(notifier: nil)
          protected_areas_result = import_geometry_for_table(Staging::ProtectedArea.table_name)
          protected_area_parcels_result = import_geometry_for_table(Staging::ProtectedAreaParcel.table_name)

          message = "#{protected_areas_result[:imported_count]} PA Geometries imported, #{protected_area_parcels_result[:imported_count]} PA parcel geometries imported"
          Rails.logger.info message
          notifier&.phase(message)

          {
            protected_areas: protected_areas_result,
            protected_area_parcels: protected_area_parcels_result
          }
        end

        def self.import_geometry_for_table(target_table)
          unless validate_target_table(target_table)
            return failure_result("Target staging table #{target_table} does not exist or has no records", 0)
          end

          imported_count = 0
          soft_errors = []
          hard_errors = []

          Wdpa::Portal::Config::PortalImportConfig.portal_protected_area_staging_materialised_views.each do |view|
            if Wdpa::Portal::ImportRuntimeConfig.checkpoints? && Wdpa::Portal::Checkpoint.geometry_done?(view,
              target_table)
              Rails.logger.info "Skipping geometry update for #{view} to #{target_table} table (checkpoint)"
              next
            end

            result = import_geometry_from_view(view, target_table)
            imported_count += result[:imported_count]
            soft_errors.concat(result[:soft_errors] || [])
            hard_errors.concat(result[:hard_errors] || [])
            if Wdpa::Portal::ImportRuntimeConfig.checkpoints?
              Wdpa::Portal::Checkpoint.mark_geometry_done(view,
                target_table)
            end
          rescue StandardError => e
            hard_errors << "Geometry import error for #{view} in #{target_table}: #{e.message}"
            Rails.logger.error "Geometry import failed for #{view} in #{target_table}: #{e.message}"
          end

          Rails.logger.info "#{target_table}: #{imported_count} records updated"
          build_result(imported_count, soft_errors, hard_errors)
        end

        def self.import_geometry_from_view(view, target_table)
          connection = ActiveRecord::Base.connection

          geometry_column = get_geometry_column(target_table)
          unless geometry_column
            return failure_result("No geometry column found in #{target_table}", 0, { number_of_records_updated: 0 })
          end

          matching_condition = get_matching_condition(target_table)

          update_query = <<~SQL
            UPDATE #{target_table}#{' '}
            SET #{geometry_column} = v.wkb_geometry
            FROM #{view} v
            WHERE #{matching_condition}
              AND v.wkb_geometry IS NOT NULL
          SQL

          imported_count = 0
          connection.transaction do
            Rails.logger.debug "Executing geometry update: #{update_query}"
            result = connection.execute(update_query)
            imported_count = result.cmd_tuples

            # Calculate coordinates after geometry import
            import_coordinates(geometry_column, target_table) if imported_count > 0
          end

          Rails.logger.info "#{target_table} from #{view}: #{imported_count} records"
          build_result(imported_count, [], [], { number_of_records_updated: imported_count })
        end

        def self.validate_target_table(target_table)
          connection = ActiveRecord::Base.connection

          unless connection.table_exists?(target_table)
            Rails.logger.error "Target table #{target_table} does not exist"
            return false
          end

          count = connection.execute("SELECT COUNT(*) FROM #{target_table}").first['count'].to_i
          if count.zero?
            # Only treat empty ProtectedArea table as a hard error
            if target_table == Staging::ProtectedArea.table_name
              Rails.logger.error "Target table #{target_table} has no records"
              return false
            else
              Rails.logger.warn "Target table #{target_table} has no records, but continuing"
            end
          end

          Rails.logger.info "#{target_table}: #{count} records validated"
          true
        end

        def self.get_geometry_column(target_table)
          geometry_columns = find_geometry_columns_from_mapping

          connection = ActiveRecord::Base.connection

          geometry_columns.find do |col_name|
            connection.column_exists?(target_table, col_name)
          end
        end

        def self.find_geometry_columns_from_mapping
          Wdpa::Portal::Utils::ProtectedAreaColumnMapper::PORTAL_TO_PP_MAPPING
            .select { |_portal_key, mapping| mapping[:type] == :geometry }
            .map { |_portal_key, mapping| mapping[:name] }
        end

        def self.get_matching_condition(target_table)
          connection = ActiveRecord::Base.connection
          has_site_pid = connection.column_exists?(target_table, 'site_pid')

          if has_site_pid
            # For tables with site_pid (parcels): match on both site_id AND site_pid to ensure correct parcel
            # Cast both sides to text to handle type differences between portal views and staging tables
            "#{target_table}.site_id = v.site_id AND #{target_table}.site_pid::text = v.site_pid::text"
          else
            # For tables without site_pid (protected areas): match only on site_id (single record per site_id)
            "#{target_table}.site_id = v.site_id"
          end
        end

        def self.import_coordinates(geometry_column, target_table)
          connection = ActiveRecord::Base.connection

          # Check if coordinate columns exist in the target table
          unless connection.column_exists?(target_table, "#{geometry_column}_longitude") &&
                 connection.column_exists?(target_table, "#{geometry_column}_latitude")
            Rails.logger.debug "Coordinate columns not found in #{target_table}, skipping coordinate calculation"
            return
          end

          coordinate_query = <<~SQL
            UPDATE #{target_table}
            SET #{geometry_column}_longitude = (
              CASE ST_IsValid(#{geometry_column})
                WHEN TRUE THEN ST_X(ST_Centroid(#{geometry_column}))
                WHEN FALSE THEN ST_X(ST_Centroid(ST_MakeValid(#{geometry_column})))
              END
            ),
            #{geometry_column}_latitude = (
              CASE ST_IsValid(#{geometry_column})
                WHEN TRUE THEN ST_Y(ST_Centroid(#{geometry_column}))
                WHEN FALSE THEN ST_Y(ST_Centroid(ST_MakeValid(#{geometry_column})))
              END
            )
            WHERE #{geometry_column} IS NOT NULL
          SQL

          connection.transaction do
            Rails.logger.debug 'Executing coordinate calculation'
            result = connection.execute(coordinate_query)
            Rails.logger.info "#{target_table}: #{result.cmd_tuples} coordinate records updated"
          end
        end
      end
    end
  end
end
