class AddCountryRelationToSubLocation < ActiveRecord::Migration
  def change
    add_column :sub_locations, :country_id, :integer
    add_index :sub_locations, :country_id
  end
end
