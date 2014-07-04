class AddColumnsToCountryStatistic < ActiveRecord::Migration
  def change
    add_column :country_statistics, :percentage_region, :decimal
    add_column :country_statistics, :percentage_land, :decimal
    add_column :country_statistics, :percentage_water, :decimal
    add_column :country_statistics, :percentage_coast, :decimal
  end
end
