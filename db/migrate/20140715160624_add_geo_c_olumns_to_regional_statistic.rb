class AddGeoCOlumnsToRegionalStatistic < ActiveRecord::Migration
  def change
    add_column :regional_statistics, :eez_area, :float
    add_column :regional_statistics, :ts_area, :float
    add_column :regional_statistics, :pa_land_area, :float
    add_column :regional_statistics, :pa_marine_area, :float
    add_column :regional_statistics, :percentage_land, :float
    add_column :regional_statistics, :percentage_pa_land_cover, :float
    add_column :regional_statistics, :percentage_pa_eez_cover, :float
    add_column :regional_statistics, :percentage_pa_ts_cover, :float
    add_column :regional_statistics, :land_area, :float
    add_column :regional_statistics, :percentage_pa_cover, :float
  end
end
