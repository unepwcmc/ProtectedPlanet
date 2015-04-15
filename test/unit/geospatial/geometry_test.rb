require 'test_helper'

class GeospatialGeometryTest < ActiveSupport::TestCase
  test '.repair runs a query to repair the given geometry column' do
    ActiveRecord::Base.connection.expects(:execute).with("""
      UPDATE table_name
      SET column_name = ST_Makevalid(ST_Multi(ST_Buffer(ST_MakeValid(column_name),0.0)))
      WHERE NOT ST_IsValid(column_name)
    """.squish)

    geometry = Geospatial::Geometry.new("table_name", "column_name")
    geometry.repair
  end
end
