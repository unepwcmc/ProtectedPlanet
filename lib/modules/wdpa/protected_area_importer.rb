class Wdpa::ProtectedAreaImporter
  def self.import
    Wdpa::ProtectedAreaImporter::AttributeImporter.import
    Wdpa::ProtectedAreaImporter::GeometryImporter.import
    Wdpa::Shared::Importer::ProtectedAreasRelatedSource.import_live
  end
end
