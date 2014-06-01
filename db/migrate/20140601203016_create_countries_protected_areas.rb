class CreateCountriesProtectedAreas < ActiveRecord::Migration
  def change
    create_table :countries_protected_areas, :id => false do |t|
      t.references :protected_area
      t.references :country
    end

    add_index :countries_protected_areas, [:protected_area_id, :country_id],
      name: 'index_countries_protected_areas_composite'
    add_index :countries_protected_areas, :country_id
  end
end
