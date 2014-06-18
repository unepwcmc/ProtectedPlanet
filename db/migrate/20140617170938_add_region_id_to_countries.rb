class AddRegionIdToCountries < ActiveRecord::Migration
  def change
    add_column :countries, :region_id, :integer
  end
end
