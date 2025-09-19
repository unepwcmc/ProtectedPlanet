# frozen_string_literal: true

module Wdpa
  module Portal
    class Importer < Wdpa::Shared::ImporterBase::Base
      def self.import(refresh_materialized_views: true, only: nil, skip: nil, sample: nil, label: nil)
        unless Wdpa::Portal::Managers::ViewManager.validate_required_views_exist
          error_msg = 'Required materialized views do not exist.'
          raise StandardError, error_msg
        end

        # Apply runtime flags
        Wdpa::Portal::ImportRuntimeConfig.reset!
        Wdpa::Portal::ImportRuntimeConfig.only = only || ENV['PP_IMPORT_ONLY']
        Wdpa::Portal::ImportRuntimeConfig.skip = skip || ENV['PP_IMPORT_SKIP']
        Wdpa::Portal::ImportRuntimeConfig.sample = sample || ENV['PP_IMPORT_SAMPLE']
        Wdpa::Portal::ImportRuntimeConfig.label = label || ENV['PP_RELEASE_LABEL']
        Wdpa::Portal::ImportRuntimeConfig.checkpoints_enabled = (ENV['PP_IMPORT_CHECKPOINTS_DISABLE'] != 'true')

        # Refresh materialized views to ensure latest data (only if refresh_views is true)
        Wdpa::Portal::Managers::ViewManager.refresh_materialized_views if refresh_materialized_views

        # Ensure staging tables exist (raise error if missing - should be created before import)
        Wdpa::Portal::Managers::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: true)
        # Check again if still not there then raise an error
        Wdpa::Portal::Managers::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: false)

        staging_tables_results = import_data_to_staging_tables
        live_tables_results = update_data_in_live_tables

        # Check for hard errors by checking if any nested keys 'hard_errors'
        # All importers should return hash using build_result, failure_result in Wdpa::Shared::ImporterBase
        has_hard_errors = check_for_hard_errors(staging_tables_results, live_tables_results)

        {
          success: !has_hard_errors,
          hard_errors: has_hard_errors ? ['Import completed with hard errors. Check the results for more details. If hard errors are arounce protected areas then you must re-run the import again otherwise you can run individual importers to re-import. See import_data_to_staging_tables, update_data_in_live_tables functions to understand the importer orders'] : []
        }.merge(staging_tables_results).merge(live_tables_results)
      rescue StandardError => e
        Rails.logger.error "Portal import failed: #{e.message}"
        failure_result("Portal import failed: #{e.message}", 0, {
          staging_tables_results: {},
          live_tables_results: {}
        })
      end

      def self.import_data_to_staging_tables
        only = Wdpa::Portal::ImportRuntimeConfig.only_list
        skip = Wdpa::Portal::ImportRuntimeConfig.skip_list

        # Helper to decide if an importer should run
        should_run = lambda do |name|
          n = name.to_s
          return false if skip.include?(n)
          return true if only.empty?
          only.include?(n)
        end

        sources_result = should_run.call('sources') ? Wdpa::Portal::Importers::Source.import_to_staging : success_result(0)
        protected_areas_result = should_run.call('protected_areas') ? Wdpa::Portal::Importers::ProtectedArea.import_to_staging : success_result(0)

        if protected_areas_result[:hard_errors].empty?
          global_stats_result = should_run.call('global_stats') ? Wdpa::Shared::Importer::GlobalStats.import_to_staging : success_result(0)
          green_list_result = should_run.call('green_list') ? Wdpa::Portal::Importers::GreenList.import_to_staging : success_result(0)
          pame_result = should_run.call('pame') ? Wdpa::Portal::Importers::Pame.import_to_staging : success_result(0)
          story_map_links_result = should_run.call('story_map_links') ? Wdpa::Shared::Importer::StoryMapLinkList.import_to_staging : success_result(0)
          country_statistics_result = if should_run.call('country_statistics')
                                         Wdpa::Portal::Importers::CountryStatistics.import_to_staging
                                       else
                                         { country_pa_geometry: success_result(0), country_general_stats: success_result(0), country_pame_stats: success_result(0) }
                                       end
        else
          # Skip subsequent importers due to hard errors in protected_areas
          errors = failure_result('Skipped due to hard errors in protected areas importer')
          global_stats_result = errors
          green_list_result = errors
          pame_result = errors
          story_map_links_result = errors
          country_statistics_result = {
            country_pa_geometry: errors,
            country_general_stats: errors,
            country_pame_stats: errors
          }
        end

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

      def self.success_result(count)
        { success: true, imported_count: count, soft_errors: [], hard_errors: [] }
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
