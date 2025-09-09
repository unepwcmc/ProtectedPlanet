# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      # There are more functions defined in Wdpa::Shared::ImporterBase::Base 
      # shared/used by portal importers and shared importers
      class Base < Wdpa::Shared::ImporterBase::Base
        def self.import_to_staging
          raise NotImplementedError, 'Subclasses must implement import_to_staging'
        rescue StandardError => e
          failure_result("Setup error: #{e.message}", 0)
        end
      end
    end
  end
end
