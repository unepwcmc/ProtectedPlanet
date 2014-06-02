class AddIucnCategoryIdIndexToProtectedArea < ActiveRecord::Migration
  def change
    add_index :protected_areas, :iucn_category_id
  end
end
