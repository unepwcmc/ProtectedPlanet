namespace :geo_stats do
  desc "Generate Country Flat protected_Areas"
  task country_dissolve: :environment do
    complex_countries_land = ['DEU','USA','FRA','GBR','AUS','FIN','BGR', 'CAN', 'ESP','SWE','BEL','EST', 'IRL', 'ITA', 'LTU', 'NZL','POL','CHE']
    complex_countries_marine = ['GBR']

    geometry_operator = Geospatial::Geometry.new(complex_countries_land,complex_countries_marine)
    geometry_operator.drop_indexes
    geometry_operator.create_buffers
    geometry_operator.dissolve_countries
    geometry_operator.create_indexes

  end

  desc "Calculates geospatial stats"
  task calculate: :environment do
    geometry_calculator = Geospatial::Calculation.new()
    puts "Deleting old stats"
    geometry_calculator.delete_country_stats
    puts "Calculating new stats"
    geometry_calculator.insert_country_stats
  end


  desc "Inserts Mollweide SRID"
  task insert_mollweide: :environment do
    query = """INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values 
    ( 954009, 'esri', 54009, '+proj=moll +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs ', 
      'PROJCS[\"World_Mollweide\",GEOGCS[\"GCS_WGS_1984\",DATUM[\"WGS_1984\",SPHEROID[\"WGS_1984\",6378137,298.257223563]],
      PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.017453292519943295]],PROJECTION[\"Mollweide\"],PARAMETER[\"False_Easting\",0],
      PARAMETER[\"False_Northing\",0],PARAMETER[\"Central_Meridian\",0],UNIT[\"Meter\",1],AUTHORITY[\"EPSG\",\"54009\"]]');""".squish
    ActiveRecord::Base.connection.execute(query)
  end
end