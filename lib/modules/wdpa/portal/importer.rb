module Wdpa::Portal
  class Importer
    def self.import
      unless validate_required_views_exist
        error_msg = 'Required materialized views do not exist.'
        error_msg += if Wdpa::Portal::Config::StagingConfig.test_mode?
                       'Check that dummy data generation succeeded.'
                     else
                       'Step 1 materialized views may not be ready yet.'
                     end
        raise StandardError, error_msg
      end

      # Ensure staging tables exist (raise error if missing - should be created before import)
      Wdpa::Portal::Utils::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: true)
      # Check again if still not there then raise an error
      Wdpa::Portal::Utils::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: false)

      {
        sources: Wdpa::Portal::Importers::SourceImporter.import,
        protected_areas_attributes: Wdpa::Portal::Importers::ProtectedAreaAttribute.import,
        protected_areas_geometries: Wdpa::Portal::Importers::ProtectedAreaGeometry.import,
        protected_areas_related_sources: Wdpa::Shared::Importer::ProtectedAreasRelatedSource.import_staging,
        countries_protected_areas_geometry_statistics: Wdpa::Portal::Importers::CountriesProtectedAreaGeometryStatistics.calculate,
        green_list: Wdpa::Portal::Importers::GreenList.import,
        country_overseas_territories: Wdpa::Shared::Importer::CountryOverseasTerritories.import,
        global_stats: Wdpa::Shared::Importer::GlobalStats.import_staging

      }

      # Wdpa::SourceImporter.import wdpa_release ## complete
      # Wdpa::ProtectedAreaImporter.import ## complete
      # Wdpa::GeometryRatioCalculator.calculate  ## complete
      # Wdpa::Shared::Importer::CountryOverseasTerritories.import ## complete
      # Wdpa::Shared::Importer::GlobalStats.import ## complete
      # Wdpa::GreenListImporter.import ## complete
      # Wdpa::PameImporter.import
      # Wdpa::StoryMapLinkListImporter.import
      # Wdpa::BiopamaCountriesImporter.import

      # TODO_IMPORT: Add post-import validation once Step 1 is complete
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
