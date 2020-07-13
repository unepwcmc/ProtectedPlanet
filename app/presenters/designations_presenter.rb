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

  def designation_total(jurisdiction)
    designations_per_jurisdiction = jurisdictions(jurisdiction).to_a
    designations_per_jurisdiction.reduce(0) { |sum, desig| sum += desig["count"] }
  end

  def jurisdictions(jurisdiction)
    jurisdiction = get_jurisdiction(jurisdiction)
    return [] unless jurisdiction

    geo_entity.protected_areas_per_designation(jurisdiction)
  end
end