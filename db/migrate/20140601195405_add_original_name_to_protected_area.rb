class AddOriginalNameToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :original_name, :text
  end
end
