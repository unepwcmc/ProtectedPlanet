class AddAreasToCountryStatistic < ActiveRecord::Migration
  def change
    add_column :country_statistics, :eez_area, :float
    add_column :country_statistics, :ts_area, :float
    add_column :country_statistics, :pa_land_area, :float
    add_column :country_statistics, :pa_marine_area, :float
    add_column :country_statistics, :percentage_pa_land_cover, :float
    add_column :country_statistics, :percentage_pa_eez_cover, :float
    add_column :country_statistics, :percentage_pa_ts_cover, :float
  end
end
