class AddBufferGeomToStandardPoints < ActiveRecord::Migration
  def change
    add_column :standard_points, :buffer_geom, :geometry
  end
end
