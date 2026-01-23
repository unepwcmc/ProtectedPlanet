# frozen_string_literal: true

module Wdpa
  module Portal
    module Adapters
      class ImportViewsAdapter
        def protected_areas_relation
          Wdpa::Portal::Adapters::ProtectedAreas.new
        end

        def protected_area_sources_relation
          Wdpa::Portal::Adapters::ProtectedAreaSources.new
        end

        end
      end
    end
  end
end
