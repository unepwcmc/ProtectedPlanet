class Wdpa::Service::GeometryImporter
  DB = ActiveRecord::Base.connection

  def self.import protected_areas
    protected_areas.each do |protected_area_attributes|
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
end
