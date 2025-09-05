# frozen_string_literal: true

module Wdpa
  module Portal
    class Importer
      def self.import
        unless validate_required_views_exist
          error_msg = 'Required materialized views do not exist.'
          raise StandardError, error_msg
        end

        # Ensure staging tables exist (raise error if missing - should be created before import)
        Wdpa::Portal::Utils::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: true)
        # Check again if still not there then raise an error
        Wdpa::Portal::Utils::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: false)

        staging_results = import_data_to_staging_tables
        live_results = update_data_in_live_tables

        staging_results.merge(live_results)
        # TODO_IMPORT: Add post-import validation once Step 1 is complete
      end

      def self.import_data_to_staging_tables
        {
          sources: Wdpa::Portal::Importers::Source.import_staging,
          protected_areas: Wdpa::Portal::Importers::ProtectedArea.import_staging,
          global_stats: Wdpa::Shared::Importer::GlobalStats.import_staging, # not depending on any importer
          green_list: Wdpa::Portal::Importers::GreenList.import_staging, # only run after ProtectedArea importer
          pame: Wdpa::Portal::Importers::Pame.import_staging, # only run after ProtectedArea importer
          story_map_links: Wdpa::Shared::Importer::StoryMapLinkList.import_staging, # only run after ProtectedArea importer
          country_statistics: Wdpa::Portal::Importers::CountryStatistics.import_staging # only run after ProtectedArea importer
        }
      end

      # The importers here update data in live country table
      def self.update_data_in_live_tables
        {
          country_overseas_territories: Wdpa::Shared::Importer::CountryOverseasTerritories.update_live_table, # not depending on any importer
          biopama_countries: Wdpa::Shared::Importer::BiopamaCountries.update_live_table, # As of 05Sep2025 it might not used # not depending on any importer
          aichi11_target: Aichi11Target.update_live_table # As of 05Sep2025 it is probably not used # not depending on any importer
        }
      end

      def self.validate_required_views_exist
        required_views = Wdpa::Portal::Config::StagingConfig.portal_views

        missing_views = required_views.select do |view_name|
          !view_exists?(view_name)
        end

        if missing_views.any?
          Rails.logger.error "Missing required materialized views: #{missing_views.join(', ')}"

          return false
        end

        Rails.logger.info 'All required materialized views exist'
        true
      end

      def self.view_exists?(view_name)
        begin
          return true if ActiveRecord::Base.connection.table_exists?(view_name)
        rescue StandardError => e
          Rails.logger.debug "Table check failed for #{view_name}: #{e.message}"
        end
        false
      end
    end
  end
end
