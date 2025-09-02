class Wdpa::ProtectedAreaImporter
  def self.import
    Wdpa::ProtectedAreaImporter::AttributeImporter.import
    Wdpa::ProtectedAreaImporter::GeometryImporter.import
    Wdpa::ProtectedAreaImporter::RelatedSourceImporter.import
  end
end
