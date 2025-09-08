# frozen_string_literal: true

module Wdpa
  module Portal
    module Adapters
      class ProtectedAreas
        def find_in_batches
          batch_size = Wdpa::Portal::Config::StagingConfig.batch_import_protected_areas_from_view_size

          Wdpa::Portal::Config::StagingConfig.portal_protected_area_views.each do |view_name|
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

        def count
          total_count = 0

          Wdpa::Portal::Config::StagingConfig.portal_protected_area_views.each do |view_name|
            count_result = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{view_name}")
            total_count += count_result.to_i
          end

          total_count
        end
      end
    end
  end
end
