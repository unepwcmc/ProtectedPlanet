class Wdpa::DownloadGenerator
  def self.generate
    DownloadWorkers::General.perform_async :general, 'all', for_import: true

    Country.pluck(:iso).each do |country_iso|
      DownloadWorkers::General.perform_async :country, country_iso, for_import: true
    end
  end
end
