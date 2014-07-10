namespace :import do
  desc "Generate Country Flat protected_Areas"
  task countries_geometries: :environment do
    FILENAME = 'countries_geometries_dump.tar.gz'
    FILEPATH = File.join(Rails.root, 'tmp', FILENAME)
    TYPE = ['LAND','TS','EEZ']

    country_importer = CountriesGeometryImporter.new(FILENAME,FILEPATH)

    puts "Downloading dump table"
    #country_importer.download_countries_geometries

    puts "Importing dump table"
    country_importer.restore_table 

    countries = Country.pluck(:iso_3)
    


    TYPE.each do |type|
      countries.each do |iso_3|
        puts "Importing #{type} for #{iso_3}"
        country_importer.update_table type, iso_3
      end
    end

    puts "Deleting temporary table and file"
    country_importer.delete_temp_table
    country_importer.delete_temp_file 
  end
end