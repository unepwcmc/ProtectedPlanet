# TO_BE_DELETED_STEP_1: This configuration should be removed once Step 1 materialized views are ready
# This file provides centralized configuration for portal import staging tables and test mode

module Wdpa
  module Portal
    module Config
      class StagingConfig
        def self.test_mode?
          ENV['WDPA_PORTAL_TEST_MODE'] == 'true'
        end

        def self.dummy_data_count
          70
        end

        def self.batch_import_protected_areas_from_view_size
          10
        end

        # Staging table configuration
        def self.staging_table_index_prefix
          'staging_'
        end

        def self.generate_staging_index_name(original_index_name)
          "#{staging_table_index_prefix}#{original_index_name}"
        end

        # Portal view names (TODO_IMPORT: Verify these match what Step 1 developer creates)
        PORTAL_VIEWS = {
          'polygons' => 'portal_standard_polygons',
          'points' => 'portal_standard_points',
          'sources' => 'portal_standard_sources'
        }

        # Portal views that contain protected area data (for parcel logic)
        # Only polygons and points contain protected area parcel data
        PORTAL_PROTECTED_AREA_VIEW_TYPES = %w[polygons points]

        def self.portal_view_for(type)
          PORTAL_VIEWS[type]
        end

        def self.portal_views_exist?
          PORTAL_VIEWS.values.all? { |view| ActiveRecord::Base.connection.table_exists?(view) }
        end

        def self.portal_views
          PORTAL_VIEWS.values
        end

        def self.portal_protected_area_views
          PORTAL_PROTECTED_AREA_VIEW_TYPES.map { |type| PORTAL_VIEWS[type] }
        end

        # All staging and live table name related configurations
        # Make sure all values are unique and do not conflict with live table names
        def self.staging_live_tables_hash
          {
            Source.table_name => Staging::Source.table_name,
            ProtectedArea.table_name => Staging::ProtectedArea.table_name,
            ProtectedAreaParcel.table_name => Staging::ProtectedAreaParcel.table_name,
            GreenListStatus.table_name => Staging::GreenListStatus.table_name,
            NoTakeStatus.table_name => Staging::NoTakeStatus.table_name,
            # Add junction tables for protected areas
            'countries_protected_areas' => 'staging_countries_protected_areas',
            'protected_areas_sources' => 'staging_protected_areas_sources',
            # Add junction tables for protected area parcels
            'countries_protected_area_parcels' => 'staging_countries_protected_area_parcels',
            'protected_area_parcels_sources' => 'staging_protected_area_parcels_sources'
          }
        end

        def self.staging_tables
          staging_live_tables_hash.values
        end

        def self.get_live_table_name_from_staging_name(staging_table)
          staging_live_tables_hash.invert[staging_table]
        end

        def self.get_staging_table_name_from_live_table(live_table)
          staging_live_tables_hash[live_table]
        end

        def self.staging_tables_exist?
          staging_live_tables_hash.values.all? { |table| ActiveRecord::Base.connection.table_exists?(table) }
        end

        # Foreign key configurations for staging tables
        # These are additional foreign keys that should exist in staging but are not present in the live schema
        def self.staging_foreign_keys
          [
            {
              table_name: Staging::ProtectedArea.table_name,
              column_name: :green_list_status_id,
              referenced_table_name: Staging::GreenListStatus.table_name
            },
            {
              table_name: Staging::ProtectedArea.table_name,
              column_name: :no_take_status_id,
              referenced_table_name: Staging::NoTakeStatus.table_name
            },
            {
              table_name: Staging::ProtectedAreaParcel.table_name,
              column_name: :no_take_status_id,
              referenced_table_name: Staging::NoTakeStatus.table_name
            }
            # Add more foreign key configurations here as needed
          ]
        end

        # Green list import configuration
        def self.green_list_csv_path
          'lib/data/seeds/green_list_sites_*.csv'
        end
      end
    end
  end
end
