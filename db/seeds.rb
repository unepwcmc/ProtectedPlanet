# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#

puts "### Importing countries"

countries_source = File.join(Rails.root, 'lib', 'data', 'iso_countries.csv')

country_count = 0
failed_countries = []

CSV.foreach(countries_source, headers: true) do |row|
  attributes = {
    name: row["short_name_en"],
    iso: row["alpha_2_code"],
    iso_3: row["alpha_3_code"]
  }

  country = Country.where(attributes).first || Country.new(attributes)
  if country.new_record?
    if country.save
      country_count += 1
    else
      failed_countries << attributes[:name]
    end
  end
end

puts "### Imported #{country_count} countries"

if failed_countries.count > 0
  puts "### The following #{failed_countries.count} sub locations failed to import:"
  puts failed_countries
end

puts "### Importing sub locations"

sub_locations_source = File.join(Rails.root, 'lib', 'data', 'iso_sub_locations.csv')

sub_location_count = 0
failed_sub_locations = []

CSV.foreach(sub_locations_source, headers: true) do |row|
  attributes = {
    english_name: row["english_name"],
    iso: row["iso_code"],
    alternate_name: row["alternate_name"]
  }

  sub_location = SubLocation.where(attributes).first || SubLocation.new(attributes)
  if sub_location.new_record?
    if sub_location.save
      sub_location_count += 1
    else
      failed_sub_locations << attributes[:name]
    end
  end
end

puts "### Imported #{sub_location_count} sub locations"

if failed_sub_locations.count > 0
  puts "### The following #{failed_sub_locations.count} sub locations failed to import:"
  puts failed_sub_locations
end

puts "### Importing Jurisdictions"

jurisdiction_count = 0
["National", "International", "ABNJ", "Not Reported"].each do |name|
  jurisdiction = Jurisdiction.where(name: name).first || Jurisdiction.new(name: name)
  if jurisdiction.new_record?
    jurisdiction.save
    jurisdiction_count += 1
  end
end

puts "### Imported #{jurisdiction_count} jurisdictions"

puts "### Importing Governances"

governance_names = [
  "For-profit organisations",
  "Private governance",
  "Private Governance",
  "Federal or national ministry or agency",
  "Federal or national ministry or agency in charge",
  "Federal or national",
  "Not Reported",
  "Sub-national ministry or agency",
  "Non-profit organisations",
  "Government-delegated management",
  "For profit organisations",
  "Shared governance",
  "Indigenous peoples",
  "Local communities",
  "Non-profit organisations",
  "Individual landowners",
  "Joint management",
  "Collaborative management",
  "Governance by government",
  "Governance by indigenous peoples and/or local communities",
  "Sub-national ministry or agency",
  "Government Agency",
  "Collaborative management (various forms of pluralist influence)",
  "Transboundary management",
  "For-profit organisations"
]

governance_count = 0
governance_names.each do |governance_name|
  governance = Governance.where(name: governance_name).first || Governance.new(name: governance_name)
  if governance.new_record?
    governance.save
    governance_count += 1
  end
end

puts "### Imported #{governance_count} governances"

puts "### Importing IUCN Categories"

iucn_categories = [
  "Ia",
  "Ib",
  "II",
  "III",
  "IV",
  "V",
  "VI",
  "Not Reported",
  "Not Applicable"
]

iucn_category_count = 0
iucn_categories.each do |category_name|
  iucn_category = IucnCategory.where(name: category_name).first || IucnCategory.new(name: category_name)
  if iucn_category.new_record?
    iucn_category.save
    iucn_category_count += 1
  end
end

puts "### Imported #{iucn_category_count} IUCN Categories"
