class Wdpa::ProtectedAreaImporter::AttributeImporter
  def self.import wdpa_release
    wdpa_release.protected_areas_in_bulk(100) do |protected_areas|
      import_bulk(protected_areas)
    end

    return true
  end

  private

  def import_bulk(protected_areas)
    protected_areas.each do |protected_area_attributes|
      protected_area_attributes = protected_area_attributes.symbolize_keys

      protected_area_attributes = remove_geometry protected_area_attributes
      standardised_attributes = Wdpa::DataStandard.attributes_from_standards_hash(
        protected_area_attributes
      )

      if standardised_attributes.nil?
        Bystander.log("Protected Area with WDPAID = #{protected_area_attributes[:wdpaid]} was skipped")
        next
      end

      begin
        pa = ProtectedArea.create!(standardised_attributes)
        ImportWorkers::WikipediaSummaryWorker.perform_async pa.id
      rescue => err
        Bystander.log("""
          PA with WDPAID #{protected_area_attributes[:wdpaid]} was not imported because:
          > #{err.message}
        """)
      end
    end
  end

  def self.remove_geometry attributes
    attributes.select do |key, hash|
      Wdpa::DataStandard.standard_geometry_attributes[key].nil?
    end
  end
end
