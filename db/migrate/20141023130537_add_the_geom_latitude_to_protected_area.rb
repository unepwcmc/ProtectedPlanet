class AddTheGeomLatitudeToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :the_geom_latitude, :string
  end
end
