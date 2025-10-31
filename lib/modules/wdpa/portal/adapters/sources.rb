# frozen_string_literal: true

module Wdpa
  module Portal
    module Adapters
      class Sources
        private
        def sources_view
          Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_views[:sources]
        end

        public
        def each(&block)
          if portal_sources_exist?
            query = "SELECT * FROM #{sources_view}"
            ActiveRecord::Base.connection.select_all(query).each(&block)
          else
            raise StandardError,
              "#{sources_view} table is required but does not exist"
          end
        end

        def count
          if portal_sources_exist?
            ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{sources_view}").to_i
          else
            raise StandardError,
              "#{sources_view} table is required but does not exist"
          end
        end

        def portal_sources_exist?
          Wdpa::Portal::Managers::ViewManager.materialized_view_exists?(sources_view)
        end
      end
    end
  end
end
