class Wdpa::ProtectedAreaImporter::AttributeImporter
  def self.import wdpa_release
    protected_areas = wdpa_release.protected_areas.map(&:symbolize_keys)

    protected_areas.each do |protected_area_attributes|
      unless protected_area_exists(protected_area_attributes[:wdpaid])
        protected_area_attributes = remove_geometry protected_area_attributes
        standardised_attributes = Wdpa::DataStandard.attributes_from_standards_hash(
          protected_area_attributes
        )

        protected_area = ProtectedArea.create(standardised_attributes)
        return false unless protected_area
      end
    end

    return true
  end

  private

  def self.remove_geometry attributes
    attributes.select do |key, hash|
      Wdpa::DataStandard.standard_geometry_attributes[key].nil?
    end
  end

  def self.protected_area_exists wdpa_id
    ProtectedArea.
      select('wdpa_id').
      where(wdpa_id: wdpa_id).
      count > 0
  end
end
