class RemovesColumnsFromCountriesStatistics < ActiveRecord::Migration
  def change
    remove_column :country_statistics, :area 
    remove_column :country_statistics, :percentage_cover_pas
    remove_column :country_statistics, :percentage_region
    remove_column :country_statistics, :percentage_water
    remove_column :country_statistics, :percentage_coast
  end
end
