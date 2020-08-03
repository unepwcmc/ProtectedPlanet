# frozen_string_literal: true

namespace :comfy do
  
  # Locally stored seeds - assumes you already have the local folder - 
  # it won't create it 
  LOCAL = (ComfortableMexicanSofa.config.seeds_path + '/protected-planet').freeze
  REMOTE = 'ProtectedPlanet/current/db/cms_seeds/protected-planet'.freeze
  PP_STAGING = 'new-web.pp-staging.linode.protectedplanet.net'.freeze
  PP_USER = 'wcmc'.freeze

  desc "Import CMS Seed data from staging"
  
    def delete_files(files, location)
      files.each do |file| 
        puts "Removing #{file} as it no longer exists remotely"
        FileUtils.rm_rf(File.join(location, file)) 
      end
    end

    def files_for_deletion(list_of_files_1, list_of_files_2, location = LOCAL)
      files = list_of_files_1 - list_of_files_2

      begin
        delete_files(files, location)
      rescue TypeError
        puts 'Nothing to delete locally, moving on to the next set of files'
      end
    end

    def download_files(source, dest, session)
      puts "Downloading #{source} as it's newer or not found locally"
      return session.scp.download!(source, dest) if File.file?(dest)
      session.scp.download!(source, dest, recursive: true)
    end
    
    def create_paths(relative_path)
      { local_path: File.join(LOCAL, relative_path), remote_path: File.join(REMOTE, relative_path) }
    end

    def check_if_newer(parent_folder, local_item, remote_item, remote_path, local_path, session, downloaded = false)
      if parent_folder.include?(local_item)
        yield if block_given?

        is_newer = Time.at(remote_item.attributes.mtime) >= File.stat(local_path).mtime  
        # If there are any outdated files, will trigger download
        if is_newer
          if Dir.glob('*', base: LOCAL).include?(local_item)
            download_files(remote_path, local_path, session) 
          elsif Dir.glob('**/*', base: LOCAL).include?(local_item)
            download_files(remote_path, LOCAL, session)
            downloaded = true  
          end                
        end
      else
        download_files(remote_path, LOCAL, session)
        downloaded = true
      end
    end

    def check_inside_folder(folder, local_list, session)
      paths = create_paths(folder)
      local_folder_content = Dir.glob('**/*', base: paths[:local_path])

      remote_folder_content = session.sftp.dir.glob(paths[:remote_path], '**/*')

      remote_content_names = remote_folder_content.map {|f| f.name.force_encoding('UTF-8') }

      files_for_deletion(local_folder_content, remote_content_names, paths[:local_path])

      remote_folder_content.each do |file|
        # Go through the various files and folders and check to see if they exist locally
        local_file = file.name
        absolute_path = File.join(paths[:local_path], file.name)

        # We don't want to download the whole folder again if it's already been re-downloaded once
        downloaded_once = false
        
        check_if_newer(local_folder_content, local_file, file, paths[:remote_path], absolute_path, session, downloaded_once)

        # Break out of loop if already downloaded
        break if downloaded_once == true
      end
    end

    task :staging_import => :environment do |_t|
      require 'net/ssh'
      require 'net/scp'  
      
      puts "Importing CMS Seed data from Staging Folder to #{LOCAL} ..."

      # SSH into staging server with Net::SSH
      Net::SSH.start(PP_STAGING, PP_USER) do |session|
        remote_list = session.sftp.dir.glob(REMOTE, '*')
        local_list = Dir.glob('*', base: LOCAL)

        remote_list_names = remote_list.map { |f| f.name }

        # First get rid of any local top-level (i.e. which exist in the main 
        # directory of REMOTE) folders/files that don't exist remotely
        files_for_deletion(local_list, remote_list_names)

        remote_list.each do |object|
          # There are files with non-ASCII characters (i.e. accented) in the CMS files
          name = object.name.force_encoding('UTF-8')
          paths = create_paths(name)
          
          check_if_newer(local_list, name, object, paths[:remote_path], paths[:local_path], session) do 
            check_inside_folder(name, local_list, session) if object.attributes.directory?
          end
        end

      # puts "Finished downloads, now replacing your local seed data..."

      # Rake::Task["comfy:cms_seeds:import"].invoke('protected-planet', 'protectedplanet')     

      # Todo: get this working with AWS bucket
    end
  end

  desc ""
end