class Wdpa::ProtectedAreaImporter::AttributeImporter
  BULK_SIZE = 1000
  def self.import
    protected_areas_in_bulk(BULK_SIZE) do |protected_areas|
      imported_pa_ids = []
      ActiveRecord::Base.transaction do
        protected_areas.each do |protected_area_attributes|
          imported_pa_ids << create_protected_area(protected_area_attributes)
        end
      end
    end
  end

  def self.create_protected_area(attributes)
    attributes = attributes.symbolize_keys
    standardised_attributes = Wdpa::DataStandard.attributes_from_standards_hash(
      attributes
    )

    protected_area_id = nil
    begin
      ActiveRecord::Base.transaction(requires_new: true) do
        ProtectedArea.connection.schema_cache.clear!
        ProtectedArea.reset_column_information
        protected_area_id = ProtectedArea.create!(standardised_attributes).id
      end
    rescue StandardError => e
      Rails.logger.info("ProtectedArea with WDPAID #{attributes[:wdpaid]} not imported")
      Rails.logger.info(e.message)
      Rails.logger.info(e.backtrace)
      Rails.logger.info("===DB CONFIGS===")
      Rails.logger.info(ActiveRecord::Base.configurations)
      Rails.logger.info(Rails.configuration.database_configuration)
      Rails.logger.info(ActiveRecord::Base.connection.current_database)
      Rails.logger.info(ProtectedArea.connection.current_database)
      ProtectedArea.connection.schema_cache.clear!
      ProtectedArea.reset_column_information
      Rails.logger.info(ProtectedArea.column_names)
      Rails.logger.info("===DB CONFIGS===")
    end

    return protected_area_id
  end

  private


  def self.protected_areas_in_bulk(size)
    ['standard_polygons', 'standard_points'].each do |table|
      total_pas = db.select_value("SELECT count(*) FROM #{table}").to_f
      pieces = (total_pas/size).ceil

      (0...pieces).each do |piece|
        query = build_query(table, size, size*piece)
        yield(db.select_all(query))
      end
    end
  end

  GEOMETRY_COLUMN = "wkb_geometry"
  def self.build_query(table, limit, offset)
    select = """
      SELECT array_to_string(ARRAY(
        SELECT c.column_name::text
        FROM information_schema.columns As c
        WHERE table_name = '#{table}'
          AND  c.column_name <> '#{GEOMETRY_COLUMN}'
      ), ',') As query
    """

    select_part = db.select_value(select)
    "SELECT #{select_part} FROM #{table} ORDER BY wdpaid LIMIT #{limit} OFFSET #{offset}"
  end

  def self.db
    ActiveRecord::Base.connection
  end
end
