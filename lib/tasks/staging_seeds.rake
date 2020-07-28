# frozen_string_literal: true

namespace :comfy do
    desc "Import CMS Seed data from staging"

    def check_timestamp(file, session, local_file, remote_file)     
      is_newer = Time.at(file.attributes.mtime) >= File.stat(local_file).mtime 
      if is_newer 
        puts "#{file.name} is newer than the local copy, downloading..."
        session.scp.download!(remote_file, local_file)
      end
    end

    # Locally stored seeds - assumes you already have the local folder - 
    # it won't create it 
    LOCAL = (ComfortableMexicanSofa.config.seeds_path + '/protected-planet').freeze
    REMOTE = 'ProtectedPlanet/current/db/cms_seeds/protected-planet'.freeze

    task :seed_import => :environment do |_t|
      require 'net/ssh'
      require 'net/scp'  
      
      puts "Importing CMS Seed data from Staging Folder to #{local} ..."

      # SSH into staging server with Net::SSH
      Net::SSH.start(ENV['PP_STAGING'], ENV['PP_USER']) do |session|
        session.sftp.dir.glob(REMOTE, '**/*').each do |file|
          # Go through the various files and folders and check to see if they exist locally
          remote_file = File.join(remote, file.name)
          local_file = File.join(LOCAL, file.name)
          
          # There are files with non-ASCII characters (i.e. accented) in the CMS files
          if Dir.glob('**/*', base: LOCAL).include?(file.name.force_encoding('UTF-8'))
            if File.file?(local_file)
              check_timestamp(file, session, local_file, remote_file)  
            end
          else
            puts "#{file.name} doesn\'t exist locally, downloading"
            # File doesn't exist locally, so download it (in any folder required)
            session.scp.download!(remote_file, local_file)
          end
        end
      end

      puts "Finished downloads, now replacing your local seed data..."

      Rake::Task["comfy:cms_seeds:import"].invoke('protected-planet', 'protectedplanet')     

      # Todo: get this working with AWS bucket
    end
end