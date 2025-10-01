# frozen_string_literal: true

module Wdpa
  module Portal
    module Adapters
      class ProtectedAreas
        def find_in_batches
          batch_size = Wdpa::Portal::Config::PortalImportConfig.batch_import_protected_areas_from_view_size
          sample_limit = Wdpa::Portal::ImportRuntimeConfig.sample_limit
          use_checkpoints = Wdpa::Portal::ImportRuntimeConfig.checkpoints?

          Wdpa::Portal::Config::PortalImportConfig.portal_protected_area_materialised_views.each do |view_name|
            total_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{view_name}").to_i

            offset = 0
            if use_checkpoints
              begin
                offset = Wdpa::Portal::Checkpoint.get_offset(view_name)
              rescue StandardError
                offset = 0
              end
            end

            # End boundary for sampling
            end_offset = sample_limit ? [offset + sample_limit, total_count].min : total_count

            while offset < end_offset
              limit = [batch_size, end_offset - offset].min
              query = "SELECT * FROM #{view_name} LIMIT #{limit} OFFSET #{offset}"
              batch = ActiveRecord::Base.connection.select_all(query)
              yield batch
              offset += limit
              Wdpa::Portal::Checkpoint.set_offset(view_name, offset) if use_checkpoints
            end
          end
        end

        def count
          total_count = 0

          Wdpa::Portal::Config::PortalImportConfig.portal_protected_area_materialised_views.each do |view_name|
            count_result = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{view_name}")
            total_count += count_result.to_i
          end

          total_count
        end
      end
    end
  end
end
