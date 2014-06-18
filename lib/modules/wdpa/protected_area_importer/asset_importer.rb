class Wdpa::ProtectedAreaImporter::AssetImporter
  def self.import
    ProtectedArea.pluck(:id).each do |protected_area_id|
      WikipediaSummaryWorker.perform_async protected_area_id
      ImageWorker.perform_async protected_area_id
    end
  end
end
