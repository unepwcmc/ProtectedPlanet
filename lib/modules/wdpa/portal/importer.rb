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

        staging_tables_results = import_data_to_staging_tables
        live_tables_results = update_data_in_live_tables

        # Log import summary
        log_import_summary(staging_tables_results)

        staging_tables_results.merge(live_tables_results)
      rescue StandardError => e
        Rails.logger.error "Portal import failed: #{e.message}"
        {
          success: false,
          error: e.message,
          staging_tables_results: {},
          live_tables_results: {}
        }
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

      def self.log_import_summary(results)
        Rails.logger.info '=== PORTAL IMPORT SUMMARY ==='

        totals = { imported: 0, soft_errors: 0, hard_errors: 0 }

        results.each do |importer_name, result|
          next unless result.is_a?(Hash)

          log_importer_result(importer_name, result, totals)
          log_sub_results(importer_name, result, totals)
        end

        log_overall_summary(totals)
      end

      def self.log_importer_result(importer_name, result, totals)
        imported = result[:imported_count] || 0
        soft_errors = result[:soft_errors] || []
        hard_errors = result[:hard_errors] || []

        totals[:imported] += imported
        totals[:soft_errors] += soft_errors.count
        totals[:hard_errors] += hard_errors.count

        status = result[:success] ? '✓ SUCCESS' : '✗ FAILED'
        Rails.logger.info "#{status} #{importer_name}: #{imported} imported, #{soft_errors.count} soft errors, #{hard_errors.count} hard errors"

        log_errors(importer_name, soft_errors, hard_errors)
      end

      def self.log_sub_results(importer_name, result, totals)
        sub_result_keys = %i[country_pa_geometry country_stats country_pame_stats protected_areas
          protected_area_parcels protected_areas_attributes protected_areas_geometries
          protected_areas_related_sources]

        sub_result_keys.each do |sub_key|
          sub_result = result[sub_key]
          next unless sub_result.is_a?(Hash)

          sub_soft_errors = sub_result[:soft_errors] || []
          sub_hard_errors = sub_result[:hard_errors] || []

          totals[:soft_errors] += sub_soft_errors.count
          totals[:hard_errors] += sub_hard_errors.count

          log_errors("#{importer_name}.#{sub_key}", sub_soft_errors, sub_hard_errors, 5)
        end
      end

      def self.log_errors(name, soft_errors, hard_errors, soft_limit = 10)
        if hard_errors.any?
          Rails.logger.error "  Hard errors for #{name}:"
          hard_errors.each { |error| Rails.logger.error "    - #{error}" }
        end

        return unless soft_errors.any?

        Rails.logger.warn "  Soft errors for #{name} (#{soft_errors.count} total):"
        soft_errors.first(soft_limit).each { |error| Rails.logger.warn "    - #{error}" }
        Rails.logger.warn "    ... and #{soft_errors.count - soft_limit} more soft errors" if soft_errors.count > soft_limit
      end

      def self.log_overall_summary(totals)
        Rails.logger.info '=== OVERALL SUMMARY ==='
        Rails.logger.info "Total imported: #{totals[:imported]}"
        Rails.logger.info "Total soft errors: #{totals[:soft_errors]}"
        Rails.logger.info "Total hard errors: #{totals[:hard_errors]}"
        Rails.logger.info "Import status: #{totals[:hard_errors] == 0 ? 'SUCCESS' : 'FAILED'}"
      end
    end
  end
end
