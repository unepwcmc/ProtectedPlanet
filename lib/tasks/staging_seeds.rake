# frozen_string_literal: true

namespace :comfy do
  
  # Locally stored seeds - assumes you already have the local folder - 
  # it won't create it 
  LOCAL = (ComfortableMexicanSofa.config.seeds_path + '/protected-planet').freeze
  REMOTE = 'ProtectedPlanet/current/db/cms_seeds/protected-planet'.freeze
  PP_STAGING = 'new-web.pp-staging.linode.protectedplanet.net'.freeze
  PP_PRODUCTION = 'new-web.pp-production.linode.protectedplanet.net'.freeze
  PP_USER = 'wcmc'.freeze

  desc "Import CMS Seed data from staging"
  task :staging_import => :environment do |_t| 
    
    puts "Importing CMS Seed data from Staging Folder to #{LOCAL} ..."

    puts question = "What would you like to import? 'All/Files/Layouts/Pages' or 'Nothing' to quit"
    valid_answers = ['All', 'Files', 'Layouts', 'Pages', 'Nothing']
    answer = STDIN.gets.chomp.downcase.capitalize
    until valid_answers.include?(answer)
      puts question
      answer = STDIN.gets.chomp.downcase.capitalize
    end

    # Fast-tracked unhappy path
    abort('Goodbye') if answer == 'Nothing'

    SyncSeeds.start_session(PP_STAGING, PP_USER)

    # SSH into staging server with Net::SSH
    Net::SSH.start(PP_STAGING, PP_USER) do |session|
      # First get rid of any local top-level (i.e. which exist in the main 
      # directory of REMOTE) folders/files that don't exist remotely
      SyncSeeds.compare_folders('*', LOCAL, REMOTE, session)

      local_list = Dir.glob('*', base: LOCAL)
      remote_list = session.sftp.dir.glob(REMOTE, '*')

      if answer == 'All'
        SyncSeeds.main_task(local_list, remote_list, session) 
      else
        local_list.filter! { |f| f == answer.downcase } 
        remote_list.filter! do |f|
          f.name.force_encoding('UTF-8') == answer.downcase
        end

        puts "Downloading a new set of #{answer.downcase}..."

        SyncSeeds.main_task(local_list, remote_list, session)
      end
  
    
    # puts "Finished downloads, now replacing your local seed data..."

    # Rake::Task["comfy:cms_seeds:import"].invoke('protected-planet', 'protectedplanet')     

    # Todo: get this working with AWS bucket
  end
  end

end