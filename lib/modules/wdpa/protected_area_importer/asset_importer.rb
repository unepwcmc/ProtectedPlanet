class Wdpa::ProtectedAreaImporter::AssetImporter
  def self.import
    ProtectedArea.pluck(:id).each do |protected_area_id|
      ImportWorkers::WikipediaSummaryWorker.perform_async protected_area_id
    end
  end
end
