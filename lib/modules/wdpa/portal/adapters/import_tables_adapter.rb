module Wdpa::Portal::Adapters
  class ImportTablesAdapter
    def protected_areas_relation
      Wdpa::Portal::Importers::PortalProtectedAreasRelation.new
    end

    def sources_relation
      Wdpa::Portal::Importers::PortalSourcesRelation.new
    end

    def portal?
      true # This adapter is portal-specific only
    end
  end
end
