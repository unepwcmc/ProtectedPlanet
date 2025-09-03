class Wdpa::ProtectedAreaImporter
  def self.import
    Wdpa::ProtectedAreaImporter::AttributeImporter.import
    Wdpa::ProtectedAreaImporter::GeometryImporter.import
    Wdpa::Shared::Importer::RelatedSource.import_live
  end
end
