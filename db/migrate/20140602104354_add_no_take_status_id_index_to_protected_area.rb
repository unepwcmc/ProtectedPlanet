class AddNoTakeStatusIdIndexToProtectedArea < ActiveRecord::Migration
  def change
    add_index :protected_areas, :no_take_status_id
  end
end
