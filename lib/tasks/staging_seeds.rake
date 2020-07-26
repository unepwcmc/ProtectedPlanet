# frozen_string_literal: true

namespace :comfy do
    desc "Import CMS Seed data from staging"

    task :seed_import => :environment do |_t|
      require 'net/ssh'
      require 'net/scp'
      
      def check_timestamp(file, session, local, local_file, remote_file)     
        newer = Time.at(file.attributes.mtime) >= File.stat(local_file).mtime 
        if newer 
          puts "#{file.name} is newer than the local copy, downloading..."
          session.scp.download!(remote_file, local_file)
        end
      end
      
      # Locally stored seeds - assumes you already have the local folder - 
      # it won't create it 
      local = ComfortableMexicanSofa.config.seeds_path + '/protected-planet'
      remote = 'ProtectedPlanet/current/db/cms_seeds/protected-planet'
      
      puts "Importing CMS Seed data from Staging Folder to #{local} ..."

      # SSH into staging server with Net::SSH
      Net::SSH.start(ENV['PP_STAGING'], ENV['PP_USER']) do |session|
        session.sftp.dir.glob(remote, '**/*').each do |file|
          # Go through the various files and folders and check to see if they exist locally
          remote_file = File.join(remote, file.name)
          local_file = File.join(local, file.name)
          
          # There are files with non-ASCII characters (i.e. accented) in the CMS files
          if Dir.glob('**/*', base: local).include?(file.name.force_encoding('UTF-8'))
            if File.file?(local_file)
              check_timestamp(file, session, local, local_file, remote_file)  
            end
          else
            puts "#{file.name} doesn\'t exist locally, downloading"
            # File doesn't exist locally, so download it (in any folder required)
            session.scp.download!(remote_file, local_file)
          end
        end
      end

      puts "Finished downloads, now replacing your local seed data..."

      Rake::Task["'comfy:cms_seeds:import[protected-planet, protectedplanet]'"].invoke

      
    end
end