# frozen_string_literal: true

namespace :comfy do
  TO    = Rails.application.secrets.aws_files_bucket
  FILES = File.join(ComfortableMexicanSofa.config.seeds_path, 'protected-planet', 'files')
  STORAGE = Rails.root.join('storage').freeze

  def check_for_identifiers(attachment)
    old_filename = nil

    if attachment.record.file_file_name.present?
      old_filename = attachment.record.file_file_name
    elsif attachment.record.label.present?
      # Exclude annoying yml files
      old_filename = Dir.glob('*.*[^yml]', base: FILES).find do |file|
        file =~ /(#{attachment.record.label.gsub(/\s/, '_')})/i
      end
    end

    old_filename
  end

  desc "Export local Activestorage files to S3 PP staging bucket"
  task :export_to_s3 => :environment do |_t|
    puts "Exporting CMS data from local ActiveStorage folder [#{STORAGE}] to Bucket [#{TO}] ..."
    
    unmigrated_files = []
    skipped_files_count = 0
    skipped_fragments_count = 0
    migrated_count = 0

    ActiveStorage::Attachment.find_each do |attachment|
      filename = attachment.blob.key
      next if attachment.record.nil?

      if attachment.record.is_a?(Comfy::Cms::File)
        old_filename = check_for_identifiers(attachment)

        if old_filename.nil?
          puts "SKIP FILE: File #{attachment.blob.filename} doesn't exist. Skipping..."
          skipped_files_count += 1
          unmigrated_files << attachment.record.id
          next
        end
        old_file = File.join(FILES, old_filename)
      elsif attachment.record.is_a?(Comfy::Cms::Fragment)
        old_filename = attachment.blob.filename
        old_key = attachment.blob.key
        f1 = old_key[0..1]
        f2 = old_key[2..3]
        old_file = File.join(STORAGE, f1, f2, old_key)

        unless File.exists?(old_file)
          puts "SKIP FRAGMENT: File #{old_filename}[#{old_file}] doesn't exist. Skipping..."
          skipped_fragments_count += 1
          unmigrated_files << attachment.record.id
          next
        end
      end

      puts "Migrating #{old_filename}[#{filename}]..."
      migrated_count += 1
      S3.upload(filename, Pathname.new(old_file), bucket: TO)
    end

    puts "Total migrated: #{migrated_count}"
    puts "Total files skipped: #{skipped_files_count}"
    puts "Total fragments skipped: #{skipped_fragments_count}"
    puts "Could not migrate records with IDs: #{unmigrated_files.join(', ')}"
  end

  desc "Sync up production's ActiveStorage files with staging's"
  task :sync_staging_production => :environment do |_t|

    # TODO: When ActiveStorage is set up on production, try to get it synced up 
  end
end