# frozen_string_literal: true

module Wdpa::Shared::Importer::GlobalStats
  def self.latest_global_statistics_csv
    ::Utilities::Files.latest_file_by_glob('lib/data/seeds/global_statistics_*.csv')
  end

  def self.import_live
    attrs = { singleton_guard: 0 }
    CSV.foreach(latest_global_statistics_csv, headers: true) do |row|
      field = row['type']
      value = parse_value(row['value'])

      # The global_statistics csv can now be downloaded so a methodology url has been added
      # to the end of the spreadsheet. We need to not add this line to the attributes.
      attrs.merge!("#{field}": value) if field.present?
    end

    stats = GlobalStatistic.first_or_initialize(attrs)
    stats.update(attrs)

    Rails.logger.info "Global statistics import completed: #{attrs.keys.length} fields updated"
    { success: true, fields_updated: attrs.keys.length, errors: [] }
  end

  def self.import_staging
    attrs = { singleton_guard: 0 }
    CSV.foreach(latest_global_statistics_csv, headers: true) do |row|
      field = row['type']
      value = parse_value(row['value'])

      # The global_statistics csv can now be downloaded so a methodology url has been added
      # to the end of the spreadsheet. We need to not add this line to the attributes.
      attrs.merge!("#{field}": value) if field.present?
    end

    stats = Staging::GlobalStatistic.first_or_initialize(attrs)
    stats.update(attrs)

    Rails.logger.info "Global statistics import completed: #{attrs.keys.length} fields updated"
    { success: true, fields_updated: attrs.keys.length, errors: [] }
  end

  # If it's a string, ensure to remove commas before casting to float.
  # If it's a float this will basically return the value as it is in the csv.
  # Even though strings in the csv are mostly integers, converting it to float here
  # shouldn't cause issues with the database where the field is explicitly an integer.
  # Postgres should take care of it.
  def self.parse_value(val)
    val.to_s.split(',').join('').to_f
  end
end
