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
    site_ids_multiple_parcels_map = protected_area_ids_with_multiple_parcels

    protected_areas_in_bulk(BULK_SIZE) do |protected_areas|
      imported_pa_ids = []
      imported_pa_pids = []
      ActiveRecord::Base.transaction do
        protected_areas.each do |attributes|
          entry_info = current_entry_parcel_info(attributes, site_ids_multiple_parcels_map)
          add_entry_to_protected_areas_table = entry_info[:is_first_or_only_parcel]
          add_entry_to_protected_areas_parcels_table = entry_info[:has_multiple_parcels]

          # In ProtectedPlanet-api wdpa_parent_id is used as wdpa_pid in models/protected_area.rb
          # so we cannot delete wdpa_parent_id field
          # TODO:
          #  - update ProtectedPlanet-api project to change wdpa_parent_id to wdpa_pid
          #  - make migration to ProtectedPlanet-db project to remove wdpa_parent_id in protected_areas table
          #  - In this project remove wdpa_parent_id in lib/modules/wdpa/data_standard.rb
          #  - See standardised_attributes[:wdpa_parent_id] in create_protected_area to know how the attribute is stored into db
          attributes['wdpa_parent_id'] = attributes['site_pid'] || attributes['wdpa_pid']

          imported_pa_ids << create_protected_area(attributes) if add_entry_to_protected_areas_table
          imported_pa_pids << create_protected_area_parcel(attributes) if add_entry_to_protected_areas_parcels_table
        end
      end
    end
  end

  def self.create_protected_area(attributes_in_view)
    protected_area_id = nil
    standardised_attributes = Wdpa::DataStandard.attributes_from_standards_hash(attributes_in_view.symbolize_keys)
    
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
      site_id #{standardised_attributes[:site_id]}
      site_pid #{standardised_attributes[:site_pid]} was not imported
      Error message: #{e.message}")
    end
    protected_area_id
  end

  def self.create_protected_area_parcel(attributes_in_view)
    protected_area_pid = nil
    standardised_attributes = Wdpa::ParcelDataStandard.attributes_from_standards_hash(attributes_in_view.symbolize_keys)
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
      site_id #{standardised_attributes[:site_id]}
      site_pid #{standardised_attributes[:site_pid]} was not imported
      Error message: #{e.message}")
    end
    protected_area_pid
  end

  def self.current_entry_parcel_info(protected_area_attributes_in_view, site_ids_multiple_parcels_map)
    site_id = protected_area_attributes_in_view['site_id'] || protected_area_attributes_in_view['wdpaid']
    site_pid = protected_area_attributes_in_view['site_pid'] || protected_area_attributes_in_view['wdpa_pid']
    parcel_info = site_ids_multiple_parcels_map[site_id]
    {
      site_id: site_id,
      site_pid: site_pid,
      parcel_info: parcel_info,
      is_first_or_only_parcel: parcel_info.nil? || parcel_info == site_pid,
      has_multiple_parcels: !parcel_info.nil?
    }
  end

  def self.protected_area_ids_with_multiple_parcels
    protected_area_ids_with_multiple_parcels = {}

    RAW_PROTECTED_AREA_TABLES.each do |table|
      # The following sql command will return all site_ids that have more then one parcels
      # and its first_site_pid (ordering by all wdpa_pid)

      # i,e site_id 18422 has parcels of 18422_A, 18422_B, 18422_C
      # and first_site_pid is 18422_A (sorted by sql MIN(wdpa_pid) )

      # Example return as below
      # site_id, first_site_pid
      # 18422 , 18422_A
      # 18426 , 18426_A
      # the views are still named wdpaid, wdpa_pid but we rename them to site_id, site_pid
      find_site_ids_with_multiple_parcels_command = "
        SELECT wdpaid as site_id, MIN(wdpa_pid) AS first_site_pid
        FROM #{table}
        GROUP BY site_id
        HAVING COUNT(*) > 1;"
      ActiveRecord::Base.connection.execute(find_site_ids_with_multiple_parcels_command).each do |row|
        protected_area_ids_with_multiple_parcels[row['site_id']] = row['first_site_pid']
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
