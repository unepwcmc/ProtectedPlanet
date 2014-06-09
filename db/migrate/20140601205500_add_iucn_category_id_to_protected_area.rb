class AddIucnCategoryIdToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :iucn_category_id, :integer
  end
end
