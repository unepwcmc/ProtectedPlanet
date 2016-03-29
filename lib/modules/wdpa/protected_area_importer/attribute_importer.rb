class Wdpa::ProtectedAreaImporter::AttributeImporter
  def self.import wdpa_release
    imported_wdpa_ids = {}

    wdpa_release.protected_areas_in_bulk(500) do |protected_areas|
      protected_areas.each do |protected_area_attributes|
        protected_area_attributes = protected_area_attributes.symbolize_keys
        if imported_wdpa_ids[protected_area_attributes[:wdpaid]]
          Bystander.log("WDPAID = #{protected_area_attributes[:wdpaid]} was skipped")
          next
        end

        protected_area_attributes = remove_geometry protected_area_attributes
        standardised_attributes = Wdpa::DataStandard.attributes_from_standards_hash(
          protected_area_attributes
        )

        if standardised_attributes.nil?
          Bystander.log("Protected Area with WDPAID = #{protected_area_attributes[:wdpaid]} was skipped")
          next
        end

        if pa = ProtectedArea.create(standardised_attributes)
          imported_wdpa_ids[protected_area_attributes[:wdpaid]] = true
          ImportWorkers::WikipediaSummaryWorker.perform_async pa.id
        else
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
