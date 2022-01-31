namespace :import do
  desc "Import geometries for Countries"
  task countries_geometries: :environment do
    CountriesGeometryImporter.import
  end

  desc "Import statistics files for new release"
  task new_release_statistics: :environment do

    # To be run AFTER deploying a new release 
    # Function:
      # 1. Checks an S3 bucket exists for the date constants provided in config/initializers/constants.rb
      # 2. Runs the required importers to complete the release

    class BucketAndConstantMismatchError < StandardError; end;

    bucket_identifier = "#{WDPA_UPDATE_MONTH.first(3)}#{WDPA_UPDATE_YEAR}"
    raise BucketAndConstantMismatchError unless Wdpa::S3.current_wdpa_identifier == bucket_identifier
    puts "Bucket matching release constants found: #{ bucket_identifier }"

    puts "importing release statistics"
    puts "Importing #{ Stats::CountryStatisticsImporter.latest_country_statistics_csv.split('/').last } and
          #{ Stats::CountryStatisticsImporter.latest_country_statistics_csv.split('/').last }"
    ImportTools.statistics_monthly_import
    
    puts "Importing #{ Wdpa::GlobalStatsImporter.latest_global_statistics_csv.split('/').last }"
    Wdpa::GlobalStatsImporter.import

    puts "Importing #{ Wdpa::GreenListImporter.latest_green_list_sites_csv.split('/').last }"
    Wdpa::GreenListImporter.import
    
    puts "Importing #{ Wdpa::PameImporter.latest_pame_data_csv.split('/').last }"
    Wdpa::PameImporter.import

    puts "Imports complete"

  rescue BucketAndConstantMismatchError
    puts "Import failed. No bucket found matching release constants in config/initializers/constants.rb: #{WDPA_UPDATE_MONTH.first(3)}#{WDPA_UPDATE_YEAR}"
  rescue => error
    puts error
  end
end
