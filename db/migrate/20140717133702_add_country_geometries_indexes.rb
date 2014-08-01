class AddCountryGeometriesIndexes < ActiveRecord::Migration
  def change
    add_index :countries, :land_geom, using: :gist
    add_index :countries, :eez_geom, using: :gist
    add_index :countries, :ts_geom, using: :gist
  end
end
