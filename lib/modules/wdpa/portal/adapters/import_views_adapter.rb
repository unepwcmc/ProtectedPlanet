module Wdpa::Portal::Adapters
  class ImportViewsAdapter
    def protected_areas_relation
      Wdpa::Portal::Adapters::Relation::ProtectedAreas.new
    end

    def sources_relation
      Wdpa::Portal::Adapters::Relation::Sources.new
    end
  end
end
