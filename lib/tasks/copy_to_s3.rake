# frozen_string_literal: true

namespace :comfy do
  FROM  = 'storage'
  TO    = ENV['PP_FILES_STAGING']
  FILES = File.join(ComfortableMexicanSofa.config.seeds_path, 'protected-planet', 'files')

  desc "Export local Activestorage files to S3 PP staging bucket"
  task :export_to_s3 => :environment do |_t|
    s3 = S3.new(ENV['AWS_REGION'])

    puts "Exporting CMS data from local ActiveStorage folder [#{FROM}] to Bucket [#{TO}] ..."
    
    unmigrated_files = []

    ActiveStorage::Attachment.where(record_type: 'Comfy::Cms::File').find_each do |attachment|
      filename = attachment.blob.key
      next if attachment.record.nil?
      
      if attachment.record.file_file_name.present?
        old_filename = attachment.record.file_file_name
      elsif attachment.record.label.present?
        # Exclude annoying yml files
        old_filename = Dir.glob('*.*[^yml]', base: FILES).find do |file|
          file =~ /(#{attachment.record.label.gsub(/\s/, '_')})/i
        end
      end

      if old_filename.nil?
        unmigrated_files << attachment.record.id
        next
      end

      old_file = File.join(FILES, old_filename)
      
      s3.upload(filename, Pathname.new(old_file), bucket: TO)
    end

    puts "Could not migrate records with IDs: #{unmigrated_files.join(', ')}"
  end

  desc "Sync up production's ActiveStorage files with staging's"
  task :sync_staging_production => :environment do |_t|
    prod_bucket = SESSION.bucket("#{ENV["PP_FILES_PRODUCTION"]}")

    # TODO: When ActiveStorage is set up on production, try to get it synced up 
  end
end