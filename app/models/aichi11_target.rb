class Aichi11Target < ActiveRecord::Base
  validates_inclusion_of :singleton_guard, in: [0]

  ATTRIBUTES = {
    representative: 'Representative',
    well_connected: 'Well connected',
    importance: 'Areas of importance for biodiversity'
  }.freeze

  def self.instance
    first || import
  end

  # Refresh values from API (As of 05Sep2025 the data comes from CSV not API)
  # Refresh representative, well_connected and importance values by fetching data again from the API
  def self.refresh_values
    obj = first
    unless obj
      import
      return
    end
    obj.update_attributes(Stats::CountryStatisticsApi.global_stats_for_import)
  end

  def self.import
    # Import representative, well_connected and importance values from API
    # global_values = Stats::CountryStatisticsApi.global_stats_for_import
    # global_values = {} if global_values.is_a?(Array)
    # Import targets from file
    CSV.foreach(aichi11_target_csv_path, headers: true) do |row|
      return create({}.merge(row)) # .merge(global_values))
    end
  end

  def self.update_live_table
    ActiveRecord::Base.transaction do
      record = first || new
      was_created = !record.persisted?

      # Ensure we only process the first row since this is a singleton model
      first_row = nil
      CSV.foreach(aichi11_target_csv_path, headers: true) do |row|
        first_row = row
        break
      end

      raise StandardError, 'No data found in CSV file' unless first_row

      if record.persisted?
        record.update_attributes!(first_row.to_h)
        Rails.logger.info 'Aichi11Target: Updated existing record with fresh CSV data'
      else
        record.assign_attributes(first_row.to_h)
        record.save!
        Rails.logger.info 'Aichi11Target: Created new record from CSV data'
      end

      {
        success: true,
        action: was_created ? 'created' : 'updated',
        message: "Aichi11Target #{was_created ? 'created' : 'updated'} successfully"
      }
    end
  rescue StandardError => e
    error_type = case e
                 when CSV::MalformedCSVError
                   'Invalid CSV format'
                 when ActiveRecord::RecordInvalid
                   'Validation error'
                 else
                   'Unexpected error'
                 end

    Rails.logger.error "Aichi11Target: #{error_type.downcase} - #{e.message}"
    {
      success: false,
      action: 'failed',
      message: "Aichi11Target import failed: #{error_type} - #{e.message}",
      error: e.message
    }
  end

  def self.aichi11_target_csv_path
    Rails.root.join('lib/data/seeds/aichi11_targets.csv')
  end

  private_class_method :import, :aichi11_target_csv_path
end
