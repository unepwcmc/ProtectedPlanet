class Wdpa::ProtectedAreaImporter::AttributeImporter
  def self.import wdpa_release
    wdpa_release.protected_areas_in_bulk(100) do |protected_areas|
      protected_areas.each do |protected_area_attributes|
        protected_area_attributes = protected_area_attributes.symbolize_keys

        protected_area_attributes = remove_geometry protected_area_attributes
        standardised_attributes = Wdpa::DataStandard.attributes_from_standards_hash(
          protected_area_attributes
        )

        next if standardised_attributes.nil?
        unless ProtectedArea.create(standardised_attributes)
          Bystander.log("Protected Area with WDPAID = #{standardised_attributes[:wdpa_id]} couldn't be imported")
        end
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
end
