class Wdpa::DownloadGenerator
  def self.generate for_import=true
    DownloadWorkers::General.perform_async :general, 'all', for_import: for_import

    Country.pluck(:iso).each do |country_iso|
      DownloadWorkers::General.perform_async :country, country_iso, for_import: for_import
    end
  end
end
