# frozen_string_literal: true

module Wdpa
  module Portal
    module Config
      class StagingConfig
        def self.dummy_data_count
          70
        end

        def self.batch_import_protected_areas_from_view_size
          10
        end

        def self.generate_staging_table_index_name(original_name)
          "staging_#{original_name}"
        end

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
            CountryStatistic.table_name => Staging::CountryStatistic.table_name,
            GlobalStatistic.table_name => Staging::GlobalStatistic.table_name,
            PameEvaluation.table_name => Staging::PameEvaluation.table_name,
            PameSource.table_name => Staging::PameSource.table_name,
            PameStatistic.table_name => Staging::PameStatistic.table_name,
            StoryMapLink.table_name => Staging::StoryMapLink.table_name,

            # Add junction tables for countries
            Country.countries_pas_junction_table_name => Country.staging_countries_pas_junction_table_name,
            Country.countries_pa_parcels_junction_table_name => Country.staging_countries_pa_parcels_junction_table_name,
            Country.countries_pame_evaluations_junction_table_name => Country.staging_countries_pame_evaluations_junction_table_name,

            # Add junction tables for sources
            Source.protected_areas_sources_junction_table_name => Staging::Source.protected_areas_sources_junction_table_name,
            Source.protected_area_parcels_sources_junction_table_name => Staging::Source.protected_area_parcels_sources_junction_table_name
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
      end
    end
  end
end
