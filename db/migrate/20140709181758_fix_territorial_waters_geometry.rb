class FixTerritorialWatersGeometry < ActiveRecord::Migration
  def change
     rename_column :countries, :territorial_waters_geom, :ts_geom
  end
end
