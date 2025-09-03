# frozen_string_literal: true

class Wdpa::ProtectedAreaImporter::AttributeImporter
  BULK_SIZE = 1000
  GEOMETRY_COLUMN = 'wkb_geometry'
  RAW_PROTECTED_AREA_TABLE = {
    polygon: 'standard_polygons',
    points: 'standard_points'
  }.freeze
  RAW_PROTECTED_AREA_TABLES = RAW_PROTECTED_AREA_TABLE.values

  def self.import
    wdpaids_multiple_parcels_map = protected_area_ids_with_multiple_parcels

    protected_areas_in_bulk(BULK_SIZE) do |protected_areas|
      imported_pa_ids = []
      imported_pa_pids = []
      ActiveRecord::Base.transaction do
        protected_areas.each do |attributes|
          entry_info = current_entry_parcel_info(attributes, wdpaids_multiple_parcels_map)
          add_entry_to_protected_areas_table = entry_info[:is_first_or_only_parcel]
          add_entry_to_protected_areas_parcels_table = entry_info[:has_multiple_parcels]

          # In ProtectedPlanet-api wdpa_parent_id is used as wdpa_pid in models/protected_area.rb
          # so we cannot delete wdpa_parent_id field
          # TODO:
          #  - update ProtectedPlanet-api project to change wdpa_parent_id to wdpa_pid
          #  - make migration to ProtectedPlanet-db project to remove wdpa_parent_id in protected_areas table
          #  - In this project remove wdpa_parent_id in lib/modules/wdpa/data_standard.rb
          #  - See standardised_attributes[:wdpa_parent_id] in create_protected_area to know how the attribute is stored into db
          attributes['wdpa_parent_id'] = attributes['wdpa_pid']

          imported_pa_ids << create_protected_area(attributes) if add_entry_to_protected_areas_table
          imported_pa_pids << create_protected_area_parcel(attributes) if add_entry_to_protected_areas_parcels_table
        end
      end
    end
  end

  def self.create_protected_area(attributes)
    protected_area_id = nil
    standardised_attributes = Wdpa::DataStandard.attributes_from_standards_hash(attributes.symbolize_keys)
    # Set wdpa_parent_id for ProtectedPlanet-api compatibility (see comment above)
    # Note: wdpa_pid is already set by DataStandard, we just need wdpa_parent_id for API compatibility
    standardised_attributes[:wdpa_parent_id] = standardised_attributes[:wdpa_pid].to_i
    begin
      ActiveRecord::Base.transaction(requires_new: true) do
        # Below lines are needed as the ProtectedArea model
        # wasn't getting the new columns information after switching from the
        # postgres db to the newly created db
        ProtectedArea.connection.schema_cache.clear!
        ProtectedArea.reset_column_information
        protected_area_id = ProtectedArea.create!(standardised_attributes).id
      end
    rescue StandardError => e
      Rails.logger.warn("Wdpa::ProtectedAreaImporter::AttributeImporter.import ProtectedArea
      WDPAID #{standardised_attributes[:wdpa_id]}
      WDPA_PID #{standardised_attributes[:wdpa_pid]} was not imported
      Error message: #{e.message}")
    end
    protected_area_id
  end

  def self.create_protected_area_parcel(attributes)
    protected_area_pid = nil
    standardised_attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash(attributes.symbolize_keys)
    begin
      ActiveRecord::Base.transaction(requires_new: true) do
        # Below lines are needed as the ProtectedArea model
        # wasn't getting the new columns information after switching from the
        # postgres db to the newly created db
        ProtectedAreaParcel.connection.schema_cache.clear!
        ProtectedAreaParcel.reset_column_information
        protected_area_pid = ProtectedAreaParcel.create!(standardised_attributes).id
      end
    rescue StandardError => e
      Rails.logger.warn("Wdpa::ProtectedAreaImporter::AttributeImporter.import ProtectedAreaParcel
      WDPAID #{standardised_attributes[:wdpa_id]}
      WDPA_PID #{standardised_attributes[:wdpa_pid]} was not imported
      Error message: #{e.message}")
    end
    protected_area_pid
  end

  def self.current_entry_parcel_info(protected_area_attributes, wdpaids_multiple_parcels_map)
    wdpa_id = protected_area_attributes['wdpaid']
    wdpa_pid = protected_area_attributes['wdpa_pid']
    parcel_info = wdpaids_multiple_parcels_map[wdpa_id]
    {
      wdpa_id: wdpa_id,
      wdpa_pid: wdpa_pid,
      parcel_info: parcel_info,
      is_first_or_only_parcel: parcel_info.nil? || parcel_info == wdpa_pid,
      has_multiple_parcels: !parcel_info.nil?
    }
  end

  def self.protected_area_ids_with_multiple_parcels
    protected_area_ids_with_multiple_parcels = {}

    RAW_PROTECTED_AREA_TABLES.each do |table|
      # The following sql command will return all wdpaids that have more then one parcels
      # and its first_wdpa_pid (ordering by all wdpa_pid)

      # i,e wdpaid 18422 has parcels of 18422_A, 18422_B, 18422_C
      # and first_wdpa_pid is 18422_A (sorted by sql MIN(wdpa_pid) )

      # Example return as below
      # wdpaid, first_wdpa_pid
      # 18422 , 18422_A
      # 18426 , 18426_A
      find_wdpa_ids_with_multiple_parcels_command = "
        SELECT wdpaid, MIN(wdpa_pid) AS first_wdpa_pid
        FROM #{table}
        GROUP BY wdpaid
        HAVING COUNT(*) > 1;"
      ActiveRecord::Base.connection.execute(find_wdpa_ids_with_multiple_parcels_command).each do |row|
        protected_area_ids_with_multiple_parcels[row['wdpaid']] = row['first_wdpa_pid']
      end
    end
    protected_area_ids_with_multiple_parcels
  end

  def self.protected_areas_in_bulk(size)
    RAW_PROTECTED_AREA_TABLES.each do |table|
      total_pas = db.select_value("SELECT count(*) FROM #{table}").to_f
      pieces = (total_pas / size).ceil
      pieces = 1 if total_pas.positive? && pieces.zero?
      (0...pieces).each do |piece|
        query = build_query(table, size, size * piece)
        yield(db.select_all(query))
      end
    end
  end

  def self.build_query(table, limit, offset)
    select = <<~SQL
      SELECT array_to_string(ARRAY(
        SELECT c.column_name::text
        FROM information_schema.columns As c
        WHERE table_name = '#{table}'
          AND  c.column_name <> '#{GEOMETRY_COLUMN}'
      ), ',') As query
    SQL

    select_part = db.select_value(select)
    "SELECT #{select_part} FROM #{table} ORDER BY wdpaid LIMIT #{limit} OFFSET #{offset}"
  end

  def self.db
    ActiveRecord::Base.connection
  end
end
