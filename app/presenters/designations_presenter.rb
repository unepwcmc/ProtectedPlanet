class DesignationsPresenter
  include Rails.application.routes.url_helpers

  def initialize(geo_entity)
    @geo_entity = geo_entity
  end
  # All avaliable JURISDICTIONS
  JURISDICTIONS = ['National', 'Regional', 'International', 'Not Applicable'].freeze
  JURISDICTIONS_TITLE = {
    'National' => 'National',
    'Regional' => 'Regional',
    'International' => 'International',
    'Not Applicable' => 'Other'
  }.freeze

  def designations(exclude_oecms: false)
    JURISDICTIONS.map do |j|
      juristiction_count_data = jurisdiction_counts(j, exclude_oecms: exclude_oecms)
      {
        title: designation_title(j),
        type: j,
        total: designation_total(juristiction_count_data),
        percent: percent_of_total(juristiction_count_data, exclude_oecms: exclude_oecms),
        has_jurisdiction: get_jurisdiction(j),
        jurisdictions: juristiction_count_data
      }
    end
  end

  def designations_list(jurisdictions: [], only_unique_wdpa_ids: false, is_oecm: false)
    jurisdictions = get_jurisdictions(jurisdictions)
    return [] unless jurisdictions.any?

    geo_entity.designations_list_by_wdpa_or_oecm(jurisdictions: jurisdictions,
      only_unique_wdpa_ids: only_unique_wdpa_ids, is_oecm: is_oecm)
  end

  private

  attr_reader :geo_entity

  def get_designations
    geo_entity.designations.group_by do |design|
      design.jurisdiction.name
    rescue StandardError
      'Not Reported'
    end
  end

  def get_jurisdiction(jurisdiction)
    Jurisdiction.find_by_name(jurisdiction)
  end

  def designation_title(jurisdiction)
    jurisdiction_title = JURISDICTIONS_TITLE[jurisdiction]
    jurisdiction_title ? "#{jurisdiction_title} designations" : 'Designation Title Not Found'
  end

  def all_pas(exclude_oecms)
    @all_pas ||= geo_entity.protected_areas_per_jurisdiction(exclude_oecms: exclude_oecms)
  end

  def total_number_of_designations(exclude_oecms)
    all_pas(exclude_oecms).reduce(0) { |count, j| count + j['count'] }
  end

  def percent_of_total(jurisdictions, exclude_oecms: false)
    total = designation_total(jurisdictions)
    ((total / total_number_of_designations(exclude_oecms).to_f) * 100).round(2)
  end

  def designation_total(jurisdictions)
    jurisdictions.reduce(0) { |count, j| count + j['count'].to_i }
  end

  def jurisdiction_counts(jurisdiction, exclude_oecms: false)
    jurisdictions = get_jurisdictions(jurisdiction)
    return [] unless jurisdictions.any?

    geo_entity.protected_areas_per_designation(jurisdictions, exclude_oecms: exclude_oecms)
  end

  def get_jurisdictions(jurisdiction)
    # 'Not Applicable' jurisdictions are to be included with
    # 'National' in the country and region show pages.
    # https://unep-wcmc.codebasehq.com/projects/protected-planet-support-and-maintenance/tickets/241
    # jurisdictions = jurisdiction == 'National' ? ['National', 'Not Applicable'] : jurisdiction

    # As 20 DEC 2023 Not Applicable is now showing as a category
    # https://unep-wcmc.codebasehq.com/projects/protected-planet-support-and-maintenance/tickets/337#update-73110217
    Jurisdiction.where(name: jurisdiction)
  end
end
