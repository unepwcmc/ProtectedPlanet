module Wdpa
  module Portal
    class Importer
      # TODO_IMPORT: Update this class once Step 1 materialized views are ready
      # This importer currently uses placeholder view names and assumes certain schemas
      # Once Step 1 is complete, verify all view names and column mappings are correct

      def self.import
        # TODO_IMPORT: Add validation that Step 1 materialized views exist before starting import
        # This should check that portal_standard_polygons, portal_standard_points, and portal_standard_sources exist

        new.import
      end

      def import
        # TODO_IMPORT: Add pre-import validation once Step 1 is complete
        # This should validate that all required materialized views exist and have expected schemas

        # TO_BE_DELETED_STEP_1: Test mode logic - remove once Step 1 materialized views are ready
        # Generate dummy data if in test mode
        if Wdpa::Portal::Config::StagingConfig.test_mode?
          Rails.logger.info 'Running in TEST MODE - generating dummy materialized views'
          Wdpa::Portal::Services::DummyDataGenerator.generate_test_views

          # Add a small delay to ensure views are fully available
          Rails.logger.info 'Waiting for dummy views to be fully available...'
          sleep(1)
        end

        # Validate that required views exist
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
        Wdpa::Portal::Utils::StagingTableManager.ensure_staging_tables_exist!(create_if_missing: false)

        results = {}

        # Import sources
        results[:sources] = Wdpa::Portal::Importers::SourceImporter.import

        # Import protected areas (attributes only - no geometry)
        results[:protected_areas] = import_protected_areas_attributes

        # Import geometries (spatial data only - updates staging tables)
        results[:geometries] = import_protected_area_geometries

        # Import green list data
        results[:green_list] = Wdpa::Portal::Importers::GreenListImporter.import

        # Import related sources (PARCC, Irreplaceability)
        results[:related_sources] = Wdpa::Shared::Importer::RelatedSource.import_staging


        # TODO_IMPORT: Add post-import validation once Step 1 is complete
        # This should validate that imported data matches expected counts from materialized views

        results
      end

      private

      def validate_required_views_exist
        required_views = Wdpa::Portal::Config::StagingConfig.portal_views

        missing_views = required_views.select do |view_name|
          !view_exists?(view_name)
        end

        if missing_views.any?
          Rails.logger.error "Missing required materialized views: #{missing_views.join(', ')}"

          # TO_BE_DELETED_STEP_1: Test mode debugging - remove once Step 1 materialized views are ready
          if Wdpa::Portal::Config::StagingConfig.test_mode?
            Rails.logger.info 'Debug: Checking what views actually exist...'
            all_views = ActiveRecord::Base.connection.execute("SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'public'").to_a
            Rails.logger.info "Available tables: #{all_views.map { |v| v['tablename'] }.join(', ')}"

            all_views = ActiveRecord::Base.connection.execute("SELECT schemaname, viewname FROM pg_views WHERE schemaname = 'public'").to_a
            Rails.logger.info "Available views: #{all_views.map { |v| v['viewname'] }.join(', ')}"
          end

          return false
        end

        Rails.logger.info 'All required materialized views exist'
        true
      end

      def view_exists?(view_name)
        # TO_BE_DELETED_STEP_1: Test mode logic - prioritize table checking since dummy data creates tables
        # In test mode, portal_standard_* are tables, not views
        # Once Step 1 is complete, these will be actual materialized views

        # Method 1: Check if table exists (for test mode dummy data)
        begin
          if ActiveRecord::Base.connection.table_exists?(view_name)
            Rails.logger.debug "Found #{view_name} as a table (test mode)"
            return true
          end
        rescue StandardError => e
          Rails.logger.debug "Table check failed for #{view_name}: #{e.message}"
        end

        # Method 2: Check if view exists in pg_views (for Step 1 materialized views)
        begin
          result = ActiveRecord::Base.connection.execute(
            "SELECT 1 FROM pg_views WHERE viewname = '#{view_name}' AND schemaname = 'public'"
          )
          if result.count > 0
            Rails.logger.debug "Found #{view_name} as a view (Step 1 materialized view)"
            return true
          end
        rescue StandardError => e
          Rails.logger.debug "View check failed for #{view_name}: #{e.message}"
        end

        # Method 3: Try to query the object directly (fallback)
        begin
          ActiveRecord::Base.connection.execute("SELECT 1 FROM #{view_name} LIMIT 1")
          Rails.logger.debug "Found #{view_name} via direct query"
          return true
        rescue StandardError => e
          Rails.logger.debug "Direct query failed for #{view_name}: #{e.message}"
        end

        false
      end

      def import_protected_areas_attributes
        # TODO_IMPORT: Update these table names once Step 1 provides the actual materialized view schemas
        # The current implementation assumes certain column names and data types

        # Import attributes only (no geometry) to staging tables
        Wdpa::Portal::Importers::AttributeImporter.import
      end

      def import_protected_area_geometries
        # Import geometries to staging tables using SQL updates
        # Handles both Staging::ProtectedArea and Staging::ProtectedAreaParcel
        Wdpa::Portal::Importers::GeometryImporter.import
      end
    end
  end
end
