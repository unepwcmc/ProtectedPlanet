class AddGisAreaToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :gis_area, :decimal
  end
end
