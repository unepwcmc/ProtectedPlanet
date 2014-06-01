class AddWdpaIdToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :wdpa_id, :integer
    add_index :protected_areas, :wdpa_id, unique: true
  end
end
