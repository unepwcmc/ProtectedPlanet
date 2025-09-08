# frozen_string_literal: true

require 'csv'

module Wdpa
  module Shared
    module Importer
      class ProtectedAreasRelatedSource < Wdpa::Shared::ImporterBase::Base
        TARGET_TABLE = {
          staging_target_table: Staging::ProtectedArea.table_name,
          live_target_table: ProtectedArea.table_name
        }.freeze

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
            parcc: import_data(PARCC_IMPORT, 'live'),
            irreplaceability: import_data(IRREPLACEABILITY_IMPORT, 'live')
          }
          Rails.logger.info "Related source imports completed: #{result[:parcc][:imported_count] + result[:irreplaceability][:imported_count]} records"
          result
        end

        def self.import_to_staging
          result = {
            parcc: import_data(PARCC_IMPORT, 'staging'),
            irreplaceability: import_data(IRREPLACEABILITY_IMPORT, 'staging')
          }
          Rails.logger.info "Related source imports completed: #{result[:parcc][:imported_count] + result[:irreplaceability][:imported_count]} records"
          result
        end

        def self.import_data(import_config, is_for)
          path = import_config[:path]
          field = import_config[:field]

          unless %w[live staging].include?(is_for)
            return Wdpa::Shared::ImporterBase::Base.failure_result("Invalid target environment: #{is_for}. Must be 'live' or 'staging'")
          end

          target_table = if is_for == 'live'
                           TARGET_TABLE[:live_target_table]
                         else
                           TARGET_TABLE[:staging_target_table]
                         end

          unless File.exist?(path)
            Rails.logger.error "File not found: #{path}"
            return Wdpa::Shared::ImporterBase::Base.failure_result("File not found: #{path}")
          end

          begin
            rows = CSV.read(path)
            wdpa_ids = rows.map(&:first).compact

            if wdpa_ids.empty?
              Rails.logger.warn "No WDPA IDs found in #{path}"
              return Wdpa::Shared::ImporterBase::Base.success_result(:imported_count, ["No WDPA IDs found in #{path}"],
                [])
            end

            Rails.logger.info "Updating #{target_table} with #{field} data"
            soft_errors = update_table(wdpa_ids, field, target_table)

            Wdpa::Shared::ImporterBase::Base.success_result(:imported_count, soft_errors, [])
          rescue StandardError => e
            Rails.logger.error "Import failed: #{e.message}"
            Wdpa::Shared::ImporterBase::Base.failure_result("Import failed: #{e.message}")
          end
        end

        def self.update_table(wdpa_ids, field, target_table)
          connection = ActiveRecord::Base.connection
          soft_errors = []

          unless column_exists?(target_table, field)
            Rails.logger.warn "Column #{field} does not exist in #{target_table}, skipping update"
            return ["Column #{field} does not exist in #{target_table}"]
          end

          wdpa_ids.each do |wdpa_id|
            connection.execute(
              "UPDATE #{connection.quote_table_name(target_table)} SET #{connection.quote_column_name(field)} = true WHERE wdpa_id = #{wdpa_id.to_i}"
            )
          rescue StandardError => e
            soft_errors << "Failed to update WDPA ID #{wdpa_id}: #{e.message}"
            Rails.logger.warn "Failed to update WDPA ID #{wdpa_id}: #{e.message}"
          end

          soft_errors
        end

        def self.column_exists?(table_name, column_name)
          connection = ActiveRecord::Base.connection
          columns = connection.columns(table_name)
          columns.any? { |col| col.name == column_name.to_s }
        end

        private_class_method :import_data, :update_table, :column_exists?
      end
    end
  end
end
