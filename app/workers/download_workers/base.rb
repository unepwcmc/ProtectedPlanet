class DownloadWorkers::Base
  include Sidekiq::Worker
  sidekiq_options retry: false, backtrace: true

  # special_status values that resolve to parcel-precise site_id+site_pid pairs.
  # Using pairs prevents false inclusion of non-matching parcels on the same site.
  SPECIAL_STATUS_PAIR_QUERIES = {
    'pa_or_any_its_parcels_is_greenlisted' => -> {
      pa_pairs     = ProtectedArea.pas_with_green_list_on_self_only.pluck(:site_id, :site_pid)
      parcel_pairs = ProtectedAreaParcel.greenlisted_parcels.pluck(:site_id, :site_pid)
      pa_pairs | parcel_pairs
    },
    'pa_or_any_its_parcels_is_greenlist_candidate' => -> {
      pa_pairs     = ProtectedArea.joins(:green_list_status)
                                  .where(green_list_statuses: { gl_status: 'Candidate' })
                                  .pluck(:site_id, :site_pid)
      parcel_pairs = ProtectedAreaParcel.joins(:green_list_status)
                                        .where(green_list_statuses: { gl_status: 'Candidate' })
                                        .pluck(:site_id, :site_pid)
      pa_pairs | parcel_pairs
    }
  }.freeze

  # special_status values that resolve to site-level site_ids (parcel precision not applicable).
  SPECIAL_STATUS_ID_QUERIES = {
    'has_parcc_info'   => -> { ProtectedArea.where(has_parcc_info: true).pluck(:site_id) },
    'is_transboundary' => -> { ProtectedArea.transboundary_sites.pluck(:site_id) }
  }.freeze

  def self.perform_async *args
    queue = if args.last.is_a?(Hash) && args.last[:for_import]
              args.pop unless keep_last_arg args
              'import'
            else
              'default'
            end

    jid = Sidekiq::Client.push('class' => self, 'queue' => queue, 'args' => args)
    jid
  end

  protected

  def key(identifier, format)
    Download::Utils.key domain, identifier, format
  end

  def filename(identifier, format)
    Download::Utils.filename domain, identifier, format
  end

  def while_generating(key)
    properties = Download::Utils.properties(key)
    generating_properties = properties.merge({ 'status' => 'generating' })
    Download::Utils.write(key, generating_properties)

    begin
      result_json = yield
      Download::Utils.write(key, result_json)
    # Exception, not StandardError. NotImplementedError is a ScriptError, so an
    # unimplemented generator hook sailed straight past the old rescue and left
    # the key pinned at "generating" forever -- which then blocked every future
    # request for that download. Anything that is not a clean success must land
    # the key in a retryable state.
    rescue Exception => e # rubocop:disable Lint/RescueException
      failed_properties = properties.merge({ 'status' => 'failed', 'error' => e.message })
      Download::Utils.write(key, failed_properties)
      Rails.logger.error("Download generation failed for #{key}: #{e.class}: #{e.message}")

      # Shutdown signals are not download failures: let Sidekiq's own handling
      # take over once the key is safely marked retryable.
      raise if e.is_a?(SignalException) || e.is_a?(SystemExit) || e.is_a?(Interrupt)

      # Otherwise do not re-raise, so status stays "failed" and future requests
      # can re-enqueue immediately.
      failed_properties.to_json
    ensure
      # Clear the enqueue lock (if any) so failed downloads can be retried immediately.
      # This is safe because requesters also check the main key's status (`generating`/`ready`)
      # to prevent duplicate enqueueing.
      $redis.del(Download::Utils.enqueue_lock_key(key))
    end
  end

  # Returns a selection hash (or nil) describing how to filter the download:
  # - country:   by ISO3 = [identifier(iso3)]
  # - region:    by ISO3 in that region's countries [iso3_1, iso3_2]
  # - marine:    by REALM IN ['Marine', 'Coastal']
  # - greenlist: by explicit [site_id, site_pid] pairs
  # - oecm/wdpa: by site_ids
  # - search:    by AND-composed search filters (identifier = parsed filters Hash)
  #
  # IMPORTANT:
  # Avoid passing very large site_ids/site_id_and_pid_pairs arrays where possible.
  # Large ID lists create heavy SQL and slow downloads; prefer composable filters
  # (iso3/is_marine/is_oecm/search filters) and only use explicit IDs/pairs when required.
  # See add_conditions in lib/modules/download/generators/base.rb for the usage
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
          is_oecm: nil
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
          is_oecm: nil
        }
      end

    when 'marine'
      {
        iso3: nil,
        site_ids: nil,
        site_id_and_pid_pairs: nil,
        is_oecm: nil,
        is_marine: true
      }

    when 'greenlist'
      pa_pairs     = ProtectedArea.pas_with_green_list_on_self_only.pluck(:site_id, :site_pid)
      parcel_pairs = ProtectedAreaParcel.greenlisted_parcels.pluck(:site_id, :site_pid)

      {
        iso3: nil,
        site_ids: nil,
        site_id_and_pid_pairs: pa_pairs | parcel_pairs,
        is_oecm: nil
      }

    when 'oecm'
      {
        iso3: nil,
        site_ids: nil,
        site_id_and_pid_pairs: nil,
        is_oecm: true
      }

    when 'wdpa'
      {
        iso3: nil,
        site_ids: nil,
        site_id_and_pid_pairs: nil,
        is_oecm: false
      }

    when 'search'
      build_search_selection(identifier)
    end
  end

  private

  # Converts parsed search filter params into an AND-composed selection hash.
  # SQL-mappable filters become direct WHERE clause values; DB-resolved filters
  # (special_status, has_irreplaceability_info) are resolved via AR scopes.
  def build_search_selection(filters)
    selection = {}

    iso3 = resolve_location_filters_to_iso3(filters)
    selection[:iso3] = iso3 if iso3.any?

    marine_val = filters['marine']
    selection[:is_marine] = marine_val unless marine_val.nil?

    is_oecm_val = filters['is_oecm']
    selection[:is_oecm] = is_oecm_val unless is_oecm_val.nil?

    iucn_cats = Array(filters['iucn_category']).reject(&:blank?)
    selection[:iucn_categories] = iucn_cats if iucn_cats.any?

    designations = Array(filters['designation']).reject(&:blank?)
    selection[:designations] = designations if designations.any?

    governance_types = Array(filters['governance']).reject(&:blank?)
    selection[:governance_types] = governance_types if governance_types.any?

    db_pairs, db_ids = resolve_db_filters(filters)
    selection[:site_id_and_pid_pairs] = db_pairs if db_pairs.any?
    selection[:site_ids] = db_ids if db_ids.any?

    # Distinguish "no filters requested" (empty hash means download all)
    # from "filters requested but resolved to no matches" (has_filters_but_empty_matches).
    selection[:has_filters_but_empty_matches] = true if selection.empty? && search_filters_requested?(filters)

    selection
  end

  def search_filters_requested?(filters)
    return false if filters.blank?

    value_filters = %w[
      country
      region
      iucn_category
      designation
      governance
      special_status
    ]
    return true if value_filters.any? { |key| Array(filters[key]).reject(&:blank?).any? }
    return true if filters['has_irreplaceability_info'].present?
    return true if !filters['marine'].nil?
    return true if !filters['is_oecm'].nil?

    false
  end

  # Resolves location filter inputs (country/region names or codes) into ISO3 values.
  def resolve_location_filters_to_iso3(filters)
    country_iso3 = country_names_to_iso3s(Array(filters['country']).reject(&:blank?))
    region_iso3 = region_names_to_iso3s(Array(filters['region']).reject(&:blank?))
    (country_iso3 + region_iso3).uniq
  end

  def country_names_to_iso3s(country_identifiers)
    return [] if country_identifiers.blank?

    Country.where(name: country_identifiers).pluck(:iso_3).uniq
  end

  def region_names_to_iso3s(region_identifiers)
    return [] if region_identifiers.blank?

    Region.where(name: region_identifiers).flat_map { |r| r.countries.pluck(:iso_3) }.uniq
  end

  # Resolves DB-backed filters (special_status, has_irreplaceability_info) into
  # two separate arrays: parcel-precise pairs and site-level ids.
  # Multiple values within a filter group are OR-ed (union).
  def resolve_db_filters(filters)
    pairs = []
    ids   = []

    special_status_values = Array(filters['special_status']).reject(&:blank?)
    special_status_values.each do |value|
      if SPECIAL_STATUS_PAIR_QUERIES.key?(value)
        pairs |= SPECIAL_STATUS_PAIR_QUERIES[value].call
      elsif SPECIAL_STATUS_ID_QUERIES.key?(value)
        ids |= SPECIAL_STATUS_ID_QUERIES[value].call
      end
    end

    if filters['has_irreplaceability_info'].present?
      ids |= ProtectedArea.where(has_irreplaceability_info: true).pluck(:site_id)
    end

    [pairs, ids]
  end

  def self.keep_last_arg(args)
    instance_method(:perform).arity.abs == args.size
  end
end
