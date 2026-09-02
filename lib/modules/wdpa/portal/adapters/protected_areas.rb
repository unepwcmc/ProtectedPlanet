# frozen_string_literal: true

module Wdpa
  module Portal
    module Adapters
      class ProtectedAreas
        include KeysetBatches

        # Natural key of both point and polygon views, and the unique index
        # FDW_VIEWS.sql builds on them.
        KEY_COLUMNS = %w[site_id site_pid].freeze

        def find_in_batches(&block)
          batch_size = Wdpa::Portal::Config::PortalImportConfig.batch_import_protected_areas_from_view_size

          # Geometry is imported separately, set-based, by ProtectedArea::Geometry.
          # Fetching it here would pull every polygon through Ruby only to drop it.
          geometry_columns = Wdpa::Portal::Utils::ProtectedAreaColumnMapper.geometry_portal_columns

          Wdpa::Portal::Config::PortalImportConfig.portal_protected_area_staging_materialised_views.each do |view_name|
            each_keyset_batch(view: view_name, key_columns: KEY_COLUMNS, batch_size: batch_size,
              exclude_columns: geometry_columns, &block)
          end
        end

        def count
          total_count = 0

          Wdpa::Portal::Config::PortalImportConfig.portal_protected_area_staging_materialised_views.each do |view_name|
            count_result = ActiveRecord::Base.lease_connection.select_value("SELECT COUNT(*) FROM #{view_name}")
            total_count += count_result.to_i
          end

          total_count
        end
      end
    end
  end
end
