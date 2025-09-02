module Wdpa
  module Portal
    class Release
      IMPORT_VIEW_NAME = "portal_imported_protected_areas"
      DOWNLOADS_VIEW_NAME = "portal_downloads_protected_areas"

      def initialize
        @start_time = Time.now
      end

      def create_import_view
        attributes = Wdpa::DataStandard.common_attributes.join(', ')
        create_query = "CREATE OR REPLACE VIEW #{IMPORT_VIEW_NAME} AS "

        select_queries = []
        select_queries << "SELECT #{attributes} FROM #{Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons')}"
        select_queries << "SELECT #{attributes} FROM #{Wdpa::Portal::Config::StagingConfig.portal_view_for('points')}"

        create_query << select_queries.join(' UNION ALL ')

        db.execute(create_query)
      end

      def create_downloads_view
        create_query = "CREATE OR REPLACE VIEW #{DOWNLOADS_VIEW_NAME} AS "
        create_query << "SELECT * FROM #{IMPORT_VIEW_NAME}"

        db.execute(create_query)
      end

      def count_records
        Wdpa::Portal::Config::StagingConfig.portal_views.flat_map do |view|
          db.select_value("SELECT COUNT(*) FROM #{view}").to_i
        end.sum
      end

      def count_records_by_view
        Wdpa::Portal::Config::StagingConfig.portal_views.each_with_object({}) do |view, counts|
          counts[view] = db.select_value("SELECT COUNT(*) FROM #{view}").to_i
        end
      end

      def validate_views
        missing_views = []
        
        Wdpa::Portal::Config::StagingConfig.portal_views.each do |view|
          unless db.table_exists?(view)
            missing_views << view
          end
        end

        if missing_views.any?
          raise "Missing portal views: #{missing_views.join(', ')}"
        end

        true
      end

      private

      def db
        ActiveRecord::Base.connection
      end
    end
  end
end
