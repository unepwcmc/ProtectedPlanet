class AddPaEezAreaToCountryStatistic < ActiveRecord::Migration
  def change
    add_column :country_statistics, :pa_eez_area, :float
    add_column :country_statistics, :pa_ts_area, :float
  end
end
