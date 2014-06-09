class AddGisMarineAreaToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :gis_marine_area, :decimal
  end
end
