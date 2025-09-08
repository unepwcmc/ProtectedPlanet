# frozen_string_literal: true

module Wdpa
  module Portal
    class Importer < Wdpa::Shared::ImporterBase::Base
      def self.import(refresh_materialized_views: true)
        unless Wdpa::Portal::Utils::ViewManager.validate_required_views_exist
          error_msg = 'Required materialized views do not exist.'
          raise StandardError, error_msg
        end

        # Refresh materialized views to ensure latest data (only if refresh_views is true)
        Wdpa::Portal::Utils::ViewManager.refresh_materialized_views if refresh_materialized_views

        # Ensure staging tables exist (raise error if missing - should be created before import)
        Wdpa::Portal::Utils::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: true)
        # Check again if still not there then raise an error
        Wdpa::Portal::Utils::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: false)

        staging_tables_results = import_data_to_staging_tables
        live_tables_results = update_data_in_live_tables

        # Check for hard errors by checking if any nested keys 'hard_errors'
        # All importers should return hash using success_result, failure_result in Wdpa::Shared::ImporterBase
        has_hard_errors = check_for_hard_errors(staging_tables_results, live_tables_results)

        {
          success: !has_hard_errors,
          hard_errors: has_hard_errors ? ['Import completed with hard errors'] : []
        }.merge(staging_tables_results).merge(live_tables_results)
      rescue StandardError => e
        Rails.logger.error "Portal import failed: #{e.message}"
        failure_result("Portal import failed: #{e.message}", :imported_count, {
          staging_tables_results: {},
          live_tables_results: {}
        })
      end

      def self.import_data_to_staging_tables
        # Run importers in dependency order
        sources_result = Wdpa::Portal::Importers::Source.import_to_staging
        protected_areas_result = Wdpa::Portal::Importers::ProtectedArea.import_to_staging
        global_stats_result = Wdpa::Shared::Importer::GlobalStats.import_to_staging
        green_list_result = Wdpa::Portal::Importers::GreenList.import_to_staging
        pame_result = Wdpa::Portal::Importers::Pame.import_to_staging
        story_map_links_result = Wdpa::Shared::Importer::StoryMapLinkList.import_to_staging
        country_statistics_result = Wdpa::Portal::Importers::CountryStatistics.import_to_staging

        {
          sources: sources_result,
          protected_areas: protected_areas_result,
          global_stats: global_stats_result,
          green_list: green_list_result,
          pame: pame_result,
          story_map_links: story_map_links_result,
          country_statistics: country_statistics_result
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

      def self.check_for_hard_errors(staging_results, live_results)
        all_results = staging_results.merge(live_results)

        all_results.any? do |importer_name, result|
          check_for_hard_errors_recursive(result, importer_name)
        end
      end

      def self.check_for_hard_errors_recursive(hash, path_prefix)
        return false unless hash.is_a?(Hash)

        # Check current level for hard errors
        if hash[:hard_errors]&.any?
          Rails.logger.error "Hard errors found in #{path_prefix}: #{hash[:hard_errors].join(', ')}"
          return true
        end

        # Recursively check all nested hashes
        hash.any? do |key, value|
          next false unless value.is_a?(Hash)
          next false if key == :hard_errors # Skip hard_errors keys

          check_for_hard_errors_recursive(value, "#{path_prefix}.#{key}")
        end
      end
    end
  end
end
