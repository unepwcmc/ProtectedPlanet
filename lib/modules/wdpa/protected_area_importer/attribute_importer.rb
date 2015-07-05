class Wdpa::ProtectedAreaImporter::AttributeImporter
  def self.import wdpa_release
    imported_wdpa_ids = {}
    protected_areas = wdpa_release.protected_areas

    protected_areas.each do |protected_area_attributes|
      protected_area_attributes = protected_area_attributes.symbolize_keys

      protected_area_attributes = remove_geometry protected_area_attributes
      standardised_attributes = Wdpa::DataStandard.attributes_from_standards_hash(
        protected_area_attributes
      )

      next if standardised_attributes.nil?
      next if imported_wdpa_ids[standardised_attributes[:wdpa_id]]

      imported_wdpa_ids[standardised_attributes[:wdpa_id]] = true
      ProtectedArea.create(standardised_attributes)
    end

    return true
  end

  private

  def self.remove_geometry attributes
    attributes.select do |key, hash|
      Wdpa::DataStandard.standard_geometry_attributes[key].nil?
    end
  end
end
