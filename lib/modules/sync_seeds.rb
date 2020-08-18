class SyncSeeds
  require 'net/ssh'
  require 'net/scp' 

  def initialize(server, username)
    @username = username
    @server = server
  end

  def start_session
    Net::SSH.start(@server, @username) do |session| 
      @session = session
      yield
    end
  end

  def list_local_files(location)
    Dir.glob('*', base: location)
  end

  def list_remote_files(location)
    @session.sftp.dir.glob(location, '*')
  end

  def delete_files(files, location)
    files.each do |file| 
      puts "Removing #{file} as it no longer exists remotely"
      FileUtils.rm_rf(File.join(location, file))
    end
  end

  def files_for_deletion(local_list, remote_list, location)
    files = local_list - remote_list

    if files.empty?
      puts "No files to delete"
    else
      delete_files(files, location)
    end
  end

  def download_files(source, dest)
    puts "Downloading #{source} as it's newer or not found locally"
    return @session.scp.download!(source, dest) if File.file?(dest)
    @session.scp.download!(source, dest, recursive: true)
  end
  
  def create_paths(relative_path)
    { local_path: File.join(@local_base, relative_path), remote_path: File.join(@remote_base, relative_path) }
  end

  def check_if_newer(parent_folder:, local_item:, remote_item:, remote_path:, local_path:, base: @local_base)
    downloaded = false

    if parent_folder.include?(local_item)
      yield if block_given?
      
      is_newer = Time.at(remote_item.attributes.mtime) >= File.stat(local_path).mtime  
      # If there are any outdated files, will trigger download
      if is_newer
        if Dir.glob('*', base: @local_base).include?(local_item)
          download_files(remote_path, local_path) 
          # Will be hit if local_item is a file or folder inside a directory
        elsif Dir.glob('**/*', base: base).include?(local_item)
          download_files(remote_path, local_path)
          downloaded = true  
        end              
      end
    else
      # Just download it if it doesn't exist at all
      download_files(remote_path, @local_base)
      downloaded = true
    end

    downloaded
  end

  def compare_folders(wildcard:, local:, remote:, base:)
    puts "Checking to see what files need to be deleted from #{local}" 

    remote_list = @session.sftp.dir.glob(remote, wildcard).map do |f|  
      f.name.force_encoding('UTF-8')
    end

    local_list = Dir.glob(wildcard, base: local)
    
    files_for_deletion(local_list, remote_list, base)
  end

  # When folders need to be checked recursively
  def check_inside_folder(folder, local_list)
    paths = create_paths(folder)

    compare_folders(wildcard: '**/*', local: paths[:local_path], remote: paths[:remote_path], base: paths[:local_path])

    local_folder_content = Dir.glob('**/*', base: paths[:local_path])
    remote_folder_content = @session.sftp.dir.glob(paths[:remote_path], '**/*')
    
    remote_folder_content.each do |file|
      # Go through the various files and folders and check to see if they exist locally
      local_file = file.name.force_encoding('UTF-8')
      
      check = check_if_newer(
        parent_folder: local_folder_content, 
        local_item: local_file, 
        remote_item: file, 
        remote_path: paths[:remote_path], 
        local_path: paths[:local_path], 
        base: paths[:local_path]
      )
      
      # We don't want to download the whole folder again if it's already been re-downloaded once
      # Break out of loop if already downloaded
      break if check == true
    end
  end

  def main_task(local_list:, remote_list:, local_base:, remote_base:)
    @local_base = local_base
    @remote_base = remote_base

    remote_list.each do |object|
      # There are files with non-ASCII characters (i.e. accented) in the CMS files
      name = object.name.force_encoding('UTF-8')
      paths = create_paths(name)
         
      check_if_newer(
        parent_folder: local_list, 
        local_item: name, 
        remote_item: object, 
        remote_path: paths[:remote_path], 
        local_path: paths[:local_path]
      ) do 
        check_inside_folder(name, local_list) if object.attributes.directory?
      end
    end
  end

  # Piggybacks on existing Comfy modules 
  def commence_comfy_import(answer)
    logger = ComfortableMexicanSofa.logger
    ComfortableMexicanSofa.logger = Logger.new(STDOUT)

    if answer == 'all'
      Rake::Task["comfy:cms_seeds:import"].invoke('protected-planet', 'protectedplanet')     
    else
      module_name = "ComfortableMexicanSofa::Seeds::#{answer.singularize}::Importer".constantize
      module_name.new('protected-planet', 'protectedplanet').import!
    end
    
    ComfortableMexicanSofa.logger = logger
  end
  
end