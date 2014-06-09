class AddLegalStatusIdIndexToProtectedArea < ActiveRecord::Migration
  def change
    add_index :protected_areas, :legal_status_id
  end
end
