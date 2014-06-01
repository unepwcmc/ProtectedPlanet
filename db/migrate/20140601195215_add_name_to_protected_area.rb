class AddNameToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :name, :text
  end
end
