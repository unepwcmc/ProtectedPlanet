# This module is used by s3bucket/portal importer make sure to keep this when removing s3bucket importer
require 'csv'

module Wdpa
  module Shared
    class RelatedSourceImporter
      # Unified configuration - same for both s3bucket and Portal importer
      PARCC_IMPORT = {
        path: Rails.root.join('lib/data/seeds/parcc_info.csv'),
        field: :has_parcc_info
      }
      
      IRREPLACEABILITY_IMPORT = {
        path: Rails.root.join('lib/data/seeds/irreplaceability_info.csv'),
        field: :has_irreplaceability_info
      }

      def self.parcc_import(target_table: 'protected_areas')
        # Use unified PARCC configuration
        import(PARCC_IMPORT.merge(target_table: target_table))
      end

      def self.irreplaceability_import(target_table: 'protected_areas')
        # Use unified IRREPLACEABILITY configuration
        import(IRREPLACEABILITY_IMPORT.merge(target_table: target_table))
      end

      private

      def self.import(import_config)
        path = import_config[:path]
        field = import_config[:field]
        target_table = import_config[:target_table] || 'protected_areas'
        
        # Validate inputs
        unless File.exist?(path)
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
            return {
              success: true,
              imported_count: 0,
              errors: ["No WDPA IDs found in #{path}"]
            }
          end

          # Update target table
          update_table(wdpa_ids, field, target_table)

          {
            success: true,
            imported_count: wdpa_ids.length,
            errors: []
          }
        rescue => e
          {
            success: false,
            imported_count: 0,
            errors: ["Import failed: #{e.message}"]
          }
        end
      end

      def self.update_table(wdpa_ids, field, target_table)
        connection = ActiveRecord::Base.connection
        
        # Check if column exists in target table
        unless column_exists?(target_table, field)
          Rails.logger.warn "Column #{field} does not exist in #{target_table}, skipping update"
          return
        end

        # Update records in target table
        wdpa_ids.each do |wdpa_id|
          connection.execute(<<~SQL)
            UPDATE #{target_table} 
            SET #{field} = true 
            WHERE wdpa_id = #{wdpa_id.to_i}
          SQL
        end
      end

      def self.column_exists?(table_name, column_name)
        connection = ActiveRecord::Base.connection
        columns = connection.columns(table_name)
        columns.any? { |col| col.name == column_name.to_s }
      end
    end
  end
end
