class Wdpa::ProtectedAreaImporter::GeometryImporter
  DB = ActiveRecord::Base.connection

  def self.import wdpa_release
    wdpa_release.geometry_tables.each do |table_name|
      begin
        query = """
          UPDATE protected_areas pa
          SET the_geom = import.wkb_geometry
          FROM #{table_name} import
          WHERE pa.wdpa_id = import.wdpaid;
        """.squish

        DB.execute(query)
      rescue
        return false
      end
    end

    true
  end
end
