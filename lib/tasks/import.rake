namespace :import do
  desc "Generate Country Flat protected_Areas"
  task countries_geometries: :environment do
    filename = 'countries_geometries_dump.tar.gz'
    filepath = File.join(Rails.root, 'tmp', filename)
    country_importer = CountriesGeometryImporter.new()
    country_importer.download_countries_geometries_to filename, filepath
  end
end