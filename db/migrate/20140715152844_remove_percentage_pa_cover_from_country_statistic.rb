class RemovePercentagePaCoverFromCountryStatistic < ActiveRecord::Migration
  def change
    remove_column :country_statistics, :percentage_pa_cover, :string
  end
end
