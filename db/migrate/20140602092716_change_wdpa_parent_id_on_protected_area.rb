class ChangeWdpaParentIdOnProtectedArea < ActiveRecord::Migration
  def change
    remove_index :protected_areas, :wdpa_parent_id
    add_index :protected_areas, :wdpa_parent_id, unique: false
  end
end
