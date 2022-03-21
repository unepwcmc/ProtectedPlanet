namespace :import do
  desc "Import geometries for Countries"
  task countries_geometries: :environment do
    CountriesGeometryImporter.import
  end
end
