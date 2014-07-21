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
    puts "Deleting old Country stats"
    geometry_calculator.delete_country_stats
    puts "Deleting old Regional and Global stats"
    geometry_calculator.delete_regional_and_global_stats
    puts "Calculating new Country stats"
    geometry_calculator.insert_country_stats
    puts "Calculating new Regional stats"
    geometry_calculator.insert_regional_stats
    puts "Calculating new Global stats"
    geometry_calculator.insert_global_stats

  end
end
