# frozen_string_literal: true

module Wdpa
  module Portal
    module Adapters
      class Sources
        def each(&block)
          if portal_sources_exist?
            query = "SELECT * FROM #{Wdpa::Portal::Config::PortalImportConfig.portal_view_for('sources')}"
            ActiveRecord::Base.connection.select_all(query).each(&block)
          else
            raise StandardError,
              "#{Wdpa::Portal::Config::PortalImportConfig.portal_view_for('sources')} table is required but does not exist"
          end
        end

        def count
          if portal_sources_exist?
            ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{Wdpa::Portal::Config::PortalImportConfig.portal_view_for('sources')}").to_i
          else
            raise StandardError,
              "#{Wdpa::Portal::Config::PortalImportConfig.portal_view_for('sources')} table is required but does not exist"
          end
        end

        def portal_sources_exist?
          Wdpa::Portal::Utils::ViewManager.view_exists?(Wdpa::Portal::Config::PortalImportConfig.portal_view_for('sources'))
        end
      end
    end
  end
end
