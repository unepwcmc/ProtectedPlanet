# frozen_string_literal: true

namespace :comfy do
  # The methods that this rake task calls are in lib/modules/sync_seeds.rb
  FROM  = 'ProtectedPlanet/current/db/cms_seeds/protected-planet'.freeze
  PP_STAGING = 'new-web.pp-staging.linode.protectedplanet.net'.freeze
  PP_USER = 'wcmc'.freeze

  def user_input
    valid_answers = %w(all files layouts pages nothing)
    puts question = "What would you like to import? 'all/files/layouts/pages' or 'nothing' to quit"
    answer = STDIN.gets.chomp.downcase

    until valid_answers.include?(answer)
      puts question  
      answer = STDIN.gets.chomp.downcase  
    end
    
    abort('Goodbye') if answer == 'nothing'

    { answer: answer, destination: File.join(ComfortableMexicanSofa.config.seeds_path, 'protected-planet') }
  end

  desc "Import CMS Seed data from staging. Can be run with arguments [<destination>, files/pages/layouts/all] or can accept user input if no argument is supplied"
  task :staging_import, %i[to folder] => [:environment] do |_t, args| 
    to = nil
    answer = nil

    if args.length.nil?
      answers = user_input
      to = answers[:destination]
      answer = answers[:answer]
    else
      to = File.join(ComfortableMexicanSofa.config.seeds_path, args[:to])
      answer = args[:folder].downcase
    end
      
    puts "Importing CMS Seed data from Staging Folder to #{to} ..."

    new_session =  SyncSeeds.new(PP_STAGING, PP_USER)

    # SSH into staging server with Net::SSH
    new_session.start_session do |session|
      # First get rid of any local top-level (i.e. which exist in the main 
      # directory of REMOTE) folders/files that don't exist remotely
      new_session.compare_folders('*', to, FROM)

      local_list = new_session.list_local_files(to)
      remote_list = new_session.list_remote_files(FROM)

      if answer == 'all'
        new_session.main_task(local_list, remote_list, to, FROM)
      else
        local_list.filter! { |f| f == answer } 
        remote_list.filter! do |f|
          f.name.force_encoding('UTF-8') == answer
        end

        puts "Downloading a new set of #{answer}..."

        new_session.main_task(local_list, remote_list, to, FROM)
      end

      puts "Finished downloads, now replacing your local seed data with your selection..."

      # new_session.commence_comfy_import(answer) 
    end
  end

end