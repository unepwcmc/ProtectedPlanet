namespace :geo_stats do
  desc "Generate Country Flat protected_Areas"
  task country_dissolve: :environment do

    geometry_operator = Geospatial::Geometry.new()
    geometry_operator.drop_indexes
    geometry_operator.create_buffers
    geometry_operator.dissolve_countries
    geometry_operator.split_countries_marine
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
end
