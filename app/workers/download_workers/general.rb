class DownloadWorkers::General < DownloadWorkers::Base
  def perform(format, type, identifier, opts = {})
    while_generating(key(identifier, format)) do
      options = opts.symbolize_keys.merge({ site_ids: collect_site_ids(type, identifier) })

      Download.generate format, filename(identifier, format), options
      { status: 'ready', filename: filename(identifier, format) }.to_json
    end
  end

  protected

  def domain
    'general'
  end

  def collect_site_ids(type, identifier = nil)
    site_ids_per_country = ->(country) { country.protected_areas.pluck(:site_id) }

    case type
    when Download::Requesters::General::TYPE_MAP[:all_wdpca]
      nil # all protected areas
    when Download::Requesters::General::TYPE_MAP[:all_marine_wdpca]
      ProtectedArea.marine_areas.pluck(:site_id)
    when Download::Requesters::General::TYPE_MAP[:all_greenlisted_wdpca]
      ProtectedArea.green_list_areas.pluck(:site_id)
    when 'country'
      site_ids_per_country.call(Country.where(iso_3: identifier).first)
    when 'region'
      region = Region.where(iso: identifier).first
      Set.new(region.countries.flat_map(&site_ids_per_country)).to_a
    else
      []  # safe fallback for unexpected types
    end
  end
end
