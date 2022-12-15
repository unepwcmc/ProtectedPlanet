desc 'Rename Turkey to Türkiye'
task rename_turkey_turkiye: :environment do
  Country.find_by(name: 'Turkey').update(name: 'Türkiye')
end
