class Wdpa::ProtectedAreaImporter::RelatedSourceImporter
  def self.import path: path, field: field
    rows = CSV.read(path)
    wdpa_ids = rows.map(&:first)

    ProtectedArea.where(wdpa_id: wdpa_ids).update_all(field => true)
  end
end
