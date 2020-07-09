class DownloadWorkers::General < DownloadWorkers::Base
  def perform format, type, identifier, opts={}
    while_generating(key(identifier)) do
      _opts = opts.symbolize_keys.merge({wdpa_ids: collect_wdpa_ids(type, identifier)})

      Download.generate format, filename(identifier), _opts
      {status: 'ready', filename: filename(identifier)}.to_json
    end
  end

  protected

  def domain
    'general'
  end

  def collect_wdpa_ids type, identifier=nil
    wdpa_ids_per_country = -> (country) {country.protected_areas.pluck(:wdpa_id)}

    case type
    when 'general'
      nil
    when 'country'
      wdpa_ids_per_country.call(Country.where(iso_3: identifier).first)
    when 'region'
      region = Region.where(iso: identifier).first
      Set.new(region.countries.flat_map(&wdpa_ids_per_country)).to_a
    when 'marine'
      ProtectedArea.where(marine: true).pluck(:wdpa_id)
    end
  end
end
