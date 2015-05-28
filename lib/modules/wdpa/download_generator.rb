class Wdpa::DownloadGenerator
  def self.generate for_import=true
    DownloadWorkers::General.perform_async :general, 'all', for_import: for_import

    Country.pluck(:iso_3).each do |country_iso_3|
      DownloadWorkers::General.perform_async :country, country_iso_3, for_import: for_import
    end
  end
end
