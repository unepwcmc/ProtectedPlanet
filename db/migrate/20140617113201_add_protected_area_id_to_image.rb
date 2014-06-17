class AddProtectedAreaIdToImage < ActiveRecord::Migration
  def change
    add_column :images, :protected_area_id, :integer
    add_index :images, :protected_area_id
  end
end
