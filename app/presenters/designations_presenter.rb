class DesignationsPresenter
  def initialize(geo_entity)
    @geo_entity = geo_entity
  end

  JURISDICTIONS = %w(National Regional International).freeze
  def designations
    designations_by_jurisdiction = get_designations
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

  def total_number_of_designations
    all_pas = geo_entity.protected_areas_per_jurisdiction.to_a
    all_pas.reduce(0) { |count, j| count += j["count"] }
  end

  def percent_of_total(jurisdiction)
    total_per_jurisdiction = designation_total(jurisdiction)
    (( total_per_jurisdiction.to_f / total_number_of_designations.to_f ) * 100).round(2)
  end

  def designation_total(jurisdiction)
    all_pas = geo_entity.protected_areas_per_jurisdiction
    all_pas.find { |result| result["name"] == jurisdiction }["count"]
  end

  def jurisdictions(jurisdiction)
    jurisdiction = get_jurisdiction(jurisdiction)
    return [] unless jurisdiction

    geo_entity.protected_areas_per_designation(jurisdiction)
  end
end