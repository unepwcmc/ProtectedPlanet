namespace :cms_update_2 do
  desc 'Reattach files to ActiveStorage'
  task :reattach_files => :environment do |t|
    files_directory = Rails.root.join("public/system/comfy/cms/files/files/000/000")
    Dir.children(files_directory).each do |f|
      Dir.children(files_directory.join("#{f}/original")).each do |file|
        comfy_file = Comfy::Cms::File.find(f.to_i)
        local_path = files_directory.join("#{f}/original/#{file}")
        puts "Attaching #{local_path} to File #{f}"
        comfy_file.attachment.attach io: File.open(local_path), filename: comfy_file.file_file_name
      rescue ActiveRecord::RecordNotFound
        warn "Did not find Comfy::Cms::File #{f}"
      end
    end
  end
end
