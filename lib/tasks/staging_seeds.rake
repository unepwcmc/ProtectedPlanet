# frozen_string_literal: true

namespace :comfy do
  # The methods that this rake task calls are in lib/modules/sync_seeds.rb
  FROM  = 'ProtectedPlanet/current/db/cms_seeds/protected-planet'.freeze
  PP_STAGING = 'new-web.pp-staging.linode.protectedplanet.net'.freeze
  PP_USER = 'wcmc'.freeze

  desc "Import CMS Seed data from staging. Can be run with arguments (<destination>, files/pages/layouts/all) or can accept user input if no argument is supplied"
  task :staging_import, %i[to folder] => [:environment] do |_t, args| 

    if args.length.nil?
      puts question = "What would you like to import? 'All/Files/Layouts/Pages' or 'Nothing' to quit"
      valid_answers = ['All', 'Files', 'Layouts', 'Pages', 'Nothing']
      answer = STDIN.gets.chomp.downcase.capitalize
      until valid_answers.include?(answer)
        puts question  
      end
      
      # Fast-tracked unhappy path
      abort('Goodbye') if answer == 'Nothing'
    else
      to    = File.join(ComfortableMexicanSofa.config.seeds_path, args[:to])
      answer = args[:folder].downcase.capitalize!
    end
    
    puts "Importing CMS Seed data from Staging Folder to #{to} ..."

    new_session =  SyncSeeds.new(PP_STAGING, PP_USER)

    # SSH into staging server with Net::SSH
    new_session.start_session do |session|
      # First get rid of any local top-level (i.e. which exist in the main 
      # directory of REMOTE) folders/files that don't exist remotely
      new_session.compare_folders('*', to, FROM, to)

      local_list = new_session.list_local_files(to)
      remote_list = new_session.list_remote_files(FROM)

      if answer == 'All'
        new_session.main_task(local_list, remote_list)
      else
        local_list.filter! { |f| f == answer.downcase } 
        remote_list.filter! do |f|
          f.name.force_encoding('UTF-8') == answer.downcase
        end

        puts "Downloading a new set of #{answer.downcase}..."

        new_session.main_task(local_list, remote_list)
      end

      puts "Finished downloads, now replacing your local seed data with your selection..."

      new_session.commence_import(answer) 
    end
  end

end