# frozen_string_literal: true

module PortalRelease
  class RelatedImporters
    def initialize(log)
      @log = log
    end

    def run_all!
      # In current Step 2, related importers are already part of Wdpa::Portal::Importer.import
      # Keep this class for forward compatibility when we split/import additional datasets.
      @log.event('related_importers_skipped')
    end
  end
end

