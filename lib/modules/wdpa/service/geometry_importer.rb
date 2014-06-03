class Wdpa::Service::GeometryImporter
  DB = ActiveRecord::Base.connection

  def self.import protected_areas
    protected_areas.each do |protected_area_attributes|
      next if protected_area_exists protected_area_attributes[:wdpaid]

      standard_attributes = Wdpa::DataStandard.attributes_from_standards_hash({
        wdpaid: protected_area_attributes[:wdpaid],
        wkb_geometry: protected_area_attributes[:wkb_geometry]
      })

      wdpa_id = standard_attributes[:wdpa_id]
      geometry = standard_attributes[:the_geom]

      begin
        DB.execute("""
          UPDATE protected_areas
          SET the_geom = ST_GeomFromText(E'#{geometry}')
          WHERE wdpa_id = #{wdpa_id}
        """)
      rescue
        return false
      end
    end

    true
  end

  private

  def self.protected_area_exists wdpa_id
    existing_protected_area = ProtectedArea.
      select('wdpa_id').
      where(
        wdpa_id: wdpa_id,
        the_geom: nil
      ).first

    existing_protected_area.nil?
  end
end
