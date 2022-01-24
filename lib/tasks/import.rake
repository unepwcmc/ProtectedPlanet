namespace :import do
  desc "Import geometries for Countries"
  task countries_geometries: :environment do
    CountriesGeometryImporter.import
  end

  desc "Import statistics files for new release"
  task new_release_statistics: :environment do
    class BucketAndConstantMistmatchError < StandardError; end;

    bucket_identifier = "#{WDPA_UPDATE_MONTH.first(3)}#{WDPA_UPDATE_YEAR}"
    raise BucketAndConstantMistmatchError unless Wdpa::S3.current_wdpa_identifier == bucket_identifier
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

  rescue BucketAndConstantMistmatchError
    puts "Import failed. No bucket found matching release constants in config/initializers/constants.rb: #{WDPA_UPDATE_MONTH.first(3)}#{WDPA_UPDATE_YEAR}"
  rescue => error
    puts error
  end
end
