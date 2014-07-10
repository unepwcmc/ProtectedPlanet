namespace :geo_stats do
  desc "Generate Country Flat protected_Areas"
  task country_dissolve: :environment do
    complex_countries_land = ['DEU','USA','FRA','GBR','AUS','FIN','BGR', 'CAN', 'ESP','SWE','BEL','EST', 'IRL', 'ITA', 'LTU', 'NZL','POL','CHE']
    complex_countries_marine = ['GBR']

    geometry_operator = Geospatial::Geometry.new(complex_countries_land,complex_countries_marine)
    geometry_operator.dissolve_countries

  end

end