class Wdpa::Service::GeometryImporter
  DB = ActiveRecord::Base.connection

  def self.import table_name
    begin
      DB.execute("""
        UPDATE protected_areas pa
        SET the_geom = import.wkb_geometry
        FROM #{table_name} import
        WHERE pa.wdpa_id = import.wdpaid;
      """)
    rescue
      return false
    end

    true
  end
end
