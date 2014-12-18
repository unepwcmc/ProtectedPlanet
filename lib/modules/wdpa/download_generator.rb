class Wdpa::DownloadGenerator
  def self.generate
    DownloadWorkers::General.perform_async :general, 'all', for_import: true

    Country.pluck(:iso_3).each do |country_iso_3|
      DownloadWorkers::General.perform_async :country, country_iso_3, for_import: true
    end

    Region.pluck(:iso).each do |region_iso|
      DownloadWorkers::General.perform_async :region, region_iso, for_import: true
    end
  end
end
