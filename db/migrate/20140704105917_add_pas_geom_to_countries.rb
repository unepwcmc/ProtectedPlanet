class AddPasGeomToCountries < ActiveRecord::Migration
  def change
    add_column :countries, :marine_pas_geom, :geometry
    add_column :countries, :land_pas_geom, :geometry
  end
end
