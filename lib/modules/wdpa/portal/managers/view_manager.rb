# frozen_string_literal: true

module Wdpa
  module Portal
    module Managers
      class ViewManager
        # Check if a single view exists
        def self.view_exists?(view_name)
          ActiveRecord::Base.connection.execute("SELECT 1 FROM #{view_name} LIMIT 1")
          true
        rescue StandardError => e
          Rails.logger.debug "View check failed for #{view_name}: #{e.message}"
          false
        end

        # Validate that all required views exist (used by importer)
        def self.validate_required_views_exist
          required_views = Wdpa::Portal::Config::PortalImportConfig.portal_materialised_view_values

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

        # Refresh all materialized views before import (with automatic index creation)
        def self.refresh_materialized_views
          views = Wdpa::Portal::Config::PortalImportConfig.portal_materialised_view_values
          views.each do |view_name|
            # Then refresh the view concurrently
            refresh_view_concurrently(view_name)
          end

          Rails.logger.info 'All materialized views refreshed successfully'
        end

        # Refresh a materialized view concurrently
        def self.refresh_view_concurrently(view_name)
          Rails.logger.info "Refreshing materialized view: #{view_name}"
          ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY #{view_name}")
          Rails.logger.info "Successfully refreshed concurrently: #{view_name}"
        rescue PG::ObjectNotInPrerequisiteState => e
          Rails.logger.error "Concurrent refresh failed for #{view_name}: #{e.message}"
          Rails.logger.error 'Indexes may not have been created properly'
          raise e # Re-raise as hard error - concurrent refresh is required for large datasets
        rescue StandardError => e
          Rails.logger.error "Failed to refresh materialized view #{view_name}: #{e.message}"
          raise e # Re-raise as hard error to stop import
        end
      end
    end
  end
end
