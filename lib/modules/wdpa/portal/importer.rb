module Wdpa::Portal
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
        sources: Wdpa::Portal::Importers::SourceImporter.import_staging,
        protected_areas_attributes: Wdpa::Portal::Importers::ProtectedAreaAttribute.import_staging,
        protected_areas_geometries: Wdpa::Portal::Importers::ProtectedAreaGeometry.import_staging,
        protected_areas_related_sources: Wdpa::Shared::Importer::ProtectedAreasRelatedSource.import_staging,
        global_stats: Wdpa::Shared::Importer::GlobalStats.import_staging,
        green_list: Wdpa::Portal::Importers::GreenList.import_staging,
        pame: Wdpa::Portal::Importers::Pame.import_staging,
        story_map_links: Wdpa::Shared::Importer::StoryMapLinkList.import_staging,
        country_statistics: Wdpa::Portal::Importers::CountryStatistics.import_staging,
      }
    end

    # The importers here update data in live country table
    def self.update_data_in_live_tables
      {
        country_overseas_territories: Wdpa::Shared::Importer::CountryOverseasTerritories.update_live_table,
        biopama_countries: Wdpa::Shared::Importer::BiopamaCountries.update_live_table
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
