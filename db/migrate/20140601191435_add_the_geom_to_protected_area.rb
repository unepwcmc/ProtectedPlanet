class AddTheGeomToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :the_geom, :geometry
  end
end
