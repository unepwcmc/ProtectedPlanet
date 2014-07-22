class AddMolleweideProjection < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO spatial_ref_sys (
            srid, auth_name, auth_srid, proj4text, srtext
          ) VALUES (
            954009, 'esri', 54009, '+proj=moll +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs ',
            'PROJCS[\"World_Mollweide\",GEOGCS[\"GCS_WGS_1984\",DATUM[\"WGS_1984\",SPHEROID[\"WGS_1984\",6378137,298.257223563]],
             PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.017453292519943295]],PROJECTION[\"Mollweide\"],PARAMETER[\"False_Easting\",0],
             PARAMETER[\"False_Northing\",0],PARAMETER[\"Central_Meridian\",0],UNIT[\"Meter\",1],AUTHORITY[\"EPSG\",\"54009\"]]'
          )
        SQL
      end

      dir.down do
        execute <<-SQL
          DELETE FROM spatial_ref_sys WHERE srid = 954009
        SQL
      end
    end
  end
end
