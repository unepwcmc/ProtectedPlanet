class AddPaEezAreaToRegionalStatistic < ActiveRecord::Migration
  def change
    add_column :regional_statistics, :pa_eez_area, :float
    add_column :regional_statistics, :pa_ts_area, :float
  end
end
