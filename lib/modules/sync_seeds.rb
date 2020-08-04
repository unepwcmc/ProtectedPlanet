class SyncSeeds
  require 'net/ssh'
  require 'net/scp' 

  def delete_files(files, location)
    files.each do |file| 
      puts "Removing #{file} as it no longer exists remotely"
      FileUtils.rm_rf(File.join(location, file)) 
    end
  end

  def files_for_deletion(list_of_files_1, list_of_files_2, location)
    files = list_of_files_1 - list_of_files_2

    if files.empty?
      puts "No files to delete"
    else
      delete_files(files, location)
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

  def check_if_newer(parent_folder, local_item, remote_item, remote_path, local_path, session, base = LOCAL)
    if parent_folder.include?(local_item)
      yield if block_given?

      is_newer = Time.at(remote_item.attributes.mtime) >= File.stat(local_path).mtime  
      # If there are any outdated files, will trigger download
      if is_newer
        if Dir.glob('*', base: LOCAL).include?(local_item)
          download_files(remote_path, local_path, session) 
        # Will be hit if local_item is a file or folder inside a directory
        elsif Dir.glob('**/*', base: base).include?(local_item)
          download_files(remote_path, base, session)
          downloaded = true  
        end              
      end
    else
      # Just download it if it doesn't exist at all
      download_files(remote_path, LOCAL, session)
      downloaded = true
    end

    downloaded
  end

  def compare_folders(wildcard, local, remote, session, base = LOCAL)
    puts "Checking to see what files need to be deleted from #{base}" 

    remote_list = session.sftp.dir.glob(remote, wildcard).map do |f|  
      f.name.force_encoding('UTF-8')
    end

    local_list = Dir.glob(wildcard, base: local)

    files_for_deletion(local_list, remote_list, base)
  end

  def check_inside_folder(folder, local_list, session)
    paths = create_paths(folder)

    compare_folders('**/*', paths[:local_path], paths[:remote_path], session, paths[:local_path])

    local_folder_content = Dir.glob('**/*', base: paths[:local_path])
    remote_folder_content = session.sftp.dir.glob(paths[:remote_path], '**/*')
    
    # We don't want to download the whole folder again if it's already been re-downloaded once


    remote_folder_content.each do |file|
      # Go through the various files and folders and check to see if they exist locally
      local_file = file.name
      absolute_path = File.join(paths[:local_path], file.name)
      
      check = check_if_newer(local_folder_content, local_file, file, paths[:remote_path], absolute_path, session, paths[:local_path])
      
      # Break out of loop if already downloaded
      break if check == true
    end
  end

  def main_task(local_list, remote_list, session)
    remote_list.each do |object|
      # There are files with non-ASCII characters (i.e. accented) in the CMS files
      name = object.name.force_encoding('UTF-8')
      paths = create_paths(name)
      
      
      check_if_newer(local_list, name, object, paths[:remote_path], paths[:local_path], session) do 
        check_inside_folder(name, local_list, session) if object.attributes.directory?
      end
    end
  end

  def start_session(server, username)
    Net::SSH.start(server, username) { yield }
  end
end