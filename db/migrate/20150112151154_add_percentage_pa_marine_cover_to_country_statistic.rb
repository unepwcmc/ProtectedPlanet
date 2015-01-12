class AddPercentagePaMarineCoverToCountryStatistic < ActiveRecord::Migration
  def change
    add_column :country_statistics, :percentage_pa_marine_cover, :float
  end
end
