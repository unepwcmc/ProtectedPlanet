# frozen_string_literal: true

module Wdpa
  module Portal
    module Adapters
      class ImportViewsAdapter
        def protected_areas_relation
          Wdpa::Portal::Adapters::ProtectedAreas.new
        end

        def sources_relation
          Wdpa::Portal::Adapters::Sources.new
        end
      end
    end
  end
end
