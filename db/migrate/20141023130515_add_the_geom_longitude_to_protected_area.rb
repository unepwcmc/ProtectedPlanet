class AddTheGeomLongitudeToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :the_geom_longitude, :string
  end
end
