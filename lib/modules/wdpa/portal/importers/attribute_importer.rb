module Wdpa
  module Portal
    module Importers
      class AttributeImporter
        def self.import
          # Import protected area attributes directly to staging table
          adapter = Wdpa::Portal::Adapters::ImportTablesAdapter.new
          relation = adapter.protected_areas_relation
          
          imported_count = 0
          errors = []

          relation.find_in_batches do |batch|
            # begin
              batch_result = process_batch(batch)
              imported_count += batch_result[:count]
              errors.concat(batch_result[:errors])
            # rescue => e
            #   errors << "Batch processing error: #{e.message}"
            #   Rails.logger.error("Batch processing failed: #{e.message}")
            # end
          end

          {
            success: errors.empty?,
            imported_count: imported_count,
            errors: errors
          }
        end

        private

        def self.process_batch(batch)
          imported_count = 0
          errors = []

          batch.each do |pa|
            # begin
              puts pa
              attrs = standardize_attributes(pa)
              puts attrs
              StagingProtectedArea.create!(attrs)
              imported_count += 1
            # rescue => e
            #   errors << "Error processing SITE_ID #{pa['wdpaid']} SITE_PID #{pa['wdpa_pid']}: #{e.message}"
            # end
          end

          { count: imported_count, errors: errors }
        end

        def self.standardize_attributes(portal_attributes)
          Wdpa::Portal::Utils::ColumnMapper.map_portal_to_pp(portal_attributes)
        end
      end
    end
  end
end
