class AddDesignationIdToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :designation_id, :integer
  end
end
