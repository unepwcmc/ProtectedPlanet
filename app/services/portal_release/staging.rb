# frozen_string_literal: true

module PortalRelease
  class Staging
    def initialize(log)
      @log = log
    end

    def prepare!
      Wdpa::Portal::Managers::StagingTableManager.create_staging_tables
      @log.event('staging_prepared', payload: { tables: Wdpa::Portal::Config::PortalImportConfig.staging_tables })
    end
  end
end

