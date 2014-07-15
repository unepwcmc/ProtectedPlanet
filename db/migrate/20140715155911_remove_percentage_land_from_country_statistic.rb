class RemovePercentageLandFromCountryStatistic < ActiveRecord::Migration
  def change
    remove_column :country_statistics, :percentage_land, :string
  end
end
