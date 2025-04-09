class Wdpa::ProtectedAreaImporter
  PARCC_IMPORT = {
    path: Rails.root.join('lib/data/seeds/parcc_info.csv'),
    field: :has_parcc_info
  }
  IRREPLACEABILITY_IMPORT = {
    path: Rails.root.join('lib/data/seeds/irreplaceability_info.csv'),
    field: :has_irreplaceability_info
  }

  def self.import
    Wdpa::ProtectedAreaImporter::AttributeImporter.import
    Wdpa::ProtectedAreaImporter::GeometryImporter.import

    Wdpa::ProtectedAreaImporter::RelatedSourceImporter.import(PARCC_IMPORT)
    Wdpa::ProtectedAreaImporter::RelatedSourceImporter.import(IRREPLACEABILITY_IMPORT)
  end
end
