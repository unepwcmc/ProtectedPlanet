class AddLandAreaToCountryStatistic < ActiveRecord::Migration
  def change
    add_column :country_statistics, :land_area, :float
  end
end
