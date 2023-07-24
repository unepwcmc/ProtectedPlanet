namespace :country_changes do
  desc 'Remove parent_id on IOT'
  task remove_gbr_iot_link: :environment do
    puts 'Removing parent_id on IOT'
    Country.find_by(iso_3: 'IOT').update!(country_id: nil)
    puts 'parent_id removed on IOT'
  end
  
  desc 'rename countries'
  task rename_countries: :environment do
    puts 'renaming countries'
    Country.find_by(iso_3: 'CZE').update!(name: 'Czechia')
    Country.find_by(iso_3: 'COD').update!(name: 'Democratic Republic of the Congo')
    Country.find_by(iso_3: 'FSM').update!(name: 'Micronesia (Federated States of)')
    Country.find_by(iso_3: 'VAT').update!(name: 'Holy See')
    puts 'countries renamed'
  end
end
