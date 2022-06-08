desc 'Rename Chinese overseas territories and assign Taiwan to China'
task rename_and_assign_chinese_territories: :environment do
  Country.find_by(name: 'Hong Kong').update(name: 'Hong Kong, SAR China')
  Country.find_by(name: 'Macau').update(name: 'Macau, SAR China')
  
  china = Country.find_by(name: 'China')
  taiwan = Country.find_by(name: 'Taiwan, Province of China')
  taiwan.update(parent: china)
end
