# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      module ProtectedArea
        class Geometry
          def self.import_staging
            results = {}

            results[:protected_areas] = import_geometry_for_table(Staging::ProtectedArea.table_name)

            results[:protected_area_parcels] = import_geometry_for_table(Staging::ProtectedAreaParcel.table_name)

            total_imported = results[:protected_areas][:imported_count] + results[:protected_area_parcels][:imported_count]
            all_errors = results[:protected_areas][:errors] + results[:protected_area_parcels][:errors]

            Rails.logger.info "Geometry import completed: #{total_imported} records updated"

            {
              success: all_errors.empty?,
              imported_count: total_imported,
              errors: all_errors,
              details: results
            }
          end

          def self.import_geometry_for_table(target_table)
            unless validate_target_table(target_table)
              return {
                imported_count: 0,
                errors: ["Target staging table #{target_table} does not exist or has no records"]
              }
            end

            imported_count = 0
            errors = []

            Wdpa::Portal::Config::StagingConfig.portal_protected_area_views.each do |view|
              result = import_geometry_from_view(view, target_table)
              imported_count += result[:count]
              errors.concat(result[:errors])
            rescue StandardError => e
              errors << "Geometry import error for #{view} in #{target_table}: #{e.message}"
              Rails.logger.error "Geometry import failed for #{view} in #{target_table}: #{e.message}"
            end

            Rails.logger.info "#{target_table}: #{imported_count} records updated"
            { imported_count: imported_count, errors: errors }
          end

          def self.import_geometry_from_view(view, target_table)
            connection = ActiveRecord::Base.connection

            geometry_column = get_geometry_column(target_table)
            return { count: 0, errors: ["No geometry column found in #{target_table}"] } unless geometry_column

            matching_condition = get_matching_condition(target_table)

            update_query = <<~SQL
              UPDATE #{target_table}#{' '}
              SET #{geometry_column} = v.wkb_geometry
              FROM #{view} v
              WHERE #{matching_condition}
                AND v.wkb_geometry IS NOT NULL
            SQL

            Rails.logger.debug "Executing geometry update: #{update_query}"
            result = connection.execute(update_query)

            Rails.logger.info "#{target_table} from #{view}: #{result.cmd_tuples} records"
            { count: result.cmd_tuples, errors: [] }
          end

          def self.validate_target_table(target_table)
            connection = ActiveRecord::Base.connection

            unless connection.table_exists?(target_table)
              Rails.logger.error "Target table #{target_table} does not exist"
              return false
            end

            count = connection.execute("SELECT COUNT(*) FROM #{target_table}").first['count'].to_i
            if count == 0
              Rails.logger.error "Target table #{target_table} has no records"
              return false
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
            Wdpa::Portal::Utils::ColumnMapper::PORTAL_TO_PP_MAPPING
              .select { |_portal_key, mapping| mapping[:type] == :geometry }
              .map { |_portal_key, mapping| mapping[:name] }
          end

          def self.get_matching_condition(target_table)
            connection = ActiveRecord::Base.connection
            has_wdpa_pid = connection.column_exists?(target_table, 'wdpa_pid')

            if has_wdpa_pid
              # For tables with wdpa_pid (parcels): match on both wdpa_id AND wdpa_pid to ensure correct parcel
              # Cast both sides to text to handle type differences between portal views and staging tables
              "#{target_table}.wdpa_id = v.wdpaid AND #{target_table}.wdpa_pid::text = v.wdpa_pid::text"
            else
              # For tables without wdpa_pid (protected areas): match only on wdpa_id (single record per wdpa_id)
              "#{target_table}.wdpa_id = v.wdpaid"
            end
          end
        end
      end
    end
  end
end
