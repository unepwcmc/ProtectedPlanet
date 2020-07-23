# frozen_string_literal: true

namespace :comfy do
    desc "Import CMS Seed data from staging"

    task :seed_import => :environment do |_t|
      require 'net/ssh'
      require 'net/scp'

      puts "Importing CMS Seed data from Staging Folder to #{local} ..."
      
      # Locally stored seeds
      local = ComfortableMexicanSofa.config.seeds_path
      
      # SSH into staging server with Net::SSH
      # Check to see if local CMS seeds are newer than local and download any
      Net::SSH.start(ENV['PP_STAGING'], ENV['PP_USER']) do |ssh|
        ssh.sftp.dir.foreach('ProtectedPlanet/current/db/cms_seeds/protected-planet') do |f|
          # Go through the various files and folders and check to see if they exist locally
          if Dir.children(local).include?(f)
            if File.stat(f).file?
              local_file_changed = File.stat(f).mtime > Time.at(sftp.stat(f).mtime)
            elsif File.stat(f).directory
              ssh.sftp.dir.foreach(f) do |file|
                local_file_changed = File.stat(file).mtime > Time.at(sftp.stat(file).mtime)
              end
            end
          else
            
          end
        end
        # ssh.scp.download!('ProtectedPlanet/current/db/cms_seeds', local, recursive: true)
      end

      puts "Replacing your local seed data..."

      Rake::Task["comfy:cms_seeds:import[protected-planet, protectedplanet]"].invoke
    end
end