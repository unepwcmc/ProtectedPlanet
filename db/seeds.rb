# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#

csv_models = [
  Country, SubLocation, Jurisdiction, Governance, IucnCategory
]

csv_models.each do |model|
  puts "### Importing seeds for #{model}"

  pretty_name = model.to_s.pluralize
  filename    = "#{pretty_name.underscore}.csv"

  source = File.join(Rails.root, 'lib', 'data', 'seeds', filename)

  import_count = 0
  failed_seeds = []

  CSV.foreach(source, headers: true) do |row|
    attributes = row.to_hash
    instance = model.where(attributes).first || model.new(attributes)

    if instance.new_record?
      if instance.save
        import_count += 1
      else
        failed_seeds << attributes
      end
    end
  end

  puts "### Imported #{import_count} #{pretty_name}"

  if failed_seeds.count > 0
    puts "### The following #{failed_seeds.count} failed to import:"
    puts failed_seeds
  end
end
