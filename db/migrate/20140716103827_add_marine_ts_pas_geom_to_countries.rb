class AddMarineTsPasGeomToCountries < ActiveRecord::Migration
  def change
    add_column :countries, :marine_ts_pas_geom, :geometry
  end
end
