class AddMarineAreaToCountryStatistic < ActiveRecord::Migration
  def change
    add_column :country_statistics, :marine_area, :float
  end
end
