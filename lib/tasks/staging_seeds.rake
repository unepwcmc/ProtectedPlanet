# frozen_string_literal: true

namespace :comfy do
    desc "Import CMS Seed data from staging"

    # Locally stored seeds - assumes you already have the local folder - 
    # it won't create it 
    LOCAL = (ComfortableMexicanSofa.config.seeds_path + '/protected-planet').freeze
    REMOTE = 'ProtectedPlanet/current/db/cms_seeds/protected-planet'.freeze
    PP_STAGING = 'new-web.pp-staging.linode.protectedplanet.net'.freeze
    PP_USER = 'wcmc'.freeze

    def delete_files(files, location)
      files.each do |file| 
        puts "Removing #{file} as it no longer exists remotely"
        FileUtils.rm_rf(File.join(location, file)) 
      end
    end

    def delete_files(list_of_files_1, list_of_files_2, location = LOCAL)
      files = list_of_files_1 - list_of_files_2.map { |f| f.name }
      
      delete_files(files, location)
    end

    task :staging_import => :environment do |_t|
      require 'net/ssh'
      require 'net/scp'  
      
      puts "Importing CMS Seed data from Staging Folder to #{LOCAL} ..."

      # SSH into staging server with Net::SSH
      Net::SSH.start(PP_STAGING, PP_USER) do |session|
        remote_list = session.sftp.dir.glob(REMOTE, '*')
        local_list = Dir.glob('*', base: LOCAL)

        # First get rid of any local top-level (i.e. which exist in the main 
        # directory of REMOTE) folders/files that don't exist remotely
        delete_files(local_list, remote_list)

        # Map the top-level folders and check top-level files
        top_level_folders = remote_list.filter { |item| item.attributes.directory? }
        top_level_files = remote_list.filter { |item| item.attributes.file? }
                           
        # download only files 
        top_level_files.each do |file|
          remote_file = File.join(REMOTE, file.name)
          local_file = File.join(LOCAL, file.name)

          if File.exist?(local_file) 
            is_newer = Time.at(file.attributes.mtime) >= File.stat(local_file).mtime 
            puts "Downloading a newer version of #{file.name}"
            session.scp.download!(remote_file, local_file) if is_newer
          else
            puts "#{file.name} doesn't exist locally, downloading..."
            session.scp.download!(remote_file, local_file)
          end 
        end

        # Start recursively delving into the folders
        top_level_folders.each do |folder|
          parent_remote = File.join(REMOTE, folder.name)
          parent_local = File.join(LOCAL, folder.name)
          local_folder_content = Dir.glob('**/*', base: parent_local)
          remote_folder_content = session.sftp.dir.glob(parent_remote, '**/*')

          delete_files(local_folder_content, remote_folder_content, parent_local)

          unless local_list.include?(folder.name)
            puts "#{folder.name} doesn\'t exist locally, downloading"
            session.scp.download!(parent_remote, LOCAL, recursive: true)
          end

          files = []

          remote_folder.each do |file|
            # Go through the various files and folders and check to see if they exist locally
            local_folder = File.join(folder.name, file.name)
            
            # There are files with non-ASCII characters (i.e. accented) in the CMS files
            if Dir.glob('**/*', base: LOCAL).include?(local_folder.force_encoding('UTF-8'))
              is_newer = Time.at(file.attributes.mtime) >= File.stat(File.join(LOCAL, local_folder)).mtime  
              files << file if is_newer                 
            else
              files << file
            end
          end

          # If there are any outdated files, will trigger download
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