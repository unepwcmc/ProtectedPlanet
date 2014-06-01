class AddLegalStatusIdToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :legal_status_id, :integer
  end
end
