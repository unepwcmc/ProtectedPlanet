class Wdpa::ProtectedAreaImporter
  def self.import wdpa_release
    Wdpa::ProtectedAreaImporter::AttributeImporter.import wdpa_release
    Wdpa::ProtectedAreaImporter::GeometryImporter.import wdpa_release
  end
end
