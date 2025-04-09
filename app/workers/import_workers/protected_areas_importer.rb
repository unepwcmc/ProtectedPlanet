# As of 03Apr2025 This file doesn't seem to be used Wdpa::ProtectedAreaImporter seems to be replacing this
# 
class ImportWorkers::ProtectedAreasImporter < ImportWorkers::Base
  def perform table, limit, offset
    query = create_query(table, limit, offset)
    imported_pa_ids = []

    Bystander.log(query)
    ActiveRecord::Base.transaction do
      db.select_all(query).each do |protected_area|
        ActiveRecord::Base.transaction(requires_new: true) do
          imported_pa_ids << import_pa(protected_area)
        end
      end
    end

    # imported_pa_ids.compact.each do |pa_id|
    #   ImportWorkers::WikipediaSummaryWorker.perform_async pa_id
    # end
  ensure
    finalise_job
  end

  def import_pa(protected_area_attributes)
    standardised_attributes = Wdpa::DataStandard.attributes_from_standards_hash(
      protected_area_attributes.symbolize_keys
    )

    pa = nil
    begin
      pa = ProtectedArea.create!(standardised_attributes)
    rescue => err
      Bystander.log("""
        PA with WDPAID #{protected_area_attributes[:wdpaid]} was not imported because:
        > #{err.message}
      """)
      raise ActiveRecord::Rollback
    end

    pa ? pa.id : nil
  end

  GEOMETRY_COLUMN = "wkb_geometry"
  def create_query table, limit, offset
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

  def db
    ActiveRecord::Base.connection
  end
end
