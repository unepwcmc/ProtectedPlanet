class AddPercentagePaCoverToCountryStatistic < ActiveRecord::Migration
  def change
    add_column :country_statistics, :percentage_pa_cover, :float
  end
end
