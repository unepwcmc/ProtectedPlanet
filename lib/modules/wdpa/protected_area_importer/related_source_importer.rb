class Wdpa::ProtectedAreaImporter::RelatedSourceImporter
  def self.import
    {
      :parcc_import => parcc_import,
      :irreplaceability_import => irreplaceability_import
    }
  end
  
  def self.parcc_import
    # Delegate to shared service - uses same logic as Portal
    Wdpa::Shared::RelatedSourceImporter.parcc_import(
      target_table: 'protected_areas')
  end

  def self.irreplaceability_import
    # Delegate to shared service - uses same logic as Portal
    Wdpa::Shared::RelatedSourceImporter.irreplaceability_import(
      target_table: 'protected_areas')
  end
end
