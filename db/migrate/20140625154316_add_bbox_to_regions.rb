class AddBboxToRegions < ActiveRecord::Migration
  def change
    add_column :regions, :bounding_box, :geometry
  end
end
