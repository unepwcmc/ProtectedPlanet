class DesignationsPresenter
  include CountriesHelper

  def initialize(geo_entity)
    @geo_entity = geo_entity
  end

  JURISDICTIONS = %w(National Regional International).freeze
  def designations
    JURISDICTIONS.map do |j|
      {
        title: designation_title(j),
        total: designation_total(j),
        percent: percent_of_total(j),
        has_jurisdiction: get_jurisdiction(j),
        jurisdictions: jurisdictions(j)
      }
    end
  end

  def designations_without_oecm
    JURISDICTIONS.map do |j|
      {
        title: designation_title(j),
        total: designation_total(j, exclude_oecms: true),
        percent: percent_of_total(j, exclude_oecms: true),
        has_jurisdiction: get_jurisdiction(j),
        jurisdictions: jurisdictions(j, exclude_oecms: true)
      }
    end
  end

  private

  def geo_entity
    @geo_entity
  end

  def get_designations
    geo_entity.designations.group_by { |design|
      design.jurisdiction.name rescue "Not Reported"
    }
  end

  def get_jurisdiction(jurisdiction)
    Jurisdiction.find_by_name(jurisdiction)
  end

  def designation_title(jurisdiction)
    "#{jurisdiction} designations"
  end

  def all_pas(exclude_oecms)
    geo_entity.protected_areas_per_jurisdiction(exclude_oecms: exclude_oecms)
  end

  def total_number_of_designations(exclude_oecms)
    all_pas(exclude_oecms).reduce(0) { |count, j| count + j["count"] }
  end

  def percent_of_total(jurisdiction, exclude_oecms: false)
    total = designation_total(jurisdiction, exclude_oecms: exclude_oecms)
    (( total.to_f / total_number_of_designations(exclude_oecms).to_f ) * 100).round(2)
  end

  def designation_total(jurisdiction, exclude_oecms: false)
    designations = all_pas(exclude_oecms).find { |result| result["name"] == jurisdiction }
    designations ? designations['count'] : 0
  end

  def jurisdictions(jurisdiction, exclude_oecms: false)
    jurisdiction = get_jurisdiction(jurisdiction)
    return [] unless jurisdiction

    geo_entity.protected_areas_per_designation(jurisdiction, exclude_oecms: exclude_oecms)
  end
end