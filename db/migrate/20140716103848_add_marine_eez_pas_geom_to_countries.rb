class AddMarineEezPasGeomToCountries < ActiveRecord::Migration
  def change
    add_column :countries, :marine_eez_pas_geom, :geometry
  end
end
