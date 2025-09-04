module Wdpa::Portal::Adapters
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

    def exists?
      Wdpa::Portal::Config::StagingConfig.portal_protected_area_views.any? do |view_name|
        ActiveRecord::Base.connection.select_value("SELECT 1 FROM #{view_name} LIMIT 1")
        true
      rescue StandardError
        false
      end
    end

    def portal_views_exist?
      Wdpa::Portal::Config::StagingConfig.portal_protected_area_views.all? do |view_name|
        ActiveRecord::Base.connection.table_exists?(view_name)
      end
    end
  end
end
