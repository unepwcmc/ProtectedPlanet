class Wdpa::ProtectedAreaImporter::IrreplaceabilityImporter
  def self.import
    rows = CSV.read(irreplaceability_csv_path)
    wdpa_ids = rows.map(&:first)

    ProtectedArea.where(wdpa_id: wdpa_ids).update_all(has_irreplaceability_info: true)
  end

  def self.irreplaceability_csv_path
    Rails.root.join('lib/data/seeds/irreplaceability_info.csv')
  end
end
