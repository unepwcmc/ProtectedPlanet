class Geospatial::Geometry
  REPAIR_TEMPLATE = File.read(
    File.expand_path(File.join('../templates', 'repair_geometries.erb'), __FILE__)
  )

  def initialize table_name, column_name
    @table_name = table_name
    @column_name = column_name
  end

  def repair
    repair_query = ERB.new(REPAIR_TEMPLATE).result(binding).squish
    db.execute repair_query
  end

  private

  def db
    ActiveRecord::Base.connection
  end
end
