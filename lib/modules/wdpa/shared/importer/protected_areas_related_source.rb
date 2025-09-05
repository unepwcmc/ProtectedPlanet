# frozen_string_literal: true

require 'csv'

module Wdpa
  module Shared
    module Importer
      class ProtectedAreasRelatedSource
        PARCC_IMPORT = {
          path: Rails.root.join('lib/data/seeds/parcc_info.csv'),
          field: :has_parcc_info
        }.freeze

        IRREPLACEABILITY_IMPORT = {
          path: Rails.root.join('lib/data/seeds/irreplaceability_info.csv'),
          field: :has_irreplaceability_info
        }.freeze

        def self.import_live
          result = {
            parcc: parcc_import(ProtectedArea.table_name),
            irreplaceability: irreplaceability_import(ProtectedArea.table_name)
          }
          Rails.logger.info "Related source imports completed: #{result[:parcc][:imported_count] + result[:irreplaceability][:imported_count]} records"
          result
        end

        def self.import_staging
          result = {
            parcc: parcc_import(Staging::ProtectedArea.table_name),
            irreplaceability: irreplaceability_import(Staging::ProtectedArea.table_name)
          }
          Rails.logger.info "Related source imports completed: #{result[:parcc][:imported_count] + result[:irreplaceability][:imported_count]} records"
          result
        end

        def self.parcc_import(target_table)
          import_data(PARCC_IMPORT.merge(target_table: target_table))
        end

        def self.irreplaceability_import(target_table)
          import_data(IRREPLACEABILITY_IMPORT.merge(target_table: target_table))
        end

        def self.import_data(import_config)
          path = import_config[:path]
          field = import_config[:field]
          target_table = import_config[:target_table]

          unless File.exist?(path)
            Rails.logger.error "File not found: #{path}"
            return {
              success: false,
              imported_count: 0,
              errors: ["File not found: #{path}"]
            }
          end

          begin
            rows = CSV.read(path)
            wdpa_ids = rows.map(&:first).compact

            if wdpa_ids.empty?
              Rails.logger.warn "No WDPA IDs found in #{path}"
              return {
                success: true,
                imported_count: 0,
                errors: ["No WDPA IDs found in #{path}"]
              }
            end

            Rails.logger.info "Updating #{target_table} with #{field} data"
            update_table(wdpa_ids, field, target_table)

            {
              success: true,
              imported_count: wdpa_ids.length,
              errors: []
            }
          rescue StandardError => e
            Rails.logger.error "Import failed: #{e.message}"
            {
              success: false,
              imported_count: 0,
              errors: ["Import failed: #{e.message}"]
            }
          end
        end

        def self.update_table(wdpa_ids, field, target_table)
          connection = ActiveRecord::Base.connection

          unless column_exists?(target_table, field)
            Rails.logger.warn "Column #{field} does not exist in #{target_table}, skipping update"
            return
          end

          updated_count = 0
          wdpa_ids.each do |wdpa_id|
            result = connection.execute(
              "UPDATE #{connection.quote_table_name(target_table)} SET #{connection.quote_column_name(field)} = true WHERE wdpa_id = #{wdpa_id.to_i}"
            )
            updated_count += result.cmd_tuples if result.respond_to?(:cmd_tuples)
          end
        end

        def self.column_exists?(table_name, column_name)
          connection = ActiveRecord::Base.connection
          columns = connection.columns(table_name)
          columns.any? { |col| col.name == column_name.to_s }
        end

        private_class_method :parcc_import, :irreplaceability_import, :import_data, :update_table, :column_exists?
      end
    end
  end
end
