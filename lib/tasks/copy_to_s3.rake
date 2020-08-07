# frozen_string_literal: true

namespace :comfy do
  FROM  = 'storage'
  TO    = ENV['PP_FILES_STAGING']

  desc "Export local Activestorage files to S3 PP staging bucket"
  task :export_to_s3 => :environment do |_t|
    s3 = S3.new(ENV['AWS_REGION'])
    # abort("Sorry, you can't run this in development") if Rails.env.development?

    puts "Exporting CMS data from local ActiveStorage folder [#{FROM}] to Bucket [#{TO}] ..."

    ActiveStorage::Attachment.find_each do |attachment|
      filename = attachment.blob.key
      next if attachment.record.nil?
      
      source_dir = File.join(
        FROM, 
        filename.first(2),
        filename.first(4).last(2)
      )
      source = File.join(source_dir, filename)
      
      s3.upload(filename, Pathname.new(source), bucket: TO)
    end

    puts "Finished exports, now syncing up production with staging..."

    Rake::Task.invoke('comfy:sync_staging_production')
  end

  desc "Sync up production's ActiveStorage files with staging's"
  task :sync_staging_production => :environment do |_t|
    prod_bucket = SESSION.bucket("#{ENV["PP_FILES_PRODUCTION"]}")

    # TODO: When ActiveStorage is set up on production, try to get it synced up - but how do we match up the ActiveStorage files with one another?
    # It would be hard to do even if they were named the same, but the keys are randomly assigned during the migration
  end
end