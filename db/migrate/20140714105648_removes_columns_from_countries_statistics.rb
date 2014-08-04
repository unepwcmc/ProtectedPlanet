class RemovesColumnsFromCountriesStatistics < ActiveRecord::Migration
  def change
    remove_column :country_statistics, :area
  end
end
