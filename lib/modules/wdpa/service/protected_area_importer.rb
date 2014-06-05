class Wdpa::Service::ProtectedAreaImporter
  def self.import protected_areas
    protected_areas = protected_areas.map(&:symbolize_keys)

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
    std_attributes = Wdpa::DataStandard::STANDARD_ATTRIBUTES

    attributes.select do |key, hash|
      std_attribute = std_attributes[key]
      unless std_attribute.nil?
        std_attribute[:type] != :geometry
      end
    end
  end

  def self.protected_area_exists wdpa_id
    ProtectedArea.
      select('wdpa_id').
      where(wdpa_id: wdpa_id).
      count > 0
  end
end
