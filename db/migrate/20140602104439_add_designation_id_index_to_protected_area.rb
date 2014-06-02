class AddDesignationIdIndexToProtectedArea < ActiveRecord::Migration
  def change
    add_index :protected_areas, :designation_id
  end
end
