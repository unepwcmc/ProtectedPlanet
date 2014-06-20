class Wdpa::DownloadGenerator
  def self.generate
    Download.generate 'all'

    Country.all.each do |country|
      Download.generate country.iso_3, country.protected_areas.pluck(:wdpa_id)
    end
  end
end
