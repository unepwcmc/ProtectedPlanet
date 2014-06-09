class CreateProtectedAreasSubLocations < ActiveRecord::Migration
  def change
    create_table :protected_areas_sub_locations, :id => false do |t|
      t.references :protected_area
      t.references :sub_location
    end

    add_index :protected_areas_sub_locations, [:protected_area_id, :sub_location_id],
      name: 'index_protected_areas_sub_locations_composite'
    add_index :protected_areas_sub_locations, :sub_location_id
  end
end
