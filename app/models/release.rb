# frozen_string_literal: true

class Release < ApplicationRecord
  # Prevent ActiveRecord from trying to introspect the table if it doesn't exist
  # This handles the case where migrations haven't been run yet
  def self.table_exists?
    @_table_exists ||= begin
      connection.table_exists?(table_name)
    rescue ActiveRecord::StatementInvalid, PG::UndefinedTable
      false
    end
  end

  # Override columns to return empty array if table doesn't exist
  # def self.columns
  #   return [] unless table_exists?
  #   super
  # rescue ActiveRecord::StatementInvalid, PG::UndefinedTable
  #   []
  # end

  has_many :release_events, dependent: :delete_all

  STATES = %w[started preflight_ok importing validating swapped rolled_back aborted failed succeeded].freeze
  BACKUP_TIMESTAMP_FORMAT = '%y%m%d%H%M'

  validates :label, presence: true
  validates :state, inclusion: { in: STATES }
  validates :is_current, uniqueness: true, if: :is_current?

  # Returns the current active release
  # Safe to call even if table doesn't exist yet
  def self.current_release
    return nil unless table_exists?
    find_by(is_current: true)
  rescue ActiveRecord::StatementInvalid, PG::UndefinedTable
    nil
  end

  # Returns the label of the current active release
  def self.current_label
    current_release&.label
  end

  # Make this release current and set all others to false
  def make_current!
    Release.transaction do
      Release.update_all(is_current: false)
      update!(is_current: true, backup_timestamp: nil)
    end
  end

  # Convert backup_timestamp datetime to string format needed by rollback
  def backup_timestamp_string
    backup_timestamp&.strftime(BACKUP_TIMESTAMP_FORMAT) if backup_timestamp
  end

  # Generate current backup timestamp string
  def self.current_backup_timestamp_string
    Time.current.strftime(BACKUP_TIMESTAMP_FORMAT)
  end

  # Convert backup timestamp string to datetime
  def self.parse_backup_timestamp_string(timestamp_string)
    return nil if timestamp_string.blank?

    begin
      Time.strptime(timestamp_string, BACKUP_TIMESTAMP_FORMAT)
    rescue ArgumentError
      nil
    end
  end

  # Find release by backup timestamp string (class method)
  def self.find_by_backup_timestamp_string(timestamp_string)
    timestamp_datetime = parse_backup_timestamp_string(timestamp_string)
    return nil if timestamp_datetime.nil?

    find_by(backup_timestamp: timestamp_datetime)
  end
end
