class AddNoTakeStatusIdToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :no_take_status_id, :integer
  end
end
