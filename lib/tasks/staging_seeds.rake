# frozen_string_literal: true

namespace :comfy do
    desc "Import CMS Seed data from staging"

    # Locally stored seeds - assumes you already have the local folder - 
    # it won't create it 
    LOCAL = (ComfortableMexicanSofa.config.seeds_path + '/protected-planet').freeze
    REMOTE = 'ProtectedPlanet/current/db/cms_seeds/protected-planet'.freeze

    task :seed_import => :environment do |_t|
      require 'net/ssh'
      require 'net/scp'  
      
      puts "Importing CMS Seed data from Staging Folder to #{LOCAL} ..."

      # SSH into staging server with Net::SSH
      Net::SSH.start(ENV['PP_STAGING'], ENV['PP_USER']) do |session|
        # Map the top-level folders and check top-level files
        top_level_folders = session.sftp.dir.glob(REMOTE,'*').filter do |item| 
                              item.attributes.directory?
                            end
        
        session.sftp.dir.glob(REMOTE, '*').each do |file|
          remote_folder = File.join(REMOTE, file.name)
          local_folder = File.join(LOCAL, file.name)
          
          # only files 
          unless top_level_folders.find { |f| file.name == f.name }
            if File.exist?(local_folder) 
                is_newer = Time.at(file.attributes.mtime) >= File.stat(local_folder).mtime 
                puts "Downloading a newer version of #{file.name}"
                session.scp.download!(remote_folder, local_folder) if is_newer
            else
              puts "#{file.name} doesn't exist locally, downloading..."
              session.scp.download!(remote_folder, local_folder)
            end
          end
        end

        top_level_folders.each do |folder|
          parent_remote = File.join(REMOTE, folder.name)
          parent_local = File.join(LOCAL, folder.name)

          unless Dir.glob('**/*', base: LOCAL).include?(folder.name.force_encoding('UTF-8'))
            puts "#{folder.name} doesn\'t exist locally, downloading"
            # Folder doesn't exist locally, so download it 
            session.scp.download!(parent_remote, LOCAL, recursive: true)
          end

          files = []

          session.sftp.dir.glob(parent_remote, '**/*').each do |file|
            # Go through the various files and folders and check to see if they exist locally
            local_folder = File.join(LOCAL, file.name)
            
            # There are files with non-ASCII characters (i.e. accented) in the CMS files
            if Dir.glob('**/*', base: local_folder).include?(file.name.force_encoding('UTF-8'))
                is_newer = Time.at(file.attributes.mtime) >= File.stat(local_folder).mtime  
                files << file if is_newer                 
            else
              files << file
            end
          end

          if files.length >= 1
            puts "Downloading a newer version of #{folder.name}"
            session.scp.download!(parent_remote, LOCAL, recursive: true)
          end
        end

      puts "Finished downloads, now replacing your local seed data..."

      Rake::Task["comfy:cms_seeds:import"].invoke('protected-planet', 'protectedplanet')     

      # Todo: get this working with AWS bucket
    end
  end
end