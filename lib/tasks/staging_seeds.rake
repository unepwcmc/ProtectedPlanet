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

    def files_for_deletion(list_of_files_1, list_of_files_2, location = LOCAL)
      files = list_of_files_1 - list_of_files_2

      begin
        delete_files(files, location)
      rescue TypeError
        puts 'Nothing to delete locally, moving on to the next set of files'
      end
    end

    def download_file(source, dest, session)
      puts "Downloading #{source} as it's newer or not found locally"
      return session.scp.download!(source, dest) if File.file?(dest)
      session.scp.download!(source, dest, recursive: true)
    end
    
    def create_paths(relative_path)
      { local_path: File.join(LOCAL, relative_path), remote_path: File.join(REMOTE, relative_path) }
    end

    def folder_delving(folder, local_list, session)
      paths = create_paths(folder)
      local_folder_content = Dir.glob('**/*', base: paths[:local_path])

      remote_folder_content = session.sftp.dir.glob(paths[:remote_path], '**/*')

      remote_content_names = remote_folder_content.map {|f| f.name.force_encoding('UTF-8') }

      files_for_deletion(local_folder_content, remote_content_names, paths[:local_path])

      files = []

      remote_folder_content.each do |file|
        # Go through the various files and folders and check to see if they exist locally
        local_folder = File.join(folder, file.name)
        
        # There are files with non-ASCII characters (i.e. accented) in the CMS files
        if Dir.glob('**/*', base: LOCAL).include?(local_folder)
          is_newer = Time.at(file.attributes.mtime) >= File.stat(File.join(LOCAL, local_folder)).mtime  
          # If there are any outdated files, will trigger download
          download_file(paths[:remote_path], LOCAL, session) if is_newer                 
        else
          download_file(paths[:local_path], LOCAL, session)
        end
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
          name = object.name.force_encoding('UTF-8')
          paths = create_paths(name)

          if local_list.include?(name)
            # If folder, look inside it to any files that don't exist any more remotely and delete them
            if object.attributes.directory?
              folder_delving(name, local_list, session)
            end

            is_newer = Time.at(object.attributes.mtime) >= File.stat(paths[:local_path]).mtime 
            download_file(paths[:remote_path], paths[:local_path], session) if is_newer
          else
            # file doesn't exist locally so download it
            download_file(paths[:remote_path], LOCAL, session)
          end
        end

      puts "Finished downloads, now replacing your local seed data..."

      Rake::Task["comfy:cms_seeds:import"].invoke('protected-planet', 'protectedplanet')     

      # Todo: get this working with AWS bucket
    end
  end
end