class DownloadWorkers::General < DownloadWorkers::Base
  def perform(format, type, identifier, opts = {})
    while_generating(key(identifier, format)) do

      options = opts.symbolize_keys.merge(
        site_selection: build_site_selection(type, identifier)
      )

      success = Download.generate format, filename(identifier, format), options
      raise "Download.generate returned false (#{domain} #{format} #{identifier})" unless success
      { status: 'ready', filename: filename(identifier, format) }.to_json
    end
  end

  protected

  def domain
    'general'
  end

  # Returns a selection hash (or nil) describing how to filter:
  # - country:   by ISO3 = [identifier(iso3)]
  # - region:    by ISO3 in that region's countries [iso3_1, iso3_2]
  # - marine:    by REALM IN ['Marine', 'Coastal']
  # - greenlist: by explicit [site_id, site_pid] pairs
  # - oecm/wdpa: by site_ids
  # See add_conditions in lib/modules/download/generators/base.rb for the usuage
  def build_site_selection(type, identifier = nil)
    case type
    when 'general'
      nil

    when 'country'
      country = Country.where(iso_3: identifier).first

      if country.nil?
        nil
      else
        {
          iso3: [country.iso_3],
          site_ids: nil,
          site_id_and_pid_pairs: nil,
          site_types: nil
        }
      end

    when 'region'
      region = Region.find_by(iso: identifier)
      iso3_codes = region ? region.countries.pluck(:iso_3) : []

      if iso3_codes.empty?
        nil
      else
        {
          iso3: iso3_codes,
          site_ids: nil,
          site_id_and_pid_pairs: nil,
          site_types: nil
        }
      end

    when 'marine'
      {
        iso3: nil,
        site_ids: nil,
        site_id_and_pid_pairs: nil,
        site_types: nil,
        realms: Download::Config.marine_realm_values
      }

    when 'greenlist'
      pa_pairs     = ProtectedArea.pas_with_green_list_on_self_only.pluck(:site_id, :site_pid)
      parcel_pairs = ProtectedAreaParcel.greenlisted_parcels.pluck(:site_id, :site_pid)

      {
        iso3: nil,
        site_ids: nil,
        site_id_and_pid_pairs: pa_pairs + parcel_pairs,
        site_types: nil
      }

    when 'oecm'
      {
        iso3: nil,
        site_ids: ProtectedArea.oecms.pluck(:site_id),
        site_id_and_pid_pairs: nil,
        site_types: [Download::Config.oecm_site_type_value]
      }

    when 'wdpa'
      {
        iso3: nil,
        site_ids: ProtectedArea.wdpas.pluck(:site_id),
        site_id_and_pid_pairs: nil,
        site_types: nil
      }
    end
  end
end
