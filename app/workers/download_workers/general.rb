class DownloadWorkers::General < DownloadWorkers::Base
  def perform(format, type, identifier, opts = {})
    while_generating(key(identifier, format)) do
      options = opts.symbolize_keys.merge({ site_ids: collect_site_ids(type, identifier) })

      success = Download.generate format, filename(identifier, format), options
      raise "Download.generate returned false (#{domain} #{format} #{identifier})" unless success
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
    when 'general'
      nil
    when 'country'
      site_ids_per_country.call(Country.where(iso_3: identifier).first)
    when 'region'
      region = Region.where(iso: identifier).first
      Set.new(region.countries.flat_map(&site_ids_per_country)).to_a
    when 'marine'
      ProtectedArea.marine_areas.pluck(:site_id)
    when 'greenlist'
      ProtectedArea.green_list_areas.pluck(:site_id)
    when 'oecm'
      ProtectedArea.oecms.pluck(:site_id)
    when 'wdpa'
      ProtectedArea.wdpas.pluck(:site_id)
    end
  end
end
