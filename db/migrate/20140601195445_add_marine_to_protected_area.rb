class AddMarineToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :marine, :boolean
  end
end
